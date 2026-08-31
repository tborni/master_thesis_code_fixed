#!/usr/bin/env python3
"""Compare the "real" sweep CSVs against the ``invsqrt_accuracy`` CSVs.

For every approximation method (BIPARTITE, LOOKUP, FAST-INVSQRT) this script
joins the two result sets on their shared *parameter* columns
(NEWTON steps, address/word widths, ...), computes the relative difference in
RMSRE for each matched configuration, and reports the **maximum** relative
difference per method.

The two CSV families differ in header case, spacing and column order, e.g.

    real:    NUM_NEWTON_STEPS,WORD_WIDTH,ADDR_WIDTH,RMSRE,MAX_REL_ERROR,WORST_INPUT
    invsqrt: num_newton_steps, addr_width, word_width, RMSRE, max_rel_error

so columns are matched by a *normalised* name (lower-cased, stripped) rather
than by position. Matching is an inner join on the parameter columns the two
files have in common; configurations present in only one file are counted but
excluded from the maximum.

Relative difference (invsqrt taken as the baseline / denominator):

    rel_diff = |RMSRE_real - RMSRE_invsqrt| / |RMSRE_invsqrt|

Because this ratio explodes when both implementations are already accurate to
the float noise floor (a ~1e-7 absolute gap on a ~1e-8 baseline reads as
>1000%), the per-method maximum is reported twice:

    raw      -- every matched config
    filtered -- configs whose smaller RMSRE is below --min-rmsre are dropped

The summary is printed to stdout and, with ``--out-file``, also written verbatim
to a text file. Both input CSVs are only read, never modified.
"""

from __future__ import annotations

import argparse
import csv
import math
import sys
from dataclasses import dataclass
from pathlib import Path

# Normalised names of the metric columns (not part of the join key).
_RMSRE = "rmsre"
_METRIC_COLUMNS = {_RMSRE, "max_rel_error", "worst_input"}

# The methods to compare, as (display name, shared CSV basename).
_METHODS = [
    ("Bipartite", "Bipartite_accuracy.csv"),
    ("Lookup", "Lookup_accuracy.csv"),
    ("Fast-InvSqrt", "Fast-InvSqrt_accuracy.csv"),
    ("IP-Core", "IP-Core_accuracy.csv"),
]


class CompareError(ValueError):
    """Raised for malformed CSVs or a missing RMSRE column."""


