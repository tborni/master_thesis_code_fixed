module exp_ip_core_accuracy_tb;
	localparam int unsigned  NUM_SAMPLES = 10000;
	localparam bit           EXCLUDE_POS = 0;

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

	exp_ip_core dut (
		.clk, .rstn,
		.idat(x), .ivld(xvld), .irdy(xrdy),
		.odat(r), .ovld(rvld), .ordy(1'b1)
	);

	// Reference Compute (double-precision to avoid catastrophic cancellation
	// when comparing two ~equal large fp32 values)
	function real exact_exp(input shortreal  x);
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
		real       exp_ref, diff, rel_error;
		assert(Q.size()) else begin
			$error("Spurious output.");
			$stop;
		end
		x_queue = Q.pop_front();
		exp_ref = exact_exp(x_queue);

		diff = real'(fr) - exp_ref;
		rel_error = ((diff < 0.0) ? (-diff) : diff) / exp_ref;
		total_rel_error_squared += rel_error * rel_error;
		if (rel_error > max_rel_error) begin
			max_rel_error = rel_error;
			max_rel_error_x = x_queue;
			max_rel_error_ref = exp_ref;
			max_rel_error_fr = fr;
		end
		num_evaluated++;
	end

endmodule : exp_ip_core_accuracy_tb
