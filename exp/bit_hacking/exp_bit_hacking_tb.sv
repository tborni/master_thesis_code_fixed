module exp_bit_hacking_tb;

	localparam bit  FORCE_BEHAVIORAL = 0;
	localparam bit  EXCLUDE_POS      = 0;   // mirror DUT generic
	localparam int unsigned  SIMD   = 1;
	localparam int unsigned  NUM_SAMPLES = 10000;   // SIMD beats; NUM_SAMPLES*SIMD relative errors

	// Schraudolph's default constants.
	localparam shortreal     A = 12102203.0;
	localparam int unsigned  D = 1065277304;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	bit  done = 0;
	always_comb begin
		if(done)  $finish;
	end

	// Random fp sample generator
	//	EXCLUDE_POS=0: any normal fp32 in [-87.0, 88.0]
	//	EXCLUDE_POS=1: any normal fp32 in [-87.0,  0.0)
	// Uniform over fp32 bit patterns (mantissa and exponent-field each drawn
	// uniformly), mirroring the rec/rsqrt samplers and the other exp accuracy
	// testbenches, rather than uniform over the reals -- the latter concentrates
	// almost all mass in the few largest exponent bins and barely exercises small
	// magnitudes.
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

	// DUT
	// Drive the packed input bus directly with fp32 bit patterns.
	logic [SIMD-1:0][31:0]  idat;
	logic  ivld;
	uwire  irdy;
	uwire [SIMD-1:0][31:0]  odat;
	uwire  ovld;
	uwire  ordy = 1;
	exp_bit_hacking #(
		.SIMD(SIMD),
		.A(A),
		.D(D),
		.EXCLUDE_POS(EXCLUDE_POS),
		.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
	) dut (
		.clk, .rst,
		.idat, .ivld, .irdy,
		.odat, .ovld, .ordy
	);

	// Stimulus
	// Reference queue: each entry holds the packed fp32 bit patterns of one
	// accepted SIMD beat (avoids unpacked-array-in-queue patterns that crash
	// some simulators).
	typedef logic [SIMD-1:0][31:0]  vec_t;
	vec_t  X[$];

	// Accumulators, spanning every lane of every accepted beat.
	int unsigned  num_evaluated          = 0;
	real          total_rel_error_squared = 0.0;
	real          max_rel_error          = 0.0;
	shortreal     max_rel_error_x        = 0.0;
	real          max_rel_error_ref      = 0.0;
	shortreal     max_rel_error_fr       = 0.0;

	initial begin
		automatic vec_t  vec;
		automatic real   rmsre;
		idat = 'x;
		ivld = 0;
		@(posedge clk iff !rst);

		// Feed NUM_SAMPLES SIMD beats of bit-pattern-uniform samples. Each lane
		// draws an independent D1 sample, so a beat carries SIMD relative errors.
		// The input handshake is respected so no beat is dropped under back-pressure.
		ivld <= 1;
		for(int unsigned  i = 0; i < NUM_SAMPLES;) begin
			for(int unsigned  k = 0; k < SIMD; k++)  vec[k] = $shortrealtobits(rand_fp());
			idat <= vec;
			@(posedge clk iff irdy);
			X.push_back(vec);
			i++;
		end
		ivld <= 0;
		idat <= 'x;

		repeat(32) @(posedge clk);
		assert(X.size() == 0) else begin
			$error("Missing %0d outputs.", X.size());
			$stop;
		end

		rmsre = $sqrt(total_rel_error_squared / num_evaluated);
		$display("=========================================================================");
		$display("exp_bit_hacking accuracy sweep");
		$display("  NUM_SAMPLES      = %0d beats (%0d lanes each)", NUM_SAMPLES, SIMD);
		$display("  EXCLUDE_POS      = %0d", EXCLUDE_POS);
		$display("  FORCE_BEHAVIORAL = %0d", FORCE_BEHAVIORAL);
		$display("  SIMD=%0d  RMSRE=%.6e  max_rel_error=%.6e  at x=%.9g  (dut=%.9g, ref=%.9g)",
			SIMD, rmsre, max_rel_error, max_rel_error_x, max_rel_error_fr, max_rel_error_ref);
		$display("=========================================================================");

		done = 1;
	end

	// Checker: accumulate RMSRE against the true exp() over every lane of every
	// accepted SIMD beat.
	always_ff @(posedge clk iff ovld) begin
		vec_t  xv;
		assert(X.size()) else begin
			$error("Spurious output.");
			$stop;
		end
		xv = X.pop_front();
		for(int unsigned  k = 0; k < SIMD; k++) begin
			automatic shortreal  x_sample = $bitstoshortreal(xv[k]);
			automatic shortreal  fr_local = $bitstoshortreal(odat[k]);
			automatic real       exp_ref  = $exp(real'(x_sample));
			automatic real       diff      = real'(fr_local) - exp_ref;
			automatic real       rel_error = ((diff < 0.0) ? -diff : diff) / exp_ref;

			total_rel_error_squared += rel_error * rel_error;
			if(rel_error > max_rel_error) begin
				max_rel_error     = rel_error;
				max_rel_error_x   = x_sample;
				max_rel_error_ref = exp_ref;
				max_rel_error_fr  = fr_local;
			end
			num_evaluated++;
		end
	end

endmodule : exp_bit_hacking_tb
