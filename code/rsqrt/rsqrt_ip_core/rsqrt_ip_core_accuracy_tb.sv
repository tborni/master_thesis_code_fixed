module rsqrt_ip_core_accuracy_tb;
	localparam int unsigned  NUM_SAMPLES = 10000;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	uwire  rstn = !rst;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end
	shortreal  fx;
	uwire [31:0]  x = $shortrealtobits(fx);
	logic  xvld = 0;
	uwire [31:0]  r;
	uwire  rvld;

	shortreal fr;
	assign	fr = $bitstoshortreal(r);

	rsqrt_ip_core dut (
		.clk, .rstn,
		.x, .xvld,
		.r, .rvld
	);

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

	int unsigned  num_evaluated = 0;
	real  total_rel_error_squared = 0.0;
	real  max_rel_error = 0.0;
	shortreal  Q[$];
	initial begin
		automatic real  rmsre;

		@(posedge clk iff !rst);
		repeat(100) @(posedge clk);
		xvld <= 1;

		repeat(NUM_SAMPLES) begin
			fx <= rand_fp();
			@(posedge clk);
			Q.push_back(fx);
		end
		xvld <= 0;
		repeat(50) @(posedge clk);

		assert(num_evaluated == NUM_SAMPLES) else begin
			$error("Unexpected number of outputs: expected %0d, got %0d", NUM_SAMPLES, num_evaluated);
			$stop;
		end

		rmsre = $sqrt(total_rel_error_squared / num_evaluated);
		$display("RMSRE: %.17g", rmsre);
		$display("max_rel_error: %.17g", max_rel_error);
		$finish;
	end

	always_ff @(posedge clk iff rvld) begin
		shortreal  x_queue;
		real       exp, diff, rel_error;
		assert(Q.size()) else begin
			$error("Spurious output.");
			$stop;
		end
		x_queue = Q.pop_front();
		exp = exact_rsqrt(x_queue);

		diff = real'(fr) - exp;
		rel_error = ((diff < 0.0) ? (-diff) : diff) / exp;
		total_rel_error_squared += rel_error * rel_error;
		max_rel_error = (rel_error > max_rel_error) ? rel_error : max_rel_error;
		num_evaluated++;
	end

endmodule : rsqrt_ip_core_accuracy_tb
