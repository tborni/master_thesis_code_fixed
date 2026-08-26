module exp_lookup_accuracy_tb;

	localparam int unsigned  NUM_SAMPLES = 10000;

	localparam int unsigned  MIN_ADDR_WIDTH   =  6;
	localparam int unsigned  MAX_ADDR_WIDTH   = 11;
	localparam int unsigned  STEP_ADDR_WIDTH  =  1;
	localparam int unsigned  MIN_WORD_WIDTH   =  6;
	localparam int unsigned  MAX_WORD_WIDTH   = 16;
	localparam int unsigned  STEP_WORD_WIDTH  =  2;

	localparam int unsigned  NUM_ADDR = (MAX_ADDR_WIDTH - MIN_ADDR_WIDTH) / STEP_ADDR_WIDTH + 1;
	localparam int unsigned  NUM_WORD = (MAX_WORD_WIDTH - MIN_WORD_WIDTH) / STEP_WORD_WIDTH + 1;
	localparam int unsigned  NUM_INST = NUM_ADDR * NUM_WORD;

	localparam bit           EXCLUDE_POS      = 1;
	localparam bit           FORCE_BEHAVIORAL = 0;

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
	//	EXCLUDE_POS=0: any normal fp32 in [-87.0, 88.0]
	//	EXCLUDE_POS=1: any normal fp32 in [-87.0,  0.0)
	// Uniform over the REALS in [lo, hi): draw a uniform u in [0,1) and map it
	// to lo + (hi-lo)*u, then quantize to the nearest fp32. This weights each
	// exponent bin by its real-line width, so large magnitudes dominate and
	// small ones are rarely exercised -- the opposite of a bit-pattern-uniform
	// sampler. Denormals (exp_field==0, man_field!=0) are rejected so every
	// returned value is a normal fp32; the man_field==0 clause admits exact
	// powers of two and guards against a pathological retry.
	// NOTE: $urandom's return type is signed `int`, so real'($urandom()) would
	// do a SIGNED conversion and yield u in [-0.5,0.5). Route the bits through
	// an unsigned logic[31:0] first so real'() converts them unsigned -> [0,1).
	// Additional casts to avoid vivado simulation error with shortreals.
	function automatic shortreal rand_fp();
		automatic real  lo = -87.0;
		automatic real  hi = EXCLUDE_POS ? 0.0 : 88.0;
		forever begin
			automatic logic [31:0]  ubits     = $urandom();
			automatic real          u         = real'(ubits) / 4294967296.0;
			automatic shortreal     s         = $bitstoshortreal($shortrealtobits(shortreal'(lo + (hi - lo) * u)));
			automatic logic [31:0]  bits      = $shortrealtobits(s);
			automatic logic [ 7:0]  exp_field = bits[30:23];
			automatic logic [22:0]  man_field = bits[22: 0];
			if(exp_field != 8'd0 || man_field == 23'd0)  return s;
		end
	endfunction : rand_fp

	// Parallel DUT instances
	for(genvar  ai = 0; ai < NUM_ADDR; ai++) begin : gAddr
		localparam int unsigned  AW = MIN_ADDR_WIDTH + ai * STEP_ADDR_WIDTH;

		for(genvar  wi = 0; wi < NUM_WORD; wi++) begin : gWord
			localparam int unsigned  WW = MIN_WORD_WIDTH + wi * STEP_WORD_WIDTH;
			localparam int unsigned  II = ai * NUM_WORD + wi;

			uwire [31:0]  r;
			uwire         rvld;

			exp_lookup #(
				.SIMD(1),
				.ADDR_WIDTH(AW),
				.WORD_WIDTH(WW),
				.EXCLUDE_POS(EXCLUDE_POS),
				.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
			) dut (
				.clk, .rst,
				.idat(x), .ivld(xvld), .irdy(xrdy_vec[II]),
				.odat(r), .ovld(rvld), .ordy(1'b1)
			);

			always_ff @(posedge clk iff rvld) begin
				shortreal  x_sample;
				shortreal  fr_local;
				real       exp_ref, diff, rel_error;

				assert(num_evaluated[II] < NUM_SAMPLES) else begin
					$error("Spurious output (AW=%0d WW=%0d) at sample %0d",
						AW, WW, num_evaluated[II]);
					$stop;
				end

				x_sample  = samples[num_evaluated[II]];
				fr_local  = $bitstoshortreal(r);
				exp_ref   = $exp(real'(x_sample));
				diff      = real'(fr_local) - exp_ref;
				rel_error = ((diff < 0.0) ? -diff : diff) / exp_ref;

				total_rel_error_squared[II] += rel_error * rel_error;
				if(rel_error > max_rel_error[II]) begin
					max_rel_error[II]     = rel_error;
					max_rel_error_x[II]   = x_sample;
					max_rel_error_ref[II] = exp_ref;
					max_rel_error_fr[II]  = fr_local;
				end
				num_evaluated[II]++;
			end

		end : gWord
	end : gAddr

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

		// Drain the pipeline
		repeat(50) @(posedge clk);

		$display("=========================================================================");
		$display("exp_lookup accuracy sweep");
		$display("  NUM_SAMPLES      = %0d", NUM_SAMPLES);
		$display("  EXCLUDE_POS      = %0d", EXCLUDE_POS);

		for(int unsigned  ai = 0; ai < NUM_ADDR; ai++) begin
			automatic int unsigned  AW = MIN_ADDR_WIDTH + ai * STEP_ADDR_WIDTH;
			for(int unsigned  wi = 0; wi < NUM_WORD; wi++) begin
				automatic int unsigned  WW = MIN_WORD_WIDTH + wi * STEP_WORD_WIDTH;
				automatic int unsigned  II = ai * NUM_WORD + wi;
				automatic real          rmsre;

				assert(num_evaluated[II] == NUM_SAMPLES) else begin
					$error("Unexpected number of outputs for (AW=%0d, WW=%0d): expected %0d, got %0d", AW, WW, NUM_SAMPLES, num_evaluated[II]);
					$stop;
				end

				rmsre = $sqrt(total_rel_error_squared[II] / num_evaluated[II]);
				$display("  AW=%2d WW=%2d  RMSRE=%.6e  max_rel_error=%.6e  at x=%.9g  (dut=%.9g, ref=%.9g)", AW, WW, rmsre, max_rel_error[II],
					max_rel_error_x[II], max_rel_error_fr[II], max_rel_error_ref[II]);
			end
		end

		$display("=========================================================================");
		$finish;
	end

endmodule : exp_lookup_accuracy_tb
