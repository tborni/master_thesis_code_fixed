module rec_ip_core_accuracy_tb;
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
	uwire  xrdy;
	uwire [31:0]  r;
	uwire  rvld;

	shortreal fr;
	assign	fr = $bitstoshortreal(r);

	rec_ip_core dut (
		.clk, .rstn,
		.idat(x), .ivld(xvld), .irdy(xrdy),
		.odat(r), .ovld(rvld)
	);

	// Reference Compute
	function real exact_rec(input shortreal  x);
		return 1.0 / real'(x);
	endfunction : exact_rec

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

	int unsigned  num_evaluated = 0;
	real  total_rel_error_squared = 0.0;
	real  max_rel_error = 0.0;
	shortreal  max_rel_error_x = 0.0;
	real  max_rel_error_ref = 0.0;
	shortreal  max_rel_error_fr = 0.0;
	shortreal  Q[$];
	initial begin
		automatic real  rmsre;

		@(posedge clk iff !rst);
		repeat(100) @(posedge clk);
		xvld <= 1;

		repeat(NUM_SAMPLES) begin
			fx <= rand_fp();
			@(posedge clk iff xrdy);
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
		$display("max_rel_error: %.17g  at x = %.17g  (dut = %.17g, ref = %.17g)",
			max_rel_error, max_rel_error_x, max_rel_error_fr, max_rel_error_ref);
		$finish;
	end

	always_ff @(posedge clk iff rvld) begin
		shortreal  x_queue;
		real       rec_ref, diff, rel_error;
		assert(Q.size()) else begin
			$error("Spurious output.");
			$stop;
		end
		x_queue = Q.pop_front();
		rec_ref = exact_rec(x_queue);

		diff = real'(fr) - rec_ref;
		rel_error = ((diff < 0.0) ? (-diff) : diff) / rec_ref;
		total_rel_error_squared += rel_error * rel_error;
		if (rel_error > max_rel_error) begin
			max_rel_error = rel_error;
			max_rel_error_x = x_queue;
			max_rel_error_ref = rec_ref;
			max_rel_error_fr = fr;
		end
		num_evaluated++;
	end

endmodule : rec_ip_core_accuracy_tb
