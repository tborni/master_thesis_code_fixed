module rsqrt_bipartite_accuracy_tb;
	typedef struct packed {
		int unsigned min;
		int unsigned max;
		int unsigned step;
		int unsigned num;
	} range_t;
	function automatic range_t make_range(input int unsigned  min, input int unsigned  max, input int unsigned  step);
		return '{
			min:       min,
			max:       max,
			step:      step,
			num: (max - min) / step + 1
		};
	endfunction : make_range
	localparam range_t NUM_NEWTON = make_range(.min(0), .max( 0), .step(1));
	localparam range_t ADDR_0     = make_range(.min(4), .max( 4), .step(1));
	localparam range_t ADDR_1     = make_range(.min(5), .max( 5), .step(1));
	localparam range_t ADDR_2     = make_range(.min(5), .max( 5), .step(1));
	localparam range_t WORD       = make_range(.min(10), .max(20), .step(1));

	localparam int unsigned  NUM_SAMPLES = 10000;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	bit [NUM_NEWTON.num-1:0][ADDR_0.num-1:0][ADDR_1.num-1:0][ADDR_2.num-1:0][WORD.num-1:0]  done = '0;
	always_comb begin
		if(&done)  $finish;
	end

	// Reference Compute (double-precision: cast the fp32 input up to `real` so
	// the sqrt and reciprocal are evaluated in fp64, matching the rec/exp TBs)
	function real exact_rsqrt(input shortreal  x);
		return 1.0 / $sqrt(real'(x));
	endfunction : exact_rsqrt

	// Generate random fp sample
	function shortreal rand_fp();
		int unsigned bits;
		bits = $urandom();
		// Force exponent into normalized range, also ensure that the required value for the Newton steps (exponent * 0.5F) is normalized
		bits[30:23] = $urandom_range(2, 254);
		bits[31] = 0;
		return $bitstoshortreal(bits);
	endfunction : rand_fp

	// Bipartite-error heuristic (mirrors rec/exp_bipartite_accuracy_tb):
	// WORD_WIDTH is chosen large enough to keep quantization noise below
	// the intrinsic linearization error of the two tables.
	//   range_0 = 2*A_0 + A_1 + 2     - upper-table curvature term
	//   range_1 = A_0 + A_1 + A_2 + 1 - lower-table cross-term (invsqrt +1)
	// Their min equals n0+n1+min(n0+1,n2)+1; with the trailing +3 the result
	// is the thesis Sec. 4.1.2 budget w0 = 2+n0+n1+min(n0+1,n2) plus a 2-bit
	// slack for accumulated quantization. Only the combo that hits this
	// heuristic is instantiated; the rest are stubbed out below.
	function int unsigned word_width_heuristic(input int unsigned  addr_width_0, input int unsigned  addr_width_1, input int unsigned  addr_width_2);
		automatic int unsigned  range_0 = 2 * addr_width_0 + addr_width_1 + 2;
		automatic int unsigned  range_1 = addr_width_0 + addr_width_1 + addr_width_2 + 1;
		return ((range_0 < range_1) ? range_0 : range_1) + 3;
	endfunction : word_width_heuristic

	for(genvar  num_newton_steps = NUM_NEWTON.min; num_newton_steps <= NUM_NEWTON.max; num_newton_steps += NUM_NEWTON.step) begin : genNewton
		for(genvar  addr_width_0 = ADDR_0.min; addr_width_0 <= ADDR_0.max; addr_width_0 += ADDR_0.step) begin : genAddr0
			for(genvar  addr_width_1 = ADDR_1.min; addr_width_1 <= ADDR_1.max; addr_width_1 += ADDR_1.step) begin : genAddr1
				for(genvar  addr_width_2 = ADDR_2.min; addr_width_2 <= ADDR_2.max; addr_width_2 += ADDR_2.step) begin : genAddr2
					for(genvar  word_width = WORD.min; word_width <= WORD.max; word_width += WORD.step) begin : genWord
						localparam int unsigned  NEWTON_IDX = (num_newton_steps - NUM_NEWTON.min) / NUM_NEWTON.step;
						localparam int unsigned  ADDR_0_IDX = (addr_width_0 - ADDR_0.min) / ADDR_0.step;
						localparam int unsigned  ADDR_1_IDX = (addr_width_1 - ADDR_1.min) / ADDR_1.step;
						localparam int unsigned  ADDR_2_IDX = (addr_width_2 - ADDR_2.min) / ADDR_2.step;
						localparam int unsigned  WORD_IDX   = (word_width   -   WORD.min) /   WORD.step;
						if(0 || word_width == word_width_heuristic(addr_width_0, addr_width_1, addr_width_2) && (addr_width_1 == addr_width_0 + 1 || addr_width_1 == addr_width_0 + 2) && addr_width_1 == addr_width_2) begin : blkCond
							// DUT
							shortreal  fx;
							uwire [31:0]  x = $shortrealtobits(fx);
							logic  xvld;
							uwire  xrdy;
							uwire [31:0]  r;
							uwire  rvld;
							rsqrt_bipartite #(
								.ADDR_WIDTH_0(addr_width_0),
								.ADDR_WIDTH_1(addr_width_1),
								.ADDR_WIDTH_2(addr_width_2),
								.WORD_WIDTH(word_width),
								.NUM_NEWTON_STEPS(num_newton_steps),
								.SUSTAINABLE_INTERVAL(1)
							) dut (
								.clk, .rst,
								.x, .xvld, .xrdy,
								.r, .rvld
							);
							shortreal  fr;
							assign	fr = $bitstoshortreal(r);

							// Samples
							real  rel_err_squared = 0.0;
							real  rel_err_max     = 0.0;
							shortreal  worst_input = 0.0;
							shortreal  Q[$];
							initial begin
								automatic real  rmsre;
								fx = 'x;
								xvld = 0;
								@(posedge clk iff !rst);
								xvld <= 1;

								repeat(NUM_SAMPLES) begin
									fx <= rand_fp();
									@(posedge clk);
									Q.push_back(fx);
								end
								xvld <= 0;
								fx <= 'x;
								repeat(32) @(posedge clk);
								assert(Q.size() == 0) else begin
									$error("Test (Newton = %0d, ADDR_0 = %0d, ADDR_1 = %0d, ADDR_2 = %0d, WORD = %0d): Missing %0d outputs.", num_newton_steps, addr_width_0, addr_width_1, addr_width_2, word_width, Q.size());
									$stop;
								end

								rmsre = $sqrt(rel_err_squared / NUM_SAMPLES);
								$display("Test (Newton = %0d, ADDR_0 = %0d, ADDR_1 = %0d, ADDR_2 = %0d, WORD = %0d): RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f", num_newton_steps, addr_width_0, addr_width_1, addr_width_2, word_width, rmsre, rel_err_max, worst_input);

								done[NEWTON_IDX][ADDR_0_IDX][ADDR_1_IDX][ADDR_2_IDX][WORD_IDX] = 1;
							end

							always_ff @(posedge clk iff rvld) begin
								shortreal  x;
								real       exp, diff, rel_err;
								assert(Q.size()) else begin
									$error("Test (Newton = %0d, ADDR_0 = %0d, ADDR_1 = %0d, ADDR_2 = %0d, WORD = %0d): Spurious output.", num_newton_steps, addr_width_0, addr_width_1, addr_width_2, word_width);
									$stop;
								end
								x = Q.pop_front();
								exp = exact_rsqrt(x);

								diff = real'(fr) - exp;
								rel_err = ((diff < 0.0) ? (-diff) : diff) / exp;
								rel_err_squared += rel_err * rel_err;
								if(rel_err > rel_err_max) begin
									rel_err_max = rel_err;
									worst_input = x;
								end
							end
						end : blkCond
						else begin
							initial begin
								done[NEWTON_IDX][ADDR_0_IDX][ADDR_1_IDX][ADDR_2_IDX][WORD_IDX] = 1;
							end
						end
					end : genWord
				end : genAddr2
			end : genAddr1
		end : genAddr0
	end : genNewton

endmodule : rsqrt_bipartite_accuracy_tb
