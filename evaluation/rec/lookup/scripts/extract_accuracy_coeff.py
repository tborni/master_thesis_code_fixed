#!/usr/bin/env python3
"""Extract the rec_lookup correction-coefficient sweep into a tidy CSV.

The coefficient sweep report (``accuracy_newton_coeff_sweep_large.txt``) opens
with a short header and then holds one test result per line, e.g.::

    rec_lookup accuracy sweep
      NUM_SAMPLES      = 10000
      NS=1 AW= 6 WW= 6 C=2.000000  RMSRE=3.396326e-05  max_rel_error=1.258487e-04  at x=1215.98303  (dut=0.000822276401, ref=0.000822379896)
      NS=1 AW= 6 WW= 6 C=2.000001  RMSRE=3.334458e-05  max_rel_error=1.248578e-04  at x=1215.98303  (dut=0.000822277216, ref=0.000822379896)

Unlike the ``addr_width``/``word_width`` sweep parsed by ``extract_accuracy.py``,
here the configuration (``NS`` Newton steps, ``AW`` address width, ``WW`` word
width) is held fixed and only the correction coefficient ``C`` is varied. Each
line therefore contributes one ``(C, RMSRE, max_rel_error)`` point.

This script writes just those three columns to a CSV::

    C, RMSRE, MAX_REL_ERROR

The trailing ``at x=... (dut=..., ref=...)`` field describes the worst-case
input and is not extracted. Lines that do not match the expected measurement
format (the header, blank lines, comments, ...) are skipped and reported on
stderr.

Because a C-only table is only meaningful when every row shares the same
NS/AW/WW configuration, the parser records the configuration of each line and
aborts if more than one distinct configuration is present, rather than silently
collapsing several sweeps into ambiguous rows.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

# Project root is the parent of this script's directory (scripts/), used to build
# sensible default paths so the tool works regardless of the current working
# directory. Input and output data both live under data/.
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"

DEFAULT_INPUT = DATA_DIR / "accuracy_newton_coeff_sweep_large.txt"
DEFAULT_OUTPUT = DATA_DIR / "accuracy_newton_coeff.csv"

CSV_HEADER = ("C", "RMSRE", "MAX_REL_ERROR")

# A float in scientific or plain notation, as emitted by the sweep.
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"

# One regex captures every field of interest in a single measurement line. The
# integer fields are right-aligned in the report (e.g. ``AW= 6``), so ``\s*``
# absorbs the padding between the ``=`` and the digits. Anchoring on ``NS=``
# means the header lines never match. The NS/AW/WW config is captured so we can
# assert the sweep varies only C; the ``at x=...`` tail is left uncaptured.
LINE_RE = re.compile(
    r"NS\s*=\s*(?P<newton>\d+)\s+"
    r"AW\s*=\s*(?P<addr>\d+)\s+"
    r"WW\s*=\s*(?P<word>\d+)\s+"
    rf"C\s*=\s*(?P<c>{_FLOAT})\s+"
    rf"RMSRE\s*=\s*(?P<rmsre>{_FLOAT})\s+"
    rf"max_rel_error\s*=\s*(?P<max_rel>{_FLOAT})"
)


@dataclass(frozen=True)
class CoeffRecord:
    """A single parsed coefficient-sweep measurement.

    ``config`` is the ``(NS, AW, WW)`` triple the measurement was taken at; it is
    used to verify the sweep holds the configuration fixed and is not written to
    the output CSV.
    """

    config: tuple[int, int, int]
    c: float
    rmsre: float
    max_rel_error: float


def parse_line(line: str) -> CoeffRecord | None:
    """Parse a single report line into a :class:`CoeffRecord`.

    Returns ``None`` when the line does not contain a valid measurement.
    """
    match = LINE_RE.search(line)
    if match is None:
        return None
    return CoeffRecord(
        config=(int(match["newton"]), int(match["addr"]), int(match["word"])),
        c=float(match["c"]),
        rmsre=float(match["rmsre"]),
        max_rel_error=float(match["max_rel"]),
    )


def parse_report(lines: Iterable[str]) -> list[CoeffRecord]:
    """Parse every measurement line in ``lines`` into :class:`CoeffRecord` s.

    Unparsable, non-blank lines are reported on stderr and skipped. Preserves the
    report's own (ascending-C) order.
    """
    records: list[CoeffRecord] = []
    for lineno, line in enumerate(lines, start=1):
        record = parse_line(line)
        if record is not None:
            records.append(record)
        elif line.strip():
            print(f"warning: skipping unparsable line {lineno}: {line.rstrip()}", file=sys.stderr)
    return records


def check_single_configuration(records: Iterable[CoeffRecord]) -> tuple[int, int, int]:
    """Return the single ``(NS, AW, WW)`` config shared by all ``records``.

    A coefficient sweep is only meaningful as a ``(C, RMSRE, MAX_REL_ERROR)``
    table when every row was measured at the same NS/AW/WW. Raise ``ValueError``
    (naming the offenders) if that is not the case, so a mixed file fails loudly
    instead of producing rows that silently mix configurations.
    """
    configs = {record.config for record in records}
    if len(configs) != 1:
        formatted = ", ".join(
            f"NS={ns} AW={aw} WW={ww}" for ns, aw, ww in sorted(configs)
        )
        raise ValueError(
            "expected a sweep over C at a single (NS, AW, WW) configuration, "
            f"but found {len(configs)}: {formatted}"
        )
    return next(iter(configs))


def write_csv(records: Iterable[CoeffRecord], output_path: Path) -> int:
    """Write ``records`` to ``output_path`` as CSV and return the row count."""
    count = 0
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(CSV_HEADER)
        for record in records:
            writer.writerow((record.c, record.rmsre, record.max_rel_error))
            count += 1
    return count


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-i",
        "--input",
        type=Path,
        default=DEFAULT_INPUT,
        help=f"path to the coefficient-sweep report (default: {DEFAULT_INPUT})",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"path to the output CSV (default: {DEFAULT_OUTPUT})",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    if not args.input.is_file():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return 1

    with args.input.open("r", encoding="utf-8") as handle:
        # Preserve the report's own order (ascending in C), matching the sweep.
        records = parse_report(handle)

    if not records:
        print(f"error: no valid records parsed from {args.input}", file=sys.stderr)
        return 1

    try:
        ns, aw, ww = check_single_configuration(records)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    count = write_csv(records, args.output)
    print(f"Wrote {count} records (NS={ns} AW={aw} WW={ww}) to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
