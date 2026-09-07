# titus_portable_bert_l1

Self-contained, machine-portable copy of the BERT-L1 FINN stitched design,
built for out-of-context synthesis + place & route on any machine with
Vivado 2025.2 (no FINN install, no Vitis HLS required).

The source project (`output_bert_l6_v80`, mislabeled — it is a **1-layer**
BERT) relied on absolute `/scratch/...` paths for RTL, weight `.dat` files, and
threshold `.dat` files. Everything is vendored here and all paths are relative.

## Target

| | |
|---|---|
| Part | `xcvc1902-vsva2197-2MP-e-S` (VCK190 / Versal) |
| Vivado | 2025.2 |
| Top module | `finn_design_wrapper` |
| Clock | `ap_clk` @ 200 MHz (5 ns, from `constraints/finn_design_ooc.xdc`) |

## Layout

```
rtl/                .v/.sv sources (flat, single namespace)
ip/                 *_ip.tcl scripts that create the Xilinx floating_point
                    IP cores instantiated by the HLS LayerNorm/Softmax cores
data/<instance>/    vendored weight + threshold .dat files
constraints/        finn_design_ooc.xdc  (ap_clk timing)
rtl_sources.f       ordered relative read list consumed by the TCL
build_synth.tcl     (create IP) -> synth -> place -> route driver
```

## LayerNorm / Softmax = Vitis-HLS cores

The three normalization operators are Vitis-HLS implementations rather than the
original behavioral RTL:

| FINN op | wrapper (`rtl/`) | HLS core | params |
|---|---|---|---|
| `LayerNorm_rtl_0` | `LayerNorm_rtl_0.v` | `layernorm_top` | N=384, SIMD=4, FP32 |
| `LayerNorm_rtl_1` | `LayerNorm_rtl_1.v` | `layernorm_top` | N=384, SIMD=4, FP32 |
| `HWSoftmax_rtl_0` | `HWSoftmax_rtl_0.v` | `softmax_top`   | N=128, SIMD=4, FP32 |

The op wrappers keep their FINN module name, port list and `X_INTERFACE_*`
attributes (so the parent `finn_design_*_0` block wrappers bind unchanged) and
simply instantiate the HLS `_top`. The 128-bit AXI-Stream payload maps directly
(FINN packs SIMD lanes little-endian, lane 0 in bits `[31:0]`, matching
`hls::vector<float,4>`); `ap_rst_n` is passed through active-low (the HLS core
does its own reset synchronization/inversion internally).

Each HLS core instantiates Xilinx `floating_point` IP (LayerNorm: fadd, fadd_x,
fdiv, fmadd, fmul, fsqrt, fsub; Softmax: fcmp, fdiv, fexp, fpext, fsub). Those
cores are created from `ip/*_ip.tcl` at the start of `build_synth.tcl`; each
sets `GENERATE_SYNTH_CHECKPOINT=false`, so the IP is synthesized inline (global
synthesis) with `finn_design_wrapper` — no per-IP out-of-context checkpoint.

## Build

Weight files are loaded at elaboration via relative `$readmemh` paths that
resolve against the working directory, so you **must** run from this directory:

```bash
cd titus_portable_bert_l1
vivado -mode batch -source build_synth.tcl
```

## Outputs (`results/`)

| file | stage |
|---|---|
| `post_synth.dcp` | synthesized checkpoint |
| `finn_design_wrapper_routed.dcp` | placed + routed checkpoint |
| `post_synth_util.rpt`, `post_synth_timing.rpt` | synthesis reports |
| `post_route_util.rpt`, `post_route_timing.rpt` | implementation reports |

## Scope

This reproduces the accelerator kernel (the stitched `finn_design`) only. It
does **not** include the Versal golden shell (CIPS, NoC, `pr_verify`) that the
original flow used to emit a boot `.pdi`. It stops at a routed checkpoint for
the kernel in isolation.

## Notes on how portability was achieved

- **RTL dedup:** the block-design flow synthesized each op out-of-context, so it
  tolerated many byte-identical copies of shared leaf modules (`fifo`,
  `axilite`, `memstream`, `dwc`, ...) all declaring the same module name. Flat
  synthesis reads everything into one namespace, so each shared module is kept
  exactly once (verified: every module name is defined by exactly one file).
- **Weights (`memblock.dat`, 29):** absolute `INIT_FILE=` params in the
  memstream wrappers rewritten to `./data/<instance>/memblock.dat`.
- **OuterShuffle (`input_gen*.dat`, 4):** absolute `$readmemh(...)` in the
  HLS-generated Verilog rewritten to `./data/<instance>/...`.
- **Thresholds (`threshs_*.dat`, 480):** `THRESHOLDS_PATH` prefix (completed at
  runtime as `<prefix>threshs_<pe>_<stage>.dat`) rewritten to
  `./data/<instance>/<prefix>`.
