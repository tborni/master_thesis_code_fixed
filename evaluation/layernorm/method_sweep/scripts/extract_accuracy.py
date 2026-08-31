#!/usr/bin/env python3
"""Turn the full-LayerNorm accuracy reports into tidy per-method CSVs.

Each candidate InvSqrt method contributes one text report under
``data/accuracy_layerorm/<method>.txt`` whose lines look like ::

    Test (METHOD = BIPARTITE, NEWTON = 0 [WORD_WIDTH = 12, ADDR_WIDTH_0/1/2 = 2/3/3], N = 64, SIMD = 2): RMSRE = 0.0005330810, MAX_REL_ERROR = 0.0016477636, WORST_INPUT = 32376.585 (elements = 32551)

The four methods share a common ``... N, SIMD): RMSRE, MAX_REL_ERROR,
WORST_INPUT (elements)`` tail but differ in the per-method parameter block
inside the brackets, so each method is parsed by its own line regex:

    bipartite     WORD_WIDTH + ADDR_WIDTH_0/1/2
    lookup        WORD_WIDTH + ADDR_WIDTH
    bit_hacking   MAGIC (hex constant)
    ip_core       no parameters

The emitted CSVs carry exactly the parameter columns of the matching
``data/resources/<method>.csv`` file (so the two can later be inner-joined by
``generate_combined.py``) followed by the metric columns
``RMSRE, MAX_REL_ERROR, WORST_INPUT``.  These parameter names also line up
(after case-folding) with ``data/accuracy_invsqrt/<method>.csv`` so that
``compare_accuracy.py`` can join the full-LayerNorm RMSRE against the
InvSqrt-only RMSRE.

Run without arguments to convert every method; ``--input``/``--output`` convert
a single report.  Unparsable non-blank lines are warned about on stderr and the
exit code is non-zero if anything could not be parsed.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass, fields
from pathlib import Path

# --- Paths -----------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent          # scripts/
PROJECT_ROOT = SCRIPT_DIR.parent                      # method_sweep/
DATA_DIR = PROJECT_ROOT / "data"
# Note: the source folder name is spelled "accuracy_layerorm" in the dataset;
# we read from it verbatim but write to a correctly-spelled sibling folder.
IN_DIR = DATA_DIR / "accuracy_layerorm"
OUT_DIR = DATA_DIR / "accuracy_layernorm"

# --- Shared regex fragments ------------------------------------------------

# A float, in either fixed or scientific notation (also matches plain ints).
_FLOAT = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"
_INT = r"\d+"

# The metric tail shared by every method's report line.  Named groups feed the
# record fields directly.  ``elements`` is captured but intentionally dropped.
_TAIL = (
    rf"\)\s*:\s*"
    rf"RMSRE\s*=\s*(?P<rmsre>{_FLOAT})\s*,\s*"
    rf"MAX_REL_ERROR\s*=\s*(?P<max_rel_error>{_FLOAT})\s*,\s*"
    rf"WORST_INPUT\s*=\s*(?P<worst_input>{_FLOAT})\s*"
    rf"\(elements\s*=\s*{_INT}\s*\)\s*"
)


@dataclass(frozen=True)
class Record:
    """One parsed report line.

    Only the fields relevant to a given method are populated; the CSV writer
    emits the subset named in ``MethodSpec.columns``.
    """

    num_newton_steps: int
    rmsre: float
    max_rel_error: float
    worst_input: float
    word_width: int | None = None
    addr_width: int | None = None       # lookup
    addr_width_0: int | None = None     # bipartite
    addr_width_1: int | None = None     # bipartite
    addr_width_2: int | None = None     # bipartite
    magic: str | None = None            # bit_hacking


@dataclass(frozen=True)
class MethodSpec:
    """How to parse one method and which columns its CSV carries."""

    name: str            # source/target basename stem, e.g. "bipartite"
    pattern: re.Pattern[str]
    columns: list[str]   # ordered CSV columns (parameters, then metrics)


_METRIC_COLUMNS = ["rmsre", "max_rel_error", "worst_input"]


def _spec(name: str, param_block: str, param_columns: list[str]) -> MethodSpec:
    """Assemble a MethodSpec from the method-specific bracket contents."""
    pattern = re.compile(
        rf"METHOD\s*=\s*[A-Za-z0-9_\-]+\s*,\s*"
        rf"NEWTON\s*=\s*(?P<num_newton_steps>{_INT})\s*"
        rf"\[\s*{param_block}\s*\]\s*,\s*"
        rf"N\s*=\s*{_INT}\s*,\s*SIMD\s*=\s*{_INT}\s*"
        rf"{_TAIL}"
    )
    return MethodSpec(name, pattern, param_columns + _METRIC_COLUMNS)


# One spec per method.  The bracket body is method-specific; everything else is
# shared through ``_spec``.
_SPECS: dict[str, MethodSpec] = {
    "bipartite": _spec(
        "bipartite",
        rf"WORD_WIDTH\s*=\s*(?P<word_width>{_INT})\s*,\s*"
        rf"ADDR_WIDTH_0/1/2\s*=\s*"
        rf"(?P<addr_width_0>{_INT})/(?P<addr_width_1>{_INT})/(?P<addr_width_2>{_INT})",
        ["num_newton_steps", "addr_width_0", "addr_width_1", "addr_width_2", "word_width"],
    ),
    "lookup": _spec(
        "lookup",
        rf"WORD_WIDTH\s*=\s*(?P<word_width>{_INT})\s*,\s*"
        rf"ADDR_WIDTH\s*=\s*(?P<addr_width>{_INT})",
        ["num_newton_steps", "addr_width", "word_width"],
    ),
    "bit_hacking": _spec(
        "bit_hacking",
        r"MAGIC\s*=\s*(?P<magic>0[xX][0-9a-fA-F]+)",
        ["num_newton_steps", "magic"],
    ),
    "ip_core": _spec(
        "ip_core",
        r"",  # empty bracket body: "[]"
        ["num_newton_steps"],
    ),
}


def parse_line(line: str, spec: MethodSpec) -> Record | None:
    """Parse one report line into a Record, or ``None`` if it doesn't match."""
    m = spec.pattern.search(line)
    if m is None:
        return None
    gd = m.groupdict()

    def _int(key: str) -> int | None:
        val = gd.get(key)
        return int(val) if val is not None else None

    return Record(
        num_newton_steps=int(gd["num_newton_steps"]),
        rmsre=float(gd["rmsre"]),
        max_rel_error=float(gd["max_rel_error"]),
        worst_input=float(gd["worst_input"]),
        word_width=_int("word_width"),
        addr_width=_int("addr_width"),
        addr_width_0=_int("addr_width_0"),
        addr_width_1=_int("addr_width_1"),
        addr_width_2=_int("addr_width_2"),
        magic=gd.get("magic"),
    )


