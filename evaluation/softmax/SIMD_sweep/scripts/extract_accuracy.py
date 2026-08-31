#!/usr/bin/env python3
"""Parse a Softmax SIMD-sweep accuracy report into a tidy CSV.

The SIMD-sweep varies the Softmax SIMD unroll width; the accuracy reports sample
it across a small grid of vector lengths ``N`` as well (``N`` = 4, 8, 16, 32 with
``SIMD`` = 1, 2, 4). Two reports are produced per sweep, distinguished by the
magnitude of the reference error they were measured against (a ``large_error``
and a ``small_error`` configuration). Every measurement line looks like::

    Test (N = 4, SIMD = 1): RMSRE = 0.0001731135, MAX_REL_ERROR = 0.0006150508, WORST_INPUT = 2.7865288257598876953125000 (elements = 32708)

This script extracts the sweep parameters and the two error metrics from every
such line and writes them to a CSV with the columns::

    N, SIMD, RMSRE, MAX_REL_ERROR

Both the ``N`` and ``SIMD`` columns are kept (unlike a pure single-parameter
sweep) because the accuracy reports vary both. The trailing ``WORST_INPUT`` /
``elements`` diagnostics describe the worst-case input and sample count and are
not extracted. Lines that do not match the expected format (blank lines,
comments, ...) are skipped and reported on stderr.

There is one report per error-magnitude configuration, so the Makefile invokes
this tool once per file with matching ``--input`` / ``--output`` paths (e.g.
``accuracy_large_error.txt`` -> ``accuracy_large_error.csv``).
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

DEFAULT_INPUT = DATA_DIR / "accuracy_large_error.txt"
DEFAULT_OUTPUT = DATA_DIR / "accuracy_large_error.csv"

CSV_HEADER = ("N", "SIMD", "RMSRE", "MAX_REL_ERROR")

# A float, possibly in scientific notation, reused for both metric fields.
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"

# One regex captures every field of interest in a single line. The integer
# sweep parameters use \d+; the metrics are parsed as floats to tolerate
# scientific notation or a varying number of decimals. ``.*?`` between fields
# skips intervening text and tolerates the trailing
# ``WORST_INPUT = ... (elements = ...)`` diagnostics, which we do not capture.
LINE_RE = re.compile(
    r"N\s*=\s*(?P<n>\d+)\s*,\s*"
    r"SIMD\s*=\s*(?P<simd>\d+).*?"
    r"RMSRE\s*=\s*(?P<rmsre>" + _FLOAT + r").*?"
    r"MAX_REL_ERROR\s*=\s*(?P<max_rel>" + _FLOAT + r")",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class AccuracyRecord:
    """A single parsed accuracy measurement."""

    n: int
    simd: int
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
        n=int(match["n"]),
        simd=int(match["simd"]),
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

    # Preserve the report's own ordering: the sweep is already written grouped by
    # ascending N then SIMD, which is the natural order for the downstream CSV.
    if not records:
        print(f"error: no valid records parsed from {args.input}", file=sys.stderr)
        return 1

    count = write_csv(records, args.output)
    print(f"Wrote {count} records to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
