#!/usr/bin/env python3
"""Generate combined accuracy/resource CSVs for the rsqrt Pareto plots.

Each evaluated method lives in its own folder under ``evaluation/rsqrt`` and
exposes two CSVs:

    <method>/data/accuracy.csv    -> RMSRE (and other error metrics) per config
    <method>/data/resources.csv   -> LUT / DSP / ... per config

This script pairs the two files for every method, keeps only the configurations
for which we have *both* an accuracy and a resource measurement (inner join on
the shared parameter columns), and writes a tidy combined file

    pareto/data_combined/<DisplayName>_combined.csv

with exactly the columns needed downstream: the join parameters plus
``lut, dsp, rmsre``. The downstream plotting script derives the method (and its
colour) from the ``<DisplayName>`` prefix, so the display name is the single
source of truth for how a method is labelled in the figures.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

# --- Configuration ---------------------------------------------------------

# Source folder (relative to the rsqrt root) -> display name used for the
# combined file name and, downstream, the figure legend. This is the only place
# the folder<->label mapping is defined.
METHODS: dict[str, str] = {
    "bipartite": "Bipartite",
    "bit_hacking": "Bit-Hacking",
    "ip_core": "IP-Core",
    "lookup": "Lookup",
}

# Metric columns we care about. Everything else shared between the two files is
# treated as a join key (an experiment parameter such as NUM_NEWTON_STEPS).
METRIC_COLS = {"lut", "dsp", "rmsre"}

# Paths are resolved relative to this script so the tool works regardless of the
# current working directory.
SCRIPT_DIR = Path(__file__).resolve().parent          # pareto/scripts
PARETO_DIR = SCRIPT_DIR.parent                        # pareto
RSQRT_ROOT = PARETO_DIR.parent                        # evaluation/rsqrt
OUTPUT_DIR = PARETO_DIR / "data_combined"             # pareto/data_combined


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


def combine_method(folder: str, display_name: str) -> Path:
    """Build the combined CSV for a single method and return its output path."""
    data_dir = RSQRT_ROOT / folder / "data"
    df_acc = load_csv(data_dir / "accuracy.csv")
    df_res = load_csv(data_dir / "resources.csv")

    # Validate that the metric columns we promise downstream actually exist.
    if "rmsre" not in df_acc.columns:
        raise ValueError(f"[{folder}] 'RMSRE' column missing in accuracy.csv")
    for metric in ("lut", "dsp"):
        if metric not in df_res.columns:
            raise ValueError(
                f"[{folder}] '{metric.upper()}' column missing in resources.csv"
            )

    # Join keys = every column shared by both files that is not a metric,
    # kept in their original order in resources.csv (NUM_NEWTON_STEPS,
    # ADDR_WIDTH*, WORD_WIDTH) rather than sorted alphabetically.
    shared = (set(df_res.columns) & set(df_acc.columns)) - METRIC_COLS
    join_cols = [c for c in df_res.columns if c in shared]

    if join_cols:
        # Standard case: match configurations by their shared parameters. An
        # inner join keeps only configs present in *both* files, which is
        # exactly what we can plot (e.g. bipartite has more accuracy rows than
        # synthesised resource rows -> only the synthesised ones survive).
        merged = pd.merge(df_res, df_acc, on=join_cols, how="inner")
        if merged.empty:
            raise ValueError(
                f"[{folder}] inner join on {join_cols} produced no rows; "
                f"accuracy and resources parameters do not overlap"
            )
    else:
        # No shared parameter columns (e.g. ip-core: a single fixed design with
        # disjoint accuracy/resource schemas). This is only well defined when
        # each file describes exactly one configuration; pair them positionally.
        if len(df_acc) != 1 or len(df_res) != 1:
            raise ValueError(
                f"[{folder}] no common columns to join on and files are not "
                f"single-row (accuracy={len(df_acc)}, resources={len(df_res)}); "
                f"cannot pair configurations unambiguously"
            )
        merged = pd.concat(
            [df_res.reset_index(drop=True), df_acc.reset_index(drop=True)], axis=1
        )

    result = merged[join_cols + ["lut", "dsp", "rmsre"]].copy()

    # Restore the upper-case column names used in the source files. All
    # parameter/metric names round-trip exactly under upper() (e.g.
    # NUM_NEWTON_STEPS, ADDR_WIDTH_0, WORD_WIDTH, LUT, DSP, RMSRE).
    result.columns = [c.upper() for c in result.columns]

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUTPUT_DIR / f"{display_name}_combined.csv"
    result.to_csv(out_path, index=False)

    print(
        f"  {folder:12s} -> {out_path.name:24s} "
        f"({len(result)} rows, join on {join_cols or ['<single row>']})"
    )
    return out_path


# --- Entry point -----------------------------------------------------------

def main() -> None:
    print(f"Writing combined files to {OUTPUT_DIR.relative_to(RSQRT_ROOT)}/")
    written = [combine_method(folder, name) for folder, name in METHODS.items()]
    print(f"Done: {len(written)} combined file(s) generated.")


if __name__ == "__main__":
    main()
