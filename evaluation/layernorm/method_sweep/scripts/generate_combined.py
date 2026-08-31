#!/usr/bin/env python3
"""Build ``<Method>_combined.csv`` files for the full-LayerNorm Pareto plots.

Each candidate InvSqrt method ships two data sources:

    data/accuracy_layernorm/<method>.csv   RMSRE of the *full LayerNorm* per config
    data/resources/<method>.csv            FPGA resources of the *InvSqrt block* per config

The end-to-end LayerNorm RMSRE is measured directly (it flows straight through),
but the resource counts describe only the InvSqrt block and must be lifted to
the *full LayerNorm* level.  Following ``description.txt``, a resource of the
LayerNorm using some candidate InvSqrt is

    R(LayerNorm, method) = R(reference LayerNorm)
                         - R(InvSqrt used inside the reference)
                         + R(InvSqrt method under consideration)

i.e. take the reference LayerNorm, remove its InvSqrt block, and graft in the
candidate InvSqrt block.  This is applied to **both LUT and DSP** so the
downstream Pareto plots can trade accuracy off against either.

The reference is the LayerNorm from ``data/resources/reference.csv`` built with
the bipartite InvSqrt (AW0=2, AW1=AW2=4, WW=13, NUM_NEWTON_STEPS=1).  Its
resource counts depend on SIMD; ``REFERENCE_SIMD`` selects the line.  The whole
accuracy sweep was measured at SIMD=2, so the reference is taken at SIMD=2 too.

Each resulting ``data/combined/<Method>_combined.csv`` mirrors the rsqrt Pareto
pipeline: the join (parameter) columns followed by ``LUT, DSP, RMSRE``, where
LUT and DSP are the lifted full-LayerNorm counts.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

# --- Reference configuration (edit here to retarget the pipeline) -----------

# Which SIMD line of reference.csv defines the reference LayerNorm.  The accuracy
# sweep was run at SIMD=2, so the reference LUT/DSP are taken at SIMD=2 as well.
# Change this single value to pick another operating point (e.g. 1, 4, 8, ...).
REFERENCE_SIMD = 2

# The bipartite InvSqrt instantiated inside the reference LayerNorm.  Its LUT/DSP
# cost is subtracted before the candidate InvSqrt's cost is added back in.
# Keys/values match the (lower-cased) columns of resources/bipartite.csv.
REFERENCE_INVSQRT_METHOD = "bipartite"
REFERENCE_INVSQRT_CONFIG = {
    "num_newton_steps": 1,
    "addr_width_0": 2,
    "addr_width_1": 4,
    "addr_width_2": 4,
    "word_width": 13,
}

# Resources lifted from the InvSqrt block to the full LayerNorm.
LIFTED_METRICS = ("lut", "dsp")

# --- Method registry --------------------------------------------------------

# Source basename (shared by the accuracy and resources CSVs) -> display name
# used for the combined file name and, downstream, the figure legend.  This is
# the single source of truth for the folder<->label mapping.
METHODS: dict[str, str] = {
    "bipartite": "Bipartite",
    "bit_hacking": "Bit-hacking",
    "ip_core": "IP core",
    "lookup": "Lookup",
}

# Metric columns we care about.  Everything else shared between the accuracy and
# resources files is treated as a join key (an experiment parameter).
METRIC_COLS = {"lut", "dsp", "rmsre"}

# --- Paths -----------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent          # scripts/
PROJECT_ROOT = SCRIPT_DIR.parent                      # method_sweep/
DATA_DIR = PROJECT_ROOT / "data"
ACC_DIR = DATA_DIR / "accuracy_layernorm"             # extracted LayerNorm RMSRE
RES_DIR = DATA_DIR / "resources"                      # InvSqrt-block resources
REFERENCE_CSV = RES_DIR / "reference.csv"             # reference LayerNorm resources
OUTPUT_DIR = DATA_DIR / "combined"                    # combined CSVs


# --- Helpers ---------------------------------------------------------------

def clean_df(df: pd.DataFrame) -> pd.DataFrame:
    """Normalise column names to lower-case and strip whitespace from cells."""
    df.columns = [c.strip().lower() for c in df.columns]
    for col in df.select_dtypes(include=["object", "string"]).columns:
        df[col] = df[col].astype(str).str.strip()
    return df


def load_csv(path: Path) -> pd.DataFrame:
    """Read a CSV, tolerating ``#`` comment lines, and normalise it."""
    if not path.is_file():
        raise FileNotFoundError(f"Expected data file not found: {path}")
    return clean_df(pd.read_csv(path, comment="#"))


def reference_layernorm_resources() -> dict[str, int]:
    """Lifted metrics of the reference LayerNorm at the selected SIMD line."""
    df = load_csv(REFERENCE_CSV)
    if "simd" not in df.columns:
        raise ValueError(f"{REFERENCE_CSV.name} must contain a 'SIMD' column")
    for metric in LIFTED_METRICS:
        if metric not in df.columns:
            raise ValueError(f"'{metric.upper()}' column missing in {REFERENCE_CSV.name}")

    match = df[df["simd"] == REFERENCE_SIMD]
    if match.empty:
        available = sorted(df["simd"].unique().tolist())
        raise ValueError(
            f"SIMD={REFERENCE_SIMD} not found in {REFERENCE_CSV.name}; "
            f"available: {available}"
        )
    if len(match) > 1:
        raise ValueError(f"SIMD={REFERENCE_SIMD} is ambiguous in {REFERENCE_CSV.name}")

    return {m: int(match[m].iloc[0]) for m in LIFTED_METRICS}


