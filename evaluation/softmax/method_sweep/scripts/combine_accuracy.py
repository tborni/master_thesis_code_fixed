#!/usr/bin/env python3
"""
Combine the exp-component, rec-component and full-softmax accuracy measurements
of the method sweep into a single table.

The softmax of this sweep is implemented as ``exp(x) * reciprocal(sum exp(x))``,
so its error decomposes into an exp-approximation error and a
reciprocal-approximation error. This script cross-references, for every setup
measured in ``data/accuracy_softmax/accuracy.txt``:

  * the RMSRE of the exp component  (looked up in ``data/exp/<Method>_combined.csv``)
  * the RMSRE of the rec component  (looked up in ``data/rec/<Method>_combined.csv``)
  * the measured softmax RMSRE      (read straight from ``data/accuracy_softmax/accuracy.txt``)
  * the theoretical softmax RMSRE, modelled as
        sqrt( RMSRE(rec)**2 + B_EXP * RMSRE(exp)**2 + D_OTHER**2 )
    where ``D_OTHER`` is a fixed softmax-level error term added in quadrature to
    account for contributions not captured by the exp/rec component
    approximations, and ``B_EXP`` weights the exp-component variance (see the
    constants below).
  * the signed relative difference between the theoretical and the measured
    softmax RMSRE, using the measured value as the base:
        rel_diff              = (theoretical - measured) / measured
        rel_diff_percent      = rel_diff * 100            (signed, new column)
        rel_diff_absolute_pct = |rel_diff| * 100

The result is written to ``data/accuracy_softmax/theory_accuracy_comparison.csv``.

Correctness is the priority here: the component look-ups are deliberately
*strict*. The exp/rec reference CSVs are indexed by their full parameter tuple,
and every configuration named in ``data/accuracy_softmax/accuracy.txt`` must resolve to exactly
one reference row. If a configuration is missing, ambiguous (duplicate rows),
or a source CSV itself contains a duplicate key, the script aborts with a clear
diagnostic and writes no output — it never silently substitutes a "close"
row.

The one method carrying parameters in ``accuracy.txt`` but *not* in its data
file is BIT_HACKING: ``data/exp/Bit-hacking_combined.csv`` records only
``LUT,DSP,RMSRE`` (the ``A``/``D`` magic constants are fixed for the sweep and
are not a swept dimension). It is therefore resolved positionally against the
single row of that file, which the loader asserts is unique; the ``A``/``D``
values parsed from ``accuracy.txt`` are still carried into the output label so
the setup remains fully identified.
"""

from __future__ import annotations

import csv
import math
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"

# The measured softmax report and the generated comparison table live together
# in the accuracy_softmax/ subfolder; the per-method component CSVs stay in
# exp/ and rec/.
ACCURACY_DIR = DATA_DIR / "accuracy_softmax"
ACCURACY_FILE = ACCURACY_DIR / "accuracy.txt"
EXP_DIR = DATA_DIR / "exp"
REC_DIR = DATA_DIR / "rec"

# Component CSVs, one per approximation method. Only the methods actually used
# by this sweep need a loader; others (e.g. the IP-core CSVs) are ignored.
EXP_BIT_HACKING_FILE = EXP_DIR / "Bit-hacking_combined.csv"
EXP_LOOKUP_FILE = EXP_DIR / "Lookup_combined.csv"
EXP_BIPARTITE_FILE = EXP_DIR / "Bipartite_combined.csv"
EXP_SPLITTING_FILE = EXP_DIR / "Splitting_combined.csv"
REC_LOOKUP_FILE = REC_DIR / "Lookup_combined.csv"
REC_BIPARTITE_FILE = REC_DIR / "Bipartite_combined.csv"

OUTPUT_FILE = ACCURACY_DIR / "theory_accuracy_comparison.csv"

# Additional constant error term folded into the theoretical model in quadrature,
# capturing softmax-level error contributions not attributable to the exp or rec
# component approximations (e.g. the fixed-point accumulation / requantisation
# floor of the surrounding softmax datapath).
D_OTHER = 1.918e-7

# Weight on the exp-component variance in the theoretical model. B > 1 amplifies
# the exp error's contribution relative to the rec error, reflecting that the
# exp approximation error propagates into the softmax output with a slightly
# larger effective gain than the reciprocal error does.
B_EXP = 1.0456234249238079


class ResolutionError(Exception):
    """Raised when a component configuration cannot be resolved uniquely."""


