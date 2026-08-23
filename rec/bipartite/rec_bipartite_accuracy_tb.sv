module rec_bipartite_accuracy_tb;

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

	localparam range_t NUM_NEWTON = make_range(.min( 0), .max( 1), .step(1));
	localparam range_t ADDR_0     = make_range(.min( 2), .max( 6), .step(1));
	localparam range_t ADDR_1     = make_range(.min( 3), .max( 7), .step(1));
	localparam range_t ADDR_2     = make_range(.min( 3), .max( 7), .step(1));
	localparam range_t WORD       = make_range(.min( 8), .max(23), .step(1));

	// Newton-coefficient sweep (used only when USE_NEWTON_COEFF_HEURISTIC == 0).
	// range_t is integer-typed, so the axis is expressed in FIXED-POINT
	// milli-units and divided by NEWTON_COEFF_SCALE to recover the real
	// NEWTON_COEFF passed to the DUT. e.g. make_range(1950, 2050, 10) / 1000.0
	// sweeps 1.95, 1.96, ... 2.05 (the textbook Newton constant is 2.0). Only
	// exercised at NUM_NEWTON_STEPS >= 1 -- the pure seed (NS = 0) ignores it.
	localparam range_t NEWTON_COEFF_RANGE = make_range(.min(1950), .max(2050), .step(10));
	localparam real    NEWTON_COEFF_SCALE = 1000.0;

	// -------------------------------------------------------------------
	// Heuristic enables.
	//
	// The DUT-legality filter (dut_legal) is ALWAYS applied so no elaborated
	// instance trips its own $error/$finish.  The two heuristics below are
	// optional Pareto-front narrowings on top of it:
	//
	//   USE_WORD_WIDTH_HEURISTIC  : keep only WORD_WIDTH == word_width_heuristic(...)
	//                               (plus the clamped WORD_WIDTH bounds).
	//   USE_ADDR_WIDTH_HEURISTIC  : keep only the addr-field relations that sit
	//                               on the accuracy Pareto front (symmetric split).
	//   USE_NEWTON_COEFF_HEURISTIC: 1 -> NEWTON_COEFF = newton_coeff(...) (one
	//                               bias-corrected coefficient per geometry, so the
	//                               coefficient axis collapses to a single point);
	//                               0 -> sweep NEWTON_COEFF_RANGE / NEWTON_COEFF_SCALE.
	//
	// Set a width/addr flag to 0 to sweep that axis fully (still constrained to
	// legal DUTs); set to 1 to instantiate only the heuristic-selected point.
	// -------------------------------------------------------------------
	localparam bit  USE_WORD_WIDTH_HEURISTIC   = 1;
	localparam bit  USE_ADDR_WIDTH_HEURISTIC   = 1;
	localparam bit  USE_NEWTON_COEFF_HEURISTIC = 1;

	// Coefficient-axis length: a single heuristic point when armed, else the
	// full fixed-point sweep. Compile-time constant -- sizes NUM_INST and the
	// II flattening below.
	localparam int unsigned  NUM_COEFF = USE_NEWTON_COEFF_HEURISTIC ? 1 : NEWTON_COEFF_RANGE.num;

	// --- Function 1 (always active): DUT legality -----------------------
	// Every constraint the rec_bipartite elaboration/runtime depends on:
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

	// Bipartite-error heuristic (mirrors exp_bipartite_accuracy_tb):
	// WORD_WIDTH is chosen large enough to keep quantization noise below
	// the intrinsic linearization error of the two tables.
	//   range_0 = 2*A_0 + A_1  - upper-table curvature term
	//   range_1 = A_0 + A_1 + A_2 - lower-table cross-term
	// adding a 2-bit slack for accumulated quantization.
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
	// The accuracy Pareto front for the reciprocal: a symmetric middle/lower
	// split (A1 == A2), which balances the two tables' error terms.
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

	localparam int unsigned  NUM_INST = NUM_NEWTON.num * ADDR_0.num * ADDR_1.num * ADDR_2.num * WORD.num * NUM_COEFF;

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

	// Reference Compute (double-precision reciprocal).
	function automatic real exact_rec(input shortreal  x);
		return 1.0 / real'(x);
	endfunction : exact_rec

	// Random fp sample generator
	// Uniform over fp32 representables in [1,inf)
	// Exclude very large values to avoid denormalized numbers on the outputs side
	//	Maximum allowed input is equal to 1 divided by minimal normal number:
	//	1/(1.0*2^(1-127)) = 2^(+126) = 2^(253-127)
	//		252 is the largest allowed exponent as 253 combined with mantissa != 0 leads to denormalized results
	//	Exponent range: {127,…,252}
	function automatic shortreal rand_fp();
		automatic int unsigned  bits = $urandom();
		bits[30:23] = $urandom_range(127, 252);
		bits[31]    = 0;
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

	// Decode a coefficient-sweep index into the real NEWTON_COEFF (fixed-point
	// milli-units / NEWTON_COEFF_SCALE). The int-to-real division promotes to
	// real arithmetic, so 1950 / 1000.0 == 1.95. Only used when the coefficient
	// heuristic is disabled.
	function automatic shortreal newton_coeff_swept(input int unsigned  coeff_idx);
		automatic int unsigned  raw = NEWTON_COEFF_RANGE.min + coeff_idx * NEWTON_COEFF_RANGE.step;
		return $bitstoshortreal($shortrealtobits(shortreal'(real'(raw) / NEWTON_COEFF_SCALE)));
	endfunction : newton_coeff_swept

	// Index flattening: II = ((((ni * ADDR_0.num + a0) * ADDR_1.num + a1) * ADDR_2.num + a2) * WORD.num + w) * NUM_COEFF + c
	// keeps the COEFF axis fastest-varying, then WORD, with the Newton-step axis
	// slowest, matching the report loop below.

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

						for(genvar  ci = 0; ci < NUM_COEFF; ci++) begin : gCoeff
							// NEWTON_COEFF source: the per-geometry bias-corrected
							// heuristic (single point), or the fixed-point sweep. Both
							// arms are pure constant functions; passing the selected
							// value straight into the parameter port mirrors the proven
							// pre-change `.NEWTON_COEFF(newton_coeff(...))` idiom (no
							// intermediate real localparam).
							localparam int unsigned  II = ((((ni * ADDR_0.num + a0i) * ADDR_1.num + a1i) * ADDR_2.num + a2i) * WORD.num + wi) * NUM_COEFF + ci;

							if(config_enabled(A0, A1, A2, WW)) begin : gEna
								uwire [31:0]  r;
								uwire         rvld;

								rec_bipartite #(
									.ADDR_WIDTH_0(A0),
									.ADDR_WIDTH_1(A1),
									.ADDR_WIDTH_2(A2),
									.WORD_WIDTH  (WW),
									.NUM_NEWTON_STEPS(NS),
									.NEWTON_COEFF(USE_NEWTON_COEFF_HEURISTIC ? newton_coeff(A0, A1, A2, WW)
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
									automatic shortreal  c_used = USE_NEWTON_COEFF_HEURISTIC ? newton_coeff(A0, A1, A2, WW)
									                                                         : newton_coeff_swept(ci);

									assert(num_evaluated[II] < NUM_SAMPLES) else begin
										$error("Spurious output (NS=%0d A0=%0d A1=%0d A2=%0d WW=%0d C=%.6f) at sample %0d",
											NS, A0, A1, A2, WW, c_used, num_evaluated[II]);
										$stop;
									end

									x_sample  = samples[num_evaluated[II]];
									fr_local  = $bitstoshortreal(r);
									rec_ref   = exact_rec(x_sample);
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

						end : gCoeff
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
							for(int unsigned  ci = 0; ci < NUM_COEFF; ci++) begin
								automatic shortreal      C  = USE_NEWTON_COEFF_HEURISTIC ? newton_coeff(A0, A1, A2, WW)
								                                                          : newton_coeff_swept(ci);
								automatic int unsigned  II = ((((ni * ADDR_0.num + a0i) * ADDR_1.num + a1i) * ADDR_2.num + a2i) * WORD.num + wi) * NUM_COEFF + ci;
								automatic real          rmsre;

								if(!config_enabled(A0, A1, A2, WW))  continue;

								assert(num_evaluated[II] == NUM_SAMPLES) else begin
									$error("Unexpected number of outputs for (NS=%0d, A0=%0d, A1=%0d, A2=%0d, WW=%0d, C=%.6f): expected %0d, got %0d",
										NS, A0, A1, A2, WW, C, NUM_SAMPLES, num_evaluated[II]);
									$stop;
								end

								rmsre = $sqrt(total_rel_error_squared[II] / num_evaluated[II]);
								$display("  NS=%0d A0=%0d A1=%0d A2=%0d WW=%2d C=%.6f  RMSRE=%.6e  max_rel_error=%.6e  at x=%.9g  (dut=%.9g, ref=%.9g)",
									NS, A0, A1, A2, WW, C, rmsre, max_rel_error[II],
									max_rel_error_x[II], max_rel_error_fr[II], max_rel_error_ref[II]);
							end
						end
					end
				end
			end
		end

		$display("=========================================================================");
		$finish;
	end

endmodule : rec_bipartite_accuracy_tb