def reference_invsqrt_resources() -> dict[str, int]:
    """Lifted metrics of the bipartite InvSqrt used inside the reference."""
    res_file = RES_DIR / f"{REFERENCE_INVSQRT_METHOD}.csv"
    df = load_csv(res_file)
    for metric in LIFTED_METRICS:
        if metric not in df.columns:
            raise ValueError(f"'{metric.upper()}' column missing in {res_file.name}")

    mask = pd.Series(True, index=df.index)
    for col, val in REFERENCE_INVSQRT_CONFIG.items():
        if col not in df.columns:
            raise ValueError(f"Reference config column '{col}' missing in {res_file.name}")
        mask &= df[col] == val

    match = df[mask]
    if match.empty:
        raise ValueError(
            f"Reference InvSqrt config {REFERENCE_INVSQRT_CONFIG} not found in {res_file.name}"
        )
    if len(match) > 1:
        raise ValueError(
            f"Reference InvSqrt config {REFERENCE_INVSQRT_CONFIG} is ambiguous in {res_file.name}"
        )

    return {m: int(match[m].iloc[0]) for m in LIFTED_METRICS}


def combine_method(
    folder: str, display_name: str, base: dict[str, int]
) -> Path:
    """Build the combined CSV for a single method and return its output path.

    ``base`` is the per-metric constant offset (reference LayerNorm minus the
    reference InvSqrt block); the candidate InvSqrt metric is added on top.
    """
    df_acc = load_csv(ACC_DIR / f"{folder}.csv")
    df_res = load_csv(RES_DIR / f"{folder}.csv")

    # Validate that the metric columns we promise downstream actually exist.
    if "rmsre" not in df_acc.columns:
        raise ValueError(f"[{folder}] 'RMSRE' column missing in accuracy CSV")
    for metric in LIFTED_METRICS:
        if metric not in df_res.columns:
            raise ValueError(f"[{folder}] '{metric.upper()}' column missing in resources CSV")

    # Join keys = every column shared by both files that is not a metric, kept in
    # their original order in resources.csv (NUM_NEWTON_STEPS, ADDR_WIDTH*,
    # WORD_WIDTH) rather than sorted alphabetically.
    shared = (set(df_res.columns) & set(df_acc.columns)) - METRIC_COLS
    join_cols = [c for c in df_res.columns if c in shared]

    if join_cols:
        # Standard case: match configurations by their shared parameters.  An
        # inner join keeps only configs present in *both* files, which is exactly
        # what we can plot (e.g. bipartite has a WW=19 resources row with no
        # accuracy row -> it drops out).
        merged = pd.merge(df_res, df_acc, on=join_cols, how="inner")
        if merged.empty:
            raise ValueError(
                f"[{folder}] inner join on {join_cols} produced no rows; "
                f"accuracy and resources parameters do not overlap"
            )
    else:
        # No shared parameter columns (e.g. ip-core: a single fixed design whose
        # accuracy/resources schemas are disjoint).  Only well defined when each
        # file describes exactly one configuration; pair them positionally.
        if len(df_acc) != 1 or len(df_res) != 1:
            raise ValueError(
                f"[{folder}] no common columns to join on and files are not "
                f"single-row (accuracy={len(df_acc)}, resources={len(df_res)}); "
                f"cannot pair configurations unambiguously"
            )
        merged = pd.concat(
            [df_res.reset_index(drop=True), df_acc.reset_index(drop=True)], axis=1
        )

    # Lift the InvSqrt-block resources to the full-LayerNorm resources.
    for metric in LIFTED_METRICS:
        merged[metric] = base[metric] + merged[metric]

    result = merged[join_cols + ["lut", "dsp", "rmsre"]].copy()

    # Restore the upper-case column names used in the source files.  All
    # parameter/metric names round-trip exactly under upper() (e.g.
    # NUM_NEWTON_STEPS, ADDR_WIDTH_0, WORD_WIDTH, LUT, DSP, RMSRE).
    result.columns = [c.upper() for c in result.columns]

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUTPUT_DIR / f"{display_name}_combined.csv"
    result.to_csv(out_path, index=False)

    print(
        f"  {folder:12s} -> {out_path.name:26s} "
        f"({len(result)} rows, join on {join_cols or ['<single row>']})"
    )
    return out_path


# --- Entry point -----------------------------------------------------------

def main() -> None:
    ref_ln = reference_layernorm_resources()
    ref_inv = reference_invsqrt_resources()
    base = {m: ref_ln[m] - ref_inv[m] for m in LIFTED_METRICS}

    def _fmt(d: dict[str, int]) -> str:
        return ", ".join(f"{k.upper()}={v}" for k, v in d.items())

    print(
        f"Reference LayerNorm (SIMD={REFERENCE_SIMD}): {_fmt(ref_ln)}\n"
        f"Reference InvSqrt block ({REFERENCE_INVSQRT_METHOD}, "
        f"NEWTON={REFERENCE_INVSQRT_CONFIG['num_newton_steps']}): {_fmt(ref_inv)}\n"
        f"Lift base (reference - reference InvSqrt): {_fmt(base)}"
    )
    print(f"Writing combined files to {OUTPUT_DIR.relative_to(PROJECT_ROOT)}/")

    written = [
        combine_method(folder, name, base) for folder, name in METHODS.items()
    ]
    print(f"Done: {len(written)} combined file(s) generated.")


if __name__ == "__main__":
    main()
