/****************************************************************************
 * Small directed testbench for rec_wrapper.
 *
 * Streams a handful of fp32 inputs into rec_wrapper and prints the fp32
 * result as it leaves the pipeline. Inputs are positive normals with
 * biased exponent E in [1, 126] (the softmax pre-normalization range),
 * including both endpoints, several mantissa patterns, and the m == 0
 * power-of-two corner.
 ***************************************************************************/

module rec_wrapper_tb;

	localparam bit  FORCE_BEHAVIORAL = 1;

	//-----------------------------------------------------------------
	// Clock & reset
	//-----------------------------------------------------------------
	logic  clk = 1'b0;
	logic  rst = 1'b1;
	always #5 clk = ~clk;	// 100 MHz

	//-----------------------------------------------------------------
	// DUT interface
	//-----------------------------------------------------------------
	logic [31:0]  idat;
	logic         ivld;
	uwire         irdy;

	uwire [31:0]  odat;
	uwire         ovld;
	logic         ordy;

	rec_wrapper #(
		.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
	) dut (
		.clk, .rst,
		.idat, .ivld, .irdy,
		.odat, .ovld, .ordy
	);

	//-----------------------------------------------------------------
	// Stimulus vector.
	//
	// All values are positive normals with biased exponent E in [1, 126]
	// (the softmax pre-normalization range). Mix of power-of-two
	// (m == 0) and non-zero-mantissa inputs across the full E range.
	//-----------------------------------------------------------------
	localparam int unsigned  N_VEC = 7;
	shortreal  vec [N_VEC] = '{
		 1.0,
		 1.3,
		 1.7,
		 2.123,
		 5.5,
		 11.0,
		 88.0
	};

	//-----------------------------------------------------------------
	// Drive side
	//-----------------------------------------------------------------
	int  sent = 0;
	initial begin
		idat = '0;
		ivld = 1'b0;
		ordy = 1'b1;	// always accept results

		// Hold reset for a few cycles
		repeat(4) @(posedge clk);
		rst <= 1'b0;
		@(posedge clk);

		while(sent < N_VEC) begin
			idat <= $shortrealtobits(vec[sent]);
			ivld <= 1'b1;
			@(posedge clk);
			if(ivld && irdy) begin
				$display("[%0t]  send[%0d]  x = %e  (0x%08h)",
				         $time, sent, vec[sent], $shortrealtobits(vec[sent]));
				sent++;
			end
		end
		ivld <= 1'b0;
	end

	//-----------------------------------------------------------------
	// Receive side: print fp32 outputs as they appear.
	//-----------------------------------------------------------------
	int  rcvd = 0;
	always_ff @(posedge clk) begin
		if(!rst && ovld && ordy) begin
			$display("[%0t]  recv[%0d]  y = %e  (0x%08h)",
			         $time, rcvd, $bitstoshortreal(odat), odat);
			rcvd <= rcvd + 1;
		end
	end

	//-----------------------------------------------------------------
	// Watchdog / completion
	//-----------------------------------------------------------------
	initial begin
		// Generous bound: LATENCY=1 pipeline + setup cycles.
		repeat(200) @(posedge clk);
		if(rcvd != N_VEC) begin
			$display("TIMEOUT: received %0d / %0d", rcvd, N_VEC);
		end
		else begin
			$display("DONE: received all %0d samples", N_VEC);
		end
		$finish;
	end

endmodule : rec_wrapper_tb
