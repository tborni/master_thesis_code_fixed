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

On top of that lift, a **sustainable-interval (folding) correction** accounts for
the InvSqrt only needing a new input every ``N / SIMD`` cycles inside the full
LayerNorm (the per-method resources are all characterised at a sustainable
interval of 1).  ``resources/resources_ii.csv`` characterises how a reference
rsqrt kernel's resources shift as it is folded over the sustainable interval; the
saving

    ii_delta = R_ii(SI = 1) - R_ii(SI = N/SIMD)

(the largest characterised ``SUSTAINABLE_INTERVAL <= N/SIMD`` is used when N/SIMD
is not itself a row) is added to each design point's lifted resources ``alpha``
times, where ``alpha = 1 - NR`` and ``NR`` is the Newton-Raphson step count of
the rsqrt that point uses (0 including the IP core, 1, or 2).  So a no-Newton
kernel gains the full saving (+ii_delta), a 1-Newton kernel is unchanged (the
reference kernel itself has one Newton step), and a 2-Newton kernel is corrected
by -ii_delta.  This mirrors the reciprocal folding correction in the softmax
method-sweep, generalised from a present-or-not offset to the ``1 - NR`` factor.

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

# --- Sustainable-interval (folding) correction ------------------------------
#
# The InvSqrt-block resources in resources/<method>.csv are all characterised at
# a sustainable interval (initiation interval) of 1 -- one inverse-sqrt every
# clock.  Inside the full LayerNorm the InvSqrt only has to accept a new input
# every  SUSTAINABLE_INTERVAL = N / SIMD  cycles, so the block can be folded down
# to that slower rate, which shifts its resource cost.  The lift above does not
# model that shift, so we add it here.
#
# resources/resources_ii.csv characterises the shift for a reference rsqrt kernel
# (bit-hacking, NUM_NEWTON_STEPS=1) swept over the sustainable interval.  For a
# target interval SI the "folding saving" of that reference kernel is
#
#     ii_delta(SI) = ii[SI = 1] - ii[SI = SI]        (per resource metric)
#
# i.e. how much resource the reference kernel sheds when relaxed from SI=1 to SI.
# If SI is not a characterised row we use the largest row whose
# SUSTAINABLE_INTERVAL is <= SI (the closest achievable fold at or below the
# required rate), exactly like the softmax method-sweep.
#
# This saving is added to a method's lifted resources ALPHA times, where
#
#     alpha = 1 - NR      (NR = number of Newton-Raphson steps of the rsqrt used)
#
# NR is 0 (a bare table/bit-hack lookup, and the IP core), 1, or 2.  The IP core
# carries no NUM_NEWTON_STEPS column at all and counts as NR=0 (alpha=+1).  So:
#   NR=0 -> +ii_delta   (a no-Newton kernel folds like the SI=1 reference, gaining
#                        the full saving);
#   NR=1 ->  0          (the reference kernel itself has one Newton step, so its
#                        own folding is already the baseline -- no net change);
#   NR=2 -> -ii_delta   (a deeper kernel folds correspondingly less well).
# This generalises the softmax correction (which only ever saw NR in {0, 1}, and
# so only ever added the saving or not) to the NR=2 case present here.
#
# The reference length/SIMD that set N/SIMD: N comes from reference.csv (the
# reference LayerNorm row) and SIMD is REFERENCE_SIMD, so the correction tracks
# the same operating point as the lift.

# resources_ii.csv column that indexes the sustainable-interval sweep.
II_CSV_NAME = "resources_ii.csv"
II_SI_COL = "sustainable_interval"

# The sustainable interval at which the per-method resources (and the ii SI=1
# row) are measured; every ii_delta is taken relative to this reference row.
II_REFERENCE_SI = 1

# Metrics over which the ii-delta is computed.  The delta is defined over every
# resource column the ii file provides (so the correction is complete), but only
# the LIFTED_METRICS actually reach the combined CSVs / Pareto plots.
II_METRICS = ("reg", "lut", "dsp", "bram", "uram")

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
II_CSV = RES_DIR / II_CSV_NAME                         # rsqrt folding-over-SI sweep
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


# --- Sustainable-interval (folding) correction ------------------------------

