#!/usr/bin/env python3
"""
Combine exp-component, rec-component and full-softmax accuracy measurements
into a single table.

For every setup measured in ``accuracy_real.txt`` this script determines:

  * RMSRE of the exp component (looked up in the ``exp_accuracy_*.txt`` files)
  * RMSRE of the rec component (looked up in the ``Rec_*.csv`` files)
  * the measured softmax RMSRE (read directly from ``accuracy_real.txt``)
  * the theoretical softmax RMSRE, computed as
        sqrt( RMSRE(exp)**2 + RMSRE(rec)**2 )
  * the relative difference between the theoretical and the measured softmax
    RMSRE, using the measured value as the base:
        (theoretical - measured) / measured

The result is written to ``softmax_rmsre_combined.csv``.

The lookups are deliberately strict: if a component configuration referenced in
``accuracy_real.txt`` cannot be found (or is ambiguous) in the corresponding
reference file, the script aborts with a clear error instead of silently
emitting a wrong number.
"""

from __future__ import annotations

import csv
import math
import re
import sys
from pathlib import Path
from typing import Dict, Tuple

HERE = Path(__file__).resolve().parent

REAL_FILE = HERE / "accuracy_real.txt"
EXP_FILES = {
    "BIT_HACKING": HERE / "exp_accuracy_bit_hacking.txt",
    "LOOKUP": HERE / "exp_accuracy_lookup.txt",
    "BIPARTITE": HERE / "exp_accuracy_bipartite.txt",
    "SPLITTING": HERE / "exp_accuracy_splittig.txt",  # note: source filename typo
}
REC_LOOKUP_FILE = HERE / "Rec_Lookup_accuracy.csv"
REC_BIPARTITE_FILE = HERE / "Rec_Bipartite_accuracy.csv"

OUTPUT_FILE = HERE / "softmax_rmsre_combined.csv"


# --------------------------------------------------------------------------- #
# Reference-table loaders
# --------------------------------------------------------------------------- #
def load_exp_bit_hacking() -> Dict[Tuple[int, int], float]:
    """exp_bit_hacking: keyed by (A, D). A is written as a float (e.g. 12102203.0)."""
    path = EXP_FILES["BIT_HACKING"]
    text = path.read_text()
    table: Dict[Tuple[int, int], float] = {}
    # e.g. "A=12102203.0 D=1065277304  RMSRE=3.824051e-02"
    pat = re.compile(
        r"A=(?P<A>[\d.]+)\s+D=(?P<D>\d+)\s+RMSRE=(?P<rmsre>[\d.eE+-]+)"
    )
    for m in pat.finditer(text):
        key = (int(float(m.group("A"))), int(m.group("D")))
        table[key] = float(m.group("rmsre"))
    if not table:
        raise ValueError(f"No entries parsed from {path}")
    return table


def load_exp_lookup() -> Dict[Tuple[int, int], float]:
    """exp_lookup: keyed by (AW, WW)."""
    path = EXP_FILES["LOOKUP"]
    text = path.read_text()
    table: Dict[Tuple[int, int], float] = {}
    # e.g. "AW= 8 WW= 8  RMSRE=1.151400e-03"
    pat = re.compile(
        r"AW=\s*(?P<AW>\d+)\s+WW=\s*(?P<WW>\d+)\s+RMSRE=(?P<rmsre>[\d.eE+-]+)"
    )
    for m in pat.finditer(text):
        key = (int(m.group("AW")), int(m.group("WW")))
        table[key] = float(m.group("rmsre"))
    if not table:
        raise ValueError(f"No entries parsed from {path}")
    return table


