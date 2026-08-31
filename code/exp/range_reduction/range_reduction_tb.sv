module range_reduction_tb;

	localparam int unsigned  ROUNDS = 64;
	localparam bit  FORCE_BEHAVIORAL = 0;

	typedef struct {
		int unsigned  simd;
		bit           exclude_pos;
	} cfg_t;
	localparam int unsigned  TESTS = 14;
	localparam cfg_t  TEST_CFG[TESTS] = '{
		'{  1, 0 },
		'{  3, 0 },
		'{  4, 0 },
		'{  6, 0 },
		'{  9, 0 },
		'{ 13, 0 },
		'{ 16, 0 },
		'{  1, 1 },
		'{  3, 1 },
		'{  4, 1 },
		'{  6, 1 },
		'{  9, 1 },
		'{ 13, 1 },
		'{ 16, 1 }
	};

	//-----------------------------------------------------------------------
	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	//-----------------------------------------------------------------------
	// Test Instantiations
	bit [TESTS-1:0]  Done = '0;
	always_comb begin
		if(&Done) $finish();
	end
	for(genvar  test = 0; test < TESTS; test++) begin : genTests
		localparam int unsigned  SIMD        = TEST_CFG[test].simd;
		localparam bit           EXCLUDE_POS = TEST_CFG[test].exclude_pos;

		// DUT
		logic [SIMD-1:0][31:0]  idat;
		logic  ivld;
		uwire  irdy;
		uwire [SIMD-1:0][ 7:0]  kdat;
		uwire [SIMD-1:0][22:0]  fdat;
		uwire  kfvld;
		logic  kfrdy;
		range_reduction #(
			.SIMD(SIMD), .EXCLUDE_POS(EXCLUDE_POS), .FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
		) dut (
			.clk, .rst,
			.idat, .ivld, .irdy,
			.kdat, .fdat, .kfvld, .kfrdy
		);

		// 2-D unpacked shortreal storage (XSim chokes on parameterized
		// typedef shortreal arrays declared inside a generate block).
		shortreal  X [ROUNDS][SIMD];

		// Stimulus
		initial begin
			idat = 'x;
			ivld = 0;
			@(posedge clk iff !rst);

			for(int unsigned  r = 0; r < ROUNDS; r++) begin
				// Keep x within the practically interesting exp() domain
				// of roughly [-90, +90] so prod = x*log2(e) lands in the
				// non-saturated [-127, +127] interval.
				for(int unsigned  j = 0; j < SIMD; j++) begin
					shortreal  v;
					v = (int'($urandom()%18001) - 9000) * 0.01;	// [-90, +90]
					if(EXCLUDE_POS && v > 0.0)  v = -v;
					X[r][j] = v;
				end

				while($urandom()%23 == 0) @(posedge clk);
				ivld <= 1;
				for(int unsigned  j = 0; j < SIMD; j++) begin
					idat[j] <= $shortrealtobits(X[r][j]);
				end
				@(posedge clk iff irdy);
				idat <= 'x;
				ivld <= 0;
			end
		end

		// Output Checker
		initial begin
			kfrdy = 0;
			@(posedge clk iff !rst);

			for(int unsigned  r = 0; r < ROUNDS; r++) begin
				while($urandom()%5 == 0) @(posedge clk);
				kfrdy <= 1;
				@(posedge clk iff kfvld);
				for(int unsigned  j = 0; j < SIMD; j++) begin
					shortreal           x;
					shortreal           ref_p;
					shortreal           frac;
					shortreal           got;
					shortreal           err;
					logic signed [8:0]  k;

					x     = X[r][j];
					ref_p = x * 1.4426950408889634;                       // log2(e)
					k     = $signed({1'b0, kdat[j]}) - 9'sd127;
					frac  = $itor(fdat[j]) / 8388608.0;                   // fdat/2^23

					if(ref_p < -127.0 || ref_p >= 127.0) begin
						// Saturation regime: fp32_to_int clamps k to [-127,+127]
						// so f = prod - (k-1) leaves the [1,2) interval and fdat
						// is meaningless. Just sanity-check kdat is at the
						// corresponding rail.
						assert((ref_p < -127.0)? (kdat[j] == 8'd0) : (kdat[j] == 8'd254)) else begin
							$error("[t%0d r%0d j%0d] saturation expected but kdat=%0d ref_p=%g",
							       test, r, j, kdat[j], ref_p);
							$stop;
						end
					end
					else begin
						// (k, f) is the range-reduced representation of prod:
						//   prod  =  k + f      with f in [0, 1)
						// where k is recovered from kdat-127 and f from
						// fdat/2^23 (fdat is the mantissa of (1+f), so the
						// 23-bit field == the fixed-point fraction of f).
						// Square the absolute error so a single threshold
						// captures both signs (fp32 multiplier can lose
						// ~1 ULP at the scale of |prod| max ~127, giving
						// an absolute error up to 127 * 2^-23 ~ 1.5e-5).
						got = $itor(k) + frac;
						err = got - ref_p;
						err *= err;
						assert(err < 4e-9) else begin
							$error("[t%0d r%0d j%0d] x=%g  got=%g (k=%0d f=%h)  ref=%g  err^2=%g",
							       test, r, j, x, got, k, fdat[j], ref_p, err);
							$stop;
						end
					end
				end
				kfrdy <= 0;
			end
			repeat(5) @(posedge clk);

			Done[test] <= 1;
		end

	end : genTests

endmodule : range_reduction_tb