def parse_report(text: str, spec: MethodSpec) -> tuple[list[Record], int]:
    """Parse a whole report; return (records, unparsable_line_count).

    Blank lines are ignored; any non-blank line that fails to match is warned
    about on stderr and counted so the caller can flag a non-zero exit.
    """
    records: list[Record] = []
    failures = 0
    for line_no, raw in enumerate(text.splitlines(), start=1):
        if not raw.strip():
            continue
        rec = parse_line(raw, spec)
        if rec is None:
            failures += 1
            print(
                f"warning: {spec.name}: unparsable line {line_no}: {raw!r}",
                file=sys.stderr,
            )
            continue
        records.append(rec)
    return records, failures


# Map each CSV column back onto its Record attribute.  Column names differ from
# attribute names only in that "worst_input" etc. already match, so this is the
# identity for our columns; kept explicit for clarity/robustness.
_RECORD_FIELDS = {f.name for f in fields(Record)}


def _cell(rec: Record, column: str) -> str:
    """Render one Record field for CSV output."""
    value = getattr(rec, column)
    if value is None:
        return ""
    if isinstance(value, float):
        # ``repr`` round-trips the float exactly without noisy trailing zeros.
        return repr(value)
    return str(value)


def write_csv(path: Path, records: list[Record], columns: list[str]) -> None:
    """Write ``records`` to ``path`` with the given ordered ``columns``.

    Column headers are emitted in upper case to match the resources CSVs
    (NUM_NEWTON_STEPS, WORD_WIDTH, ...); ``compare_accuracy.py`` and
    ``generate_combined.py`` both case-fold, so the casing is cosmetic.
    """
    unknown = [c for c in columns if c not in _RECORD_FIELDS]
    if unknown:
        raise ValueError(f"unknown column(s) for {path.name}: {unknown}")

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow([c.upper() for c in columns])
        for rec in records:
            writer.writerow([_cell(rec, c) for c in columns])


def _display_path(path: Path) -> Path:
    """Path relative to the project root when possible, else the path itself.

    Keeps batch-mode logging tidy (``data/...``) without crashing when the
    caller points ``--output`` outside the project tree.
    """
    try:
        return path.relative_to(PROJECT_ROOT)
    except ValueError:
        return path


def convert(spec: MethodSpec, in_path: Path, out_path: Path) -> int:
    """Convert a single report file; return the number of unparsable lines."""
    if not in_path.is_file():
        print(f"error: input not found: {in_path}", file=sys.stderr)
        return -1
    records, failures = parse_report(in_path.read_text(encoding="utf-8"), spec)
    if not records:
        print(f"error: {in_path.name}: no parsable rows", file=sys.stderr)
        return max(failures, 1)
    write_csv(out_path, records, spec.columns)
    print(f"  {in_path.name:20s} -> {_display_path(out_path)} ({len(records)} rows)")
    return failures


def _spec_for(name: str) -> MethodSpec:
    try:
        return _SPECS[name]
    except KeyError:
        raise SystemExit(
            f"error: unknown method '{name}'; expected one of {sorted(_SPECS)}"
        )


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "-i", "--input", type=Path, default=None,
        help="Single report .txt to convert (default: all methods under "
             f"{IN_DIR.relative_to(PROJECT_ROOT)}/).",
    )
    parser.add_argument(
        "-o", "--output", type=Path, default=None,
        help="Output CSV path (only valid with --input).",
    )
    parser.add_argument(
        "-m", "--method", default=None, choices=sorted(_SPECS),
        help="Method spec for --input (default: inferred from the file stem).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    if args.output is not None and args.input is None:
        print("error: --output requires --input", file=sys.stderr)
        return 2

    if args.input is not None:
        name = args.method or args.input.stem
        spec = _spec_for(name)
        out_path = args.output or (OUT_DIR / f"{spec.name}.csv")
        print(f"Converting {args.input} -> {out_path}")
        failures = convert(spec, args.input, out_path)
        return 1 if failures != 0 else 0

    # Batch mode: convert every known method.
    print(f"Converting reports from {IN_DIR.relative_to(PROJECT_ROOT)}/ "
          f"to {OUT_DIR.relative_to(PROJECT_ROOT)}/")
    exit_code = 0
    for name, spec in _SPECS.items():
        failures = convert(spec, IN_DIR / f"{name}.txt", OUT_DIR / f"{name}.csv")
        if failures != 0:
            exit_code = 1
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
