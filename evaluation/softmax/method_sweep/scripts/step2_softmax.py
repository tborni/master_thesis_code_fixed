"""Step 2 - combine Exp x Rec into softmax implementations.

LUT/DSP live in the combined method files (not in separate resource files), so
the resource *sources* are:

  * the base-case LUT/DSP are read from the combined files
    ``data/{exp,rec}/<Label>_combined.csv`` (same files step 1 consumes)
  * the total-softmax LUT/DSP per SIMD are read from ``data/resources_SIMD.csv``

For every (exp, rec) pair from the step-1 Pareto fronts:

  RMSRE(softmax)^2 = B_EXP*RMSRE(exp)^2 + RMSRE(rec)^2 + RMSRE(other)^2
      with B_EXP = 1.0456234249238079 and RMSRE(other) = 1.918e-7

  Resources(softmax) = 1*Resources(rec')
                     + SIMD*Resources(exp)
                     + 1*Resources(base)

  Resources(base) = resources_SIMD(SIMD) - 1*Resources(rec_base) - SIMD*Resources(exp_base)

Resources(rec') is the reciprocal's own resources with the *folding correction*
applied.  The combined-file reciprocal resources are measured at a sustainable
interval of 1; in softmax the reciprocal only accepts a new input every
SUSTAINABLE_INTERVAL = N / SIMD cycles, so a reciprocal WITHOUT a Newton step is
folded to that rate and its resources shift by

    delta(SI) = folding[SI = 1] - folding[SI = N/SIMD]

added per resource metric (helper_config.folding_delta).  A reciprocal WITH a
Newton step is left exactly as measured; the IP core reciprocal (no
NUM_NEWTON_STEPS column) counts as no-Newton and is corrected.  See the
"Folding correction" section of helper_config for the full definition.

The base blocks are looked up in the combined method files; if either base case
is missing we abort immediately (per the description).  The base reciprocal has a
Newton step, so it is NOT folding-corrected and the base subtraction is
unchanged.

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
# step 1's per-method loader is reused by the pre-filter safety check below, so
# the folding-corrected reciprocal front can be recomputed from the raw inputs.
import step1_components as step1


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


def _simd_sweep_total(simd: int) -> Tuple[int, int, int]:
    """Total softmax (N, LUT, DSP) at the given SIMD from resources_SIMD.csv.

    N is read from the same row (it is the softmax length that sets the
    reciprocal's sustainable interval N/SIMD); every SIMD row carries it.
    """
    rows = C.read_csv_dicts(C.SIMD_SWEEP_CSV, required=("N", "SIMD", "LUT", "DSP"))
    for r in rows:
        if int(r["SIMD"]) == simd:
            return int(r["N"]), int(r["LUT"]), int(r["DSP"])
    have = sorted(int(r["SIMD"]) for r in rows)
    raise SystemExit(
        f"ERROR: SIMD={simd} not present in resources_SIMD.csv (have {have}) - "
        "aborting."
    )


def compute_base_resources(simd: int) -> Tuple[int, int, int]:
    """Base(softmax) = resources_SIMD(SIMD) - rec_base - SIMD*exp_base.

    Returns ``(N, base_lut, base_dsp)``; N (read from the same resources_SIMD row)
    is carried out so the caller can form the reciprocal's sustainable interval
    N/SIMD without re-reading the file.  The base reciprocal has a Newton step and
    is therefore NOT folding-corrected, so the base subtraction is the plain
    measured value.
    """
    rec_lut, rec_dsp = _lookup_resource(C.REC_BASE)
    exp_lut, exp_dsp = _lookup_resource(C.EXP_BASE)
    n, tot_lut, tot_dsp = _simd_sweep_total(simd)

    base_lut = tot_lut - rec_lut - simd * exp_lut
    base_dsp = tot_dsp - rec_dsp - simd * exp_dsp

    print(f"[BASE] SIMD={simd}  (N={n})")
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
    return n, base_lut, base_dsp


# --------------------------------------------------------------------------- #
# Folding correction for the reciprocal component
# --------------------------------------------------------------------------- #
def _fold_correct_rec(rec, simd: int, n: int):
    """Return the reciprocal records with the folding correction applied.

    Every reciprocal record WITHOUT a Newton step (parametric NUM_NEWTON_STEPS=0
    and the IP core, which has no such column) gets ``folding_delta(N/SIMD)``
    added to each of its resource metrics; a reciprocal WITH a Newton step is
    returned unchanged.  LUT/DSP are the only metrics carried on the component
    record (they are the ones the softmax sum and the plot use), so the delta is
    applied to those; the remaining folding metrics are computed for the log line
    only.  Records are copied, never mutated in place.
    """
    folding = C.read_folding()
    si = C.sustainable_interval(n, simd)
    row_si = C.folding_row_for_si(folding, si)
    delta = C.folding_delta(folding, si)

    print(f"[FOLD] SIMD={simd}  sustainable interval N/SIMD = {n}/{simd} = {si}")
    print(f"  folding row used  : SI={row_si} (largest characterised SI <= {si})")
    print(f"  delta (SI=1 - SI={row_si}): "
          + "  ".join(f"{m}={delta[m]:+d}" for m in C.FOLDING_METRICS))

    corrected = []
    n_corr = 0
    for r in rec:
        if C.rec_has_newton(r["params"]):
            corrected.append(r)
            continue
        n_corr += 1
        rr = dict(r)
        rr["lut"] = r["lut"] + delta["LUT"]
        rr["dsp"] = r["dsp"] + delta["DSP"]
        corrected.append(rr)

    n_newton = len(rec) - n_corr
    print(f"  corrected {n_corr} no-Newton rec point(s) by (LUT{delta['LUT']:+d}, "
          f"DSP{delta['DSP']:+d}); left {n_newton} Newton rec point(s) unchanged.")
    # The folding delta is a fixed offset taken from the folding file's reciprocal
    # block, so for a reciprocal whose own LUT is smaller than |delta| the
    # component value can dip below zero *in isolation*.  That is harmless: Pareto
    # optimality is decided on the full-softmax total (rec' + SIMD*exp + base),
    # which stays firmly positive.  We only note it, and only flag it as a real
    # problem if that full total were to go negative (checked in combine()).
    sub_zero = [rr for rr in corrected if rr["lut"] < 0 or rr["dsp"] < 0]
    if sub_zero:
        print(f"  note: {len(sub_zero)} reciprocal(s) have a sub-zero component "
              f"resource in isolation after folding (smaller than |delta|); "
              f"absorbed by the softmax base+exp total below.")
    print()
    _assert_prefilter_safe(delta, simd)
    return corrected


def _assert_prefilter_safe(delta, simd: int) -> None:
    """Fail loudly if step-1's (uncorrected) reciprocal front pruned any point
    that the folding correction would promote back onto the front.

    Step 1 selects the reciprocal Pareto front on the *uncorrected* (SI=1)
    resources; that pre-filter is only valid for the corrected softmax if no
    reciprocal point dropped in step 1 becomes non-dominated once the (subset-
    only) folding delta is added.  The delta is a constant offset applied to the
    no-Newton points and zero for the Newton points, so it can only change
    domination across that boundary.  Rather than trust that stays benign for
    future data, we recompute the reciprocal front from the raw combined files
    WITH the correction and confirm it adds nothing beyond step 1's front.
    """
    bounds, included = C.load_filter()
    all_rec = []
    # step1.load_method prints a per-method report; step 1 already emitted it, so
    # silence the reused call here to keep step 2's output clean.
    with open(os.devnull, "w") as devnull:
        saved_stdout = sys.stdout
        sys.stdout = devnull
        try:
            for m in C.REC_METHODS:
                if not C.method_included(m, included):
                    continue
                for r in step1.load_method(m, bounds):
                    rr = dict(r)
                    if not C.rec_has_newton(r["params"]):
                        rr["lut"] = r["lut"] + delta["LUT"]
                        rr["dsp"] = r["dsp"] + delta["DSP"]
                    all_rec.append(rr)
        finally:
            sys.stdout = saved_stdout
    corrected_front = C.pareto_front(all_rec)

    prefilter = C.read_components(C.REC_CSV)
    prefilter_obj = set()
    for r in prefilter:
        lut, dsp = r["lut"], r["dsp"]
        if not C.rec_has_newton(r["params"]):
            lut, dsp = lut + delta["LUT"], dsp + delta["DSP"]
        prefilter_obj.add((round(r["rmsre"], 12), lut, dsp))

    missed = [r for r in corrected_front
              if (round(r["rmsre"], 12), r["lut"], r["dsp"]) not in prefilter_obj]
    if missed:
        raise SystemExit(
            f"ERROR: the step-1 reciprocal front is not a valid pre-filter under "
            f"the folding correction at SIMD={simd}: {len(missed)} corrected "
            f"reciprocal point(s) are non-dominated but were pruned in step 1. "
            f"The reciprocal front must be recomputed with the correction applied "
            f"before pruning. Offending points: "
            f"{[(f'{r['rmsre']:.3e}', r['lut'], r['dsp']) for r in missed]}."
        )


# --------------------------------------------------------------------------- #
# Combination
# --------------------------------------------------------------------------- #
def combine(simd: int) -> None:
    exp = C.read_components(C.EXP_CSV)
    rec = C.read_components(C.REC_CSV)
    n, base_lut, base_dsp = compute_base_resources(simd)
    rec = _fold_correct_rec(rec, simd, n)

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

    # The full-softmax total is what Pareto optimality is decided on, so it must
    # be physical: abort if any combination's LUT/DSP is negative (a folding
    # correction big enough to sink the whole datapath below zero is a data/model
    # error, not just a sub-zero component in isolation).
    neg = [c for c in combined if c["lut"] < 0 or c["dsp"] < 0]
    if neg:
        worst = min(neg, key=lambda c: min(c["lut"], c["dsp"]))
        raise SystemExit(
            f"ERROR: SIMD={simd}: {len(neg)} softmax combination(s) have a "
            f"negative total resource after the folding correction "
            f"(e.g. {worst['method']}: LUT={worst['lut']}, DSP={worst['dsp']}). "
            f"The full-softmax total drives Pareto selection and cannot be "
            f"negative - check the folding file / base-case resources."
        )

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