def _load_exp_a012(path: Path) -> Dict[Tuple[int, int, int, int], float]:
    """exp_bipartite / exp_splitting: keyed by (A0, A1, A2, WW)."""
    text = path.read_text()
    table: Dict[Tuple[int, int, int, int], float] = {}
    # e.g. "A0=2 A1=5 A2=5 WW=15  RMSRE=9.432000e-05"
    pat = re.compile(
        r"A0=(?P<A0>\d+)\s+A1=(?P<A1>\d+)\s+A2=(?P<A2>\d+)\s+WW=(?P<WW>\d+)"
        r"\s+RMSRE=(?P<rmsre>[\d.eE+-]+)"
    )
    for m in pat.finditer(text):
        key = (
            int(m.group("A0")),
            int(m.group("A1")),
            int(m.group("A2")),
            int(m.group("WW")),
        )
        table[key] = float(m.group("rmsre"))
    if not table:
        raise ValueError(f"No entries parsed from {path}")
    return table


def load_rec_lookup() -> Dict[Tuple[int, int, int], float]:
    """Rec_Lookup: keyed by (NUM_NEWTON_STEPS, ADDR_WIDTH, WORD_WIDTH)."""
    path = REC_LOOKUP_FILE
    table: Dict[Tuple[int, int, int], float] = {}
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            key = (
                int(row["NUM_NEWTON_STEPS"]),
                int(row["ADDR_WIDTH"]),
                int(row["WORD_WIDTH"]),
            )
            table[key] = float(row["RMSRE"])
    if not table:
        raise ValueError(f"No entries parsed from {path}")
    return table


def load_rec_bipartite() -> Dict[Tuple[int, int, int, int, int], float]:
    """Rec_Bipartite: keyed by (NEWTON, ADDR_WIDTH_0, ADDR_WIDTH_1, ADDR_WIDTH_2, WORD_WIDTH)."""
    path = REC_BIPARTITE_FILE
    table: Dict[Tuple[int, int, int, int, int], float] = {}
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            key = (
                int(row["NUM_NEWTON_STEPS"]),
                int(row["ADDR_WIDTH_0"]),
                int(row["ADDR_WIDTH_1"]),
                int(row["ADDR_WIDTH_2"]),
                int(row["WORD_WIDTH"]),
            )
            table[key] = float(row["RMSRE"])
    if not table:
        raise ValueError(f"No entries parsed from {path}")
    return table


# --------------------------------------------------------------------------- #
# accuracy_real.txt parsing
# --------------------------------------------------------------------------- #
# Each line looks like:
#   Test (EXP = <exp spec>, REC = <rec spec>, N = 64, SIMD = 2): RMSRE = <val>, ...
#
# We split into the EXP block and the REC block, then parse each block's
# method + parameters.

# The "EXP = ... , REC = ..." region up to the first ", N =".
_LINE_RE = re.compile(
    r"EXP\s*=\s*(?P<exp>.*?),\s*REC\s*=\s*(?P<rec>.*?),\s*N\s*=.*?"
    r"RMSRE\s*=\s*(?P<rmsre>[\d.eE+-]+)"
)

# EXP method specs.
_EXP_BIT_HACKING_RE = re.compile(
    r"BIT_HACKING\s*\[\s*A=(?P<A>\d+)\s*,\s*D=(?P<D>\d+)\s*\]"
)
_EXP_LOOKUP_RE = re.compile(r"LOOKUP\s*\[\s*WW=(?P<WW>\d+)\s*,\s*AW=(?P<AW>\d+)\s*\]")
_EXP_A012_RE = re.compile(
    r"(?P<method>BIPARTITE|SPLITTING)\s*\[\s*WW=(?P<WW>\d+)\s*,\s*"
    r"AW0/1/2=(?P<A0>\d+)/(?P<A1>\d+)/(?P<A2>\d+)\s*\]"
)

# REC method specs.
_REC_LOOKUP_RE = re.compile(
    r"LOOKUP\s*\[\s*NEWTON=(?P<NEWTON>\d+)\s*,\s*WW=(?P<WW>\d+)\s*,\s*AW=(?P<AW>\d+)\s*\]"
)
_REC_BIPARTITE_RE = re.compile(
    r"BIPARTITE\s*\[\s*NEWTON=(?P<NEWTON>\d+)\s*,\s*WW=(?P<WW>\d+)\s*,\s*"
    r"AW0/1/2=(?P<A0>\d+)/(?P<A1>\d+)/(?P<A2>\d+)\s*\]"
)


