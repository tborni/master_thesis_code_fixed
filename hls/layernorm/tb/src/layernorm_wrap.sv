/****************************************************************************
 * Interface shim: expose the Vitis-HLS-generated `layernorm_top` behind the
 * exact same module interface as the hand-written reference `layernorm.sv`.
 *
 * Purpose
 * -------
 * The reference SystemVerilog kernel (layernorm.sv) and the HLS-compiled
 * Verilog kernel (layernorm_top.v) implement the same streaming LayerNorm but
 * present slightly different pin-level interfaces:
 *
 *     reference `layernorm`        HLS `layernorm_top`
 *     ---------------------        -------------------
 *     clk                          ap_clk
 *     rst           (active-HIGH)  ap_rst_n        (active-LOW)
 *     xdat[SIMD-1:0][31:0]         src_TDATA[63:0]
 *     xvld                         src_TVALID
 *     xrdy                         src_TREADY
 *     ydat[SIMD-1:0][31:0]         dst_TDATA[63:0]
 *     yvld                         dst_TVALID
 *     yrdy                         dst_TREADY
 *
 * Both sides speak the same AXI-Stream-style handshake (VALID/READY, transfer
 * when both are asserted), so this wrapper is pure structural glue: it renames
 * the ports, inverts the reset polarity, and passes the flattened SIMD lanes
 * straight through. This lets the accuracy testbench that was written against
 * the reference `layernorm` drive the HLS core with *no* testbench changes:
 * identical stimulus, identical golden reference, identical error metric.
 *
 * Frozen configuration
 * --------------------
 * The provided HLS netlist was compiled for exactly ONE configuration:
 *
 *     N = 64,  SIMD = 2,  EPSILON = 1e-5  (fp32),  DSPFP32-primitive datapath
 *
 * (see layernorm_top.hpp: `constexpr unsigned N=64, SIMD=2;`). The wrapper is
 * therefore parameterized only to match the reference module's parameter list;
 * it CANNOT retarget the HLS core. An `initial` guard hard-stops elaboration
 * (`$fatal`) if instantiated with any other N/SIMD, and warns if EPSILON or
 * FORCE_BEHAVIORAL are set to values the frozen netlist does not implement.
 *
 * Lane packing (verified against the generated RTL)
 * -------------------------------------------------
 * The HLS `hls::vector<float,2>` maps to the 64-bit AXIS word little-endian:
 *   - element 0 (lane 0) occupies bits [31:0]
 *   - element 1 (lane 1) occupies bits [63:32]
 * on BOTH src_TDATA and dst_TDATA. Confirmed in the netlist:
 *   mean_stage:    add_i_i lane0 <- src_TDATA[31:0], lane1 <- src_TDATA[63:32]
 *   inv_sqrt_stage:dst_TDATA = { lane1(ln154_1), lane0(ln154) }
 * The reference `logic [SIMD-1:0][31:0] xdat` uses the identical convention
 * (xdat[0] = bits [31:0]), so the flattened bus maps 1:1 with no lane swap.
 ***************************************************************************/

module layernorm #(
	int unsigned  N,
	int unsigned  SIMD,
	shortreal  EPSILON = 1.0e-5,
	bit  FORCE_BEHAVIORAL = 0
)(
	// Global Control
	input	logic  clk,
	input	logic  rst,

	// (Parallel) Input Stream
	input	logic [SIMD-1:0][31:0]  xdat,
	input	logic  xvld,
	output	logic  xrdy,

	// (Parallel) Output Stream
	output	logic [SIMD-1:0][31:0]  ydat,
	output	logic  yvld,
	input	logic  yrdy
);

	//-----------------------------------------------------------------------
	// Compile-time guard: the HLS netlist is frozen at (N=64, SIMD=2).
	// Refuse any other configuration loudly instead of silently misbehaving.
	initial begin
		if((N != 64) || (SIMD != 2)) begin
			$fatal(1, "%m: HLS layernorm_top is compiled for N=64, SIMD=2 only; got N=%0d, SIMD=%0d.", N, SIMD);
		end
		// The HLS core bakes eps=1e-5 (layernorm.hpp default). Flag a mismatch:
		// the measured error would silently be against a different stabilizer.
		if(EPSILON != shortreal'(1.0e-5)) begin
			$warning("%m: HLS core uses a fixed EPSILON=1e-5; wrapper EPSILON=%e is ignored.", EPSILON);
		end
		// The HLS core always uses the DSPFP32-primitive fp datapath; it has no
		// behavioral-model switch. FORCE_BEHAVIORAL only affects the reference.
		if(FORCE_BEHAVIORAL) begin
			$warning("%m: FORCE_BEHAVIORAL=1 has no effect on the HLS core (fixed DSPFP32-primitive datapath).");
		end
	end

	//-----------------------------------------------------------------------
	// Reset polarity: reference `rst` is active-HIGH, HLS `ap_rst_n` active-LOW.
	uwire  ap_rst_n = ~rst;

	//-----------------------------------------------------------------------
	// Flatten the SIMD lanes onto the 64-bit AXIS words. The packed dimension
	// [SIMD-1:0][31:0] is already contiguous little-endian (lane 0 = LSBs), so
	// a direct bit-cast matches the HLS lane order with no reordering.
	uwire [SIMD*32-1:0]  src_tdata = xdat;
	uwire [SIMD*32-1:0]  dst_tdata;
	assign  ydat = dst_tdata;

	//-----------------------------------------------------------------------
	// The HLS core is `ap_ctrl_none` (free-running): ap_start/ap_continue are
	// tied high inside layernorm_top, so only the AXIS + reset pins remain and
	// the handshake semantics coincide with the reference's elastic streams.
	layernorm_top dut (
		.ap_clk    (clk),
		.ap_rst_n  (ap_rst_n),

		.src_TDATA (src_tdata),
		.src_TVALID(xvld),
		.src_TREADY(xrdy),

		.dst_TDATA (dst_tdata),
		.dst_TVALID(yvld),
		.dst_TREADY(yrdy)
	);

endmodule : layernorm
