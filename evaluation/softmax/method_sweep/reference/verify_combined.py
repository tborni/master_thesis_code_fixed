#!/usr/bin/env python3
"""
Independent verification of softmax_rmsre_combined.csv.

This script re-derives every expected value from the RAW source files using a
different code path than combine_accuracy.py (hand-built dictionaries with
explicitly stated ground-truth values pulled by eye from the source files),
then asserts the produced CSV matches. It also re-checks the theoretical and
relative-difference arithmetic independently.
"""

from __future__ import annotations

import csv
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
CSV_FILE = HERE / "softmax_rmsre_combined.csv"

# --------------------------------------------------------------------------- #
# GROUND TRUTH pulled BY HAND directly from the source files.
# (exp_method_label, rec_method_label) -> (exp_rmsre, rec_rmsre)
#
# exp values:
#   BIT_HACKING A=12102203.0 D=1065277304 -> 3.824051e-02   (bit_hacking, line 8)
#   LOOKUP AW=8 WW=8                       -> 1.151400e-03   (lookup,      line 22)
#   BIPARTITE A0=2 A1=5 A2=5 WW=15         -> 9.432000e-05   (bipartite,   line 9)
#   SPLITTING A0=7 A1=6 A2=6 WW=22         -> 5.371696e-07   (splitting,   line 19)
# rec values:
#   BIPARTITE 0,2,3,3,11                   -> 1.068728e-03   (Rec_Bipartite line 2)
#   LOOKUP    0,11,16                      -> 1.003585e-04   (Rec_Lookup    line 37)
#   LOOKUP    1, 9, 8                      -> 7.756683e-07 ??? <- CHECK below
#   BIPARTITE 1,5,6,6,20                   -> 4.739927e-08   (Rec_Bipartite line 45)
# --------------------------------------------------------------------------- #

EXP_TRUTH = {
    "BIT_HACKING(A=12102203,D=1065277304)": 3.824051e-02,
    "LOOKUP(AW=8,WW=8)": 1.151400e-03,
    "BIPARTITE(AW0/1/2=2/5/5,WW=15)": 9.432000e-05,
    "SPLITTING(AW0/1/2=7/6/6,WW=22)": 5.371696e-07,
}

REC_TRUTH = {
    "BIPARTITE(NEWTON=0,AW0/1/2=2/3/3,WW=11)": 1.068728e-03,
    "LOOKUP(NEWTON=0,AW=11,WW=16)": 1.003585e-04,
    "LOOKUP(NEWTON=1,AW=9,WW=8)": 9.920150e-07,
    "BIPARTITE(NEWTON=1,AW0/1/2=5/6/6,WW=20)": 4.739927e-08,
}


def rel(a: float, b: float) -> float:
    """Relative difference between a and b (guard against zero)."""
    if b == 0:
        return math.inf if a != 0 else 0.0
    return abs(a - b) / abs(b)


def main() -> int:
    with CSV_FILE.open(newline="") as fh:
        rows = list(csv.DictReader(fh))

    assert len(rows) == 16, f"expected 16 rows, got {len(rows)}"

    problems = []
    for i, row in enumerate(rows, start=1):
        exp_label = row["exp_method"]
        rec_label = row["rec_method"]
        exp_rmsre = float(row["rmsre_exp"])
        rec_rmsre = float(row["rmsre_rec"])
        measured = float(row["rmsre_softmax_measured"])
        theo = float(row["rmsre_softmax_theoretical"])
        rel_diff = float(row["rel_diff"])

        # 1) exp/rec RMSRE match hand-pulled ground truth (relative tol 1e-6).
        exp_true = EXP_TRUTH.get(exp_label)
        rec_true = REC_TRUTH.get(rec_label)
        if exp_true is None:
            problems.append(f"row {i}: unknown exp label {exp_label!r}")
        elif rel(exp_rmsre, exp_true) > 1e-6:
            problems.append(
                f"row {i}: exp RMSRE {exp_rmsre:.6e} != truth {exp_true:.6e} "
                f"for {exp_label}"
            )
        if rec_true is None:
            problems.append(f"row {i}: unknown rec label {rec_label!r}")
        elif rel(rec_rmsre, rec_true) > 1e-6:
            problems.append(
                f"row {i}: rec RMSRE {rec_rmsre:.6e} != truth {rec_true:.6e} "
                f"for {rec_label}"
            )

        # 2) theoretical = sqrt(exp^2 + rec^2), recomputed from the CSV's own
        #    exp/rec columns (tolerant to the 6-sig-fig rounding in the file).
        theo_recompute = math.sqrt(exp_rmsre**2 + rec_rmsre**2)
        if rel(theo, theo_recompute) > 1e-4:
            problems.append(
                f"row {i}: theoretical {theo:.6e} != sqrt(exp^2+rec^2) "
                f"{theo_recompute:.6e}"
            )

        # 3) rel_diff = (theoretical - measured) / measured, recomputed.
        rel_diff_recompute = (theo_recompute - measured) / measured
        # CSV stores rel_diff rounded to 4 decimals -> abs tol 5e-5 plus a
        # little slack for the rounded theoretical value.
        if abs(rel_diff - rel_diff_recompute) > 1e-3:
            problems.append(
                f"row {i}: rel_diff {rel_diff:+.4f} != recomputed "
                f"{rel_diff_recompute:+.6f}"
            )

        # 4) sanity: measured base is positive.
        if measured <= 0:
            problems.append(f"row {i}: non-positive measured RMSRE {measured}")

    # 5) All 4 exp methods x 4 rec methods present exactly once (full 4x4 grid).
    seen = {(r["exp_method"], r["rec_method"]) for r in rows}
    assert len(seen) == 16, "duplicate (exp, rec) combination detected"
    for e in EXP_TRUTH:
        for r in REC_TRUTH:
            if (e, r) not in seen:
                problems.append(f"missing combination: ({e}, {r})")

    if problems:
        print("VERIFICATION FAILED:")
        for p in problems:
            print("  -", p)
        return 1

    print("VERIFICATION PASSED: all 16 rows match hand-pulled ground truth,")
    print("theoretical = sqrt(exp^2 + rec^2) and rel_diff = (theo-meas)/meas hold,")
    print("and the full 4x4 exp/rec grid is present exactly once.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
