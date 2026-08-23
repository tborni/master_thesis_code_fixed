module rec_bipartite_accuracy_tb;

	localparam int unsigned  NUM_SAMPLES = 10000;

	// Parameter sweep ranges. Filtered Pareto-front:
	//   - ADDR_WIDTH_1 == ADDR_WIDTH_2 (symmetric split)
	//   - WORD_WIDTH set by the bipartite-error heuristic (see below)
	// so only ~ (#ADDR_0 * #ADDR_1) DUTs are actually instantiated per
	// Newton-step setting.
	localparam int unsigned  MIN_ADDR_0     = 2;
	localparam int unsigned  MAX_ADDR_0     = 6;
	localparam int unsigned  MIN_ADDR_1     = 3;
	localparam int unsigned  MAX_ADDR_1     = 7;
	localparam int unsigned  MIN_ADDR_2     = 3;
	localparam int unsigned  MAX_ADDR_2     = 7;
	localparam int unsigned  MIN_WORD       = 8;
	localparam int unsigned  MAX_WORD       = 23;
	localparam int unsigned  MIN_NUM_NEWTON = 0;
	localparam int unsigned  MAX_NUM_NEWTON = 1;

	localparam int unsigned  NUM_ADDR_0 = MAX_ADDR_0 - MIN_ADDR_0 + 1;
	localparam int unsigned  NUM_ADDR_1 = MAX_ADDR_1 - MIN_ADDR_1 + 1;
	localparam int unsigned  NUM_ADDR_2 = MAX_ADDR_2 - MIN_ADDR_2 + 1;
	localparam int unsigned  NUM_WORD   = MAX_WORD   - MIN_WORD   + 1;
	localparam int unsigned  NUM_NEWTON = MAX_NUM_NEWTON - MIN_NUM_NEWTON + 1;
	localparam int unsigned  NUM_INST   = NUM_NEWTON * NUM_ADDR_0 * NUM_ADDR_1 * NUM_ADDR_2 * NUM_WORD;

	// Bipartite-error heuristic (mirrors exp_bipartite_accuracy_tb):
	// WORD_WIDTH is chosen large enough to keep quantization noise below
	// the intrinsic linearization error of the two tables.
	//   range_0 = 2*A_0 + A_1 + 2  - upper-table curvature term
	//   range_1 = A_0 + A_1 + A_2 + 1 - lower-table cross-term
	// adding a 2-bit slack for accumulated quantization. Only the combo
	// that hits this heuristic is instantiated; the rest are stubbed out
	// so the driver's all_xrdy reduction doesn't stall on them.
	function automatic int unsigned word_width_heuristic(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2
	);
		automatic int unsigned  range_0 = 2*addr_width_0 + addr_width_1;
		automatic int unsigned  range_1 =   addr_width_0 + addr_width_1 + addr_width_2;
		automatic int unsigned  word_width = ((range_0 < range_1) ? range_0 : range_1) + 1 + 3;
		// Cap at 23: the fp32 output keeps only 23 mantissa bits, so table precision
		// beyond 23 fractional bits is discarded before it reaches the result. Any
		// wider value only grows the ROMs and the mantissa adder for no accuracy gain.
		return (word_width > 23) ? 23 : word_width;
	endfunction : word_width_heuristic

	function automatic bit config_enabled(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2,
		input int unsigned  word_width
	);
		return (addr_width_1 == addr_width_2)
			&& (word_width == word_width_heuristic(addr_width_0, addr_width_1, addr_width_2))
			&& (addr_width_0 + addr_width_1 + addr_width_2 <= 23)
			&& (addr_width_0 + addr_width_1 >= 3);
	endfunction : config_enabled

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	// Shared input stream. `xvld` only asserts on cycles when every DUT is
	// ready, so the fork transfers the same sample to all DUTs in lockstep.
	shortreal     fx;
	uwire [31:0]  x = $shortrealtobits(fx);
	logic         xvld_int = 0;
	logic [NUM_INST-1:0]  xrdy_vec;
	uwire         all_xrdy = &xrdy_vec;
	uwire         xvld     = xvld_int & all_xrdy;

	// Shared sample buffer. Index = sequence number of an accepted sample.
	shortreal     samples[NUM_SAMPLES];

	// Per-instance accumulators, flattened so the report loop can index
	// them with a plain `int`. Slots belonging to disabled configs are
	// stubbed out below with num_evaluated == NUM_SAMPLES so the drain
	// assertion still passes.
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

	// Newton-step coefficient. The textbook update uses 2.0; with the
	// per-geometry seed RMSRE d characterized below (NS=0 sweep from
	// accuracy_bipartite.txt) the bias-corrected value 2 + d^2/(1 - d^2)
	// shifts the Newton optimum to the centroid of the seed error
	// distribution. Same derivation as rec_lookup_accuracy_tb; see it
	// for context.
	function automatic shortreal newton_coeff(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2,
		input int unsigned  word_width
	);
		real  d;
		// RMSRE for NS = 0
		case(((addr_width_0 * 10 + addr_width_1) * 10 + addr_width_2) * 100 + word_width)
			23311:  d = 1.068728e-03;
			24412:  d = 4.107992e-04;
			25513:  d = 1.882719e-04;
			26614:  d = 9.147795e-05;
			27715:  d = 4.506498e-05;
			33313:  d = 4.362955e-04;
			34414:  d = 1.348261e-04;
			35515:  d = 5.187148e-05;
			36616:  d = 2.359834e-05;
			37717:  d = 1.149383e-05;
			43314:  d = 2.055342e-04;
			44416:  d = 5.489595e-05;
			45517:  d = 1.686220e-05;
			46618:  d = 6.518152e-06;
			47719:  d = 2.950319e-06;
			53315:  d = 1.010053e-04;
			54417:  d = 2.574804e-05;
			55519:  d = 6.864644e-06;
			56620:  d = 2.093365e-06;
			57721:  d = 8.123573e-07;
			63316:  d = 5.050462e-05;
			64418:  d = 1.265969e-05;
			65520:  d = 3.223586e-06;
			66622:  d = 8.532496e-07;
			67723:  d = 2.571051e-07;
			default:  d = 0.0;
		endcase
		return $bitstoshortreal($shortrealtobits(shortreal'(2.0 + d * d / (1.0 + d * d))));
	endfunction : newton_coeff

	// Index flattening: II = (((ni * NUM_ADDR_0 + a0) * NUM_ADDR_1 + a1) * NUM_ADDR_2 + a2) * NUM_WORD + w
	// keeps the WORD axis fastest-varying and the Newton-step axis slowest,
	// matching the report loop below.

	// Parallel DUT instances
	for(genvar  ni = 0; ni < NUM_NEWTON; ni++) begin : gNewton
		localparam int unsigned  NS = MIN_NUM_NEWTON + ni;

		for(genvar  a0i = 0; a0i < NUM_ADDR_0; a0i++) begin : gA0
			localparam int unsigned  A0 = MIN_ADDR_0 + a0i;

			for(genvar  a1i = 0; a1i < NUM_ADDR_1; a1i++) begin : gA1
				localparam int unsigned  A1 = MIN_ADDR_1 + a1i;

				for(genvar  a2i = 0; a2i < NUM_ADDR_2; a2i++) begin : gA2
					localparam int unsigned  A2 = MIN_ADDR_2 + a2i;

					for(genvar  wi = 0; wi < NUM_WORD; wi++) begin : gW
						localparam int unsigned  WW = MIN_WORD + wi;
						localparam int unsigned  II = (((ni * NUM_ADDR_0 + a0i) * NUM_ADDR_1 + a1i) * NUM_ADDR_2 + a2i) * NUM_WORD + wi;

						if(config_enabled(A0, A1, A2, WW)) begin : gEna
							uwire [31:0]  r;
							uwire         rvld;

							rec_bipartite #(
								.ADDR_WIDTH_0(A0),
								.ADDR_WIDTH_1(A1),
								.ADDR_WIDTH_2(A2),
								.WORD_WIDTH  (WW),
								.NUM_NEWTON_STEPS(NS),
								.NEWTON_COEFF(newton_coeff(A0, A1, A2, WW))
							) dut (
								.clk, .rst,
								.idat(x), .ivld(xvld), .irdy(xrdy_vec[II]),
								.odat(r), .ovld(rvld)
							);

							always_ff @(posedge clk iff rvld) begin
								shortreal  x_sample;
								shortreal  fr_local;
								real       rec_ref, diff, rel_error;

								assert(num_evaluated[II] < NUM_SAMPLES) else begin
									$error("Spurious output (NS=%0d A0=%0d A1=%0d A2=%0d WW=%0d) at sample %0d",
										NS, A0, A1, A2, WW, num_evaluated[II]);
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
						end : gEna
						else begin : gStub
							// Disabled by the filter: tie off readiness to 1 so
							// the AND-reduction doesn't stall, and prefill the
							// sample count so the drain assertion passes. The
							// per-instance accumulators stay at their default
							// zero, and the report loop skips this slot.
							assign  xrdy_vec[II] = 1'b1;
							initial begin
								num_evaluated[II] = NUM_SAMPLES;
							end
						end : gStub

					end : gW
				end : gA2
			end : gA1
		end : gA0
	end : gNewton

	// -------------------------------------------------------------------
	// Driver
	// -------------------------------------------------------------------
	initial begin
		@(posedge clk iff !rst);
		repeat(100) @(posedge clk);

		// Issue NUM_SAMPLES samples. `fx` is updated via NBA so it takes
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

		// Drain the pipeline. rec_bipartite latency = SEED_LATENCY (3) +
		// NUM_NEWTON_STEPS * 2 * DSP_LATENCY (8) = 11 cycles at NS=1;
		// pad generously.
		repeat(64) @(posedge clk);

		$display("=========================================================================");
		$display("rec_bipartite accuracy sweep");
		$display("  NUM_SAMPLES      = %0d", NUM_SAMPLES);

		for(int unsigned  ni = 0; ni < NUM_NEWTON; ni++) begin
			automatic int unsigned  NS = MIN_NUM_NEWTON + ni;
			for(int unsigned  a0i = 0; a0i < NUM_ADDR_0; a0i++) begin
				automatic int unsigned  A0 = MIN_ADDR_0 + a0i;
				for(int unsigned  a1i = 0; a1i < NUM_ADDR_1; a1i++) begin
					automatic int unsigned  A1 = MIN_ADDR_1 + a1i;
					for(int unsigned  a2i = 0; a2i < NUM_ADDR_2; a2i++) begin
						automatic int unsigned  A2 = MIN_ADDR_2 + a2i;
						for(int unsigned  wi = 0; wi < NUM_WORD; wi++) begin
							automatic int unsigned  WW = MIN_WORD + wi;
							automatic int unsigned  II = (((ni * NUM_ADDR_0 + a0i) * NUM_ADDR_1 + a1i) * NUM_ADDR_2 + a2i) * NUM_WORD + wi;
							automatic real          rmsre;

							if(!config_enabled(A0, A1, A2, WW))  continue;

							assert(num_evaluated[II] == NUM_SAMPLES) else begin
								$error("Unexpected number of outputs for (NS=%0d, A0=%0d, A1=%0d, A2=%0d, WW=%0d): expected %0d, got %0d",
									NS, A0, A1, A2, WW, NUM_SAMPLES, num_evaluated[II]);
								$stop;
							end

							rmsre = $sqrt(total_rel_error_squared[II] / num_evaluated[II]);
							$display("  NS=%0d A0=%0d A1=%0d A2=%0d WW=%2d  RMSRE=%.6e  max_rel_error=%.6e  at x=%.9g  (dut=%.9g, ref=%.9g)",
								NS, A0, A1, A2, WW, rmsre, max_rel_error[II],
								max_rel_error_x[II], max_rel_error_fr[II], max_rel_error_ref[II]);
						end
					end
				end
			end
		end

		$display("=========================================================================");
		$finish;
	end

endmodule : rec_bipartite_accuracy_tb
