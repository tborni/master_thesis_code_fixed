/****************************************************************************
 * Interface shim: expose the Vitis-HLS-generated `softmax_top` behind the
 * exact same module interface as the hand-written reference `softmax.sv`.
 *
 * Purpose
 * -------
 * The reference SystemVerilog kernel (softmax.sv) and the HLS-compiled Verilog
 * kernel (softmax_top.v) implement the same streaming SoftMax but present
 * slightly different pin-level interfaces:
 *
 *     reference `softmax`          HLS `softmax_top`
 *     -------------------          -----------------
 *     clk                          ap_clk
 *     rst           (active-HIGH)  ap_rst_n        (active-LOW)
 *     xdat[SIMD-1:0][31:0]         src_TDATA[31:0]
 *     xvld                         src_TVALID
 *     xrdy                         src_TREADY
 *     ydat[SIMD-1:0][31:0]         dst_TDATA[31:0]
 *     yvld                         dst_TVALID
 *     yrdy                         dst_TREADY
 *
 * Both sides speak the same AXI-Stream-style handshake (VALID/READY, transfer
 * when both are asserted), so this wrapper is pure structural glue: it renames
 * the ports, inverts the reset polarity, and passes the flattened SIMD lanes
 * straight through. This lets the accuracy testbench that was written against
 * the reference `softmax` drive the HLS core with *no* testbench changes:
 * identical stimulus, identical golden reference, identical error metric.
 *
 * Frozen configuration
 * --------------------
 * The provided HLS netlist was compiled for exactly ONE configuration:
 *
 *     N = 64,  SIMD = 1,  TI = TO = float (fp32)
 *
 * (see softmax_top.hpp: `constexpr size_t N=64, SIMD=1; using TI=float; using
 * TO=float;`). The wrapper is therefore parameterized only to match the
 * reference module's parameter list; it CANNOT retarget the HLS core. An
 * `initial` guard hard-stops elaboration (`$fatal`) if instantiated with any
 * other N/SIMD, and warns if FORCE_BEHAVIORAL is set (the frozen netlist has no
 * behavioral-model switch; the pin is kept only to match the reference).
 *
 * Note there is NO EPSILON here: unlike LayerNorm, the SoftMax datapath carries
 * no stabilizer constant. Numerical stability comes from the max-subtraction
 * (every exp() argument is <= 0), so the reference `softmax` and this wrapper
 * both take only (N, SIMD, FORCE_BEHAVIORAL).
 *
 * Lane packing (SIMD = 1)
 * -----------------------
 * With SIMD = 1 the AXIS word is a single 32-bit fp32: element 0 (lane 0)
 * occupies bits [31:0] of both src_TDATA and dst_TDATA. The reference
 * `logic [SIMD-1:0][31:0] xdat` with SIMD=1 is likewise just bits [31:0], so
 * the flattened bus maps 1:1 with no lane reordering. (The generated netlist's
 * src/dst AXIS words are 32 bits wide, confirming the single-lane packing.)
 ***************************************************************************/

module softmax #(
	int unsigned  N,
	int unsigned  SIMD,
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
	// Compile-time guard: the HLS netlist is frozen at (N=64, SIMD=1).
	// Refuse any other configuration loudly instead of silently misbehaving.
	initial begin
		if((N != 64) || (SIMD != 1)) begin
			$fatal(1, "%m: HLS softmax_top is compiled for N=64, SIMD=1 only; got N=%0d, SIMD=%0d.", N, SIMD);
		end
		// The HLS core always uses the fixed floating_point-IP datapath; it has
		// no behavioral-model switch. FORCE_BEHAVIORAL only affects the reference.
		if(FORCE_BEHAVIORAL) begin
			$warning("%m: FORCE_BEHAVIORAL=1 has no effect on the HLS core (fixed floating_point-IP datapath).");
		end
	end

	//-----------------------------------------------------------------------
	// Reset polarity: reference `rst` is active-HIGH, HLS `ap_rst_n` active-LOW.
	uwire  ap_rst_n = ~rst;

	//-----------------------------------------------------------------------
	// Flatten the SIMD lanes onto the AXIS words. The packed dimension
	// [SIMD-1:0][31:0] is already contiguous little-endian (lane 0 = LSBs), so
	// a direct bit-cast matches the HLS lane order with no reordering. With the
	// frozen SIMD=1 this is simply the 32-bit fp32 word.
	uwire [SIMD*32-1:0]  src_tdata = xdat;
	uwire [SIMD*32-1:0]  dst_tdata;
	assign  ydat = dst_tdata;

	//-----------------------------------------------------------------------
	// The HLS core is `ap_ctrl_none` (free-running): ap_start/ap_continue are
	// tied high inside softmax_top, so only the AXIS + reset pins remain and
	// the handshake semantics coincide with the reference's elastic streams.
	softmax_top dut (
		.ap_clk    (clk),
		.ap_rst_n  (ap_rst_n),

		.src_TDATA (src_tdata),
		.src_TVALID(xvld),
		.src_TREADY(xrdy),

		.dst_TDATA (dst_tdata),
		.dst_TVALID(yvld),
		.dst_TREADY(yrdy)
	);

endmodule : softmax
