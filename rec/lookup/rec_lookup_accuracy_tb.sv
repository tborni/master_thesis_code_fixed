module rec_lookup_accuracy_tb;

	localparam int unsigned  NUM_SAMPLES = 10000;

	localparam int unsigned  MIN_ADDR_WIDTH   =  6;
	localparam int unsigned  MAX_ADDR_WIDTH   =  6;
	localparam int unsigned  STEP_ADDR_WIDTH  =  1;
	localparam int unsigned  MIN_WORD_WIDTH   =  6;
	localparam int unsigned  MAX_WORD_WIDTH   =  6;
	localparam int unsigned  STEP_WORD_WIDTH  =  2;
	localparam int unsigned  MIN_NUM_NEWTON   =  1;
	localparam int unsigned  MAX_NUM_NEWTON   =  1;
	localparam real          NEWTON_COEFF_START = 2.000000;
	localparam real          NEWTON_COEFF_END   = 2.000066;
	localparam real          NEWTON_COEFF_STEP  = 0.000001;

	localparam bit  USE_NEWTON_COEFF_HEURISTIC = 0;

	// Initiation interval sustained by the lookup+Newton datapath.  The Newton
	// arithmetic (and hence the accuracy) is identical for every II; changing
	// this only re-times the shared DSP.  Set to a single constant here (the
	// in-order DUTs stay matched to the accepted-sample stream via `all_xrdy`).
	//   1     : fully pipelined (2 DSPs)
	//   2..7  : single-DSP interleave
	//   >= 8  : single-DSP exclusive
	localparam int unsigned  SUSTAINABLE_INTERVAL = 1;

	localparam int unsigned  NUM_ADDR   = (MAX_ADDR_WIDTH - MIN_ADDR_WIDTH) / STEP_ADDR_WIDTH + 1;
	localparam int unsigned  NUM_WORD   = (MAX_WORD_WIDTH - MIN_WORD_WIDTH) / STEP_WORD_WIDTH + 1;
	localparam int unsigned  NUM_NEWTON = MAX_NUM_NEWTON - MIN_NUM_NEWTON + 1;
	// Inclusive count of coefficient steps.  The +1e-9 absorbs float rounding
	// so an exactly-reachable END is not dropped by the floor of int'().
	localparam int unsigned  NUM_COEFF_SWEEP = int'((NEWTON_COEFF_END - NEWTON_COEFF_START) / NEWTON_COEFF_STEP + 1.0e-9) + 1;
	// Coefficient-axis length: a single heuristic point when armed, else the
	// full sweep. Compile-time constant -- sizes NUM_INST and the II
	// flattening below.
	localparam int unsigned  NUM_COEFF  = USE_NEWTON_COEFF_HEURISTIC ? 1 : NUM_COEFF_SWEEP;
	localparam int unsigned  NUM_INST   = NUM_NEWTON * NUM_ADDR * NUM_WORD * NUM_COEFF;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	// Shared input stream.  `xvld` only asserts on cycles when every DUT is
	// ready, so the fork transfers the same sample to all DUTs in lockstep.
	shortreal     fx;
	uwire [31:0]  x = $shortrealtobits(fx);
	logic         xvld_int = 0;
	logic [NUM_INST-1:0]  xrdy_vec;
	uwire         all_xrdy = &xrdy_vec;
	uwire         xvld     = xvld_int & all_xrdy;

	// Shared sample buffer.  Index = sequence number of an accepted sample.
	shortreal     samples[NUM_SAMPLES];

	// Per-instance accumulators, written from inside the generate block and
	// read from the driver after drain.  Flattening these out of the genvar
	// scope lets the driver loop over them with a plain `int` index.
	int unsigned  num_evaluated          [NUM_INST];
	real          total_rel_error_squared[NUM_INST];
	real          max_rel_error          [NUM_INST];
	shortreal     max_rel_error_x        [NUM_INST];
	real          max_rel_error_ref      [NUM_INST];
	shortreal     max_rel_error_fr       [NUM_INST];

	// Random fp sample generator
	// Uniform over fp32 representables in [1,inf)
	// Exclude very large values to avoid denormalized numbers on the outputs side
	//	Maximum allowed input is equal to 1 divided by minimal normal number:
	//	1/(1.0*2^(1-127)) = 2^(+126) = 2^(253-127)
	//		252 is the largest allowed exponent as 253 combined with mantissa != 0 leads to denormalized results
	//	Exponent range: {127,…,252}
	function shortreal rand_fp();
		int unsigned bits;
		bits = $urandom();
		bits[30:23] = $urandom_range(127, 252);
		bits[31] = 0;
		return $bitstoshortreal(bits);
	endfunction : rand_fp

	function automatic shortreal newton_coeff(input int unsigned  aw, input int unsigned  ww);
		real  d;
		// RMSRE for NS = 0
		case(aw * 100 + ww)
			 606:  d = 4.814353e-03;
			 608:  d = 3.311962e-03;
			 610:  d = 3.213591e-03;
			 612:  d = 3.208322e-03;
			 614:  d = 3.208223e-03;
			 616:  d = 3.208117e-03;
			 706:  d = 3.750721e-03;
			 708:  d = 1.825100e-03;
			 710:  d = 1.610490e-03;
			 712:  d = 1.594521e-03;
			 714:  d = 1.594599e-03;
			 716:  d = 1.594475e-03;
			 806:  d = 3.527327e-03;
			 808:  d = 1.172035e-03;
			 810:  d = 8.252768e-04;
			 812:  d = 7.980845e-04;
			 814:  d = 7.962687e-04;
			 816:  d = 7.961944e-04;
			 906:  d = 3.469722e-03;
			 908:  d = 9.512602e-04;
			 910:  d = 4.568629e-04;
			 912:  d = 4.008632e-04;
			 914:  d = 3.979835e-04;
			 916:  d = 3.979233e-04;
			1006:  d = 3.449031e-03;
			1008:  d = 8.834157e-04;
			1010:  d = 2.877750e-04;
			1012:  d = 2.059388e-04;
			1014:  d = 1.992885e-04;
			1016:  d = 1.988556e-04;
			1106:  d = 3.445430e-03;
			1108:  d = 8.674724e-04;
			1110:  d = 2.360037e-04;
			1112:  d = 1.136588e-04;
			1114:  d = 1.007381e-04;
			1116:  d = 9.986526e-05;
			default:  d = 0.0;
		endcase
		return $bitstoshortreal($shortrealtobits(shortreal'(2.0 + d * d / (1.0 + d * d))));
	endfunction : newton_coeff

	// Decode a coefficient-sweep index into the real NEWTON_COEFF. Only used
	// when the coefficient heuristic is disabled; mirrors newton_coeff_swept in
	// rec_bipartite_accuracy_tb (there the sweep is fixed-point milli-units,
	// here it is the NEWTON_COEFF_START..END real grid).
	function automatic shortreal newton_coeff_swept(input int unsigned  coeff_idx);
		return shortreal'(NEWTON_COEFF_START + real'(coeff_idx) * NEWTON_COEFF_STEP);
	endfunction : newton_coeff_swept

	// Parallel DUT instances
	for(genvar  ni = 0; ni < NUM_NEWTON; ni++) begin : gNewton
		localparam int unsigned  NS = MIN_NUM_NEWTON + ni;

		for(genvar  ai = 0; ai < NUM_ADDR; ai++) begin : gAddr
			localparam int unsigned  AW = MIN_ADDR_WIDTH + ai * STEP_ADDR_WIDTH;

			for(genvar  wi = 0; wi < NUM_WORD; wi++) begin : gWord
				localparam int unsigned  WW = MIN_WORD_WIDTH + wi * STEP_WORD_WIDTH;

				for(genvar  ci = 0; ci < NUM_COEFF; ci++) begin : gCoeff
					// NEWTON_COEFF source: the per-geometry bias-corrected
					// heuristic (single point), or the swept real grid. Both
					// arms are pure constant functions; passing the selected
					// value straight into the parameter port mirrors the proven
					// pre-change `.NEWTON_COEFF(C)` idiom (no intermediate real
					// localparam).
					localparam int unsigned  II = ((ni * NUM_ADDR + ai) * NUM_WORD + wi) * NUM_COEFF + ci;

					uwire [31:0]  r;
					uwire         rvld;

					rec_lookup #(
						.ADDR_WIDTH(AW),
						.WORD_WIDTH(WW),
						.NUM_NEWTON_STEPS(NS),
						.SUSTAINABLE_INTERVAL(SUSTAINABLE_INTERVAL),
						.NEWTON_COEFF(USE_NEWTON_COEFF_HEURISTIC ? newton_coeff(AW, WW)
						                                         : newton_coeff_swept(ci))
					) dut (
						.clk, .rst,
						.idat(x), .ivld(xvld), .irdy(xrdy_vec[II]),
						.odat(r), .ovld(rvld)
					);

					always_ff @(posedge clk iff rvld) begin
						shortreal  x_sample;
						shortreal  fr_local;
						real       rec_ref, diff, rel_error;
						// Coefficient for diagnostics (matches the value elaborated
						// into this instance's NEWTON_COEFF above).
						automatic shortreal  c_used = USE_NEWTON_COEFF_HEURISTIC ? newton_coeff(AW, WW)
						                                                         : newton_coeff_swept(ci);

						assert(num_evaluated[II] < NUM_SAMPLES) else begin
							$error("Spurious output (NS=%0d AW=%0d WW=%0d C=%.6f) at sample %0d",
								NS, AW, WW, c_used, num_evaluated[II]);
							$stop;
						end

						x_sample  = samples[num_evaluated[II]];
						fr_local  = $bitstoshortreal(r);
						rec_ref   = 1.0 / real'(x_sample);
						diff      = real'(fr_local) - rec_ref;
						rel_error = ((diff < 0.0) ? -diff : diff) / rec_ref;

						total_rel_error_squared[II] += rel_error * rel_error;
						if(rel_error > max_rel_error[II]) begin
							max_rel_error[II]     = rel_error;
							max_rel_error_x[II]   = x_sample;
							max_rel_error_ref[II] = rec_ref;
							max_rel_error_fr[II]  = fr_local;
						end
						num_evaluated[II]++;
					end

				end : gCoeff

			end : gWord
		end : gAddr
	end : gNewton

	// -------------------------------------------------------------------
	// Driver
	// -------------------------------------------------------------------
	initial begin
		@(posedge clk iff !rst);
		repeat(100) @(posedge clk);

		// Issue NUM_SAMPLES samples.  `fx` is updated via NBA so it takes
		// effect at the next posedge; we wait for the cycle on which every
		// DUT is simultaneously ready (the cycle on which the sample is
		// accepted) and then record it.
		xvld_int <= 1;
		for(int unsigned  i = 0; i < NUM_SAMPLES; i++) begin
			fx <= rand_fp();
			@(posedge clk iff all_xrdy);
			samples[i] = fx;
		end
		xvld_int <= 0;

		// Drain the pipeline.  The shared-DSP bands take up to one initiation
		// interval plus the 2*DSP_LATENCY traversal to emit the final result,
		// so scale the drain with SUSTAINABLE_INTERVAL.
		repeat(50 + 4*SUSTAINABLE_INTERVAL) @(posedge clk);

		$display("=========================================================================");
		$display("rec_lookup accuracy sweep");
		$display("  NUM_SAMPLES      = %0d", NUM_SAMPLES);

		for(int unsigned  ni = 0; ni < NUM_NEWTON; ni++) begin
			automatic int unsigned  NS = MIN_NUM_NEWTON + ni;
			for(int unsigned  ai = 0; ai < NUM_ADDR; ai++) begin
				automatic int unsigned  AW = MIN_ADDR_WIDTH + ai * STEP_ADDR_WIDTH;
				for(int unsigned  wi = 0; wi < NUM_WORD; wi++) begin
					automatic int unsigned  WW = MIN_WORD_WIDTH + wi * STEP_WORD_WIDTH;
					for(int unsigned  ci = 0; ci < NUM_COEFF; ci++) begin
						automatic shortreal     C  = USE_NEWTON_COEFF_HEURISTIC ? newton_coeff(AW, WW)
						                                                         : newton_coeff_swept(ci);
						automatic int unsigned  II = ((ni * NUM_ADDR + ai) * NUM_WORD + wi) * NUM_COEFF + ci;
						automatic real          rmsre;

						assert(num_evaluated[II] == NUM_SAMPLES) else begin
							$error("Unexpected number of outputs for (NS=%0d, AW=%0d, WW=%0d, C=%.6f): expected %0d, got %0d", NS, AW, WW, C, NUM_SAMPLES, num_evaluated[II]);
							$stop;
						end

						rmsre = $sqrt(total_rel_error_squared[II] / num_evaluated[II]);
						$display("  NS=%0d AW=%2d WW=%2d C=%.6f  RMSRE=%.6e  max_rel_error=%.6e  at x=%.9g  (dut=%.9g, ref=%.9g)", NS, AW, WW, C, rmsre, max_rel_error[II],
							max_rel_error_x[II], max_rel_error_fr[II], max_rel_error_ref[II]);
					end
				end
			end
		end

		$display("=========================================================================");
		$finish;
	end

endmodule : rec_lookup_accuracy_tb
