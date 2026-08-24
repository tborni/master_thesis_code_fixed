module exp_bit_hacking_tb;

	localparam bit  FORCE_BEHAVIORAL = 0;
	localparam bit  EXCLUDE_POS      = 0;   // mirror DUT generic
	localparam int unsigned  SIMD   = 1;
	localparam int unsigned  NUM_SAMPLES = 10000;   // SIMD beats; NUM_SAMPLES*SIMD relative errors

	// Schraudolph's default constants.
	localparam shortreal     A = 12102203.0;
	localparam int unsigned  D = 1064866936;

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
