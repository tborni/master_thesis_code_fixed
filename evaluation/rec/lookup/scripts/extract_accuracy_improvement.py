#!/usr/bin/env python3
"""Tabulate the RMSRE improvement of the tuned coefficient over ``C = 2``.

Two ``rec_lookup`` accuracy sweeps describe the same ``(AW, WW)`` grid at one
Newton step (``NS=1``) but differ in how the correction coefficient is chosen:

* the *baseline* sweep (``accuracy_newton_2_width_sweep.txt``) pins the
  coefficient to the nominal ``C = 2`` for every configuration;
* the *optimized* sweep (the ``NS=1`` rows of ``accuracy.txt``) uses the
  per-configuration coefficient found by the tuning heuristic (``C`` a hair
  above 2, e.g. ``C=2.000023``).

Both reports share the one-measurement-per-line format parsed elsewhere::

    rec_lookup accuracy sweep
      NUM_SAMPLES      = 10000
      NS=1 AW= 6 WW= 6 C=2.000000  RMSRE=3.517505e-05  max_rel_error=1.257560e-04  at x=...

This script joins the two sweeps on their ``(NS, AW, WW)`` configuration and, for
each configuration, computes the *relative improvement* of the RMSRE::

    improvement% = (RMSRE_baseline - RMSRE_optimized) / RMSRE_baseline * 100

A positive value means the tuned coefficient shrinks the RMSRE (the expected
direction); a negative value means it grew. The result is written to a CSV with
the columns::

    NUM_NEWTON_STEPS, ADDR_WIDTH, WORD_WIDTH,
    RMSRE_C2, RMSRE_OPT, C_OPT, RMSRE_IMPROVEMENT_PCT

``RMSRE_C2``/``RMSRE_OPT`` are kept so the percentage can be audited against the
inputs, and ``C_OPT`` records which tuned coefficient produced ``RMSRE_OPT``; the
plotting tool that consumes the CSV reads only the improvement column.

The *baseline* sweep defines the grid of configurations to report; the optimized
report may legitimately carry more (``accuracy.txt`` also holds the ``NS=0``
sweep), and those extra configurations are ignored. Because a per-configuration
comparison needs a match on both sides, the parser aborts (naming the offenders)
if any baseline configuration is absent from the optimized report, rather than
silently dropping cells. Lines that do not match the expected measurement format
(the header, blank lines, comments, ...) are skipped and reported on stderr.
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

DEFAULT_BASELINE = DATA_DIR / "accuracy_newton_2_width_sweep.txt"
DEFAULT_OPTIMIZED = DATA_DIR / "accuracy.txt"
DEFAULT_OUTPUT = DATA_DIR / "accuracy_newton_improvement.csv"

CSV_HEADER = (
    "NUM_NEWTON_STEPS",
    "ADDR_WIDTH",
    "WORD_WIDTH",
    "RMSRE_C2",
    "RMSRE_OPT",
    "C_OPT",
    "RMSRE_IMPROVEMENT_PCT",
)

# A float in scientific or plain notation, as emitted by the sweep.
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"

# One regex captures every field of interest in a single measurement line. The
# integer fields are right-aligned in the report (e.g. ``AW= 6``), so ``\s*``
# absorbs the padding between the ``=`` and the digits. Anchoring on ``NS=``
# means the header lines never match. The ``at x=...`` tail is left uncaptured.
LINE_RE = re.compile(
    r"NS\s*=\s*(?P<newton>\d+)\s+"
    r"AW\s*=\s*(?P<addr>\d+)\s+"
    r"WW\s*=\s*(?P<word>\d+)\s+"
    rf"C\s*=\s*(?P<c>{_FLOAT})\s+"
    rf"RMSRE\s*=\s*(?P<rmsre>{_FLOAT})\s+"
    rf"max_rel_error\s*=\s*(?P<max_rel>{_FLOAT})"
)

# The (NS, AW, WW) triple identifying one configuration; the join key below.
Config = tuple[int, int, int]


@dataclass(frozen=True)
class SweepRecord:
    """A single parsed accuracy measurement.

    ``config`` is the ``(NS, AW, WW)`` triple the measurement was taken at; it is
    the key on which the baseline and optimized sweeps are joined.
    """

    config: Config
    c: float
    rmsre: float
    max_rel_error: float


@dataclass(frozen=True)
class ImprovementRecord:
    """The RMSRE comparison for one ``(NS, AW, WW)`` configuration."""

    config: Config
    rmsre_c2: float
    rmsre_opt: float
    c_opt: float
    improvement_pct: float


def parse_line(line: str) -> SweepRecord | None:
    """Parse a single report line into a :class:`SweepRecord`.

    Returns ``None`` when the line does not contain a valid measurement.
    """
    match = LINE_RE.search(line)
    if match is None:
        return None
    return SweepRecord(
        config=(int(match["newton"]), int(match["addr"]), int(match["word"])),
        c=float(match["c"]),
        rmsre=float(match["rmsre"]),
        max_rel_error=float(match["max_rel"]),
    )


def parse_report(lines: Iterable[str], source: str) -> list[SweepRecord]:
    """Parse every measurement line in ``lines`` into :class:`SweepRecord` s.

    Unparsable, non-blank lines are reported on stderr (tagged with ``source`` so
    the two inputs can be told apart) and skipped. Preserves the report's order.
    """
    records: list[SweepRecord] = []
    for lineno, line in enumerate(lines, start=1):
        record = parse_line(line)
        if record is not None:
            records.append(record)
        elif line.strip():
            print(
                f"warning: skipping unparsable line {lineno} in {source}: {line.rstrip()}",
                file=sys.stderr,
            )
    return records


def index_by_config(records: Iterable[SweepRecord], source: str) -> dict[Config, SweepRecord]:
    """Index ``records`` by their ``(NS, AW, WW)`` configuration.

    Raises ``ValueError`` (naming the offender) if a configuration appears more
    than once, since a duplicate makes the comparison for that cell ambiguous.
    """
    by_config: dict[Config, SweepRecord] = {}
    for record in records:
        if record.config in by_config:
            ns, aw, ww = record.config
            raise ValueError(
                f"duplicate configuration NS={ns} AW={aw} WW={ww} in {source}"
            )
        by_config[record.config] = record
    return by_config


def compute_improvements(
    baseline: dict[Config, SweepRecord],
    optimized: dict[Config, SweepRecord],
) -> list[ImprovementRecord]:
    """Join ``baseline`` and ``optimized`` on config and rate the RMSRE change.

    The *baseline* sweep defines the grid of configurations to report; every one
    of its configurations must have a match in ``optimized``. Configurations that
    appear only in ``optimized`` are ignored, since the tuned report legitimately
    carries extra rows the baseline does not (e.g. accuracy.txt also holds the
    ``NS=0`` sweep). A baseline configuration with no optimized counterpart raises
    ``ValueError`` (naming the offenders) so a partial overlap fails loudly
    instead of silently dropping cells; a zero baseline RMSRE (no division
    possible) is likewise an error.

    Records are returned sorted by ``(NS, AW, WW)`` — ascending in Newton steps,
    then address width, then word width — matching the ordering of the other
    extracted tables.
    """
    missing = set(baseline) - set(optimized)
    if missing:
        formatted = ", ".join(
            f"NS={ns} AW={aw} WW={ww}" for ns, aw, ww in sorted(missing)
        )
        raise ValueError(
            "the optimized sweep is missing configurations present in the "
            f"baseline sweep: {formatted}"
        )

    improvements: list[ImprovementRecord] = []
    for config in sorted(baseline):
        base = baseline[config]
        opt = optimized[config]
        if base.rmsre == 0.0:
            ns, aw, ww = config
            raise ValueError(
                f"baseline RMSRE is zero for NS={ns} AW={aw} WW={ww}; "
                "cannot express a relative improvement"
            )
        improvement_pct = (base.rmsre - opt.rmsre) / base.rmsre * 100.0
        improvements.append(
            ImprovementRecord(
                config=config,
                rmsre_c2=base.rmsre,
                rmsre_opt=opt.rmsre,
                c_opt=opt.c,
                improvement_pct=improvement_pct,
            )
        )
    return improvements


def write_csv(records: Iterable[ImprovementRecord], output_path: Path) -> int:
    """Write ``records`` to ``output_path`` as CSV and return the row count."""
    count = 0
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(CSV_HEADER)
        for record in records:
            ns, aw, ww = record.config
            writer.writerow(
                (
                    ns,
                    aw,
                    ww,
                    record.rmsre_c2,
                    record.rmsre_opt,
                    record.c_opt,
                    record.improvement_pct,
                )
            )
            count += 1
    return count


def load_sweep(path: Path, source: str) -> dict[Config, SweepRecord]:
    """Read and index one sweep report, returning ``{config: record}``.

    Raises ``ValueError`` if the file yields no parsable measurement, matching the
    "fail loudly on empty input" behaviour of the other extractors.
    """
    with path.open("r", encoding="utf-8") as handle:
        records = parse_report(handle, source)
    if not records:
        raise ValueError(f"no valid records parsed from {path}")
    return index_by_config(records, source)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-b",
        "--baseline",
        type=Path,
        default=DEFAULT_BASELINE,
        help=f"path to the C=2 baseline sweep (default: {DEFAULT_BASELINE})",
    )
    parser.add_argument(
        "-t",
        "--optimized",
        type=Path,
        default=DEFAULT_OPTIMIZED,
        help=f"path to the tuned-coefficient sweep (default: {DEFAULT_OPTIMIZED})",
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

    for path in (args.baseline, args.optimized):
        if not path.is_file():
            print(f"error: input file not found: {path}", file=sys.stderr)
            return 1

    try:
        # The baseline sweep pins the (NS, AW, WW) grid to report; the optimized
        # report may span more (accuracy.txt also carries the NS=0 sweep), and
        # compute_improvements ignores those extra configurations.
        baseline = load_sweep(args.baseline, "baseline")
        optimized = load_sweep(args.optimized, "optimized")
        improvements = compute_improvements(baseline, optimized)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    count = write_csv(improvements, args.output)
    print(f"Wrote {count} records to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
