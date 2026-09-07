/****************************************************************************
 * Accuracy testbench for the Vitis-HLS-generated SoftMax core, frozen at the
 * single configuration it was compiled for: N = 64, SIMD = 1, fp32.
 *
 * This is a single-configuration port of softmax_accuracy_tb.sv. It keeps ALL
 * of that testbench's measurement machinery unchanged so the number it reports
 * is directly comparable to the reference SystemVerilog kernel's (N=64, SIMD=1)
 * row:
 *   - rand_fp()          : identical fp32 logit generator (uniform real in
 *                          [-8, +8], denormals rejected)
 *   - exact_softmax()    : PRECISE fp32 golden reference -- exp(x-max)/sum
 *                          evaluated in full (double) precision. The error is
 *                          measured against the exact mathematical SoftMax, NOT
 *                          against the DUT's internal fixed-point accumulation,
 *                          so the reported RMSRE is the DUT's total deviation
 *                          from the ideal fp32 result.
 *   - RMSRE / max relative error / worst input, with REL_ERR_FLOOR gating so
 *     outputs that collapse into the underflow tail (exp(x-max) ~ 0) do not
 *     create meaningless divisions against a ~0 truth
 *   - process-local RNG seeded from N, so the input stream is reproducible and
 *     replays the reference testbench's (N=64, SIMD=1) stream element-for-element
 *   - TARGET_ELEMENTS-driven sample count and the drain-then-check protocol
 *
 * The only thing removed is the N x SIMD generate sweep: there is exactly one
 * DUT here, instantiated through softmax_wrap.sv (module `softmax`), which
 * adapts the HLS `softmax_top` to the reference interface.
 *
 * ---------------------------------------------------------------------------
 * COMPILE / RUN (Vivado xsim; the HLS core instantiates Xilinx floating_point
 * IP, so a bare open-source simulator will NOT elaborate it):
 *
 *   # 1. Create the five fp primitives' IP (run once, from a dir with the tcls);
 *   #    these .tcl files ship alongside the netlist in ../src:
 *   vivado -mode batch -source softmax_top_fcmp_32ns_32ns_1_1_no_dsp_1_ip.tcl
 *   vivado -mode batch -source softmax_top_fsub_32ns_32ns_32_1_primitive_dsp_1_ip.tcl
 *   vivado -mode batch -source softmax_top_fexp_32ns_32ns_32_9_med_dsp_1_ip.tcl
 *   vivado -mode batch -source softmax_top_fdiv_32ns_32ns_32_15_no_dsp_1_ip.tcl
 *   vivado -mode batch -source softmax_top_fpext_32ns_64_1_no_dsp_1_ip.tcl
 *
 *   # 2. Compile Verilog netlist + IP + this SV testbench and wrapper:
 *   xvlog                 softmax_top*.v          # all generated .v netlist files
 *   xvlog -sv             softmax_wrap.sv softmax_wrap_accuracy_tb.sv
 *
 *   # 3. Elaborate against the Xilinx sim libraries and run:
 *   xelab -L unisims_ver -L floating_point_v7_1 -timescale 1ns/1ps \
 *         softmax_wrap_accuracy_tb -s tb_sim
 *   xsim tb_sim -runall
 *
 * In practice the run_sim.tcl in ../scripts drives all of this in project mode
 * (launch_simulation compiles the IP sim models and the required Xilinx sim
 * libraries automatically -- no manual -L flags). The netlist .v files needed
 * are the ones under ../src:
 *   softmax_top.v, softmax_top_execute.v, softmax_top_max_extract.v,
 *   softmax_top_exponentiate.v, softmax_top_div_stage.v, *_fifo_*.v,
 *   *_regslice_both.v, and the five *_primitive_/_no_dsp_/_med_dsp_*.v fp wrappers.
 ***************************************************************************/

