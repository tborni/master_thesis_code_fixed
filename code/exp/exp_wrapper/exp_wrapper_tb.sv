/****************************************************************************
 * Small directed testbench for exp_wrapper.
 *
 * Streams a handful of fp32 inputs into one SIMD=1 lane of exp_wrapper and
 * prints the fp32 result as it leaves the pipeline. Uses FORCE_BEHAVIORAL=1
 * so the DSPFP32 primitive is not required to simulate.
 ***************************************************************************/

module exp_wrapper_tb;

	localparam int unsigned  SIMD             = 1;
	localparam bit           EXCLUDE_POS      = 0;   // 0 exercises both shift-extraction arms
	localparam bit           FORCE_BEHAVIORAL = 1;

	//-----------------------------------------------------------------
	// Clock & reset
	//-----------------------------------------------------------------
	logic  clk = 1'b0;
	logic  rst = 1'b1;
	always #5 clk = ~clk;   // 100 MHz

	//-----------------------------------------------------------------
	// DUT interface
	//-----------------------------------------------------------------
	logic [SIMD-1:0][31:0]  idat;
	logic                   ivld;
	uwire                   irdy;

	uwire [SIMD-1:0][31:0]  odat;
	uwire                   ovld;
	logic                   ordy;

	exp_wrapper #(
		.SIMD(SIMD),
		.EXCLUDE_POS(EXCLUDE_POS),
		.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
	) dut (
		.clk, .rst,
		.idat, .ivld, .irdy,
		.odat, .ovld, .ordy
	);

	//-----------------------------------------------------------------
	// Stimulus vector.
	//
	// EXCLUDE_POS=0 takes signed x, so both the positive (k=I, f=F) and
	// negative (k=-ceil, f=1-F) arms of the shift extraction are exercised.
	//-----------------------------------------------------------------
	localparam int unsigned  N_VEC = 12;
	shortreal  vec [N_VEC] = '{
		 0.0,
		 1.0,
		-1.0,
		 0.5,
		-0.5,
		 2.0,
		-2.0,
		 5.5,
		-10.0,
		 88.0,
		-88.0,
		 0.6931471805599453   // +ln(2)
	};

	//-----------------------------------------------------------------
	// Drive side
	//-----------------------------------------------------------------
	int  sent = 0;
	initial begin
		idat = '0;
		ivld = 1'b0;
		ordy = 1'b1;   // always accept results

		// Hold reset for a few cycles
		repeat(4) @(posedge clk);
		rst <= 1'b0;
		@(posedge clk);

		while(sent < N_VEC) begin
			idat[0] <= $shortrealtobits(vec[sent]);
			ivld    <= 1'b1;
			@(posedge clk);
			if(ivld && irdy) begin
				$display("[%0t]  send[%0d]  x = %f  (0x%08h)",
				         $time, sent, vec[sent], $shortrealtobits(vec[sent]));
				sent++;
			end
		end
		ivld <= 1'b0;
	end

	//-----------------------------------------------------------------
	// Receive side: print fp32 outputs as they appear.
	// The wrapper assembles odat = {0, biased_exp, mantissa}; biased_exp=0
	// is the underflow-to-zero sentinel, which prints naturally as 0.0.
	//-----------------------------------------------------------------
	int  rcvd = 0;
	always_ff @(posedge clk) begin
		if(!rst && ovld && ordy) begin
			$display("[%0t]  recv[%0d]  y = %f  (0x%08h)",
			         $time, rcvd, $bitstoshortreal(odat[0]), odat[0]);
			rcvd <= rcvd + 1;
		end
	end

	//-----------------------------------------------------------------
	// Watchdog / completion
	//-----------------------------------------------------------------
	initial begin
		// Generous bound: 5-cycle pipeline + a few setup cycles.
		repeat(200) @(posedge clk);
		if(rcvd != N_VEC) begin
			$display("TIMEOUT: received %0d / %0d", rcvd, N_VEC);
		end
		else begin
			$display("DONE: received all %0d samples", N_VEC);
		end
		$finish;
	end

endmodule : exp_wrapper_tb
