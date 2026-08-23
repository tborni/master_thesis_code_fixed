#!/usr/bin/env python3
"""Parse the rec_lookup accuracy sweep into a tidy CSV.

The accuracy report (``accuracy.txt``) opens with a short header and then holds
one test result per line, e.g.::

    rec_lookup accuracy sweep
      NUM_SAMPLES      = 10000
      NS=0 AW= 6 WW= 6 C=2.000000  RMSRE=4.814353e-03  max_rel_error=1.121214e-02  at x=223227.953  (dut=4.529953e-06, ref=4.47972571e-06)

Each measurement line encodes the configuration (``NS`` Newton steps, ``AW``
address width, ``WW`` word width, ``C`` correction coefficient) followed by the
error metrics (``RMSRE``, ``max_rel_error``). The trailing ``at x=... (dut=...,
ref=...)`` describes the worst-case input and is not extracted.

This script writes the configuration parameters and error metrics of every such
line to a CSV with the columns::

    NUM_NEWTON_STEPS, ADDR_WIDTH, WORD_WIDTH, C, RMSRE, MAX_REL_ERROR

The ``C`` column is preserved so no information from the report is lost; the
plotting tools that consume the CSV simply ignore it. Lines that do not match
the expected format (the header, blank lines, comments, ...) are skipped and
reported on stderr.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import astuple, dataclass
from pathlib import Path
from typing import Iterable, Iterator

# Project root is the parent of this script's directory (scripts/), used to build
# sensible default paths so the tool works regardless of the current working
# directory. Input and output data both live under data/.
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"

DEFAULT_INPUT = DATA_DIR / "accuracy.txt"
DEFAULT_OUTPUT = DATA_DIR / "accuracy.csv"

CSV_HEADER = (
    "NUM_NEWTON_STEPS",
    "ADDR_WIDTH",
    "WORD_WIDTH",
    "C",
    "RMSRE",
    "MAX_REL_ERROR",
)

# A float in scientific or plain notation, as emitted by the sweep.
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"

# One regex captures every field of interest in a single measurement line. The
# integer fields are right-aligned in the report (e.g. ``AW= 6``), so ``\s*``
# absorbs the padding between the ``=`` and the digits. Anchoring on ``NS=``
# means the header lines never match. The ``at x=...`` tail is deliberately left
# uncaptured.
LINE_RE = re.compile(
    r"NS\s*=\s*(?P<newton>\d+)\s+"
    r"AW\s*=\s*(?P<addr>\d+)\s+"
    r"WW\s*=\s*(?P<word>\d+)\s+"
    rf"C\s*=\s*(?P<c>{_FLOAT})\s+"
    rf"RMSRE\s*=\s*(?P<rmsre>{_FLOAT})\s+"
    rf"max_rel_error\s*=\s*(?P<max_rel>{_FLOAT})"
)


@dataclass(frozen=True)
class AccuracyRecord:
    """A single parsed accuracy measurement."""

    num_newton_steps: int
    addr_width: int
    word_width: int
    c: float
    rmsre: float
    max_rel_error: float


def parse_line(line: str) -> AccuracyRecord | None:
    """Parse a single report line into an :class:`AccuracyRecord`.

    Returns ``None`` when the line does not contain a valid measurement.
    """
    match = LINE_RE.search(line)
    if match is None:
        return None
    return AccuracyRecord(
        num_newton_steps=int(match["newton"]),
        addr_width=int(match["addr"]),
        word_width=int(match["word"]),
        c=float(match["c"]),
        rmsre=float(match["rmsre"]),
        max_rel_error=float(match["max_rel"]),
    )


def parse_report(lines: Iterable[str]) -> Iterator[AccuracyRecord]:
    """Yield an :class:`AccuracyRecord` for every parsable line in ``lines``.

    Unparsable, non-blank lines are reported on stderr and skipped.
    """
    for lineno, line in enumerate(lines, start=1):
        record = parse_line(line)
        if record is not None:
            yield record
        elif line.strip():
            print(f"warning: skipping unparsable line {lineno}: {line.rstrip()}", file=sys.stderr)


def write_csv(records: Iterable[AccuracyRecord], output_path: Path) -> int:
    """Write ``records`` to ``output_path`` as CSV and return the row count."""
    count = 0
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(CSV_HEADER)
        for record in records:
            writer.writerow(astuple(record))
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
        help=f"path to the accuracy report (default: {DEFAULT_INPUT})",
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
        # Preserve the report's own order (ascending in NS, then AW, then WW),
        # which mirrors the row order of resources.csv.
        records = list(parse_report(handle))

    if not records:
        print(f"error: no valid records parsed from {args.input}", file=sys.stderr)
        return 1

    count = write_csv(records, args.output)
    print(f"Wrote {count} records to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
