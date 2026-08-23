module exp_splitting_tb;

	localparam int unsigned  NUM_SAMPLES = 10000;

	// Parameter sweep ranges. Filtered Pareto-front:
	//   - ADDR_WIDTH_1 == ADDR_WIDTH_2 (symmetric split)
	//   - WORD_WIDTH set by the splitting-error heuristic (see below)
	// so only ~ (#ADDR_0 * #ADDR_1) DUTs are actually instantiated.
	localparam int unsigned  MIN_ADDR_0   = 5;
	localparam int unsigned  MAX_ADDR_0   = 7;
	localparam int unsigned  MIN_ADDR_1   = 5;
	localparam int unsigned  MAX_ADDR_1   = 7;
	localparam int unsigned  MIN_ADDR_2   = 5;
	localparam int unsigned  MAX_ADDR_2   = 7;
	localparam int unsigned  MIN_WORD     = 22;
	localparam int unsigned  MAX_WORD     = 22;

	localparam int unsigned  NUM_ADDR_0 = MAX_ADDR_0 - MIN_ADDR_0 + 1;
	localparam int unsigned  NUM_ADDR_1 = MAX_ADDR_1 - MIN_ADDR_1 + 1;
	localparam int unsigned  NUM_ADDR_2 = MAX_ADDR_2 - MIN_ADDR_2 + 1;
	localparam int unsigned  NUM_WORD   = MAX_WORD   - MIN_WORD   + 1;
	localparam int unsigned  NUM_INST   = NUM_ADDR_0 * NUM_ADDR_1 * NUM_ADDR_2 * NUM_WORD;

	localparam bit           EXCLUDE_POS      = 0;
	localparam bit           FORCE_BEHAVIORAL = 0;
	
	function automatic bit addr_widths_allowed(input int unsigned  addr_width_a, input int unsigned  addr_width_b);
	   if(addr_width_a > addr_width_b + 1) return 0;
	   if(addr_width_b > addr_width_a + 1) return 0;
	   return 1;
	endfunction : addr_widths_allowed

	function automatic bit config_enabled(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2,
		input int unsigned  word_width
	);
		return addr_widths_allowed(addr_width_0, addr_width_1) && addr_widths_allowed(addr_width_0, addr_width_2) && addr_widths_allowed(addr_width_1, addr_width_2);
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
	//	EXCLUDE_POS=0: any normal fp32 in [-87.0, 88.0]
	//	EXCLUDE_POS=1: any normal fp32 in [-87.0,  0.0)
	// Uniform over fp32 bit patterns (mantissa and exponent-field each drawn
	// uniformly), mirroring the rec/rsqrt samplers, rather than uniform over
	// the reals -- the latter concentrates almost all mass in the few largest
	// exponent bins and barely exercises small magnitudes.
	// Exclude denormalized numbers: the exponent field is drawn from {1,...,133}
	// so field 0 (subnormals/zero) never occurs. The top bin (field 133,
	// magnitudes in [64,128)) is capped to keep the admitted value-set identical
	// to the earlier sampler: positive up to 88.0 (mantissa 0x300000), negative
	// up to 87.0 (mantissa 0x2E0000); larger mantissas in that bin are redrawn.
	// Additional casts at the end to avoid vivado simulation error with shortreals
	function automatic shortreal rand_fp();
		forever begin
			automatic logic [31:0]  r         = $urandom();
			automatic logic         sign      = EXCLUDE_POS ? 1'b1 : r[23];
			automatic logic [22:0]  man_field = r[22:0];
			automatic logic [ 7:0]  exp_field = 8'($urandom_range(1, 133));
			automatic logic [22:0]  lim       = sign ? 23'h2E_0000 : 23'h30_0000;
			if(exp_field == 8'd133 && man_field > lim)  continue;
			return $bitstoshortreal($shortrealtobits($bitstoshortreal({ sign, exp_field, man_field })));
		end
	endfunction : rand_fp

	// Index flattening: II = ((a0 * NUM_ADDR_1 + a1) * NUM_ADDR_2 + a2) * NUM_WORD + w
	// keeps the WORD axis fastest-varying, matching the report loop below.

	// Parallel DUT instances
	for(genvar  a0i = 0; a0i < NUM_ADDR_0; a0i++) begin : gA0
		localparam int unsigned  A0 = MIN_ADDR_0 + a0i;

		for(genvar  a1i = 0; a1i < NUM_ADDR_1; a1i++) begin : gA1
			localparam int unsigned  A1 = MIN_ADDR_1 + a1i;

			for(genvar  a2i = 0; a2i < NUM_ADDR_2; a2i++) begin : gA2
				localparam int unsigned  A2 = MIN_ADDR_2 + a2i;

				for(genvar  wi = 0; wi < NUM_WORD; wi++) begin : gW
					localparam int unsigned  WW = MIN_WORD + wi;
					localparam int unsigned  II = ((a0i * NUM_ADDR_1 + a1i) * NUM_ADDR_2 + a2i) * NUM_WORD + wi;

					if(config_enabled(A0, A1, A2, WW)) begin : gEna
						uwire [31:0]  r;
						uwire         rvld;

						exp_splitting #(
							.SIMD(1),
							.EXCLUDE_POS(EXCLUDE_POS),
							.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL),
							.ADDR_WIDTH_0(A0),
							.ADDR_WIDTH_1(A1),
							.ADDR_WIDTH_2(A2),
							.WORD_WIDTH  (WW)
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
								$error("Spurious output (A0=%0d A1=%0d A2=%0d WW=%0d) at sample %0d",
									A0, A1, A2, WW, num_evaluated[II]);
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

		// Drain the pipeline. exp_splitting latency = range_reduction (9)
		// + local 4-stage = 13 cycles; pad generously.
		repeat(64) @(posedge clk);

		$display("=========================================================================");
		$display("exp_splitting accuracy sweep");
		$display("  NUM_SAMPLES      = %0d", NUM_SAMPLES);
		$display("  EXCLUDE_POS      = %0d", EXCLUDE_POS);
		$display("  FORCE_BEHAVIORAL = %0d", FORCE_BEHAVIORAL);

		for(int unsigned  a0i = 0; a0i < NUM_ADDR_0; a0i++) begin
			automatic int unsigned  A0 = MIN_ADDR_0 + a0i;
			for(int unsigned  a1i = 0; a1i < NUM_ADDR_1; a1i++) begin
				automatic int unsigned  A1 = MIN_ADDR_1 + a1i;
				for(int unsigned  a2i = 0; a2i < NUM_ADDR_2; a2i++) begin
					automatic int unsigned  A2 = MIN_ADDR_2 + a2i;
					for(int unsigned  wi = 0; wi < NUM_WORD; wi++) begin
						automatic int unsigned  WW = MIN_WORD + wi;
						automatic int unsigned  II = ((a0i * NUM_ADDR_1 + a1i) * NUM_ADDR_2 + a2i) * NUM_WORD + wi;
						automatic real          rmsre;

						if(!config_enabled(A0, A1, A2, WW))  continue;

						assert(num_evaluated[II] == NUM_SAMPLES) else begin
							$error("Unexpected number of outputs for (A0=%0d, A1=%0d, A2=%0d, WW=%0d): expected %0d, got %0d",
								A0, A1, A2, WW, NUM_SAMPLES, num_evaluated[II]);
							$stop;
						end

						rmsre = $sqrt(total_rel_error_squared[II] / num_evaluated[II]);
						$display("  A0=%0d A1=%0d A2=%0d WW=%2d  RMSRE=%.6e  max_rel_error=%.6e  at x=%.9g  (dut=%.9g, ref=%.9g)",
							A0, A1, A2, WW, rmsre, max_rel_error[II],
							max_rel_error_x[II], max_rel_error_fr[II], max_rel_error_ref[II]);
					end
				end
			end
		end

		$display("=========================================================================");
		$finish;
	end

endmodule : exp_splitting_tb