# --------------------------------------------------------------------------- #
# Reference-table loaders
#
# Each loader reads one component CSV into a {param_tuple: rmsre} dict, keyed by
# the integer parameter columns. Duplicate keys inside a single file are a data
# error (an ambiguous look-up) and abort immediately.
# --------------------------------------------------------------------------- #
def _read_rows(path: Path) -> List[dict]:
    if not path.is_file():
        raise ResolutionError(f"reference file not found: {path}")
    with path.open(newline="") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        raise ResolutionError(f"no data rows in {path}")
    return rows


def _insert_unique(table: dict, key, value: float, path: Path) -> None:
    if key in table:
        raise ResolutionError(
            f"duplicate key {key} in {path.name} (ambiguous look-up)"
        )
    table[key] = value


def load_exp_bit_hacking() -> float:
    """exp bit-hacking: no swept parameters -> the file's single RMSRE value.

    ``A``/``D`` are fixed magic constants for the sweep and are not columns in
    the CSV, so the configuration is resolved positionally. Assert there is
    exactly one row to guarantee the mapping is unambiguous.
    """
    rows = _read_rows(EXP_BIT_HACKING_FILE)
    if len(rows) != 1:
        raise ResolutionError(
            f"expected exactly 1 row in {EXP_BIT_HACKING_FILE.name}, "
            f"found {len(rows)} — cannot resolve BIT_HACKING positionally"
        )
    return float(rows[0]["RMSRE"])


def load_exp_lookup() -> Dict[Tuple[int, int], float]:
    """exp lookup: keyed by (ADDR_WIDTH, WORD_WIDTH)."""
    table: Dict[Tuple[int, int], float] = {}
    for row in _read_rows(EXP_LOOKUP_FILE):
        key = (int(row["ADDR_WIDTH"]), int(row["WORD_WIDTH"]))
        _insert_unique(table, key, float(row["RMSRE"]), EXP_LOOKUP_FILE)
    return table


def _load_a012(path: Path) -> Dict[Tuple[int, int, int, int], float]:
    """exp bipartite / splitting: keyed by (AW0, AW1, AW2, WORD_WIDTH)."""
    table: Dict[Tuple[int, int, int, int], float] = {}
    for row in _read_rows(path):
        key = (
            int(row["ADDR_WIDTH_0"]),
            int(row["ADDR_WIDTH_1"]),
            int(row["ADDR_WIDTH_2"]),
            int(row["WORD_WIDTH"]),
        )
        _insert_unique(table, key, float(row["RMSRE"]), path)
    return table


def load_rec_lookup() -> Dict[Tuple[int, int, int], float]:
    """rec lookup: keyed by (NUM_NEWTON_STEPS, ADDR_WIDTH, WORD_WIDTH)."""
    table: Dict[Tuple[int, int, int], float] = {}
    for row in _read_rows(REC_LOOKUP_FILE):
        key = (
            int(row["NUM_NEWTON_STEPS"]),
            int(row["ADDR_WIDTH"]),
            int(row["WORD_WIDTH"]),
        )
        _insert_unique(table, key, float(row["RMSRE"]), REC_LOOKUP_FILE)
    return table


def load_rec_bipartite() -> Dict[Tuple[int, int, int, int, int], float]:
    """rec bipartite: keyed by (NEWTON, AW0, AW1, AW2, WORD_WIDTH)."""
    table: Dict[Tuple[int, int, int, int, int], float] = {}
    for row in _read_rows(REC_BIPARTITE_FILE):
        key = (
            int(row["NUM_NEWTON_STEPS"]),
            int(row["ADDR_WIDTH_0"]),
            int(row["ADDR_WIDTH_1"]),
            int(row["ADDR_WIDTH_2"]),
            int(row["WORD_WIDTH"]),
        )
        _insert_unique(table, key, float(row["RMSRE"]), REC_BIPARTITE_FILE)
    return table


# --------------------------------------------------------------------------- #
# accuracy.txt parsing
#
# Each measured line looks like:
#   Test (EXP = <exp spec>, REC = <rec spec>, N = 64, SIMD = 2): RMSRE = <val>, ...
# Split into the EXP block (between "EXP =" and ", REC =") and the REC block
# (between "REC =" and ", N ="), then parse each block's method + parameters.
# --------------------------------------------------------------------------- #
_LINE_RE = re.compile(
    r"EXP\s*=\s*(?P<exp>.*?),\s*REC\s*=\s*(?P<rec>.*?),\s*N\s*=.*?"
    r"RMSRE\s*=\s*(?P<rmsre>[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)"
)

