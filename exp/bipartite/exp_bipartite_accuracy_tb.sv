module exp_bipartite_accuracy_tb;

	localparam int unsigned  NUM_SAMPLES = 10000;

	// -------------------------------------------------------------------
	// Parameter sweep ranges.
	//
	// make_range(min, max, step) packs an inclusive sweep axis (bounds +
	// derived count) into one struct so the generate loops and the report
	// loop can share a single source of truth.  All three bipartite
	// accuracy TBs (rec/exp/rsqrt) share this structure; only the
	// per-function specifics (sampler, reference, DUT ports, heuristic
	// constants) differ.
	//
	// exp_bipartite has no Newton refinement, so the NUM_NEWTON axis is a
	// single point (0). It is retained so the generate nest, the II index
	// flattening, and the report loop are identical to rec/rsqrt.
	// -------------------------------------------------------------------
	typedef struct packed {
		int unsigned min;
		int unsigned max;
		int unsigned step;
		int unsigned num;
	} range_t;
	function automatic range_t make_range(input int unsigned  min, input int unsigned  max, input int unsigned  step);
		return '{
			min:  min,
			max:  max,
			step: step,
			num:  (max - min) / step + 1
		};
	endfunction : make_range

	localparam range_t NUM_NEWTON = make_range(.min( 0), .max( 0), .step(1));
	localparam range_t ADDR_0     = make_range(.min( 2), .max( 6), .step(1));
	localparam range_t ADDR_1     = make_range(.min( 4), .max( 7), .step(1));
	localparam range_t ADDR_2     = make_range(.min( 4), .max( 7), .step(1));
	localparam range_t WORD       = make_range(.min(10), .max(30), .step(1));

	localparam bit  EXCLUDE_POS      = 0;
	localparam bit  FORCE_BEHAVIORAL = 0;

	// -------------------------------------------------------------------
	// Heuristic enables.
	//
	// The DUT-legality filter (dut_legal) is ALWAYS applied so no elaborated
	// instance trips its own $error/$finish.  The two heuristics below are
	// optional Pareto-front narrowings on top of it:
	//
	//   USE_WORD_WIDTH_HEURISTIC : keep only WORD_WIDTH == word_width_heuristic(...)
	//                              (plus the clamped WORD_WIDTH bounds).
	//   USE_ADDR_WIDTH_HEURISTIC : keep only the addr-field relations that sit
	//                              on the accuracy Pareto front (symmetric split).
	//
	// Set a flag to 0 to sweep that axis fully (still constrained to legal
	// DUTs); set to 1 to instantiate only the heuristic-selected point.
	// -------------------------------------------------------------------
	localparam bit  USE_WORD_WIDTH_HEURISTIC = 1;
	localparam bit  USE_ADDR_WIDTH_HEURISTIC = 1;

	// --- Function 1 (always active): DUT legality -----------------------
	// Every constraint the exp_bipartite elaboration/runtime depends on:
	//   * WORD_WIDTH > A0 + A1 - 2   : bipartite is only meaningful above a
	//                                  direct lookup of the same width (DUT $error).
	//   * WORD_WIDTH <= 23           : the fp32 output keeps only 23 mantissa
	//                                  bits, so wider tables add no accuracy.
	//   * A0 + A1 + A2 <= 23         : the x_2 field is sliced at bit
	//                                  (22 - A0 - A1) down to (23 - A0 - A1 - A2);
	//                                  exceeding 23 gives a negative bit index.
	//   * A0 + A1 >= 3               : the lower table needs at least a sign bit
	//                                  plus one data bit to carry information.
	function automatic bit dut_legal(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2,
		input int unsigned  word_width
	);
		return (word_width > addr_width_0 + addr_width_1 - 2)
			&& (word_width <= 23)
			&& (addr_width_0 + addr_width_1 + addr_width_2 <= 23)
			&& (addr_width_0 + addr_width_1 >= 3);
	endfunction : dut_legal

	// Bipartite-error heuristic (mirrors rsqrt_bipartite_accuracy_tb):
	// WORD_WIDTH is chosen large enough to keep quantization noise below
	// the intrinsic linearization error of the two tables.
	//   range_0 = 2*A_0 + A_1 + 2  - upper-table curvature term
	//   range_1 = A_0 + A_1 + A_2  - lower-table cross-term
	// adding a 2-bit slack for accumulated quantization.
	function automatic int unsigned word_width_heuristic(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2
	);
		automatic int unsigned  range_0 = 2*addr_width_0 + addr_width_1 + 2;
		automatic int unsigned  range_1 =   addr_width_0 + addr_width_1 + addr_width_2;
		automatic int unsigned  word_width = ((range_0 < range_1) ? range_0 : range_1) + 1 + 3;
		// Cap at 23: the fp32 output keeps only 23 mantissa bits, so table precision
		// beyond 23 fractional bits is discarded before it reaches the result. Any
		// wider value only grows the ROMs and the mantissa adder for no accuracy gain.
		return (word_width > 23) ? 23 : word_width;
	endfunction : word_width_heuristic

	// --- Function 2 (gated by USE_WORD_WIDTH_HEURISTIC): WORD_WIDTH match --
	// True when WORD_WIDTH equals the bipartite-error heuristic value AND
	// stays within the clamped WORD_WIDTH bounds (redundant with dut_legal
	// but kept here so the WORD axis is fully self-describing).
	function automatic bit word_width_heuristic_ok(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2,
		input int unsigned  word_width
	);
		return (word_width == word_width_heuristic(addr_width_0, addr_width_1, addr_width_2))
			&& (word_width > addr_width_0 + addr_width_1 - 2)
			&& (word_width <= 23);
	endfunction : word_width_heuristic_ok

	// --- Function 3 (gated by USE_ADDR_WIDTH_HEURISTIC): addr-field relations --
	// The accuracy Pareto front for 2^x: a symmetric middle/lower split
	// (A1 == A2), which balances the two tables' error terms.
	function automatic bit addr_width_heuristic_ok(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2
	);
		return (addr_width_1 == addr_width_2);
	endfunction : addr_width_heuristic_ok

	// Combined per-config enable: legality always, heuristics only when armed.
	function automatic bit config_enabled(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2,
		input int unsigned  word_width
	);
		return dut_legal(addr_width_0, addr_width_1, addr_width_2, word_width)
			&& (!USE_WORD_WIDTH_HEURISTIC || word_width_heuristic_ok(addr_width_0, addr_width_1, addr_width_2, word_width))
			&& (!USE_ADDR_WIDTH_HEURISTIC || addr_width_heuristic_ok(addr_width_0, addr_width_1, addr_width_2));
	endfunction : config_enabled

	localparam int unsigned  NUM_INST = NUM_NEWTON.num * ADDR_0.num * ADDR_1.num * ADDR_2.num * WORD.num;

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

	// Reference Compute (double-precision exponential).
	function automatic real exact_exp(input shortreal  x);
		return $exp(real'(x));
	endfunction : exact_exp

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

	// Index flattening: II = (((ni * ADDR_0.num + a0) * ADDR_1.num + a1) * ADDR_2.num + a2) * WORD.num + w
	// keeps the WORD axis fastest-varying and the Newton-step axis slowest,
	// matching the report loop below.

	// Parallel DUT instances
	for(genvar  ni = 0; ni < NUM_NEWTON.num; ni++) begin : gNewton
		localparam int unsigned  NS = NUM_NEWTON.min + ni * NUM_NEWTON.step;

		for(genvar  a0i = 0; a0i < ADDR_0.num; a0i++) begin : gA0
			localparam int unsigned  A0 = ADDR_0.min + a0i * ADDR_0.step;

			for(genvar  a1i = 0; a1i < ADDR_1.num; a1i++) begin : gA1
				localparam int unsigned  A1 = ADDR_1.min + a1i * ADDR_1.step;

				for(genvar  a2i = 0; a2i < ADDR_2.num; a2i++) begin : gA2
					localparam int unsigned  A2 = ADDR_2.min + a2i * ADDR_2.step;

					for(genvar  wi = 0; wi < WORD.num; wi++) begin : gW
						localparam int unsigned  WW = WORD.min + wi * WORD.step;
						localparam int unsigned  II = (((ni * ADDR_0.num + a0i) * ADDR_1.num + a1i) * ADDR_2.num + a2i) * WORD.num + wi;

						if(config_enabled(A0, A1, A2, WW)) begin : gEna
							uwire [31:0]  r;
							uwire         rvld;

							exp_bipartite #(
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
									$error("Spurious output (NS=%0d A0=%0d A1=%0d A2=%0d WW=%0d) at sample %0d",
										NS, A0, A1, A2, WW, num_evaluated[II]);
									$stop;
								end

								x_sample  = samples[num_evaluated[II]];
								fr_local  = $bitstoshortreal(r);
								exp_ref   = exact_exp(x_sample);
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

		// Drain the pipeline. exp_bipartite latency = range_reduction (9)
		// + local 3-stage = 12 cycles; pad generously.
		repeat(64) @(posedge clk);

		$display("=========================================================================");
		$display("exp_bipartite accuracy sweep");
		$display("  NUM_SAMPLES      = %0d", NUM_SAMPLES);
		$display("  EXCLUDE_POS      = %0d", EXCLUDE_POS);

		for(int unsigned  ni = 0; ni < NUM_NEWTON.num; ni++) begin
			automatic int unsigned  NS = NUM_NEWTON.min + ni * NUM_NEWTON.step;
			for(int unsigned  a0i = 0; a0i < ADDR_0.num; a0i++) begin
				automatic int unsigned  A0 = ADDR_0.min + a0i * ADDR_0.step;
				for(int unsigned  a1i = 0; a1i < ADDR_1.num; a1i++) begin
					automatic int unsigned  A1 = ADDR_1.min + a1i * ADDR_1.step;
					for(int unsigned  a2i = 0; a2i < ADDR_2.num; a2i++) begin
						automatic int unsigned  A2 = ADDR_2.min + a2i * ADDR_2.step;
						for(int unsigned  wi = 0; wi < WORD.num; wi++) begin
							automatic int unsigned  WW = WORD.min + wi * WORD.step;
							automatic int unsigned  II = (((ni * ADDR_0.num + a0i) * ADDR_1.num + a1i) * ADDR_2.num + a2i) * WORD.num + wi;
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

endmodule : exp_bipartite_accuracy_tb