class LookupError_(Exception):
    """Raised when a component configuration cannot be resolved."""


def resolve_exp(spec: str, tables: dict, line_no: int) -> Tuple[str, float]:
    """Return (canonical_label, rmsre) for an EXP spec string."""
    spec = spec.strip()

    m = _EXP_BIT_HACKING_RE.search(spec)
    if m:
        key = (int(m.group("A")), int(m.group("D")))
        label = f"BIT_HACKING(A={m.group('A')},D={m.group('D')})"
        try:
            return label, tables["exp_bit_hacking"][key]
        except KeyError:
            raise LookupError_(
                f"[line {line_no}] EXP BIT_HACKING config {key} not found in "
                f"{EXP_FILES['BIT_HACKING'].name}"
            )

    m = _EXP_LOOKUP_RE.search(spec)
    if m:
        aw, ww = int(m.group("AW")), int(m.group("WW"))
        key = (aw, ww)
        label = f"LOOKUP(AW={aw},WW={ww})"
        try:
            return label, tables["exp_lookup"][key]
        except KeyError:
            raise LookupError_(
                f"[line {line_no}] EXP LOOKUP config AW={aw},WW={ww} not found in "
                f"{EXP_FILES['LOOKUP'].name}"
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
        try:
            return label, tables[tbl_name][key]
        except KeyError:
            raise LookupError_(
                f"[line {line_no}] EXP {method} config {key} not found in "
                f"reference table '{tbl_name}'"
            )

    raise LookupError_(f"[line {line_no}] could not parse EXP spec: {spec!r}")


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
            raise LookupError_(
                f"[line {line_no}] REC LOOKUP config NEWTON={newton},AW={aw},WW={ww} "
                f"not found in {REC_LOOKUP_FILE.name}"
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
            raise LookupError_(
                f"[line {line_no}] REC BIPARTITE config "
                f"NEWTON={newton},AW0/1/2={a0}/{a1}/{a2},WW={ww} "
                f"not found in {REC_BIPARTITE_FILE.name}"
            )

    raise LookupError_(f"[line {line_no}] could not parse REC spec: {spec!r}")


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
def main() -> int:
    tables = {
        "exp_bit_hacking": load_exp_bit_hacking(),
        "exp_lookup": load_exp_lookup(),
        "exp_bipartite": _load_exp_a012(EXP_FILES["BIPARTITE"]),
        "exp_splitting": _load_exp_a012(EXP_FILES["SPLITTING"]),
        "rec_lookup": load_rec_lookup(),
        "rec_bipartite": load_rec_bipartite(),
    }

    rows = []
    errors = []
    real_text = REAL_FILE.read_text()

    for line_no, raw in enumerate(real_text.splitlines(), start=1):
        line = raw.strip()
        if not line or not line.startswith("Test"):
            continue

        m = _LINE_RE.search(line)
        if not m:
            errors.append(f"[line {line_no}] could not parse Test line: {line!r}")
            continue

        exp_spec = m.group("exp")
        rec_spec = m.group("rec")
        measured = float(m.group("rmsre"))

        try:
            exp_label, exp_rmsre = resolve_exp(exp_spec, tables, line_no)
            rec_label, rec_rmsre = resolve_rec(rec_spec, tables, line_no)
        except LookupError_ as exc:
            errors.append(str(exc))
            continue

        theoretical = math.sqrt(exp_rmsre**2 + rec_rmsre**2)
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

    fieldnames = [
        "exp_method",
        "rec_method",
        "rmsre_exp",
        "rmsre_rec",
        "rmsre_softmax_measured",
        "rmsre_softmax_theoretical",
        "rel_diff",
        "rel_diff_abs_pct",
    ]
    with OUTPUT_FILE.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
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
                    "rel_diff_abs_pct": f"{abs(r['rel_diff']) * 100:.2f}%",
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