# EXP method specs (as written in accuracy.txt).
_EXP_BIT_HACKING_RE = re.compile(
    r"BIT_HACKING\s*\[\s*A=(?P<A>\d+)\s*,\s*D=(?P<D>\d+)\s*\]"
)
_EXP_LOOKUP_RE = re.compile(r"LOOKUP\s*\[\s*WW=(?P<WW>\d+)\s*,\s*AW=(?P<AW>\d+)\s*\]")
_EXP_A012_RE = re.compile(
    r"(?P<method>BIPARTITE|SPLITTING)\s*\[\s*WW=(?P<WW>\d+)\s*,\s*"
    r"AW0/1/2=(?P<A0>\d+)/(?P<A1>\d+)/(?P<A2>\d+)\s*\]"
)

# REC method specs (as written in accuracy.txt).
_REC_LOOKUP_RE = re.compile(
    r"LOOKUP\s*\[\s*NEWTON=(?P<NEWTON>\d+)\s*,\s*WW=(?P<WW>\d+)\s*,\s*AW=(?P<AW>\d+)\s*\]"
)
_REC_BIPARTITE_RE = re.compile(
    r"BIPARTITE\s*\[\s*NEWTON=(?P<NEWTON>\d+)\s*,\s*WW=(?P<WW>\d+)\s*,\s*"
    r"AW0/1/2=(?P<A0>\d+)/(?P<A1>\d+)/(?P<A2>\d+)\s*\]"
)


def resolve_exp(spec: str, tables: dict, line_no: int) -> Tuple[str, float]:
    """Return (canonical_label, rmsre) for an EXP spec string."""
    spec = spec.strip()

    m = _EXP_BIT_HACKING_RE.search(spec)
    if m:
        # No swept params in the data file -> positional single-row resolution.
        label = f"BIT_HACKING(A={m.group('A')},D={m.group('D')})"
        return label, tables["exp_bit_hacking"]

    m = _EXP_LOOKUP_RE.search(spec)
    if m:
        aw, ww = int(m.group("AW")), int(m.group("WW"))
        label = f"LOOKUP(AW={aw},WW={ww})"
        try:
            return label, tables["exp_lookup"][(aw, ww)]
        except KeyError:
            raise ResolutionError(
                f"[line {line_no}] EXP LOOKUP config AW={aw},WW={ww} not found "
                f"in {EXP_LOOKUP_FILE.name}"
            )

    m = _EXP_A012_RE.search(spec)
    if m:
        method = m.group("method")
        a0, a1, a2, ww = (
            int(m.group("A0")),
            int(m.group("A1")),
            int(m.group("A2")),
            int(m.group("WW")),
        )
        key = (a0, a1, a2, ww)
        label = f"{method}(AW0/1/2={a0}/{a1}/{a2},WW={ww})"
        tbl_name = "exp_bipartite" if method == "BIPARTITE" else "exp_splitting"
        src = EXP_BIPARTITE_FILE if method == "BIPARTITE" else EXP_SPLITTING_FILE
        try:
            return label, tables[tbl_name][key]
        except KeyError:
            raise ResolutionError(
                f"[line {line_no}] EXP {method} config AW0/1/2={a0}/{a1}/{a2},"
                f"WW={ww} not found in {src.name}"
            )

    raise ResolutionError(f"[line {line_no}] could not parse EXP spec: {spec!r}")


def resolve_rec(spec: str, tables: dict, line_no: int) -> Tuple[str, float]:
    """Return (canonical_label, rmsre) for a REC spec string."""
    spec = spec.strip()

    m = _REC_LOOKUP_RE.search(spec)
    if m:
        newton, ww, aw = (
            int(m.group("NEWTON")),
            int(m.group("WW")),
            int(m.group("AW")),
        )
        key = (newton, aw, ww)  # table key order: (NEWTON, ADDR_WIDTH, WORD_WIDTH)
        label = f"LOOKUP(NEWTON={newton},AW={aw},WW={ww})"
        try:
            return label, tables["rec_lookup"][key]
        except KeyError:
            raise ResolutionError(
                f"[line {line_no}] REC LOOKUP config NEWTON={newton},AW={aw},"
                f"WW={ww} not found in {REC_LOOKUP_FILE.name}"
            )

    m = _REC_BIPARTITE_RE.search(spec)
    if m:
        newton, ww, a0, a1, a2 = (
            int(m.group("NEWTON")),
            int(m.group("WW")),
            int(m.group("A0")),
            int(m.group("A1")),
            int(m.group("A2")),
        )
        key = (newton, a0, a1, a2, ww)  # (NEWTON, AW0, AW1, AW2, WORD_WIDTH)
        label = f"BIPARTITE(NEWTON={newton},AW0/1/2={a0}/{a1}/{a2},WW={ww})"
        try:
            return label, tables["rec_bipartite"][key]
        except KeyError:
            raise ResolutionError(
                f"[line {line_no}] REC BIPARTITE config NEWTON={newton},"
                f"AW0/1/2={a0}/{a1}/{a2},WW={ww} not found in "
                f"{REC_BIPARTITE_FILE.name}"
            )

    raise ResolutionError(f"[line {line_no}] could not parse REC spec: {spec!r}")


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
FIELDNAMES = [
    "exp_method",
    "rec_method",
    "rmsre_exp",
    "rmsre_rec",
    "rmsre_softmax_measured",
    "rmsre_softmax_theoretical",
    "rel_diff",
    "rel_diff_percent",
    "rel_diff_absolute_percent",
]


