module rsqrt_lookup_tb;
	localparam int unsigned  MIN_NUM_NEWTON            = 0;
	localparam int unsigned  MAX_NUM_NEWTON            = 2;
	localparam int unsigned  STEP_NUM_NEWTON           = 1;
	localparam int unsigned  MIN_ADDR_WIDTH            =  6;
	localparam int unsigned  MAX_ADDR_WIDTH            = 11;
	localparam int unsigned  STEP_ADDR_WIDTH           =  1;
	localparam int unsigned  MIN_WORD_WIDTH            =  6;
	localparam int unsigned  MAX_WORD_WIDTH            = 16;
	localparam int unsigned  STEP_WORD_WIDTH           =  2;
	localparam int unsigned  MIN_SUSTAINABLE_INTERVAL  = 1;
	localparam int unsigned  MAX_SUSTAINABLE_INTERVAL  = 1;
	localparam int unsigned  STEP_SUSTAINABLE_INTERVAL = 4;

	localparam int unsigned  NUM_NEWTON_STEPS         = (MAX_NUM_NEWTON - MIN_NUM_NEWTON) / STEP_NUM_NEWTON + 1;
	localparam int unsigned  NUM_ADDR_STEPS           = (MAX_ADDR_WIDTH - MIN_ADDR_WIDTH) / STEP_ADDR_WIDTH + 1;
	localparam int unsigned  NUM_WORD_STEPS           = (MAX_WORD_WIDTH - MIN_WORD_WIDTH) / STEP_WORD_WIDTH + 1;
	localparam int unsigned  NUM_SUSTAINABLE_INTERVAL = (MAX_SUSTAINABLE_INTERVAL - MIN_SUSTAINABLE_INTERVAL) / STEP_SUSTAINABLE_INTERVAL + 1;

	localparam int unsigned  NUM_SAMPLES = 10000;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	bit [NUM_NEWTON_STEPS-1:0][NUM_ADDR_STEPS-1:0][NUM_WORD_STEPS-1:0][NUM_SUSTAINABLE_INTERVAL-1:0]  done = '0;
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

	for(genvar  num_newton_steps = MIN_NUM_NEWTON; num_newton_steps <= MAX_NUM_NEWTON; num_newton_steps += STEP_NUM_NEWTON) begin : genNewtonSteps
		for(genvar  addr_width = MIN_ADDR_WIDTH; addr_width <= MAX_ADDR_WIDTH; addr_width += STEP_ADDR_WIDTH) begin : genTestsAddr
			for(genvar  word_width = MIN_WORD_WIDTH; word_width <= MAX_WORD_WIDTH; word_width += STEP_WORD_WIDTH) begin : genTestsWord
				for(genvar  sustainable_interval = MIN_SUSTAINABLE_INTERVAL; sustainable_interval <= MAX_SUSTAINABLE_INTERVAL; sustainable_interval += STEP_SUSTAINABLE_INTERVAL) begin : genTestsII
					localparam int unsigned  NEWTON_IDX = (num_newton_steps - MIN_NUM_NEWTON) / STEP_NUM_NEWTON;
					localparam int unsigned  ADDR_IDX   = (addr_width - MIN_ADDR_WIDTH) / STEP_ADDR_WIDTH;
					localparam int unsigned  WORD_IDX   = (word_width - MIN_WORD_WIDTH) / STEP_WORD_WIDTH;
					localparam int unsigned  II_IDX     = (sustainable_interval - MIN_SUSTAINABLE_INTERVAL) / STEP_SUSTAINABLE_INTERVAL;
					if(num_newton_steps == 2 && sustainable_interval > 1) begin
						initial begin
							done[NEWTON_IDX][ADDR_IDX][WORD_IDX][II_IDX] = 1;
						end
					end
					else begin
						// DUT
						shortreal  fx;
						uwire [31:0]  x = $shortrealtobits(fx);
						logic  xvld;
						uwire  xrdy;
						uwire [31:0]  r;
						uwire  rvld;
						rsqrt_lookup #(
							.ADDR_WIDTH(addr_width),
							.WORD_WIDTH(word_width),
							.NUM_NEWTON_STEPS(num_newton_steps),
							.SUSTAINABLE_INTERVAL(sustainable_interval)
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

							// Feed NUM_SAMPLES bit-pattern-uniform samples, respecting the
							// DUT's input handshake so no sample is dropped at II > 1.
							for(int unsigned  i = 0; i < NUM_SAMPLES;) begin
								fx <= rand_fp();
								@(posedge clk iff xrdy);
								Q.push_back(fx);
								i++;
							end
							xvld <= 0;
							fx <= 'x;
							repeat(32) @(posedge clk);
							assert(Q.size() == 0) else begin
								$error("Test (Newton = %0d, ADDR_W = %0d, WORD_W = %0d, II = %0d): Missing %0d outputs.", num_newton_steps, addr_width, word_width, sustainable_interval, Q.size());
								$stop;
							end

							rmsre = $sqrt(rel_err_squared / NUM_SAMPLES);
							$display("Test (Newton = %0d, ADDR_W = %0d, WORD_W = %0d, II = %0d): RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f", num_newton_steps, addr_width, word_width, sustainable_interval, rmsre, rel_err_max, worst_input);

							done[NEWTON_IDX][ADDR_IDX][WORD_IDX][II_IDX] = 1;
						end

						// Checker
						always_ff @(posedge clk iff rvld) begin
							shortreal  x;
							real       exp, diff, rel_err;
							assert(Q.size()) else begin
								$error("Test (Newton = %0d, ADDR_W = %0d, WORD_W = %0d, II = %0d): Spurious output.", num_newton_steps, addr_width, word_width, sustainable_interval);
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
					end
				end : genTestsII
			end : genTestsWord
		end : genTestsAddr
	end : genNewtonSteps

endmodule : rsqrt_lookup_tb
