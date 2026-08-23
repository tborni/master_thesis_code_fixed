/****************************************************************************
 * Copyright (C) 2025-2026, Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * @author	Thomas B. Preußer <thomas.preusser@amd.com>
 ***************************************************************************/

module rsqrt_bit_hacking_tb;

	localparam bit  FORCE_BEHAVIORAL = 0;
	localparam int unsigned  MIN_NEWTON = 0;
	localparam int unsigned  MAX_NEWTON = 2;
	localparam int unsigned  MIN_SUSTAINABLE_INTERVAL =  1;
	localparam int unsigned  MAX_SUSTAINABLE_INTERVAL = 1;
	localparam int unsigned  TEST_COUNT = MAX_SUSTAINABLE_INTERVAL - MIN_SUSTAINABLE_INTERVAL + 1;

	localparam int unsigned  NUM_SAMPLES = 10000;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	bit [MAX_NEWTON:MIN_NEWTON][MAX_SUSTAINABLE_INTERVAL:MIN_SUSTAINABLE_INTERVAL]  done = '0;
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

	for(genvar  num_newton = MIN_NEWTON; num_newton <= MAX_NEWTON; num_newton++) begin : genTestNewton
		for(genvar  t = MIN_SUSTAINABLE_INTERVAL; t <= MAX_SUSTAINABLE_INTERVAL; t++) begin : genTestsII
			if(num_newton == 2 && t > 1) begin
				initial begin
					done[num_newton][t] = 1;
				end
			end
			else begin
				// DUT
				shortreal  fx;
				uwire [31:0]  x = $shortrealtobits(fx);
				logic  xvld;
				uwire [31:0]  r;
				uwire  rvld;
				uwire  xrdy;
				rsqrt_bit_hacking #(
					.NUM_NEWTON_STEPS(num_newton),
					.SUSTAINABLE_INTERVAL(t),
					.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
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
						$error("Test (Newton = %0d, II = %0d): Missing %0d outputs.", num_newton, t, Q.size());
						$stop;
					end

					rmsre = $sqrt(rel_err_squared / NUM_SAMPLES);
					$display("Test (Newton = %0d, II = %0d): RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f", num_newton, t, rmsre, rel_err_max, worst_input);

					done[num_newton][t] = 1;
				end

				// Checker
				always_ff @(posedge clk iff rvld) begin
					shortreal  x;
					real       exp, diff, rel_err;
					assert(Q.size()) else begin
						$error("Test (Newton = %0d, II = %0d): Spurious output.", num_newton, t);
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
	end : genTestNewton

endmodule : rsqrt_bit_hacking_tb
