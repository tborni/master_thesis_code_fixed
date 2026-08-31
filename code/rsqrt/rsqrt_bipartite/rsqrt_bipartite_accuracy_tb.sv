module rsqrt_bipartite_accuracy_tb;

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

	localparam range_t NUM_NEWTON = make_range(.min( 0), .max( 0), .step(1));
	localparam range_t ADDR_0     = make_range(.min( 2), .max( 2), .step(1));
	localparam range_t ADDR_1     = make_range(.min( 6), .max( 6), .step(1));
	localparam range_t ADDR_2     = make_range(.min( 6), .max( 6), .step(1));
	localparam range_t WORD       = make_range(.min(10), .max(23), .step(1));

	localparam bit  USE_WORD_WIDTH_HEURISTIC = 1;
	localparam bit  USE_ADDR_WIDTH_HEURISTIC = 0;

	// --- Function 1 (always active): DUT legality -----------------------
	// Every constraint the rsqrt_bipartite elaboration/runtime depends on:
	//   * WORD_WIDTH > A0 + A1 - 1   : bipartite is only meaningful above a
	//                                  direct lookup of the same width
	//                                  (thesis Sec. 4.1.2; DUT $error).
	//   * WORD_WIDTH <= 23           : the fp32 output keeps man_lookup[22:0],
	//                                  so wider tables add no accuracy.
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
		return (word_width > addr_width_0 + addr_width_1 - 1)
			&& (word_width <= 23)
			&& (addr_width_0 + addr_width_1 + addr_width_2 <= 23)
			&& (addr_width_0 + addr_width_1 >= 3);
	endfunction : dut_legal

	// Bipartite-error heuristic (mirrors rec/exp_bipartite_accuracy_tb):
	// WORD_WIDTH is chosen large enough to keep quantization noise below
	// the intrinsic linearization error of the two tables.
	//   range_0 = 2*A_0 + A_1 + 2     - upper-table curvature term
	//   range_1 = A_0 + A_1 + A_2 + 1 - lower-table cross-term (invsqrt +1)
	// Their min equals n0+n1+min(n0+1,n2)+1; with the trailing +3 the result
	// is the thesis Sec. 4.1.2 budget w0 = 2+n0+n1+min(n0+1,n2) plus a 2-bit
	// slack for accumulated quantization.
	function automatic int unsigned word_width_heuristic(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2
	);
		automatic int unsigned  range_0 = 2 * addr_width_0 + addr_width_1 + 2;
		automatic int unsigned  range_1 = addr_width_0 + addr_width_1 + addr_width_2 + 1;
		automatic int unsigned  word_width = ((range_0 < range_1) ? range_0 : range_1) + 3;
		// Cap at 23: the fp32 output keeps only man_lookup[22:0], so table precision
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
			&& (word_width > addr_width_0 + addr_width_1 - 1)
			&& (word_width <= 23);
	endfunction : word_width_heuristic_ok

	// --- Function 3 (gated by USE_ADDR_WIDTH_HEURISTIC): addr-field relations --
	// The accuracy Pareto front for invsqrt: a symmetric middle/lower split
	// (A1 == A2) with the upper field offset one or two bits above the top
	// field (A1 == A0+1 or A0+2), which balances the two tables' error terms.
	function automatic bit addr_width_heuristic_ok(
		input int unsigned  addr_width_0,
		input int unsigned  addr_width_1,
		input int unsigned  addr_width_2
	);
		return (addr_width_1 == addr_width_2)
			&& ((addr_width_1 == addr_width_0 + 1) || (addr_width_1 == addr_width_0 + 2));
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

	// Reference Compute (double-precision: cast the fp32 input up to `real`
	// so the sqrt and reciprocal are evaluated in fp64, matching rec/exp).
	function automatic real exact_rsqrt(input shortreal  x);
		return 1.0 / $sqrt(real'(x));
	endfunction : exact_rsqrt

	// Random fp sample generator.
	// Force exponent into normalized range, also ensure that the required
	// value for the Newton steps (exponent * 0.5F) is normalized.
	function automatic shortreal rand_fp();
		automatic int unsigned  bits = $urandom();
		bits[30:23] = $urandom_range(2, 254);
		bits[31]    = 0;
		return $bitstoshortreal(bits);
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

							rsqrt_bipartite #(
								.ADDR_WIDTH_0(A0),
								.ADDR_WIDTH_1(A1),
								.ADDR_WIDTH_2(A2),
								.WORD_WIDTH  (WW),
								.NUM_NEWTON_STEPS(NS),
								.SUSTAINABLE_INTERVAL(1)
							) dut (
								.clk, .rst,
								.x, .xvld, .xrdy(xrdy_vec[II]),
								.r, .rvld
							);

							always_ff @(posedge clk iff rvld) begin
								shortreal  x_sample;
								shortreal  fr_local;
								real       rsqrt_ref, diff, rel_error;

								assert(num_evaluated[II] < NUM_SAMPLES) else begin
									$error("Spurious output (NS=%0d A0=%0d A1=%0d A2=%0d WW=%0d) at sample %0d",
										NS, A0, A1, A2, WW, num_evaluated[II]);
									$stop;
								end

								x_sample  = samples[num_evaluated[II]];
								fr_local  = $bitstoshortreal(r);
								rsqrt_ref = exact_rsqrt(x_sample);
								diff      = real'(fr_local) - rsqrt_ref;
								rel_error = ((diff < 0.0) ? -diff : diff) / rsqrt_ref;

								total_rel_error_squared[II] += rel_error * rel_error;
								if(rel_error > max_rel_error[II]) begin
									max_rel_error[II]     = rel_error;
									max_rel_error_x[II]   = x_sample;
									max_rel_error_ref[II] = rsqrt_ref;
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

		// Drain the pipeline. rsqrt_bipartite latency at NS=0 is a few
		// cycles; higher NS adds Newton DSP latency. Pad generously.
		repeat(64) @(posedge clk);

		$display("=========================================================================");
		$display("rsqrt_bipartite accuracy sweep");
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

endmodule : rsqrt_bipartite_accuracy_tb
