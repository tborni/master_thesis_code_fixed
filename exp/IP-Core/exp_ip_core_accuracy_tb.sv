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
