#!/usr/bin/env python3
"""
Independent verification of data/accuracy_softmax/theory_accuracy_comparison.csv.

This re-derives every expected value through a *different* code path than
combine_accuracy.py: hand-transcribed ground-truth RMSRE values pulled by eye
from data/exp/*.csv and data/rec/*.csv, plus the measured softmax RMSRE pulled
by eye from data/accuracy_softmax/accuracy.txt. It then asserts the produced
CSV matches, and
re-checks the theoretical and relative-difference arithmetic independently.

If combine_accuracy.py and this file disagree, one of them is wrong — the point
is that they were written from the source data independently.
"""

from __future__ import annotations

import csv
import math
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
CSV_FILE = PROJECT_ROOT / "data" / "accuracy_softmax" / "theory_accuracy_comparison.csv"

# --------------------------------------------------------------------------- #
# GROUND TRUTH — pulled BY HAND from the data CSVs.
#
# exp values (data/exp/):
#   Bit-hacking      : single row                       -> 0.01790955
#   Lookup    AW=8  WW=8                                 -> 0.001172048
#   Bipartite AW0/1/2=2/5/5 WW=15                        -> 9.280045e-05
#   Splitting AW0/1/2=6/5/6 WW=22 (row "6,5,6,22")       -> 1.901869e-06
# rec values (data/rec/):
#   Bipartite NEWTON=0 AW0/1/2=2/3/3 WW=11 (row 0,2,3,3,11) -> 0.001057613
#   Lookup    NEWTON=0 AW=11 WW=16         (row 0,11,16)    -> 9.986526e-05
#   Lookup    NEWTON=1 AW=9  WW=8          (row 1,9,8)      -> 9.902895e-07
#   Bipartite NEWTON=1 AW0/1/2=4/6/6 WW=18 (row 1,4,6,6,18) -> 4.845592e-08
# --------------------------------------------------------------------------- #
EXP_TRUTH = {
    "BIT_HACKING(A=12102203,D=1065277304)": 0.01790955,
    "LOOKUP(AW=8,WW=8)": 0.001172048,
    "BIPARTITE(AW0/1/2=2/5/5,WW=15)": 9.280045e-05,
    "SPLITTING(AW0/1/2=6/5/6,WW=22)": 1.901869e-06,
}

REC_TRUTH = {
    "BIPARTITE(NEWTON=0,AW0/1/2=2/3/3,WW=11)": 0.001057613,
    "LOOKUP(NEWTON=0,AW=11,WW=16)": 9.986526e-05,
    "LOOKUP(NEWTON=1,AW=9,WW=8)": 9.902895e-07,
    "BIPARTITE(NEWTON=1,AW0/1/2=4/6/6,WW=18)": 4.845592e-08,
}

# Fixed softmax-level error term and exp-variance weight used by the theoretical
# model. Hardcoded independently here (not imported) so this stays an
# independent check.
D_OTHER = 1.918e-7
B_EXP = 1.0456234249238079

