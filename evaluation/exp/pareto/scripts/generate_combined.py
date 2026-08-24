#!/usr/bin/env python3
"""Generate combined accuracy/resource CSVs for the rec Pareto plots.

Each evaluated method lives in its own folder under ``evaluation/rec`` and
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

# Source folder (relative to the rec root) -> display name used for the
# combined file name and, downstream, the figure legend. This is the only place
# the folder<->label mapping is defined. A method whose data folder does not yet
# contain both CSVs (e.g. bipartite before it is evaluated) is skipped with a
# notice, so it is picked up automatically once its data lands.
METHODS: dict[str, str] = {
    "bipartite": "Bipartite",
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
REC_ROOT = PARETO_DIR.parent                          # evaluation/rec
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


def combine_method(folder: str, display_name: str) -> Path | None:
    """Build the combined CSV for a single method and return its output path.

    Returns ``None`` (with a notice) when the method's data folder does not yet
    hold both ``accuracy.csv`` and ``resources.csv`` -- e.g. bipartite before it
    has been evaluated -- so the rest of the pipeline can proceed.
    """
    data_dir = REC_ROOT / folder / "data"
    acc_path = data_dir / "accuracy.csv"
    res_path = data_dir / "resources.csv"
    if not acc_path.is_file() or not res_path.is_file():
        missing = [p.name for p in (acc_path, res_path) if not p.is_file()]
        print(f"  {folder:12s} -> skipped (no data yet: missing {', '.join(missing)})")
        return None

    df_acc = load_csv(acc_path)
    df_res = load_csv(res_path)

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
        # No shared parameter columns (e.g. ip-core: a fixed design whose
        # accuracy and resource schemas are disjoint). This is well defined only
        # when the accuracy file describes a single configuration; that one row
        # is then broadcast across every resource row. That covers both a single
        # design (1 resource row) and several resource variants that share the
        # same accuracy (e.g. ip-core with/without DSP -> two rows keyed by
        # DSP_USAGE).
        if len(df_acc) != 1:
            raise ValueError(
                f"[{folder}] no common columns to join on and accuracy.csv has "
                f"{len(df_acc)} rows (expected 1); cannot pair configurations "
                f"unambiguously"
            )
        merged = df_res.reset_index(drop=True).copy()
        for col in df_acc.columns:
            merged[col] = df_acc.iloc[0][col]

    # In the broadcast case (no join keys) carry any extra *identifier* resource
    # columns -- e.g. ip-core's DSP_USAGE -- into the output so distinct resource
    # variants sharing one accuracy stay identifiable. Identifiers are the
    # non-numeric columns; numeric extras (clock_period, WNS, ...) are dropped as
    # noise. In the join case the shared parameters already identify each row, so
    # we keep only params + metrics (matching the lookup schema:
    # NUM_NEWTON_STEPS, ADDR_WIDTH, ...). Order: join keys, extras, then metrics.
    if join_cols:
        extra_cols: list[str] = []
    else:
        non_metric = df_res.drop(columns=[c for c in METRIC_COLS if c in df_res])
        identifiers = set(non_metric.select_dtypes(exclude="number").columns)
        extra_cols = [c for c in df_res.columns if c in identifiers]
    result = merged[join_cols + extra_cols + ["lut", "dsp", "rmsre"]].copy()

    # Restore the upper-case column names used in the source files. All
    # parameter/metric names round-trip exactly under upper() (e.g.
    # NUM_NEWTON_STEPS, ADDR_WIDTH_0, WORD_WIDTH, DSP_USAGE, LUT, DSP, RMSRE).
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
    print(f"Writing combined files to {OUTPUT_DIR.relative_to(REC_ROOT)}/")
    written = [
        path
        for folder, name in METHODS.items()
        if (path := combine_method(folder, name)) is not None
    ]
    print(f"Done: {len(written)} combined file(s) generated.")


if __name__ == "__main__":
    main()