def reference_length() -> int:
    """The reference LayerNorm length N (from reference.csv), used for N/SIMD.

    reference.csv is a single reference build; its ``N`` column is the LayerNorm
    length that, together with :data:`REFERENCE_SIMD`, fixes the InvSqrt's
    sustainable interval N/SIMD.  N is read from the row selected by
    REFERENCE_SIMD so it always matches the operating point the lift uses.
    """
    df = load_csv(REFERENCE_CSV)
    if "n" not in df.columns:
        raise ValueError(f"{REFERENCE_CSV.name} must contain an 'N' column")
    match = df[df["simd"] == REFERENCE_SIMD]
    if match.empty:
        raise ValueError(f"SIMD={REFERENCE_SIMD} not found in {REFERENCE_CSV.name}")
    if match["n"].nunique() > 1:
        raise ValueError(f"N is ambiguous at SIMD={REFERENCE_SIMD} in {REFERENCE_CSV.name}")
    return int(match["n"].iloc[0])


def sustainable_interval(n: int, simd: int) -> int:
    """The InvSqrt's sustainable interval N/SIMD for the reference operating point.

    N/SIMD must be exact (the fold is a whole number of cycles); a non-divisible
    pair is a configuration error and aborts.
    """
    if simd <= 0:
        raise ValueError(f"SIMD must be positive, got {simd}.")
    if n % simd != 0:
        raise ValueError(
            f"sustainable interval N/SIMD = {n}/{simd} is not an integer; "
            "the InvSqrt fold must be a whole number of cycles."
        )
    return n // simd


def read_ii_table() -> dict[int, dict[str, int]]:
    """Read resources_ii.csv into ``{sustainable_interval: {metric: value}}``.

    ``metric`` ranges over :data:`II_METRICS`.  Aborts if the file is missing, a
    sustainable interval is duplicated (ambiguous row), or the reference row
    (SI = :data:`II_REFERENCE_SI`) is absent, since every delta is taken against
    it.
    """
    df = load_csv(II_CSV)
    if II_SI_COL not in df.columns:
        raise ValueError(f"'{II_SI_COL.upper()}' column missing in {II_CSV.name}")
    for metric in II_METRICS:
        if metric not in df.columns:
            raise ValueError(f"'{metric.upper()}' column missing in {II_CSV.name}")

    table: dict[int, dict[str, int]] = {}
    for _, row in df.iterrows():
        si = int(row[II_SI_COL])
        if si in table:
            raise ValueError(
                f"duplicate {II_SI_COL.upper()}={si} in {II_CSV.name} "
                "(ambiguous folding row)"
            )
        table[si] = {m: int(row[m]) for m in II_METRICS}
    if not table:
        raise ValueError(f"{II_CSV.name} has no data rows")
    if II_REFERENCE_SI not in table:
        raise ValueError(
            f"{II_CSV.name} is missing the reference row "
            f"{II_SI_COL.upper()}={II_REFERENCE_SI}; every folding delta is "
            f"measured against it. Present intervals: {sorted(table)}"
        )
    return table


def ii_row_for_si(table: dict[int, dict[str, int]], si: int) -> int:
    """Return the ii key to use for a target interval ``si``: the largest
    characterised interval ``<= si`` (the closest achievable fold at or below the
    required rate).  Aborts if ``si`` is below every characterised interval.
    """
    candidates = [k for k in table if k <= si]
    if not candidates:
        raise ValueError(
            f"target sustainable interval {si} is below every row in "
            f"{II_CSV.name} (min {min(table)}); cannot pick a fold <= {si}"
        )
    return max(candidates)


def ii_delta(table: dict[int, dict[str, int]], si: int) -> dict[str, int]:
    """Per-metric folding saving ``ii[SI=1] - ii[SI=row(si)]``.

    ``row(si)`` is :func:`ii_row_for_si`.  At the reference interval the delta is
    all-zero by construction.  This is the reference rsqrt kernel's resource
    saving when relaxed from SI=1 to the target interval; it is later scaled by
    ``alpha = 1 - NR`` per design point.
    """
    ref = table[II_REFERENCE_SI]
    row = table[ii_row_for_si(table, si)]
    return {m: ref[m] - row[m] for m in II_METRICS}


NR_COL = "num_newton_steps"