# Measured softmax RMSRE, keyed by (exp_label, rec_label), pulled by hand from
# data/accuracy_softmax/accuracy.txt (the 16 Test lines, in file order 1..16).
MEASURED_TRUTH = {
    ("BIT_HACKING(A=12102203,D=1065277304)", "BIPARTITE(NEWTON=0,AW0/1/2=2/3/3,WW=11)"): 0.0194088375,
    ("BIT_HACKING(A=12102203,D=1065277304)", "LOOKUP(NEWTON=0,AW=11,WW=16)"): 0.0193145144,
    ("BIT_HACKING(A=12102203,D=1065277304)", "LOOKUP(NEWTON=1,AW=9,WW=8)"): 0.0189306822,
    ("BIT_HACKING(A=12102203,D=1065277304)", "BIPARTITE(NEWTON=1,AW0/1/2=4/6/6,WW=18)"): 0.0192466955,
    ("LOOKUP(AW=8,WW=8)", "BIPARTITE(NEWTON=0,AW0/1/2=2/3/3,WW=11)"): 0.0016224882,
    ("LOOKUP(AW=8,WW=8)", "LOOKUP(NEWTON=0,AW=11,WW=16)"): 0.0011768550,
    ("LOOKUP(AW=8,WW=8)", "LOOKUP(NEWTON=1,AW=9,WW=8)"): 0.0011715218,
    ("LOOKUP(AW=8,WW=8)", "BIPARTITE(NEWTON=1,AW0/1/2=4/6/6,WW=18)"): 0.0011741454,
    ("BIPARTITE(AW0/1/2=2/5/5,WW=15)", "BIPARTITE(NEWTON=0,AW0/1/2=2/3/3,WW=11)"): 0.0010663968,
    ("BIPARTITE(AW0/1/2=2/5/5,WW=15)", "LOOKUP(NEWTON=0,AW=11,WW=16)"): 0.0001395453,
    ("BIPARTITE(AW0/1/2=2/5/5,WW=15)", "LOOKUP(NEWTON=1,AW=9,WW=8)"): 0.0000958119,
    ("BIPARTITE(AW0/1/2=2/5/5,WW=15)", "BIPARTITE(NEWTON=1,AW0/1/2=4/6/6,WW=18)"): 0.0000953897,
    ("SPLITTING(AW0/1/2=6/5/6,WW=22)", "BIPARTITE(NEWTON=0,AW0/1/2=2/3/3,WW=11)"): 0.0011222907,
    ("SPLITTING(AW0/1/2=6/5/6,WW=22)", "LOOKUP(NEWTON=0,AW=11,WW=16)"): 0.0001056593,
    ("SPLITTING(AW0/1/2=6/5/6,WW=22)", "LOOKUP(NEWTON=1,AW=9,WW=8)"): 0.0000024275,
    ("SPLITTING(AW0/1/2=6/5/6,WW=22)", "BIPARTITE(NEWTON=1,AW0/1/2=4/6/6,WW=18)"): 0.0000018797,
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
        rel_diff_pct = float(row["rel_diff_percent"].rstrip("%"))
        rel_diff_abs_pct = float(row["rel_diff_absolute_percent"].rstrip("%"))

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

        # 2) measured softmax RMSRE matches the hand-pulled value from accuracy.txt.
        meas_true = MEASURED_TRUTH.get((exp_label, rec_label))
        if meas_true is None:
            problems.append(
                f"row {i}: no hand-pulled measured value for "
                f"({exp_label}, {rec_label})"
            )
        elif rel(measured, meas_true) > 1e-6:
            problems.append(
                f"row {i}: measured {measured:.6e} != truth {meas_true:.6e}"
            )

        # 3) theoretical = sqrt(rec^2 + B_EXP*exp^2 + D_OTHER^2), recomputed from
        #    the CSV's own exp/rec columns (tolerant to the 6-sig-fig rounding in
        #    the file).
        theo_recompute = math.sqrt(rec_rmsre**2 + B_EXP * exp_rmsre**2 + D_OTHER**2)
        if rel(theo, theo_recompute) > 1e-4:
            problems.append(
                f"row {i}: theoretical {theo:.6e} != "
                f"sqrt(rec^2+B_EXP*exp^2+D_OTHER^2) {theo_recompute:.6e}"
            )

        # 4) rel_diff = (theoretical - measured) / measured, recomputed.
        rel_diff_recompute = (theo_recompute - measured) / measured
        if abs(rel_diff - rel_diff_recompute) > 1e-3:
            problems.append(
                f"row {i}: rel_diff {rel_diff:+.4f} != recomputed "
                f"{rel_diff_recompute:+.6f}"
            )

        # 5) percent columns are internally consistent with rel_diff.
        if abs(rel_diff_pct - rel_diff * 100) > 1e-2:
            problems.append(
                f"row {i}: rel_diff_percent {rel_diff_pct:+.2f} != "
                f"rel_diff*100 {rel_diff * 100:+.2f}"
            )
        if abs(rel_diff_abs_pct - abs(rel_diff) * 100) > 1e-2:
            problems.append(
                f"row {i}: rel_diff_absolute_percent {rel_diff_abs_pct:.2f} != "
                f"|rel_diff|*100 {abs(rel_diff) * 100:.2f}"
            )
        # sign consistency: the signed percent's magnitude equals the abs percent.
        if abs(abs(rel_diff_pct) - rel_diff_abs_pct) > 1e-2:
            problems.append(
                f"row {i}: |rel_diff_percent| {abs(rel_diff_pct):.2f} != "
                f"rel_diff_absolute_percent {rel_diff_abs_pct:.2f}"
            )

        # 6) sanity: measured base is positive.
        if measured <= 0:
            problems.append(f"row {i}: non-positive measured RMSRE {measured}")

    # 7) All 4 exp methods x 4 rec methods present exactly once (full 4x4 grid).
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

    print("VERIFICATION PASSED: all 16 rows match hand-pulled ground truth")
    print("(exp/rec RMSRE from data/{exp,rec}/*.csv, measured from accuracy.txt),")
    print("theoretical = sqrt(rec^2 + B_EXP*exp^2 + D_OTHER^2), rel_diff =")
    print("(theo-meas)/meas, the")
    print("percent columns are consistent, and the full 4x4 exp/rec grid is")
    print("present exactly once.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