def main() -> int:
    tables = {
        "exp_bit_hacking": load_exp_bit_hacking(),
        "exp_lookup": load_exp_lookup(),
        "exp_bipartite": _load_a012(EXP_BIPARTITE_FILE),
        "exp_splitting": _load_a012(EXP_SPLITTING_FILE),
        "rec_lookup": load_rec_lookup(),
        "rec_bipartite": load_rec_bipartite(),
    }

    rows = []
    errors = []
    text = ACCURACY_FILE.read_text()

    for line_no, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if not line or not line.startswith("Test"):
            continue

        m = _LINE_RE.search(line)
        if not m:
            errors.append(f"[line {line_no}] could not parse Test line: {line!r}")
            continue

        try:
            exp_label, exp_rmsre = resolve_exp(m.group("exp"), tables, line_no)
            rec_label, rec_rmsre = resolve_rec(m.group("rec"), tables, line_no)
        except ResolutionError as exc:
            errors.append(str(exc))
            continue

        measured = float(m.group("rmsre"))
        if measured <= 0:
            errors.append(
                f"[line {line_no}] non-positive measured RMSRE {measured!r}; "
                "cannot use it as the relative-difference base"
            )
            continue

        theoretical = math.sqrt(rec_rmsre**2 + B_EXP * exp_rmsre**2 + D_OTHER**2)
        rel_diff = (theoretical - measured) / measured  # measured is the base

        rows.append(
            {
                "exp_method": exp_label,
                "rec_method": rec_label,
                "rmsre_exp": exp_rmsre,
                "rmsre_rec": rec_rmsre,
                "rmsre_softmax_measured": measured,
                "rmsre_softmax_theoretical": theoretical,
                "rel_diff": rel_diff,
            }
        )

    if errors:
        for e in errors:
            print(f"ERROR: {e}", file=sys.stderr)
        raise SystemExit(
            f"\nAborting: {len(errors)} configuration(s) could not be resolved. "
            "No output written."
        )

    if not rows:
        raise SystemExit(f"Aborting: no Test lines found in {ACCURACY_FILE}.")

    with OUTPUT_FILE.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=FIELDNAMES)
        writer.writeheader()
        for r in rows:
            writer.writerow(
                {
                    "exp_method": r["exp_method"],
                    "rec_method": r["rec_method"],
                    "rmsre_exp": f"{r['rmsre_exp']:.6e}",
                    "rmsre_rec": f"{r['rmsre_rec']:.6e}",
                    "rmsre_softmax_measured": f"{r['rmsre_softmax_measured']:.6e}",
                    "rmsre_softmax_theoretical": f"{r['rmsre_softmax_theoretical']:.6e}",
                    "rel_diff": f"{r['rel_diff']:+.4f}",
                    "rel_diff_percent": f"{r['rel_diff'] * 100:+.2f}%",
                    "rel_diff_absolute_percent": f"{abs(r['rel_diff']) * 100:.2f}%",
                }
            )

    print(f"Wrote {len(rows)} rows to {OUTPUT_FILE}")

    # Console summary table for a quick eyeball check.
    hdr = (
        f"{'EXP':<34} {'REC':<44} {'exp':>11} {'rec':>11} "
        f"{'sm_meas':>11} {'sm_theo':>11} {'rel_diff':>10} {'|rd|%':>8}"
    )
    print("\n" + hdr)
    print("-" * len(hdr))
    for r in rows:
        print(
            f"{r['exp_method']:<34} {r['rec_method']:<44} "
            f"{r['rmsre_exp']:>11.3e} {r['rmsre_rec']:>11.3e} "
            f"{r['rmsre_softmax_measured']:>11.3e} "
            f"{r['rmsre_softmax_theoretical']:>11.3e} "
            f"{r['rel_diff']:>+10.2%} "
            f"{abs(r['rel_diff']) * 100:>8.2f}"
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