module softmax_wrap_accuracy_tb;

	// Frozen configuration of the compiled HLS core.
	localparam int unsigned  N    = 64;
	localparam int unsigned  SIMD = 1;
	localparam int unsigned  NN   = N / SIMD;

	// Set to 1 only if the reference kernel is being simulated with behavioral
	// fp models. The HLS core has no such switch (fixed floating_point-IP
	// datapath); this is kept solely to match the reference testbench's
	// convention and is 0.
	localparam bit  FORCE_BEHAVIORAL = 0;

	// Hold the number of exercised output elements constant. TARGET_ELEMENTS
	// must be divisible by N; 32768 is a multiple of 64.
	localparam int unsigned  TARGET_ELEMENTS = 32768;
	localparam int unsigned  NUM_SAMPLES     = TARGET_ELEMENTS / N;

	// Reference relative error is only defined where the exact output is not
	// (near) zero. A SoftMax output is exp(x-max)/sum, strictly in (0, 1].
	// Elements far below the group maximum drive exp(x-max) into the underflow
	// regime where both the DUT and the reference collapse to ~0; a relative
	// error against a ~0 truth is meaningless. Such elements are excluded from
	// the relative-error statistics. Kept at the reference testbench's 1e-5 so
	// the scored output-magnitude window (and hence the DUT error regime) is
	// identical to the reference kernel's (N=64, SIMD=1) measurement.
	localparam shortreal     REL_ERR_FLOOR = 1.0e-5;

	// Reported RMSRE when no output element cleared REL_ERR_FLOOR, i.e. the
	// metric is undefined. Negative distinguishes it from a perfect 0.0.
	localparam real          RMSRE_UNDEFINED = -1.0;

	initial begin
		assert(TARGET_ELEMENTS % N == 0) else begin
			$error("TARGET_ELEMENTS(%0d) must be divisible by N(%0d).", TARGET_ELEMENTS, N);
			$finish;
		end
	end

	//=======================================================================
	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	//=======================================================================
	// DUT: HLS core behind the reference `softmax` interface (see wrapper).
	logic [SIMD-1:0][31:0]  xdat;
	logic  xvld;
	uwire  xrdy;
	uwire [SIMD-1:0][31:0]  ydat;
	uwire  yvld;
	logic  yrdy;
	softmax #(
		.N(N),
		.SIMD(SIMD),
		.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
	) dut (
		.clk, .rst,
		.xdat, .xvld, .xrdy,
		.ydat, .yvld, .yrdy
	);

	//=======================================================================
	// Random fp32 logit generator (bit-identical to the reference testbench):
	// uniform over the reals in [-LOGIT_ABS, +LOGIT_ABS] (so each representable
	// value is NOT equally likely) with denormalized results excluded. Draw a
	// uniform real, then reject-and-redraw any denormal (an exponent field of 0
	// with a non-zero mantissa); exact +-0 is kept. The
	// $shortrealtobits/$bitstoshortreal round-trip on the drawn value avoids a
	// Vivado shortreal simulation error.
	function automatic shortreal rand_fp();
		localparam shortreal     LOGIT_ABS = 8.0;

		automatic real  lo = -real'(LOGIT_ABS);
		automatic real  hi =  real'(LOGIT_ABS);
		forever begin
			automatic real          u         = real'($urandom()) / 4294967296.0;
			automatic shortreal     s         = $bitstoshortreal($shortrealtobits(shortreal'(lo + (hi - lo) * u)));
			automatic logic [31:0]  bits      = $shortrealtobits(s);
			automatic logic [ 7:0]  exp_field = bits[30:23];
			automatic logic [22:0]  man_field = bits[22: 0];
			if(exp_field != 8'd0 || man_field == 23'd0)  return s;
		end
	endfunction : rand_fp

	// Exact (precise-fp32) SoftMax over one complete vector of N input elements,
	// evaluated in full precision. The DUT subtracts the group maximum from
	// every element, exponentiates the residuals and divides by their sum; the
	// reference mirrors the same max-shift, exp, normalize but in `real`
	// (double) precision. The measured error is therefore the DUT's total
	// deviation from the ideal fp32 SoftMax (exp/reciprocal table approximation
	// plus its fixed-point accumulation), not a modeling artifact. The max shift
	// is a mathematical identity for the exact result but is retained to match
	// the DUT's numerics and to keep every exp() argument <= 0.
	function automatic void exact_softmax(input shortreal  x[$], output shortreal  y[$]);
		automatic real  mx = x[0];
		automatic real  sum = 0.0;
		y.delete();
		foreach(x[i])  if(x[i] > mx)  mx = x[i];
		foreach(x[i])  sum += $exp(x[i] - mx);
		foreach(x[i])  y.push_back(shortreal'($exp(x[i] - mx) / sum));
	endfunction : exact_softmax

	//=======================================================================
	// Statistics
	int unsigned  err_count       = 0;	// output elements entering the RMSRE
	real          rel_err_squared = 0.0;
	real          rel_err_max     = 0.0;
	shortreal     worst_input     = 0.0;

	// Input vectors awaiting their corresponding output for comparison.
	shortreal  Q[$][$];		// FIFO of length-N input vectors

	//=======================================================================
	// Stimulus feeder
	initial begin
		automatic shortreal  vec[$];		// input vector under construction
		automatic real       rmsre;
		// Seed the feeder's RNG from N so the input stream is reproducible and
		// matches the reference testbench's (N=64, SIMD=1) stream element-for-element.
		process::self().srandom(N);
		xdat = 'x;
		xvld = 0;
		@(posedge clk iff !rst);

		xvld <= 1;
		vec.delete();
		repeat(NUM_SAMPLES * NN) begin : feedBeats
			automatic logic [SIMD-1:0][31:0]  beat;
			for(int unsigned  i = 0; i < SIMD; i++) begin
				automatic shortreal  v = rand_fp();
				beat[i] = $shortrealtobits(v);
				vec.push_back(v);
			end
			xdat <= beat;
			@(posedge clk iff xrdy);	// beat accepted on this edge
			if(vec.size() == N) begin
				Q.push_back(vec);
				vec.delete();
			end
		end : feedBeats
		xvld <= 0;
		xdat <= 'x;

		// Drain: allow all outstanding groups to propagate out of the pipeline.
		// 2*NN keeps a 2x margin on the streaming part and 512 covers the fixed
		// pipeline depths (max/exp/adder/accumulator/reciprocal + the N-deep
		// dataflow FIFOs) generously.
		repeat(2*NN + 512) @(posedge clk);
		assert(Q.size() == 0) else begin
			$error("Test (N = %0d, SIMD = %0d): Missing %0d output vectors.", N, SIMD, Q.size());
			$stop;
		end

		rmsre = (err_count != 0) ? $sqrt(rel_err_squared / err_count) : RMSRE_UNDEFINED;
		$display("Test (N = %0d, SIMD = %0d): RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f (elements = %0d)",
			N, SIMD, rmsre, rel_err_max, worst_input, err_count);

		$finish;
	end

	//=======================================================================
	// Output collection: sink always ready; gather SIMD lanes per accepted
	// beat, assemble N-element vectors and compare against the exact reference.
	assign	yrdy = 1;
	shortreal  outv[$];		// output vector under construction
	initial  outv.delete();
	always_ff @(posedge clk iff (yvld && yrdy)) begin
		automatic shortreal  xin[$];
		automatic shortreal  yref[$];
		for(int unsigned  i = 0; i < SIMD; i++) begin
			outv.push_back($bitstoshortreal(ydat[i]));
		end
		if(outv.size() == N) begin
			assert(Q.size()) else begin
				$error("Test (N = %0d, SIMD = %0d): Spurious output vector.", N, SIMD);
				$stop;
			end
			xin = Q.pop_front();
			exact_softmax(xin, yref);
			foreach(yref[i]) begin
				automatic shortreal  exp     = yref[i];
				automatic shortreal  diff    = outv[i] - exp;
				automatic shortreal  abs_exp = (exp  < 0.0) ? -exp  : exp;
				automatic shortreal  abs_dif = (diff < 0.0) ? -diff : diff;
				automatic real       rel_err;
				if(abs_exp >= REL_ERR_FLOOR) begin
					rel_err = abs_dif / abs_exp;
					rel_err_squared += rel_err * rel_err;
					err_count += 1;
					if(rel_err > rel_err_max) begin
						rel_err_max = rel_err;
						worst_input = xin[i];
					end
				end
			end
			outv.delete();
		end
	end

endmodule : softmax_wrap_accuracy_tb
