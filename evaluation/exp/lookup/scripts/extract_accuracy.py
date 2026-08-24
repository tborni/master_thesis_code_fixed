#!/usr/bin/env python3
"""Parse the exp_lookup accuracy report into a tidy CSV.

The lookup design sweeps the table address width and the shared word width, so
every measurement carries two configuration parameters. Unlike the rsqrt lookup
variant this was adapted from, there is no Newton-refinement stage, so the report
lines carry no ``Newton =`` field. A measurement line looks like::

    AW= 6 WW= 6  RMSRE=4.440618e-03  max_rel_error=1.233381e-02  at x=-77.5893021  (dut=..., ref=...)

Optional whitespace around the ``=`` and leading indentation are tolerated (the
sweep report indents its rows and pads single-digit widths), and matching is
anchored on the ``AW=`` field so the surrounding preamble (``NUM_SAMPLES``,
``EXCLUDE_POS``, ...) and the trailing ``at x=... (dut=..., ref=...)``
diagnostics are ignored.

Lines are parsed into the columns::

    ADDR_WIDTH, WORD_WIDTH, RMSRE, MAX_REL_ERROR

which mirror the address/word-width columns of this experiment's
``resources.csv``. Lines that do not match (headers, blank lines, comments, ...)
are skipped and reported on stderr.
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

CSV_HEADER = ("ADDR_WIDTH", "WORD_WIDTH", "RMSRE", "MAX_REL_ERROR")

# A float, possibly in scientific notation, reused for both metric fields.
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"

# One regex captures every field of interest in a single line. Integer fields
# use \d+; the metrics are parsed as floats to tolerate scientific notation or a
# varying number of decimals. ``.*?`` between metrics skips the intervening
# whitespace and tolerates the trailing "at x=... (dut=..., ref=...)" diagnostics,
# which we do not capture.
LINE_RE = re.compile(
    r"AW\s*=\s*(?P<addr>\d+)\s+"
    r"WW\s*=\s*(?P<word>\d+)\s+"
    r"RMSRE\s*=\s*(?P<rmsre>" + _FLOAT + r").*?"
    r"max_rel_error\s*=\s*(?P<max_rel>" + _FLOAT + r")",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class AccuracyRecord:
    """A single parsed accuracy measurement."""

    addr_width: int
    word_width: int
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
        addr_width=int(match["addr"]),
        word_width=int(match["word"]),
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

    # Preserve the report's ordering by default: the sweep is already written in
    # ascending order (address width, then word width). Use --reverse for reports
    # written last-config-first.
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