def newton_steps(merged: pd.DataFrame, from_resources: bool) -> "pd.Series[int]":
    """Per-row Newton-Raphson step count (NR) of the rsqrt used by each design.

    NR must come from the *resources* side.  ``from_resources`` says whether the
    resources file carried a ``NUM_NEWTON_STEPS`` column:

      * True  (bipartite/bit_hacking/lookup): it was a join key, so the merged
        frame's ``num_newton_steps`` equals the resources value for every row
        (join keys are identical on both sides); read it straight off ``merged``.
      * False (IP core): the resources file has no such column, so NR is 0 for
        every row -- alpha = +1 -- even though the accuracy row (concatenated in)
        lists NUM_NEWTON_STEPS=3, which must NOT drive the folding correction.

    Returns an integer Series aligned to ``merged``'s index.
    """
    if from_resources:
        return merged[NR_COL].astype(int)
    return pd.Series(0, index=merged.index, dtype=int)


def combine_method(
    folder: str, display_name: str, base: dict[str, int], delta: dict[str, int]
) -> Path:
    """Build the combined CSV for a single method and return its output path.

    ``base`` is the per-metric constant offset (reference LayerNorm minus the
    reference InvSqrt block); the candidate InvSqrt metric is added on top.

    ``delta`` is the per-metric sustainable-interval folding saving
    ``ii[SI=1] - ii[SI=N/SIMD]``; each design point additionally receives
    ``(1 - NR) * delta`` (NR = its rsqrt's Newton-step count), see
    :func:`ii_delta` / :func:`newton_steps`.
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

    # Sustainable-interval (folding) correction: add (1 - NR) * delta per point.
    # NR comes from the resources side only (values 0/1/2), so alpha is +1 for a
    # no-Newton kernel, 0 for a 1-Newton kernel, and -1 for a 2-Newton kernel; the
    # IP core resources file carries no NUM_NEWTON_STEPS column and so is NR=0
    # (alpha=+1), never the 3 its accuracy row lists.  Applied only to the lifted
    # metrics (LUT/DSP); the delta over the remaining ii metrics is for logging.
    nr_from_resources = NR_COL in df_res.columns
    alpha = 1 - newton_steps(merged, nr_from_resources)
    for metric in LIFTED_METRICS:
        merged[metric] = merged[metric] + alpha * delta[metric]

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

    def _fmt(d: dict[str, int], keys=None, signed: bool = False) -> str:
        keys = keys if keys is not None else d.keys()
        spec = "+d" if signed else "d"
        return ", ".join(f"{k.upper()}={d[k]:{spec}}" for k in keys)

    # Sustainable-interval (folding) correction: compute the ii-delta once at the
    # reference operating point (N from reference.csv, SIMD = REFERENCE_SIMD).
    n = reference_length()
    si = sustainable_interval(n, REFERENCE_SIMD)
    ii_table = read_ii_table()
    ii_row = ii_row_for_si(ii_table, si)
    delta = ii_delta(ii_table, si)

    print(
        f"Reference LayerNorm (SIMD={REFERENCE_SIMD}): {_fmt(ref_ln, LIFTED_METRICS)}\n"
        f"Reference InvSqrt block ({REFERENCE_INVSQRT_METHOD}, "
        f"NEWTON={REFERENCE_INVSQRT_CONFIG['num_newton_steps']}): {_fmt(ref_inv, LIFTED_METRICS)}\n"
        f"Lift base (reference - reference InvSqrt): {_fmt(base, LIFTED_METRICS)}\n"
        f"Sustainable interval N/SIMD = {n}/{REFERENCE_SIMD} = {si} "
        f"(ii row used: SI={ii_row}, largest characterised SI <= {si})\n"
        f"ii-delta (ii[SI=1] - ii[SI={ii_row}]): {_fmt(delta, signed=True)}\n"
        f"  applied per point as (1 - NR) * delta over {[m.upper() for m in LIFTED_METRICS]} "
        f"(alpha: NR=0->+1, NR=1->0, NR=2->-1; IP core = NR=0)"
    )
    print(f"Writing combined files to {OUTPUT_DIR.relative_to(PROJECT_ROOT)}/")

    written = [
        combine_method(folder, name, base, delta) for folder, name in METHODS.items()
    ]
    print(f"Done: {len(written)} combined file(s) generated.")


if __name__ == "__main__":
    main()
