#!/usr/bin/env python3
"""Parse the rec_bipartite accuracy report into a tidy CSV.

The bipartite design sweeps three address widths (one per table) plus the shared
word width, so every measurement carries five configuration parameters. The
rec_bipartite sweep additionally emits a correction coefficient ``C`` between the
word width and the error metrics. Two line formats appear across the various
bipartite reports and both are accepted:

Compact sweep format (``accuracy.txt``, ``accuracy_aw_sweep.txt``, ...)::

    NS=0 A0=3 A1=4 A2=4 WW=14 C=2.000000  RMSRE=1.330765e-04  max_rel_error=5.623835e-04  at x=6.87e+10  (dut=..., ref=...)

Verbose "Test (...)" format (as produced by the rsqrt lookup harness, accepted
for cross-compatibility)::

    Test (Newton = 0, ADDR_0 = 5, ADDR_1 = 5, ADDR_2 = 5, WORD = 20): RMSRE = 0.0000032932, MAX_REL_ERROR = 0.0000121402, WORST_INPUT = ...

Both are parsed into the columns::

    NUM_NEWTON_STEPS, ADDR_WIDTH_0, ADDR_WIDTH_1, ADDR_WIDTH_2, WORD_WIDTH, C, RMSRE, MAX_REL_ERROR

The ``C`` column is preserved so no information from the report is lost; the
plotting tools that consume the CSV simply ignore it, and it is left empty for
lines (such as the verbose format) that carry no coefficient. This mirrors the
rec_lookup extractor but with the bipartite design's three address widths. Lines
that do not match either format (headers, blank lines, comments, ...) are skipped
and reported on stderr.
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
    "ADDR_WIDTH_0",
    "ADDR_WIDTH_1",
    "ADDR_WIDTH_2",
    "WORD_WIDTH",
    "C",
    "RMSRE",
    "MAX_REL_ERROR",
)

# A float, possibly in scientific notation, reused for the coefficient and both
# metric fields.
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"

# Two regexes, one per report format. Each captures the five integer
# configuration fields and the two metric fields under the same group names, so
# downstream handling is identical regardless of which format matched. The
# coefficient ``C`` group is optional: the rec_bipartite sweep always emits it,
# but the verbose format (and other bipartite reports) may not, in which case the
# ``c`` group is ``None`` and the column is left empty.
#
# Compact sweep format:
#   "NS=0 A0=3 A1=4 A2=4 WW=14 C=2.000000  RMSRE=...  max_rel_error=..."
COMPACT_RE = re.compile(
    r"NS\s*=\s*(?P<newton>\d+)\s+"
    r"A0\s*=\s*(?P<addr0>\d+)\s+"
    r"A1\s*=\s*(?P<addr1>\d+)\s+"
    r"A2\s*=\s*(?P<addr2>\d+)\s+"
    r"WW\s*=\s*(?P<word>\d+)\s+"
    r"(?:C\s*=\s*(?P<c>" + _FLOAT + r")\s+)?"
    r"RMSRE\s*=\s*(?P<rmsre>" + _FLOAT + r").*?"
    r"max_rel_error\s*=\s*(?P<max_rel>" + _FLOAT + r")",
    re.IGNORECASE,
)

# Verbose format: "Test (Newton = 0, ADDR_0 = 5, ...): RMSRE = ..., MAX_REL_ERROR = ..."
VERBOSE_RE = re.compile(
    r"Newton\s*=\s*(?P<newton>\d+).*?"
    r"ADDR_0\s*=\s*(?P<addr0>\d+).*?"
    r"ADDR_1\s*=\s*(?P<addr1>\d+).*?"
    r"ADDR_2\s*=\s*(?P<addr2>\d+).*?"
    r"WORD\s*=\s*(?P<word>\d+).*?"
    r"(?:C\s*=\s*(?P<c>" + _FLOAT + r").*?)?"
    r"RMSRE\s*=\s*(?P<rmsre>" + _FLOAT + r").*?"
    r"MAX_REL_ERROR\s*=\s*(?P<max_rel>" + _FLOAT + r")",
    re.IGNORECASE,
)

LINE_PATTERNS = (COMPACT_RE, VERBOSE_RE)


@dataclass(frozen=True)
class AccuracyRecord:
    """A single parsed accuracy measurement.

    ``c`` is the correction coefficient reported by the rec_bipartite sweep. It
    is ``None`` for report formats that do not carry it, which serializes to an
    empty CSV cell.
    """

    num_newton_steps: int
    addr_width_0: int
    addr_width_1: int
    addr_width_2: int
    word_width: int
    c: float | None
    rmsre: float
    max_rel_error: float


def parse_line(line: str) -> AccuracyRecord | None:
    """Parse a single report line into an :class:`AccuracyRecord`.

    Tries each supported line format in turn. Returns ``None`` when the line
    matches none of them (i.e. it carries no measurement).
    """
    for pattern in LINE_PATTERNS:
        match = pattern.search(line)
        if match is not None:
            coeff = match["c"]
            return AccuracyRecord(
                num_newton_steps=int(match["newton"]),
                addr_width_0=int(match["addr0"]),
                addr_width_1=int(match["addr1"]),
                addr_width_2=int(match["addr2"]),
                word_width=int(match["word"]),
                c=float(coeff) if coeff is not None else None,
                rmsre=float(match["rmsre"]),
                max_rel_error=float(match["max_rel"]),
            )
    return None


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
    parser.add_argument(
        "--reverse",
        action="store_true",
        help=(
            "emit rows in reverse of the report order (last line first); "
            "the default preserves the report's own ordering"
        ),
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    if not args.input.is_file():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return 1

    with args.input.open("r", encoding="utf-8") as handle:
        records = list(parse_report(handle))

    # Preserve the report's ordering by default: the bipartite sweep is already
    # written in ascending order (Newton steps, then address widths). Use
    # --reverse for reports written last-config-first.
    if args.reverse:
        records.reverse()

    if not records:
        print(f"error: no valid records parsed from {args.input}", file=sys.stderr)
        return 1

    count = write_csv(records, args.output)
    print(f"Wrote {count} records to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