def _norm(name: str) -> str:
    """Normalise a header cell so the two files' columns line up."""
    return name.strip().lower()


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Read ``path`` into (normalised_fieldnames, list-of-normalised-row-dicts).

    Both keys and values are stripped; keys are additionally lower-cased.
    """
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.reader(fh)
        try:
            header = next(reader)
        except StopIteration:
            raise CompareError(f"{path}: file is empty")

        fieldnames = [_norm(h) for h in header]
        rows: list[dict[str, str]] = []
        for line_no, raw in enumerate(reader, start=2):
            if not any(cell.strip() for cell in raw):
                continue  # skip blank lines
            if len(raw) != len(fieldnames):
                raise CompareError(
                    f"{path} line {line_no}: expected {len(fieldnames)} columns, "
                    f"got {len(raw)}: {raw!r}"
                )
            rows.append({k: v.strip() for k, v in zip(fieldnames, raw)})

    if _RMSRE not in fieldnames:
        raise CompareError(f"{path}: no RMSRE column (found {fieldnames})")
    return fieldnames, rows


def _param_columns(fieldnames: list[str]) -> list[str]:
    """Return the parameter columns (everything that is not a metric)."""
    return [f for f in fieldnames if f not in _METRIC_COLUMNS]


def _key_columns(real_fields: list[str], inv_fields: list[str]) -> list[str]:
    """Shared parameter columns, ordered as they appear in the real file.

    These form the join key. Requiring them on *both* sides means, e.g., the
    Fast-InvSqrt files (real has MAGIC, invsqrt does not) join on NEWTON only.
    """
    real_params = _param_columns(real_fields)
    inv_params = set(_param_columns(inv_fields))
    shared = [c for c in real_params if c in inv_params]
    if not shared:
        raise CompareError(
            f"no shared parameter columns between {real_fields} and {inv_fields}"
        )
    return shared


def _canonical_int(value: str) -> str:
    """Canonicalise a numeric key component so '06', '6', '6.0' all match.

    Falls back to the raw (case-folded) string for non-integer keys such as a
    MAGIC hex constant.
    """
    try:
        return str(int(value))
    except ValueError:
        try:
            f = float(value)
        except ValueError:
            return value.strip().lower()
        return str(int(f)) if f.is_integer() else repr(f)


def _index_by_key(
    rows: list[dict[str, str]], key_cols: list[str], source: Path
) -> dict[tuple[str, ...], dict[str, str]]:
    """Build {key-tuple -> row}, erroring on duplicate keys."""
    index: dict[tuple[str, ...], dict[str, str]] = {}
    for row in rows:
        key = tuple(_canonical_int(row[c]) for c in key_cols)
        if key in index:
            raise CompareError(
                f"{source}: duplicate parameter combination "
                f"{dict(zip(key_cols, key))}"
            )
        index[key] = row
    return index


def _format_key(key_cols: list[str], key: tuple[str, ...]) -> str:
    return ", ".join(f"{c}={v}" for c, v in zip(key_cols, key))


@dataclass
class MaxDiff:
    """The worst matched config under one variant of the comparison."""

    max_rel_diff: float | None  # None if no config qualified
    at_key: tuple[str, ...] | None
    real_rmsre: float | None
    inv_rmsre: float | None
    considered: int  # configs that contributed to this maximum
    skipped_floor: int  # matched configs dropped because min(real,inv) < floor


@dataclass
class MethodResult:
    method: str
    key_cols: list[str]
    # Two views of the same matched set:
    #  * unthresholded -> the original metric (every config with inv != 0)
    #  * thresholded   -> configs below the RMSRE noise floor removed
    unthresholded: MaxDiff
    thresholded: MaxDiff
    min_rmsre: float
    matched: int
    only_real: int
    only_inv: int
    skipped_zero: int  # matched but invsqrt RMSRE == 0 (undefined denominator)


def _max_diff(
    configs: list[tuple[tuple[str, ...], float, float]], floor: float
) -> MaxDiff:
    """Largest relative RMSRE difference over ``configs``, ignoring any config
    whose smaller RMSRE is below ``floor`` (the noise-floor filter).

    ``configs`` is a list of (key, real_rmsre, inv_rmsre) with inv_rmsre != 0.
    """
    best: MaxDiff = MaxDiff(None, None, None, None, considered=0, skipped_floor=0)
    for key, real_rmsre, inv_rmsre in configs:
        if min(real_rmsre, inv_rmsre) < floor:
            best.skipped_floor += 1
            continue
        best.considered += 1
        rel_diff = abs(real_rmsre - inv_rmsre) / abs(inv_rmsre)
        if best.max_rel_diff is None or rel_diff > best.max_rel_diff:
            best.max_rel_diff = rel_diff
            best.at_key = key
            best.real_rmsre = real_rmsre
            best.inv_rmsre = inv_rmsre
    return best


def compare_method(
    method: str, real_path: Path, inv_path: Path, min_rmsre: float
) -> MethodResult:
    """Compare one method's two CSVs and return the summary result.

    Computes the maximum relative RMSRE difference twice over the same matched
    set: once with no floor (the original metric) and once ignoring configs
    below ``min_rmsre``, where both implementations sit at the float noise floor
    and the relative metric explodes on a negligible absolute difference.
    """
    real_fields, real_rows = _read_csv(real_path)
    inv_fields, inv_rows = _read_csv(inv_path)

    key_cols = _key_columns(real_fields, inv_fields)
    real_idx = _index_by_key(real_rows, key_cols, real_path)
    inv_idx = _index_by_key(inv_rows, key_cols, inv_path)

    real_keys = set(real_idx)
    inv_keys = set(inv_idx)
    shared_keys = real_keys & inv_keys

    configs: list[tuple[tuple[str, ...], float, float]] = []
    skipped_zero = 0
    for key in shared_keys:
        try:
            real_rmsre = float(real_idx[key][_RMSRE])
            inv_rmsre = float(inv_idx[key][_RMSRE])
        except ValueError as exc:
            raise CompareError(
                f"{method}: non-numeric RMSRE at {_format_key(key_cols, key)}: {exc}"
            )
        if inv_rmsre == 0.0:
            # Baseline is invsqrt RMSRE; a zero denominator is undefined.
            skipped_zero += 1
            continue
        configs.append((key, real_rmsre, inv_rmsre))

    return MethodResult(
        method=method,
        key_cols=key_cols,
        unthresholded=_max_diff(configs, floor=0.0),
        thresholded=_max_diff(configs, floor=min_rmsre),
        min_rmsre=min_rmsre,
        matched=len(shared_keys),
        only_real=len(real_keys - inv_keys),
        only_inv=len(inv_keys - real_keys),
        skipped_zero=skipped_zero,
    )


_INDENT = " " * 15  # aligns continuation lines under the method column


def _format_variant(label: str, key_cols: list[str], md: MaxDiff) -> list[str]:
    """Render one variant (raw or filtered) as indented continuation lines."""
    if md.max_rel_diff is None:
        return [f"{_INDENT}{label:<9} no comparable configs"]
    pct = md.max_rel_diff * 100.0
    lines = [
        f"{_INDENT}{label:<9} max rel-diff = {md.max_rel_diff:.6f} ({pct:.4f}%) "
        f"at {_format_key(key_cols, md.at_key)}",
        f"{_INDENT}          real RMSRE = {md.real_rmsre:.10g}, "
        f"invsqrt RMSRE = {md.inv_rmsre:.10g}",
    ]
    return lines


def _format_result(res: MethodResult) -> str:
    """Render one method's result as a multi-line string (no trailing newline).

    Reports both the original (unthresholded) maximum and the noise-floor
    filtered maximum, so the effect of the threshold is visible side by side.
    """
    lines = [f"{res.method}"]

    lines += _format_variant("raw:", res.key_cols, res.unthresholded)
    lines += _format_variant(
        f"filtered:", res.key_cols, res.thresholded
    )

    # Shared join / filtering statistics.
    notes = [f"matched {res.matched}"]
    if res.only_real:
        notes.append(f"{res.only_real} only in real")
    if res.only_inv:
        notes.append(f"{res.only_inv} only in invsqrt")
    if res.skipped_zero:
        notes.append(f"{res.skipped_zero} skipped (invsqrt RMSRE = 0)")
    if res.thresholded.skipped_floor:
        notes.append(
            f"{res.thresholded.skipped_floor} below {res.min_rmsre:g} noise floor"
        )
    lines.append(f"{_INDENT}[{', '.join(notes)}]")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--real-dir",
        type=Path,
        default=here,
        help="Directory with the reference CSVs (default: this script's folder).",
    )
    parser.add_argument(
        "--invsqrt-dir",
        type=Path,
        default=here / "invsqrt_accuracy",
        help="Directory with the invsqrt CSVs (default: ./invsqrt_accuracy).",
    )
    parser.add_argument(
        "--min-rmsre",
        type=float,
        default=1e-6,
        help=(
            "Noise-floor threshold: configs whose smaller RMSRE is below this "
            "are excluded from the 'filtered' maximum, where the relative metric "
            "explodes on a negligible absolute difference (default: 1e-6)."
        ),
    )
    parser.add_argument(
        "-o",
        "--out-file",
        type=Path,
        default=None,
        help="Also write the printed summary to this text file.",
    )
    args = parser.parse_args(argv)

    # Accumulate the whole summary so stdout and the txt file are identical.
    out: list[str] = [
        "Relative RMSRE difference  |RMSRE_real - RMSRE_invsqrt| / |RMSRE_invsqrt|",
        f"  real   : {args.real_dir}",
        f"  invsqrt: {args.invsqrt_dir}",
        "  raw      = all matched configs",
        f"  filtered = configs with min(real,invsqrt) RMSRE >= {args.min_rmsre:g}"
        " (drops noise-floor blow-ups)",
        "",
    ]

    exit_code = 0
    overall_raw = -1.0
    overall_filtered = -1.0
    for method, basename in _METHODS:
        real_path = args.real_dir / basename
        inv_path = args.invsqrt_dir / basename
        if not real_path.is_file():
            out.append(f"{method:<13} SKIP: missing {real_path}")
            exit_code = 1
            continue
        if not inv_path.is_file():
            out.append(f"{method:<13} SKIP: missing {inv_path}")
            exit_code = 1
            continue
        try:
            res = compare_method(method, real_path, inv_path, args.min_rmsre)
        except CompareError as exc:
            # Diagnostics go to stderr only; the summary stays a clean report.
            print(f"{method:<13} ERROR: {exc}", file=sys.stderr)
            out.append(f"{method:<13} ERROR: {exc}")
            exit_code = 1
            continue
        out.append(_format_result(res))
        if res.unthresholded.max_rel_diff is not None:
            overall_raw = max(overall_raw, res.unthresholded.max_rel_diff)
        if res.thresholded.max_rel_diff is not None:
            overall_filtered = max(overall_filtered, res.thresholded.max_rel_diff)

    if overall_raw >= 0.0:
        out.append(
            f"\nOverall maximum relative RMSRE difference:"
            f"\n  raw      = {overall_raw:.6f} ({overall_raw * 100.0:.4f}%)"
        )
        if overall_filtered >= 0.0:
            out.append(
                f"  filtered = {overall_filtered:.6f} "
                f"({overall_filtered * 100.0:.4f}%)"
            )
        else:
            out.append(f"  filtered = n/a (all configs below {args.min_rmsre:g})")

    summary = "\n".join(out) + "\n"
    print(summary, end="")

    if args.out_file is not None:
        try:
            args.out_file.write_text(summary, encoding="utf-8")
        except OSError as exc:
            print(f"ERROR: could not write {args.out_file}: {exc}", file=sys.stderr)
            return 1
        print(f"wrote {args.out_file}")

    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
