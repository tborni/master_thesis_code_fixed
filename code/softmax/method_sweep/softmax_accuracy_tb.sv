module softmax_accuracy_tb;
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
	// Swept exp/reciprocal-method configurations.
	//
	// SoftMax has TWO interchangeable approximation cores -- the exponential on
	// the main path and the reciprocal in the sum-diamond statistics branch --
	// each selectable by the DUT's EXP_METHOD / REC_METHOD with its own disjoint
	// tuning knobs. To sweep both uniformly, each configuration is described by a
	// single numeric descriptor holding an exp sub-descriptor and a rec
	// sub-descriptor, each carrying a small method id plus every knob any core
	// of that kind might read. Fields not used by a given method are simply
	// ignored by the DUT (which forwards only the parameters its selected cores
	// consume), so one flat struct covers all combinations without per-method
	// branching in the array.
	//
	// To add/adjust a sweep point, edit only the CONFIGS array below -- the
	// generate loop, the result tables and the report all derive from it.
	typedef enum int unsigned {
		EXP_M_LOOKUP      = 0,
		EXP_M_BIPARTITE   = 1,
		EXP_M_SPLITTING   = 2,
		EXP_M_BIT_HACKING = 3
	} exp_method_id_t;

	typedef enum int unsigned {
		REC_M_LOOKUP    = 0,
		REC_M_BIPARTITE = 1
	} rec_method_id_t;

	// Exponential sub-descriptor: a method id plus every knob any exp core reads.
	typedef struct packed {
		exp_method_id_t  id;			// selects the exp core
		int unsigned     word_width;	// EXP_WORD_WIDTH   (all three; SPLITTING needs < 23)
		int unsigned     addr_width_0;	// EXP_ADDR_WIDTH_0 (BIPARTITE, SPLITTING)
		int unsigned     addr_width_1;	// EXP_ADDR_WIDTH_1 (BIPARTITE, SPLITTING)
		int unsigned     addr_width_2;	// EXP_ADDR_WIDTH_2 (BIPARTITE, SPLITTING)
		int unsigned     addr_width;	// EXP_ADDR_WIDTH   (LOOKUP)
	} exp_cfg_t;

	// Reciprocal sub-descriptor: a method id plus every knob any rec core reads.
	typedef struct packed {
		rec_method_id_t  id;			// selects the reciprocal core
		int unsigned     newton;		// REC_NUM_NEWTON_STEPS (0, 1)
		int unsigned     word_width;	// REC_WORD_WIDTH   (both)
		int unsigned     addr_width_0;	// REC_ADDR_WIDTH_0 (BIPARTITE)
		int unsigned     addr_width_1;	// REC_ADDR_WIDTH_1 (BIPARTITE)
		int unsigned     addr_width_2;	// REC_ADDR_WIDTH_2 (BIPARTITE)
		int unsigned     addr_width;	// REC_ADDR_WIDTH   (LOOKUP)
	} rec_cfg_t;

	// A full configuration: one exp descriptor + one rec descriptor.
	typedef struct packed {
		exp_cfg_t  exp;
		rec_cfg_t  rec;
	} config_t;

	// Constructors defaulting the irrelevant knobs, so each CONFIGS entry only
	// states the fields that matter for the cores it selects.
	function automatic exp_cfg_t exp_lookup_cfg(input int unsigned word_width, input int unsigned addr_width);
		return '{ id: EXP_M_LOOKUP, word_width: word_width,
		          addr_width_0: 6, addr_width_1: 6, addr_width_2: 6, addr_width: addr_width };
	endfunction : exp_lookup_cfg

	function automatic exp_cfg_t exp_bipartite_cfg(input int unsigned word_width,
	                                              input int unsigned aw0, input int unsigned aw1, input int unsigned aw2);
		return '{ id: EXP_M_BIPARTITE, word_width: word_width,
		          addr_width_0: aw0, addr_width_1: aw1, addr_width_2: aw2, addr_width: 10 };
	endfunction : exp_bipartite_cfg

	function automatic exp_cfg_t exp_splitting_cfg(input int unsigned word_width,
	                                              input int unsigned aw0, input int unsigned aw1, input int unsigned aw2);
		return '{ id: EXP_M_SPLITTING, word_width: word_width,
		          addr_width_0: aw0, addr_width_1: aw1, addr_width_2: aw2, addr_width: 10 };
	endfunction : exp_splitting_cfg

	// BIT_HACKING (Schraudolph) reads none of the table knobs -- it is a single
	// fp32 multiply + int cast + int add -- so every width field is a harmless
	// placeholder that the DUT ignores for this method.
	function automatic exp_cfg_t exp_bit_hacking_cfg();
		return '{ id: EXP_M_BIT_HACKING, word_width: 0,
		          addr_width_0: 0, addr_width_1: 0, addr_width_2: 0, addr_width: 0 };
	endfunction : exp_bit_hacking_cfg

	function automatic rec_cfg_t rec_lookup_cfg(input int unsigned newton, input int unsigned word_width, input int unsigned addr_width);
		return '{ id: REC_M_LOOKUP, newton: newton, word_width: word_width,
		          addr_width_0: 3, addr_width_1: 4, addr_width_2: 4, addr_width: addr_width };
	endfunction : rec_lookup_cfg

	function automatic rec_cfg_t rec_bipartite_cfg(input int unsigned newton, input int unsigned word_width,
	                                              input int unsigned aw0, input int unsigned aw1, input int unsigned aw2);
		return '{ id: REC_M_BIPARTITE, newton: newton, word_width: word_width,
		          addr_width_0: aw0, addr_width_1: aw1, addr_width_2: aw2, addr_width: 10 };
	endfunction : rec_bipartite_cfg

	function automatic config_t mk_config(input exp_cfg_t exp, input rec_cfg_t rec);
		return '{ exp: exp, rec: rec };
	endfunction : mk_config

	// The configuration sweep is the full Cartesian product of the four exp options and the
	// four reciprocal options -- every exp paired with every reciprocal (4*4 = 16 entries),
	// laid out exp-major (all four reciprocal options for exp #0, then exp #1, #2, #3) so the
	// report groups by exp method. Written as an explicit unpacked literal of direct
	// constructor calls (mirrors the layernorm testbench's METHODS[]); the trailing comment on
	// each row names the (exp x rec) pair. To change the sweep, edit the entries below.
	//
	//   exp[0] = BIT_HACKING (Schraudolph; no table knobs)
	//   exp[1] = LOOKUP      AW=WW=8
	//   exp[2] = BIPARTITE   AW0=2, AW1=AW2=5, WW=15
	//   exp[3] = SPLITTING   AW0=7, AW1=AW2=6, WW=22
	//   rec[0] = BIPARTITE   AW0=2, AW1=AW2=3, WW=11, NEWTON=0
	//   rec[1] = LOOKUP      AW=11, WW=16, NEWTON=0
	//   rec[2] = LOOKUP      AW=9,  WW=8,  NEWTON=1
	//   rec[3] = BIPARTITE   AW0=5, AW1=AW2=6, WW=20, NEWTON=1
	localparam int unsigned  NUM_CONFIGS = 16;	// 4 exp options x 4 reciprocal options
	localparam config_t  CONFIGS[NUM_CONFIGS] = '{
		mk_config(exp_bit_hacking_cfg(), rec_bipartite_cfg(.newton(0), .word_width(11), .aw0(2), .aw1(3), .aw2(3))),	// exp[0] x rec[0]
		mk_config(exp_bit_hacking_cfg(), rec_lookup_cfg   (.newton(0), .word_width(16), .addr_width(11))),	// exp[0] x rec[1]
		mk_config(exp_bit_hacking_cfg(), rec_lookup_cfg   (.newton(1), .word_width(8),  .addr_width(9))),	// exp[0] x rec[2]
		mk_config(exp_bit_hacking_cfg(), rec_bipartite_cfg(.newton(1), .word_width(20), .aw0(5), .aw1(6), .aw2(6))),	// exp[0] x rec[3]
		mk_config(exp_lookup_cfg   (.word_width(8),  .addr_width(8)), rec_bipartite_cfg(.newton(0), .word_width(11), .aw0(2), .aw1(3), .aw2(3))),	// exp[1] x rec[0]
		mk_config(exp_lookup_cfg   (.word_width(8),  .addr_width(8)), rec_lookup_cfg   (.newton(0), .word_width(16), .addr_width(11))),	// exp[1] x rec[1]
		mk_config(exp_lookup_cfg   (.word_width(8),  .addr_width(8)), rec_lookup_cfg   (.newton(1), .word_width(8),  .addr_width(9))),	// exp[1] x rec[2]
		mk_config(exp_lookup_cfg   (.word_width(8),  .addr_width(8)), rec_bipartite_cfg(.newton(1), .word_width(20), .aw0(5), .aw1(6), .aw2(6))),	// exp[1] x rec[3]
		mk_config(exp_bipartite_cfg(.word_width(15), .aw0(2), .aw1(5), .aw2(5)), rec_bipartite_cfg(.newton(0), .word_width(11), .aw0(2), .aw1(3), .aw2(3))),	// exp[2] x rec[0]
		mk_config(exp_bipartite_cfg(.word_width(15), .aw0(2), .aw1(5), .aw2(5)), rec_lookup_cfg   (.newton(0), .word_width(16), .addr_width(11))),	// exp[2] x rec[1]
		mk_config(exp_bipartite_cfg(.word_width(15), .aw0(2), .aw1(5), .aw2(5)), rec_lookup_cfg   (.newton(1), .word_width(8),  .addr_width(9))),	// exp[2] x rec[2]
		mk_config(exp_bipartite_cfg(.word_width(15), .aw0(2), .aw1(5), .aw2(5)), rec_bipartite_cfg(.newton(1), .word_width(20), .aw0(5), .aw1(6), .aw2(6))),	// exp[2] x rec[3]
		mk_config(exp_splitting_cfg(.word_width(22), .aw0(7), .aw1(6), .aw2(6)), rec_bipartite_cfg(.newton(0), .word_width(11), .aw0(2), .aw1(3), .aw2(3))),	// exp[3] x rec[0]
		mk_config(exp_splitting_cfg(.word_width(22), .aw0(7), .aw1(6), .aw2(6)), rec_lookup_cfg   (.newton(0), .word_width(16), .addr_width(11))),	// exp[3] x rec[1]
		mk_config(exp_splitting_cfg(.word_width(22), .aw0(7), .aw1(6), .aw2(6)), rec_lookup_cfg   (.newton(1), .word_width(8),  .addr_width(9))),	// exp[3] x rec[2]
		mk_config(exp_splitting_cfg(.word_width(22), .aw0(7), .aw1(6), .aw2(6)), rec_bipartite_cfg(.newton(1), .word_width(20), .aw0(5), .aw1(6), .aw2(6)))	// exp[3] x rec[3]
	};

	// Short human-readable tags for the two method families, used in the report.
	function automatic string exp_method_name(input exp_method_id_t id);
		case(id)
		EXP_M_LOOKUP:      return "LOOKUP";
		EXP_M_BIPARTITE:   return "BIPARTITE";
		EXP_M_SPLITTING:   return "SPLITTING";
		EXP_M_BIT_HACKING: return "BIT_HACKING";
		default:           return "?";
		endcase
	endfunction : exp_method_name

	function automatic string rec_method_name(input rec_method_id_t id);
		case(id)
		REC_M_LOOKUP:    return "LOOKUP";
		REC_M_BIPARTITE: return "BIPARTITE";
		default:         return "?";
		endcase
	endfunction : rec_method_name

	// Method-specific internal parameters, formatted for the report. Only the knobs the
	// selected cores actually consume are shown, so each line documents exactly the
	// configuration that produced its RMSRE.
	function automatic string exp_params(input exp_cfg_t e);
		case(e.id)
		EXP_M_LOOKUP:      return $sformatf("WW=%0d, AW=%0d", e.word_width, e.addr_width);
		EXP_M_BIPARTITE:   return $sformatf("WW=%0d, AW0/1/2=%0d/%0d/%0d", e.word_width, e.addr_width_0, e.addr_width_1, e.addr_width_2);
		EXP_M_SPLITTING:   return $sformatf("WW=%0d, AW0/1/2=%0d/%0d/%0d", e.word_width, e.addr_width_0, e.addr_width_1, e.addr_width_2);
		EXP_M_BIT_HACKING: return "A=12102203, D=1065277304";
		default:           return "";
		endcase
	endfunction : exp_params

	function automatic string rec_params(input rec_cfg_t r);
		case(r.id)
		REC_M_LOOKUP:    return $sformatf("NEWTON=%0d, WW=%0d, AW=%0d", r.newton, r.word_width, r.addr_width);
		REC_M_BIPARTITE: return $sformatf("NEWTON=%0d, WW=%0d, AW0/1/2=%0d/%0d/%0d", r.newton, r.word_width, r.addr_width_0, r.addr_width_1, r.addr_width_2);
		default:         return "";
		endcase
	endfunction : rec_params

	// Full per-configuration descriptor prefix (everything left of "RMSRE").
	function automatic string config_desc(input config_t c, input int unsigned n, input int unsigned simd);
		return $sformatf("Test (EXP = %-9s [%s], REC = %-9s [%s], N = %0d, SIMD = %0d):",
			exp_method_name(c.exp.id), exp_params(c.exp),
			rec_method_name(c.rec.id), rec_params(c.rec), n, simd);
	endfunction : config_desc

	// Left-justify `s` into a field of `w` characters by appending spaces. Used to pad the
	// report's descriptor prefix to a common width so the numeric columns line up. Uses only
	// standard string operations (len/concatenation) rather than the non-portable "%*s"
	// dynamic field-width, which not all simulators accept.
	function automatic string ljust(input string s, input int unsigned w);
		ljust = s;
		while(ljust.len() < w)  ljust = {ljust, " "};
		return ljust;
	endfunction : ljust

	// Set to 1 to replace the DSPFP32 hard-macro instances by their behavioral fp32 models,
	// mirroring the option threaded through the DUT. Leave at 0 to match the bipartite
	// testbench, which simulates against the DSPFP32 primitive model.
	localparam bit  FORCE_BEHAVIORAL = 0;

	// Hold the number of exercised output elements constant across configurations. Each
	// configuration processes TARGET_ELEMENTS outputs, split into TARGET_ELEMENTS/N vectors
	// of N elements each. TARGET_ELEMENTS must be divisible by every N in the sweep; as the
	// N values are powers of two up to 16384, a multiple of 16384 is chosen.
	localparam int unsigned  TARGET_ELEMENTS = 32768;

	// Reference relative error is only defined where the exact output is not (near) zero.
	// A SoftMax output is exp(x-max)/sum, strictly in (0, 1]. Elements far below the group
	// maximum drive exp(x-max) into the denormal/underflow regime where both the DUT and the
	// reference collapse to ~0; a relative error against a ~0 truth is meaningless (and, for
	// the fixed EXP unit, dominated by its absolute error near zero rather than any N/SIMD
	// reassociation). Such elements are excluded from the relative-error statistics.
	//
	// The floor is a FIXED absolute output magnitude, deliberately NOT scaled by N. What makes
	// two per-N RMSRE values comparable is that they score the SAME domain of true-output
	// magnitudes (and hence the same DUT error regime), not that they average the same NUMBER of
	// elements. An N-scaled floor (base/N, base/sqrt(N)) holds the population count roughly
	// constant but only by dredging progressively deeper into the tail as N grows -- at large N
	// it would admit elements whose output is small enough that the EXP unit's absolute noise,
	// not the reassociation under test, dominates the ratio, so the large-N RMSRE would measure
	// something different from the small-N one. A fixed floor keeps the measured window identical.
	//
	// 1e-5 is chosen so that even the largest sweep (N=16384, where sum ~ 1e3 and the top element
	// outputs ~1e-3) still has a substantial floor-clearing population, while every included
	// element stays a normal fp32: the smallest admitted output ~1e-5 corresponds to an exp
	// argument ~-11, and exp(-11) ~ 1.7e-5 >> the ~1.2e-38 denormal threshold, so the DUT error
	// remains ulp-bounded (relative), never absolute-noise-dominated. (Note the sum GROWS toward
	// its maximum N as the logit spread NARROWS, so shrinking LOGIT_ABS would lower 1/sum and make
	// large-N coverage worse, not better -- the floor, not the sampler range, is the right knob.)
	localparam shortreal     REL_ERR_FLOOR = 1.0e-5;

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

	// Completion matrix, indexed [CONFIG_IDX][N_IDX][SIMD_IDX]. `&done` fires $finish
	// only once every generated cell (run or skipped) has set its bit.
	bit [NUM_CONFIGS-1:0][N.num-1:0][SIMD.num-1:0]  done = '0;

	// Per-configuration results, indexed [CONFIG_IDX][N_IDX][SIMD_IDX]. Configurations run
	// concurrently and finish out of order; each stores its result here and the report is
	// emitted in sweep order at the end (see the `final` block) so the output is deterministic.
	localparam int unsigned  NOT_RUN = '1;	// `count` sentinel for a skipped configuration
	real       res_rmsre  [NUM_CONFIGS][N.num][SIMD.num];
	real       res_maxrel [NUM_CONFIGS][N.num][SIMD.num];
	shortreal  res_worst  [NUM_CONFIGS][N.num][SIMD.num];
	int unsigned  res_count[NUM_CONFIGS][N.num][SIMD.num] = '{ default: NOT_RUN };
	always_comb begin
		if(&done)  $finish;
	end

	// Emit the collected results in sweep order (config, then ascending N, then SIMD).
	// Mirrors the index mapping of the generate loops so each stored entry is printed
	// against its own config/N/SIMD. A first pass measures the widest descriptor prefix
	// among the run configs; the second pass left-pads every prefix to that width so the
	// RMSRE value (and every following column) lands at the same character position.
	final begin
		automatic int unsigned  desc_w = 0;
		for(int unsigned  ci = 0; ci < NUM_CONFIGS; ci++) begin
			for(int unsigned  ni = 0; ni < N.num; ni++) begin
				for(int unsigned  si = 0; si < SIMD.num; si++) begin
					automatic config_t      c    = CONFIGS[ci];	// copy element before field-selecting
					automatic int unsigned  n    = range_value(N,    ni);
					automatic int unsigned  simd = range_value(SIMD, si);
					if(res_count[ci][ni][si] != NOT_RUN) begin
						automatic string  desc = config_desc(c, n, simd);
						if(desc.len() > desc_w)  desc_w = desc.len();
					end
				end
			end
		end
		for(int unsigned  ci = 0; ci < NUM_CONFIGS; ci++) begin
			for(int unsigned  ni = 0; ni < N.num; ni++) begin
				for(int unsigned  si = 0; si < SIMD.num; si++) begin
					automatic config_t      c    = CONFIGS[ci];	// copy element before field-selecting
					automatic int unsigned  n    = range_value(N,    ni);
					automatic int unsigned  simd = range_value(SIMD, si);
					if(res_count[ci][ni][si] != NOT_RUN) begin
						automatic string  desc = config_desc(c, n, simd);
						$display("%s RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f (elements = %0d)",
							ljust(desc, desc_w), res_rmsre[ci][ni][si], res_maxrel[ci][ni][si], res_worst[ci][ni][si], res_count[ci][ni][si]);
					end
				end
			end
		end
	end

	// Generate a random fp32 logit, uniform over the reals in [-LOGIT_ABS, +LOGIT_ABS] (so each
	// representable value is NOT equally likely) with denormalized results excluded. This mirrors
	// the sampling idiom of exp_bipartite_accuracy_tb: draw a uniform real, then reject-and-redraw
	// any denormal (an exponent field of 0 with a non-zero mantissa); exact +-0 is kept. The
	// $shortrealtobits/$bitstoshortreal round-trip on the drawn value avoids a Vivado shortreal
	// simulation error, as in the exp testbench.
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

	// Iterate over the constant index ranges [0, NUM_CONFIGS) x [0, N.num) x [0, SIMD.num) and
	// recover the swept config descriptor and N/SIMD values from their declarations. Because the
	// loop counts and the done-matrix dimensions are both NUM_CONFIGS x N.num x SIMD.num, every
	// generated cell writes exactly one done bit and no bit is left stuck -- so `&done` is
	// reachable regardless of arithmetic vs geometric sweep, and independently of the config.
	for(genvar  CONFIG_IDX = 0; CONFIG_IDX < NUM_CONFIGS; CONFIG_IDX++) begin : genCONFIG
	for(genvar  N_IDX = 0; N_IDX < N.num; N_IDX++) begin : genN
		for(genvar  SIMD_IDX = 0; SIMD_IDX < SIMD.num; SIMD_IDX++) begin : genSIMD
			localparam config_t      c    = CONFIGS[CONFIG_IDX];
			localparam int unsigned  n    = range_value(N,    N_IDX);
			localparam int unsigned  simd = range_value(SIMD, SIMD_IDX);
			if(simd <= n && n % simd == 0) begin : blkCond
				localparam int unsigned  NN = n / simd;
				// The exact method strings the DUT validates against, hoisted to constants so
				// they are unambiguously usable as parameter overrides.
				localparam string  EXP_METHOD_NAME = exp_method_name(c.exp.id);
				localparam string  REC_METHOD_NAME = rec_method_name(c.rec.id);
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
				// those its two selected cores need.
				softmax #(
					.N(n),
					.SIMD(simd),
					.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL),
					.EXP_METHOD(EXP_METHOD_NAME),
					.EXP_WORD_WIDTH(c.exp.word_width),
					.EXP_ADDR_WIDTH_0(c.exp.addr_width_0),
					.EXP_ADDR_WIDTH_1(c.exp.addr_width_1),
					.EXP_ADDR_WIDTH_2(c.exp.addr_width_2),
					.EXP_ADDR_WIDTH(c.exp.addr_width),
					.REC_METHOD(REC_METHOD_NAME),
					.REC_NUM_NEWTON_STEPS(c.rec.newton),
					.REC_WORD_WIDTH(c.rec.word_width),
					.REC_ADDR_WIDTH_0(c.rec.addr_width_0),
					.REC_ADDR_WIDTH_1(c.rec.addr_width_1),
					.REC_ADDR_WIDTH_2(c.rec.addr_width_2),
					.REC_ADDR_WIDTH(c.rec.addr_width)
				) dut (
					.clk, .rst,
					.xdat, .xvld, .xrdy,
					.ydat, .yvld, .yrdy
				);

				// Exact SoftMax of the algorithm implemented by the DUT, evaluated in full
				// precision over one complete vector of `n` input elements. The DUT subtracts
				// the group maximum from every element, exponentiates the residuals and divides
				// by their sum; the reference mirrors this exactly (max-shift, exp, normalize) so
				// that the measured error is the finite-precision/table-approximation error of
				// the EXP and REC units together with the fp32 summation reassociation alone.
				// The max shift is a mathematical identity for the exact result but is retained
				// to match the DUT's numerics and to keep every exp() argument <= 0.
				function automatic void exact_softmax(input shortreal  x[$], output shortreal  y[$]);
					automatic real  mx = x[0];
					automatic real  sum = 0.0;
					y.delete();
					foreach(x[i])  if(x[i] > mx)  mx = x[i];
					foreach(x[i])  sum += $exp(x[i] - mx);
					foreach(x[i])  y.push_back(shortreal'($exp(x[i] - mx) / sum));
				endfunction : exact_softmax

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
					// Seed this feeder's RNG from N alone so that every config and every SIMD
					// value at a given N replays the identical input stream. For a fixed seed the
					// $urandom sequence is fixed, hence rand_fp()'s reject-loop decisions and its
					// sequence of RETURNED samples are fixed too (the per-element $urandom count
					// may vary with rejections, but that does not affect the returned values).
					// Each configuration draws exactly NUM_SAMPLES*N samples in order, so the k-th
					// element is identical across config and SIMD; only the packing of those
					// elements into beats (SIMD) and the exp/reciprocal approximations (config)
					// differ. This isolates the config's effect on RMSRE from input-sample
					// variance. Each generated cell runs this in its own process, so the
					// per-process RNG is re-seeded independently and deterministically.
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

					// Drain: allow all outstanding groups to propagate out of the pipeline. The
					// pipeline drains at ~one beat/cycle, so the post-input tail is O(NN): the
					// bypass-queue occupancy (~NN) plus the fixed exp / adder-tree / accumulator
					// / reciprocal depths (a couple hundred cycles total). 2*NN keeps a 2x margin
					// on the streaming part and 512 covers the fixed depths generously. (The old
					// 128 + 64*NN over-bounded this by ~64x -- for NN=8192 that was 524k cycles,
					// ~5.24 ms, which dominated the sweep and made the run look hung.)
					repeat(2*NN + 512) @(posedge clk);
					assert(Q.size() == 0) else begin
						$error("Test (EXP = %s, REC = %s, N = %0d, SIMD = %0d): Missing %0d output vectors.",
							exp_method_name(c.exp.id), rec_method_name(c.rec.id), n, simd, Q.size());
						$stop;
					end

					rmsre = (err_count != 0) ? $sqrt(rel_err_squared / err_count) : RMSRE_UNDEFINED;
					res_rmsre [CONFIG_IDX][N_IDX][SIMD_IDX] = rmsre;
					res_maxrel[CONFIG_IDX][N_IDX][SIMD_IDX] = rel_err_max;
					res_worst [CONFIG_IDX][N_IDX][SIMD_IDX] = worst_input;
					res_count [CONFIG_IDX][N_IDX][SIMD_IDX] = err_count;	// also clears the NOT_RUN sentinel

					done[CONFIG_IDX][N_IDX][SIMD_IDX] = 1;
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
							$error("Test (EXP = %s, REC = %s, N = %0d, SIMD = %0d): Spurious output vector.",
								exp_method_name(c.exp.id), rec_method_name(c.rec.id), n, simd);
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

			end : blkCond
			else begin
				initial begin
					done[CONFIG_IDX][N_IDX][SIMD_IDX] = 1;
				end
			end
		end : genSIMD
	end : genN
	end : genCONFIG

endmodule : softmax_accuracy_tb
