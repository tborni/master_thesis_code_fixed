module layernorm_accuracy_tb;
	// A swept parameter range. `geo` selects how `step` is applied: arithmetic (v += step)
	// or geometric (v *= step). All loop iteration and index/count math is derived from these
	// fields through the range_* helpers below, so a sweep is fully described by its make_*
	// declaration alone -- switching a parameter between arithmetic and geometric, or changing
	// min/max/step, needs no edits anywhere else in the testbench.
	typedef struct packed {
		int unsigned min;
		int unsigned max;
		int unsigned step;
		bit          geo;	// 0: arithmetic (v += step); 1: geometric (v *= step)
		int unsigned num;	// number of values in the sweep
	} range_t;

	// Number of values produced by iterating `min` to `max` under the given stride mode.
	function automatic int unsigned range_num(input bit  geo, input int unsigned  min, input int unsigned  max, input int unsigned  step);
		return  geo? ($clog2(max / min) / $clog2(step) + 1) : ((max - min) / step + 1);
	endfunction : range_num

	// Arithmetic sweep: values are min, min+step, min+2*step, ..., max.
	function automatic range_t make_range(input int unsigned  min, input int unsigned  max, input int unsigned  step);
		return '{ min: min, max: max, step: step, geo: 1'b0, num: range_num(1'b0, min, max, step) };
	endfunction : make_range

	// Geometric sweep: values are min, min*step, min*step^2, ..., max (step is the ratio).
	// Assumes min, max and step are powers of two with max a power-of-step multiple of min.
	function automatic range_t make_geo_range(input int unsigned  min, input int unsigned  max, input int unsigned  step);
		return '{ min: min, max: max, step: step, geo: 1'b1, num: range_num(1'b1, min, max, step) };
	endfunction : make_geo_range

	// Advance one position along the sweep (arithmetic or geometric). Single source of truth
	// for the stride; range_value walks this from r.min to reach any position.
	function automatic int unsigned range_next(input range_t  r, input int unsigned  v);  return  r.geo? v * r.step : v + r.step;  endfunction : range_next

	// Value at sweep position `idx` (0 .. r.num-1). Lets the generate loops iterate over a
	// constant index range -- the only form of genvar loop that is portable across tools --
	// while still deriving the actual N/SIMD value from the range declaration.
	function automatic int unsigned range_value(input range_t  r, input int unsigned  idx);
		automatic int unsigned  v = r.min;
		for(int unsigned  k = 0; k < idx; k++)  v = range_next(r, v);
		return  v;
	endfunction : range_value

	localparam range_t N    = make_geo_range(.min(64), .max(64), .step(2));	// fixed at 64 (single-value sweep)
	localparam range_t SIMD = make_geo_range(.min(2),  .max(2),  .step(2));	// fixed at 2 (single-value sweep)

	//===========================================================================
	// Swept rsqrt-method configurations.
	//
	// The three interchangeable rsqrt cores selected by the DUT's RSQRT_METHOD
	// have disjoint tuning knobs. To sweep them uniformly, each configuration is
	// described by a single numeric descriptor: a small method id plus every knob
	// any core might read. Fields not used by a given method are simply ignored by
	// the DUT (which forwards only the parameters its selected core consumes), so
	// one flat struct covers all three without per-method branching in the array.
	//
	// To add/adjust a sweep point, edit only the METHODS array below -- the
	// generate loop, the result tables and the report all derive from it.
	typedef enum int unsigned {
		M_BIPARTITE = 0,
		M_LOOKUP    = 1,
		M_BITHACK   = 2
	} method_id_t;

	typedef struct packed {
		method_id_t   id;			// selects the rsqrt core
		int unsigned  newton;		// RSQRT_NUM_NEWTON_STEPS (0, 1, 2)
		int unsigned  word_width;	// RSQRT_WORD_WIDTH   (BIPARTITE, LOOKUP)
		int unsigned  addr_width_0;	// RSQRT_ADDR_WIDTH_0 (BIPARTITE)
		int unsigned  addr_width_1;	// RSQRT_ADDR_WIDTH_1 (BIPARTITE)
		int unsigned  addr_width_2;	// RSQRT_ADDR_WIDTH_2 (BIPARTITE)
		int unsigned  addr_width;	// RSQRT_ADDR_WIDTH   (LOOKUP)
		bit           use_default_magic;	// RSQRT_USE_DEFAULT_MAGIC_CONSTANT (BITHACK)
		logic [31:0]  magic;		// RSQRT_MAGIC_CONSTANT (BITHACK)
	} method_t;

	// Constructors defaulting the irrelevant knobs, so each METHODS entry only
	// states the fields that matter for its core.
	function automatic method_t mk_bipartite(input int unsigned newton, input int unsigned word_width,
	                                         input int unsigned aw0, input int unsigned aw1, input int unsigned aw2);
		return '{ id: M_BIPARTITE, newton: newton, word_width: word_width,
		          addr_width_0: aw0, addr_width_1: aw1, addr_width_2: aw2,
		          addr_width: 10, use_default_magic: 1, magic: 32'h5F3759DF };
	endfunction : mk_bipartite

	function automatic method_t mk_lookup(input int unsigned newton, input int unsigned word_width, input int unsigned addr_width);
		return '{ id: M_LOOKUP, newton: newton, word_width: word_width,
		          addr_width_0: 2, addr_width_1: 4, addr_width_2: 4,
		          addr_width: addr_width, use_default_magic: 1, magic: 32'h5F3759DF };
	endfunction : mk_lookup

	// use_default_magic=1 lets the core pick a Newton-tuned constant; pass magic=0 then.
	function automatic method_t mk_bithack(input int unsigned newton, input bit use_default_magic, input logic [31:0] magic);
		return '{ id: M_BITHACK, newton: newton, word_width: 13,
		          addr_width_0: 2, addr_width_1: 4, addr_width_2: 4,
		          addr_width: 10, use_default_magic: use_default_magic, magic: magic };
	endfunction : mk_bithack

	// The method sweep. Order is preserved in the report. Extend freely.
	localparam int unsigned  NUM_METHODS = 3;
	localparam method_t  METHODS[NUM_METHODS] = '{
        mk_bithack(.newton(0), .use_default_magic(0), .magic(32'h5F34C8C3)),
        mk_bithack(.newton(1), .use_default_magic(0), .magic(32'h5F360742)),
        mk_bithack(.newton(2), .use_default_magic(0), .magic(32'h5F3759DF))
	};

	// Short human-readable tag for a method configuration, used in the report.
	function automatic string method_name(input method_id_t id);
		case(id)
		M_BIPARTITE: return "BIPARTITE";
		M_LOOKUP:    return "LOOKUP";
		M_BITHACK:   return "BITHACK";
		default:     return "?";
		endcase
	endfunction : method_name

	// Effective bit-hacking magic constant: with use_default_magic set, the core selects
	// a Newton-step-tuned constant (mirrors rsqrt_bit_hacking's MAGIC_ACTUAL); otherwise
	// the user-supplied constant is used. Reported so the output is self-describing.
	function automatic logic [31:0] bithack_magic(input method_t m);
		if(!m.use_default_magic)  return m.magic;
		case(m.newton)
		0:       return 32'h5F34C8C3;
		1:       return 32'h5F360742;
		default: return 32'h5F3759DF;	// 2 Newton steps (Quake constant)
		endcase
	endfunction : bithack_magic

	// Method-specific internal parameters, formatted for the report. Only the knobs the
	// selected core actually consumes are shown, so each line documents exactly the
	// configuration that produced its RMSRE.
	function automatic string method_params(input method_t m);
		case(m.id)
		M_BIPARTITE: return $sformatf("WORD_WIDTH = %0d, ADDR_WIDTH_0/1/2 = %0d/%0d/%0d",
		                              m.word_width, m.addr_width_0, m.addr_width_1, m.addr_width_2);
		M_LOOKUP:    return $sformatf("WORD_WIDTH = %0d, ADDR_WIDTH = %0d", m.word_width, m.addr_width);
		M_BITHACK:   return $sformatf("MAGIC = 0x%08H%s", bithack_magic(m), m.use_default_magic? " (default)" : "");
		default:     return "";
		endcase
	endfunction : method_params

	// Left-justify `s` into a field of `w` characters by appending spaces. Used to pad the
	// report's descriptor prefix to a common width so the numeric columns line up. Uses only
	// standard string operations (len/concatenation) rather than the non-portable "%*s"
	// dynamic field-width, which not all simulators accept.
	function automatic string ljust(input string s, input int unsigned w);
		ljust = s;
		while(ljust.len() < w)  ljust = {ljust, " "};
		return ljust;
	endfunction : ljust

	localparam shortreal     EPSILON     = 1.0e-5;

	// Hold the number of exercised output elements constant across configurations. Each
	// configuration processes TARGET_ELEMENTS outputs, split into TARGET_ELEMENTS/N vectors
	// of N elements each. TARGET_ELEMENTS must be divisible by every N in the sweep; as the
	// N values are powers of two up to 1024, it is chosen as the multiple of 1024 just below 10000.
	localparam int unsigned  TARGET_ELEMENTS = 32768;

	// Set to 1 to replace the DSPFP32 hard-macro instances by their behavioral fp32 models,
	// mirroring the option threaded through the DUT. Leave at 0 to match the bipartite
	// testbench, which simulates against the DSPFP32 primitive model.
	localparam bit  FORCE_BEHAVIORAL = 0;

	// Reference relative error is only defined where the exact output is not (near) zero.
	// LayerNorm outputs pass through zero whenever an input equals the mean; such elements
	// are excluded from the relative-error statistics to avoid a meaningless division.
	localparam shortreal     REL_ERR_FLOOR = 1.0e-3;

	// Reported RMSRE for a configuration in which no output element cleared REL_ERR_FLOOR,
	// i.e. the metric is undefined. A negative value distinguishes this from a perfect 0.0.
	localparam real          RMSRE_UNDEFINED = -1.0;

	// Global Control
	logic  clk = 0;
	always #5ns clk = !clk;
	logic  rst = 1;
	initial begin
		repeat(12) @(posedge clk);
		rst <= 0;
	end

	// Completion matrix, indexed [METHOD_IDX][N_IDX][SIMD_IDX]. `&done` fires $finish
	// only once every generated cell (run or skipped) has set its bit.
	bit [NUM_METHODS-1:0][N.num-1:0][SIMD.num-1:0]  done = '0;

	// Per-configuration results, indexed [METHOD_IDX][N_IDX][SIMD_IDX]. Configurations run
	// concurrently and finish out of order; each stores its result here and the report is
	// emitted in sweep order at the end (see the `final` block) so the output is deterministic.
	localparam int unsigned  NOT_RUN = '1;	// `count` sentinel for a skipped configuration
	real       res_rmsre  [NUM_METHODS][N.num][SIMD.num];
	real       res_maxrel [NUM_METHODS][N.num][SIMD.num];
	shortreal  res_worst  [NUM_METHODS][N.num][SIMD.num];
	int unsigned  res_count[NUM_METHODS][N.num][SIMD.num] = '{ default: NOT_RUN };
	always_comb begin
		if(&done)  $finish;
	end

	// Emit the collected results in sweep order (method, then ascending N, then SIMD).
	// Mirrors the index mapping of the generate loops so each stored entry is printed
	// against its own method/N/SIMD.
	final begin
		// Build the per-line descriptor prefix (everything left of "RMSRE") into a string, so
		// the numeric columns can be aligned. The descriptor width varies with the method and
		// its parameters, so a first pass measures the widest prefix among the run configs and
		// the second pass left-pads every prefix to that width -- placing the RMSRE value (and
		// hence every following column) at the same character position on every line.
		automatic int unsigned  desc_w = 0;
		for(int unsigned  mi = 0; mi < NUM_METHODS; mi++) begin
			for(int unsigned  ni = 0; ni < N.num; ni++) begin
				for(int unsigned  si = 0; si < SIMD.num; si++) begin
					automatic method_t      m    = METHODS[mi];	// copy element before field-selecting
					automatic int unsigned  n    = range_value(N,    ni);
					automatic int unsigned  simd = range_value(SIMD, si);
					if(res_count[mi][ni][si] != NOT_RUN) begin
						automatic string  desc = $sformatf("Test (METHOD = %-9s, NEWTON = %0d [%s], N = %0d, SIMD = %0d):",
							method_name(m.id), m.newton, method_params(m), n, simd);
						if(desc.len() > desc_w)  desc_w = desc.len();
					end
				end
			end
		end
		for(int unsigned  mi = 0; mi < NUM_METHODS; mi++) begin
			for(int unsigned  ni = 0; ni < N.num; ni++) begin
				for(int unsigned  si = 0; si < SIMD.num; si++) begin
					automatic method_t      m    = METHODS[mi];	// copy element before field-selecting
					automatic int unsigned  n    = range_value(N,    ni);
					automatic int unsigned  simd = range_value(SIMD, si);
					if(res_count[mi][ni][si] != NOT_RUN) begin
						automatic string  desc = $sformatf("Test (METHOD = %-9s, NEWTON = %0d [%s], N = %0d, SIMD = %0d):",
							method_name(m.id), m.newton, method_params(m), n, simd);
						// Left-justify desc into a desc_w-wide field, then print the aligned columns.
						$display("%s RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f (elements = %0d)",
							ljust(desc, desc_w), res_rmsre[mi][ni][si], res_maxrel[mi][ni][si], res_worst[mi][ni][si], res_count[mi][ni][si]);
					end
				end
			end
		end
	end

	// Generate random fp sample
	function shortreal rand_fp();
		int unsigned bits;
		bits = $urandom();
		// Keep inputs strictly normalized (exp >= 1). The upper bound is the only real
		// constraint: it bounds the squared values and the reduction sums well within the
		// normalized fp32 range. No matching lower bound is needed for the inverse square
		// root, since the EPSILON added to the variance floors its argument at EPSILON and
		// hence it never sees denormalized inputs however small the samples become.
		bits[30:23] = $urandom_range(87, 142);	// ~[2^-40, 2^15)
		bits[31]    = $urandom_range(0, 1);
		return $bitstoshortreal(bits);
	endfunction : rand_fp

	// Iterate over the constant index ranges [0, NUM_METHODS) x [0, N.num) x [0, SIMD.num) and
	// recover the swept method descriptor and N/SIMD values from their declarations. Because the
	// loop counts and the done-matrix dimensions are both NUM_METHODS x N.num x SIMD.num, every
	// generated cell writes exactly one done bit and no bit is left stuck -- so `&done` is reachable
	// regardless of arithmetic vs geometric sweep, and independently of which method is selected.
	for(genvar  METHOD_IDX = 0; METHOD_IDX < NUM_METHODS; METHOD_IDX++) begin : genMETHOD
	for(genvar  N_IDX = 0; N_IDX < N.num; N_IDX++) begin : genN
		for(genvar  SIMD_IDX = 0; SIMD_IDX < SIMD.num; SIMD_IDX++) begin : genSIMD
			localparam method_t      m    = METHODS[METHOD_IDX];
			localparam int unsigned  n    = range_value(N,    N_IDX);
			localparam int unsigned  simd = range_value(SIMD, SIMD_IDX);
			if(simd <= n && n % simd == 0) begin : blkCond
				localparam int unsigned  NN = n / simd;
				// The exact string the DUT validates against ("BIPARTITE"/"LOOKUP"/"BITHACK"),
				// hoisted to a constant so it is unambiguously usable as a parameter override.
				localparam string  RSQRT_METHOD_NAME = method_name(m.id);
				// Vectors fed so that exactly TARGET_ELEMENTS output elements are exercised.
				localparam int unsigned  NUM_SAMPLES = TARGET_ELEMENTS / n;
				initial begin
					assert(TARGET_ELEMENTS % n == 0) else begin
						$error("TARGET_ELEMENTS(%0d) must be divisible by N(%0d) for an equal element count.", TARGET_ELEMENTS, n);
						$finish;
					end
				end

				// DUT
				logic [simd-1:0][31:0]  xdat;
				logic  xvld;
				uwire  xrdy;
				uwire [simd-1:0][31:0]  ydat;
				uwire  yvld;
				logic  yrdy;
				// All knobs are forwarded from the swept descriptor; the DUT consults only
				// those its selected core needs.
				layernorm #(
					.N(n),
					.SIMD(simd),
					.EPSILON(EPSILON),
					.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL),
					.RSQRT_METHOD(RSQRT_METHOD_NAME),
					.RSQRT_NUM_NEWTON_STEPS(m.newton),
					.RSQRT_WORD_WIDTH(m.word_width),
					.RSQRT_ADDR_WIDTH_0(m.addr_width_0),
					.RSQRT_ADDR_WIDTH_1(m.addr_width_1),
					.RSQRT_ADDR_WIDTH_2(m.addr_width_2),
					.RSQRT_ADDR_WIDTH(m.addr_width),
					.RSQRT_USE_DEFAULT_MAGIC_CONSTANT(m.use_default_magic),
					.RSQRT_MAGIC_CONSTANT(m.magic)
				) dut (
					.clk, .rst,
					.xdat, .xvld, .xrdy,
					.ydat, .yvld, .yrdy
				);

				// Exact LayerNorm of the algorithm implemented by the DUT, evaluated in full
				// precision over one complete vector of `n` input elements. The DUT shifts by
				// the plain mean, forms the variance of the shifted values and stabilizes the
				// inverse square root by EPSILON; the reference mirrors this exactly so that the
				// measured error is the finite-precision/table-approximation error alone.
				function automatic void exact_layernorm(input shortreal  x[$], output shortreal  y[$]);
					automatic real  sum = 0.0;
					automatic real  mean;
					automatic real  var_sum = 0.0;
					automatic real  variance;
					automatic real  inv_std;
					y.delete();
					foreach(x[i])  sum += x[i];
					mean = sum / n;
					foreach(x[i])  var_sum += (x[i] - mean) ** 2;
					variance = var_sum / n;
					inv_std  = 1.0 / $sqrt(variance + EPSILON);
					foreach(x[i])  y.push_back(shortreal'((x[i] - mean) * inv_std));
				endfunction : exact_layernorm

				// Statistics
				int unsigned  err_count      = 0;	// number of output elements entering the RMSRE
				real          rel_err_squared = 0.0;
				real          rel_err_max     = 0.0;
				shortreal     worst_input     = 0.0;

				// Input vectors awaiting their corresponding output for comparison
				shortreal  Q[$][$];		// queue of length-`n` input vectors (FIFO)

				initial begin
					automatic shortreal  vec[$];		// input vector under construction
					automatic real       rmsre;
					// Seed this feeder's RNG from N alone so that every method and every SIMD
					// value at a given N replays the identical input stream. rand_fp() draws a
					// fixed number of $urandom calls per element in a fixed order, and each
					// configuration feeds exactly NUM_SAMPLES*N elements, so the k-th element is
					// identical across method and SIMD; only the packing of those elements into
					// beats (SIMD) and the rsqrt approximation (method) differ. This isolates the
					// method's and SIMD's effect on RMSRE from input-sample variance. Each
					// generated cell runs this in its own process, so the per-process RNG is
					// re-seeded independently and deterministically.
					process::self().srandom(n);
					xdat = 'x;
					xvld = 0;
					@(posedge clk iff !rst);

					xvld <= 1;
					vec.delete();
					repeat(NUM_SAMPLES * NN) begin : feedBeats
						automatic logic [simd-1:0][31:0]  beat;
						for(int unsigned  i = 0; i < simd; i++) begin
							automatic shortreal  v = rand_fp();
							beat[i] = $shortrealtobits(v);
							vec.push_back(v);
						end
						xdat <= beat;
						@(posedge clk iff xrdy);	// beat accepted on this edge
						if(vec.size() == n) begin
							Q.push_back(vec);
							vec.delete();
						end
					end : feedBeats
					xvld <= 0;
					xdat <= 'x;

					// Drain: allow all outstanding vectors to propagate out of the pipeline.
					repeat(64 + 32*NN) @(posedge clk);
					assert(Q.size() == 0) else begin
						$error("Test (METHOD = %s, N = %0d, SIMD = %0d): Missing %0d output vectors.", method_name(m.id), n, simd, Q.size());
						$stop;
					end

					rmsre = (err_count != 0) ? $sqrt(rel_err_squared / err_count) : RMSRE_UNDEFINED;
					res_rmsre [METHOD_IDX][N_IDX][SIMD_IDX] = rmsre;
					res_maxrel[METHOD_IDX][N_IDX][SIMD_IDX] = rel_err_max;
					res_worst [METHOD_IDX][N_IDX][SIMD_IDX] = worst_input;
					res_count [METHOD_IDX][N_IDX][SIMD_IDX] = err_count;	// also clears the NOT_RUN sentinel

					done[METHOD_IDX][N_IDX][SIMD_IDX] = 1;
				end

				// Output Collection: sink is always ready; gather `simd` lanes per accepted beat,
				// assemble `n`-element output vectors and compare against the exact reference.
				assign	yrdy = 1;
				shortreal  outv[$];		// output vector under construction
				initial  outv.delete();
				always_ff @(posedge clk iff (yvld && yrdy)) begin
					automatic shortreal  xin[$];
					automatic shortreal  yref[$];
					for(int unsigned  i = 0; i < simd; i++) begin
						outv.push_back($bitstoshortreal(ydat[i]));
					end
					if(outv.size() == n) begin
						assert(Q.size()) else begin
							$error("Test (METHOD = %s, N = %0d, SIMD = %0d): Spurious output vector.", method_name(m.id), n, simd);
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

			end : blkCond
			else begin
				initial begin
					done[METHOD_IDX][N_IDX][SIMD_IDX] = 1;
				end
			end
		end : genSIMD
	end : genN
	end : genMETHOD

endmodule : layernorm_accuracy_tb
