"""Step 2 - combine Exp x Rec into softmax implementations.

LUT/DSP live in the combined method files (not in separate resource files), so
the resource *sources* are:

  * the base-case LUT/DSP are read from the combined files
    ``data/{exp,rec}/<Label>_combined.csv`` (same files step 1 consumes)
  * the total-softmax LUT/DSP per SIMD are read from ``data/resources_SIMD.csv``

For every (exp, rec) pair from the step-1 Pareto fronts:

  RMSRE(softmax)^2 = B_EXP*RMSRE(exp)^2 + RMSRE(rec)^2 + RMSRE(other)^2
      with B_EXP = 1.0456234249238079 and RMSRE(other) = 1.918e-7

  Resources(softmax) = 1*Resources(rec)
                     + SIMD*Resources(exp)
                     + 1*Resources(base)

  Resources(base) = resources_SIMD(SIMD) - 1*Resources(rec_base) - SIMD*Resources(exp_base)

The base blocks are looked up in the combined method files; if either base case
is missing we abort immediately (per the description).

Finally we keep only the Pareto front over (RMSRE, LUT, DSP).

Runs once per SIMD value.  Usage:
  step2_softmax.py            -> sweep every value in helper_config.SIMD_SWEEP
  step2_softmax.py <simd>     -> just that value

Output: data/generated/softmax_SIMD_<v>.csv
"""

from __future__ import annotations

import math
import os
import sys
from typing import Tuple

import helper_config as C


# --------------------------------------------------------------------------- #
# Base-resource resolution
# --------------------------------------------------------------------------- #
def _lookup_resource(base_spec: dict) -> Tuple[int, int]:
    """Return (LUT, DSP) for a base case from its combined method file, or abort
    if the configuration does not exist.

    The base cases are parametric, so ``match`` values are integers and the row
    is found by an exact integer comparison on every key column.
    """
    method = base_spec["method"]
    match = base_spec["match"]
    path = C.method_file(method)
    rows = C.read_csv_dicts(path, required=(*match.keys(), "LUT", "DSP"))
    for r in rows:
        if all(int(r[k]) == v for k, v in match.items()):
            return int(r["LUT"]), int(r["DSP"])
    raise SystemExit(
        f"ERROR: required base case not found in {C.METHODS[method]['file']}: "
        f"{match}. Cannot compute base resources - aborting."
    )


def _simd_sweep_total(simd: int) -> Tuple[int, int]:
    """Total softmax (LUT, DSP) at the given SIMD from resources_SIMD.csv."""
    rows = C.read_csv_dicts(C.SIMD_SWEEP_CSV, required=("SIMD", "LUT", "DSP"))
    for r in rows:
        if int(r["SIMD"]) == simd:
            return int(r["LUT"]), int(r["DSP"])
    have = sorted(int(r["SIMD"]) for r in rows)
    raise SystemExit(
        f"ERROR: SIMD={simd} not present in resources_SIMD.csv (have {have}) - "
        "aborting."
    )


def compute_base_resources(simd: int) -> Tuple[int, int]:
    """Base(softmax) = resources_SIMD(SIMD) - rec_base - SIMD*exp_base."""
    rec_lut, rec_dsp = _lookup_resource(C.REC_BASE)
    exp_lut, exp_dsp = _lookup_resource(C.EXP_BASE)
    tot_lut, tot_dsp = _simd_sweep_total(simd)

    base_lut = tot_lut - rec_lut - simd * exp_lut
    base_dsp = tot_dsp - rec_dsp - simd * exp_dsp

    print(f"[BASE] SIMD={simd}")
    print(f"  resources_SIMD tot: LUT={tot_lut:>6}  DSP={tot_dsp:>4}")
    print(f"  rec_base          : LUT={rec_lut:>6}  DSP={rec_dsp:>4}  "
          f"({C.REC_BASE['method']} {C.REC_BASE['match']})")
    print(f"  exp_base (x SIMD) : LUT={exp_lut:>6}  DSP={exp_dsp:>4}  "
          f"({C.EXP_BASE['method']} {C.EXP_BASE['match']})")
    print(f"  => base(softmax)  : LUT={base_lut:>6}  DSP={base_dsp:>4}")
    if base_lut < 0 or base_dsp < 0:
        # Not fatal per the spec, but almost certainly a data/assumption error.
        print(f"  WARNING: negative base resource "
              f"(LUT={base_lut}, DSP={base_dsp}) - check base-case choice/SIMD.")
    print()
    return base_lut, base_dsp


# --------------------------------------------------------------------------- #
# Combination
# --------------------------------------------------------------------------- #
def combine(simd: int) -> None:
    exp = C.read_components(C.EXP_CSV)
    rec = C.read_components(C.REC_CSV)
    base_lut, base_dsp = compute_base_resources(simd)

    other_sq = C.RMSRE_OTHER ** 2

    combined = []
    for e in exp:
        for r in rec:
            # RMSRE(softmax)^2 = B_EXP*RMSRE(exp)^2 + RMSRE(rec)^2 + RMSRE(other)^2
            rmsre = math.sqrt(
                C.RMSRE_B_EXP * e["rmsre"] ** 2 + r["rmsre"] ** 2 + other_sq
            )
            lut = r["lut"] + simd * e["lut"] + base_lut
            dsp = r["dsp"] + simd * e["dsp"] + base_dsp
            combined.append({
                # keep enough provenance to be useful, but the plot ignores it
                "method": f"exp:{e['method']}+rec:{r['method']}",
                "params": {
                    **{f"exp_{k}": v for k, v in e["params"].items()},
                    **{f"rec_{k}": v for k, v in r["params"].items()},
                },
                "rmsre": rmsre,
                "lut": lut,
                "dsp": dsp,
            })

    print(f"[SOFTMAX] combinations: {len(exp)} exp x {len(rec)} rec = {len(combined)}")
    front = C.pareto_front(combined)
    out_path = C.softmax_csv(simd)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    C.write_components(out_path, front)
    print(f"[SOFTMAX] pareto={len(front)}  (dropped {len(combined) - len(front)} "
          f"dominated)  -> {out_path}")

    # Small human-readable summary of the frontier extent.
    if front:
        rmsres = [f["rmsre"] for f in front]
        luts = [f["lut"] for f in front]
        dsps = sorted({f["dsp"] for f in front})
        print(f"  RMSRE range: [{min(rmsres):.3e}, {max(rmsres):.3e}]")
        print(f"  LUT   range: [{min(luts)}, {max(luts)}]")
        print(f"  DSP   values on front: {dsps}")


def main() -> None:
    if len(sys.argv) > 1:
        simds = [int(sys.argv[1])]
    else:
        simds = C.SIMD_SWEEP
    for simd in simds:
        combine(simd)


if __name__ == "__main__":
    sys.exit(main())
