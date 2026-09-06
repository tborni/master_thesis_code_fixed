/****************************************************************************
 * Accuracy testbench for the Vitis-HLS-generated LayerNorm core, frozen at
 * the single configuration it was compiled for: N = 64, SIMD = 2, fp32,
 * EPSILON = 1e-5.
 *
 * This is a single-configuration port of layernorm_accuracy_tb.sv. It keeps
 * ALL of that testbench's measurement machinery unchanged so the number it
 * reports is directly comparable to the reference SystemVerilog kernel's
 * (N=64, SIMD=2) row:
 *   - rand_fp()          : identical bit-level fp32 sample generator
 *   - exact_layernorm()  : full-precision golden reference mirroring the DUT's
 *                          exact algorithm (plain-mean shift, variance of the
 *                          shifted values, EPSILON-stabilized inverse sqrt)
 *   - RMSRE / max relative error / worst input, with REL_ERR_FLOOR gating so
 *     outputs passing through zero (input == mean) do not create meaningless
 *     divisions
 *   - process-local RNG seeded from N, so the input stream is reproducible
 *   - TARGET_ELEMENTS-driven sample count and the drain-then-check protocol
 *
 * The only thing removed is the N x SIMD generate sweep: there is exactly one
 * DUT here, instantiated through layernorm_wrap.sv (module `layernorm`), which
 * adapts the HLS `layernorm_top` to the reference interface.
 *
 * ---------------------------------------------------------------------------
 * COMPILE / RUN (Vivado xsim; the HLS core instantiates Xilinx floating_point
 * IP, so a bare open-source simulator will NOT elaborate it):
 *
 *   # 1. Create the six fp primitives' IP (run once, from a dir with the tcls):
 *   #    these .tcl files ship alongside the netlist in this folder.
 *   vivado -mode batch -source layernorm_top_fadd_32ns_32ns_32_1_primitive_dsp_1_ip.tcl
 *   vivado -mode batch -source layernorm_top_fsub_32ns_32ns_32_1_primitive_dsp_1_ip.tcl
 *   vivado -mode batch -source layernorm_top_fmul_32ns_32ns_32_2_primitive_dsp_1_ip.tcl
 *   vivado -mode batch -source layernorm_top_fmadd_32ns_32ns_32ns_32ns_32_3_primitive_dsp_1_ip.tcl
 *   vivado -mode batch -source layernorm_top_fdiv_32ns_32ns_32_15_no_dsp_1_ip.tcl
 *   vivado -mode batch -source layernorm_top_fsqrt_32ns_32ns_32_15_no_dsp_1_ip.tcl
 *   #    (simplest in practice: add these to a Vivado project / project_ip.tcl
 *   #     and export simulation, or use the .xci already under sweeps/.)
 *
 *   # 2. Compile Verilog netlist + IP + this SV testbench and wrapper:
 *   xvlog                 layernorm_top*.v          # all generated .v netlist files
 *   xvlog -sv             layernorm_wrap.sv layernorm_wrap_accuracy_tb.sv
 *
 *   # 3. Elaborate against the Xilinx sim libraries and run:
 *   xelab -L unisims_ver -L floating_point_v7_1 -timescale 1ns/1ps \
 *         layernorm_wrap_accuracy_tb -s tb_sim
 *   xsim tb_sim -runall
 *
 * Note: xvlog/xelab library names (-L) depend on your Vivado version; the IP
 * created in step 1 pulls in floating_point_v7_1. Adjust as your install
 * requires. The netlist .v files needed are the ones in this folder:
 *   layernorm_top.v, layernorm_top_layernorm_*.v, *_mean_stage_*.v,
 *   *_var_stage_*.v, *_inv_sqrt_stage_*.v, *_fifo_*.v, *_regslice_both.v,
 *   and the six *_primitive_/_no_dsp_*.v fp wrappers.
 ***************************************************************************/

module layernorm_wrap_accuracy_tb;

	// Frozen configuration of the compiled HLS core.
	localparam int unsigned  N    = 64;
	localparam int unsigned  SIMD = 2;
	localparam int unsigned  NN   = N / SIMD;

	localparam shortreal     EPSILON = 1.0e-5;

	// Set to 1 only if the reference kernel is being simulated with behavioral
	// fp models. The HLS core has no such switch (fixed DSPFP32 datapath); this
	// is kept solely to match the reference testbench's convention and is 0.
	localparam bit  FORCE_BEHAVIORAL = 0;

	// Hold the number of exercised output elements constant. TARGET_ELEMENTS
	// must be divisible by N; 32768 is a multiple of 64.
	localparam int unsigned  TARGET_ELEMENTS = 32768;
	localparam int unsigned  NUM_SAMPLES     = TARGET_ELEMENTS / N;

	// Reference relative error is only defined where the exact output is not
	// (near) zero. LayerNorm outputs pass through zero whenever an input equals
	// the mean; such elements are excluded from the relative-error statistics.
	localparam shortreal     REL_ERR_FLOOR = 1.0e-3;

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
	// DUT: HLS core behind the reference `layernorm` interface (see wrapper).
	logic [SIMD-1:0][31:0]  xdat;
	logic  xvld;
	uwire  xrdy;
	uwire [SIMD-1:0][31:0]  ydat;
	uwire  yvld;
	logic  yrdy;
	layernorm #(
		.N(N),
		.SIMD(SIMD),
		.EPSILON(EPSILON),
		.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
	) dut (
		.clk, .rst,
		.xdat, .xvld, .xrdy,
		.ydat, .yvld, .yrdy
	);

	//=======================================================================
	// Random fp sample generator (bit-identical to the reference testbench).
	function shortreal rand_fp();
		int unsigned bits;
		bits = $urandom();
		// Keep inputs strictly normalized (exp >= 1). The upper bound bounds
		// the squared values and the reduction sums well within the normalized
		// fp32 range. No matching lower bound is needed: EPSILON floors the
		// inverse-square-root argument, so it never sees denormals.
		bits[30:23] = $urandom_range(87, 142);	// ~[2^-40, 2^15)
		bits[31]    = $urandom_range(0, 1);
		return $bitstoshortreal(bits);
	endfunction : rand_fp

	// Exact LayerNorm of the algorithm implemented by the DUT, evaluated in
	// full precision over one complete vector of N input elements. The DUT
	// shifts by the plain mean, forms the variance of the shifted values and
	// stabilizes the inverse square root by EPSILON; the reference mirrors this
	// exactly so the measured error is the finite-precision / table-
	// approximation error of the DUT alone.
	function automatic void exact_layernorm(input shortreal  x[$], output shortreal  y[$]);
		automatic real  sum = 0.0;
		automatic real  mean;
		automatic real  var_sum = 0.0;
		automatic real  variance;
		automatic real  inv_std;
		y.delete();
		foreach(x[i])  sum += x[i];
		mean = sum / N;
		foreach(x[i])  var_sum += (x[i] - mean) ** 2;
		variance = var_sum / N;
		inv_std  = 1.0 / $sqrt(variance + EPSILON);
		foreach(x[i])  y.push_back(shortreal'((x[i] - mean) * inv_std));
	endfunction : exact_layernorm

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
		// matches the reference testbench's (N=64) stream element-for-element.
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

		// Drain: allow all outstanding vectors to propagate out of the pipeline.
		repeat(64 + 32*NN) @(posedge clk);
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
			exact_layernorm(xin, yref);
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

endmodule : layernorm_wrap_accuracy_tb
