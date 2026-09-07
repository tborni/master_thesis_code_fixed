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
rtl/                477 deduplicated .v/.sv sources (flat, single namespace)
data/<instance>/    vendored weight + threshold .dat files
constraints/        finn_design_ooc.xdc  (ap_clk timing)
rtl_sources.f       ordered relative read list consumed by the TCL
build_synth.tcl     synth -> place -> route driver
```

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
