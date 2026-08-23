#!/usr/bin/env python3
"""Parse the rsqrt bit-hacking accuracy report into a tidy CSV.

The accuracy report (``accuracy.txt``) contains one test result per line, e.g.::

    Test (Newton = 2, II = 1): RMSRE = 0.0000024736, MAX_REL_ERROR = 0.0000046852, WORST_INPUT = 54731788220514779689800510360170528768.0000000000000000000000000

Unlike the lookup variant, the bit-hacking design has no address/word-width
sweep, so the only configuration parameter is the number of Newton steps. This
script extracts it together with the error metrics from every such line and
writes them to a CSV with the columns::

    NUM_NEWTON_STEPS, RMSRE, MAX_REL_ERROR

Lines that do not match the expected format (blank lines, comments, ...) are
skipped and reported on stderr.
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

CSV_HEADER = ("NUM_NEWTON_STEPS", "RMSRE", "MAX_REL_ERROR")

# One regex captures every field of interest in a single line. The integer field
# uses \d+; the metrics are parsed as floats to tolerate scientific notation or a
# varying number of decimals.
LINE_RE = re.compile(
    r"Newton\s*=\s*(?P<newton>\d+).*?"
    r"RMSRE\s*=\s*(?P<rmsre>[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?).*?"
    r"MAX_REL_ERROR\s*=\s*(?P<max_rel>[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)"
)


@dataclass(frozen=True)
class AccuracyRecord:
    """A single parsed accuracy measurement."""

    num_newton_steps: int
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
        records = list(parse_report(handle))

    # Emit rows in reverse of the report order (last line first), which orders
    # the sweep by ascending Newton steps.
    records.reverse()

    if not records:
        print(f"error: no valid records parsed from {args.input}", file=sys.stderr)
        return 1

    count = write_csv(records, args.output)
    print(f"Wrote {count} records to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
