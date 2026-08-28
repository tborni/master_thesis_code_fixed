#!/usr/bin/env python3
"""Render the rec Pareto figures from the combined CSVs.

Reads ``pareto/data_combined/*_combined.csv`` (produced by
``generate_combined.py``) and writes three publication-quality PNGs into
``pareto/images``:

    diagram.png       raw scatter of every design point (no Pareto highlight)
    pareto.png        2-D Pareto front over (RMSRE, LUT) with a staircase
    full_pareto.png   3-D Pareto front over (RMSRE, LUT, DSP), staircase per DSP

All three figures share the same colour-by-method / marker-by-DSP encoding and
the same twin (Method + DSP) legend, so the visual language is consistent.

The method of a point is taken from its combined-file name (the part before
``_combined.csv``, split on ``+`` so that variant suffixes collapse onto their
base method), which is why the generator writes files named after the display
label.
"""

from __future__ import annotations

import tomllib
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D
from matplotlib.markers import MarkerStyle
from matplotlib.transforms import Affine2D

# --- Configuration ---------------------------------------------------------

METHOD_TO_COLOR: dict[str, str] = {
    "Bipartite": "#E69F00",
    "Bit-hacking": "#0072B2",
    "IP core": "red",
    "Lookup": "#83C19D",
    "Splitting": "#9467bd",
}

# Marker per DSP count. Covers the DSP values we distinguish in the legend
# ({0, 1, 2, 7}); 7 is IP-Core's "Full" variant, drawn with "P" to match the
# highest-DSP marker used in the rec/rsqrt figures. Anything else falls back to
# "X" and is flagged.
DSP_TO_MARKER: dict[int, str] = {
    0: "o",
    1: "^",
    2: "s",
    7: "P",
}
FALLBACK_MARKER = "X"

# Paths relative to this script, independent of the caller's cwd.
SCRIPT_DIR = Path(__file__).resolve().parent          # pareto/scripts
PARETO_DIR = SCRIPT_DIR.parent                        # pareto
DATA_DIR = PARETO_DIR / "data_combined"               # pareto/data_combined
IMAGE_DIR = PARETO_DIR / "images"                     # pareto/images
FILTER_PATH = PARETO_DIR / "filter.toml"              # pareto/filter.toml

REQUIRED_COLS = {"rmsre", "lut", "dsp"}

# Permissive defaults used when filter.toml (or a given key) is absent: every
# point passes. Bounds are inclusive; an empty method list means "all methods".
DEFAULT_BOUNDS = {
    "lut_min": float("-inf"), "lut_max": float("inf"),
    "dsp_min": float("-inf"), "dsp_max": float("inf"),
    "rmsre_min": float("-inf"), "rmsre_max": float("inf"),
}

# When true, keep only per-method Pareto-optimal points (see filter.toml).
DEFAULT_PARETO_PER_METHOD = False

# --- Style for publication ---
plt.rcParams.update({
    "font.family": "serif",
    "font.size": 12,
    "axes.labelsize": 14,
    "axes.titlesize": 14,
    "legend.fontsize": 10,
    "xtick.labelsize": 12,
    "ytick.labelsize": 12,
    "figure.dpi": 300,
})


# --- Filtering -------------------------------------------------------------

def load_filter() -> tuple[dict[str, float], list[str] | None, bool]:
    """Read ``filter.toml`` and return ``(bounds, methods, pareto_per_method)``.

    ``bounds`` always contains all six inclusive bounds (missing keys fall back
    to the permissive defaults). ``methods`` is the allow-list of method names,
    or ``None`` to allow every method (missing file, missing key, or empty list).
    ``pareto_per_method`` is the ``[display].pareto_per_method_only`` flag.
    """
    bounds = dict(DEFAULT_BOUNDS)
    methods: list[str] | None = None
    pareto_per_method = DEFAULT_PARETO_PER_METHOD

    if not FILTER_PATH.is_file():
        print(f"No {FILTER_PATH.name} found; showing all configurations.")
        return bounds, methods, pareto_per_method

    with FILTER_PATH.open("rb") as fh:
        cfg = tomllib.load(fh)

    for key, value in cfg.get("bounds", {}).items():
        if key not in DEFAULT_BOUNDS:
            print(f"Warning: unknown bound '{key}' in {FILTER_PATH.name}; ignored.")
            continue
        bounds[key] = float(value)

    include = cfg.get("methods", {}).get("include")
    if include:  # non-empty list -> restrict; empty/absent -> all methods
        methods = list(include)

    pareto_per_method = bool(
        cfg.get("display", {}).get("pareto_per_method_only", DEFAULT_PARETO_PER_METHOD)
    )

    return bounds, methods, pareto_per_method


def apply_filter(df: pd.DataFrame, bounds: dict[str, float]) -> pd.DataFrame:
    """Return the rows of ``df`` inside every inclusive metric bound."""
    keep = (
        df["lut"].between(bounds["lut_min"], bounds["lut_max"])
        & df["dsp"].between(bounds["dsp_min"], bounds["dsp_max"])
        & df["rmsre"].between(bounds["rmsre_min"], bounds["rmsre_max"])
    )
    return df[keep]


def method_pareto_only(df: pd.DataFrame) -> pd.DataFrame:
    """Keep only the rows of ``df`` on its own (LUT, DSP, RMSRE) Pareto front.

    Each combined file holds a single method, so ``df`` *is* one method's group.
    A row is dropped only when another row IN THIS FRAME dominates it; domination
    across methods is irrelevant here (handled by comparing whole frames later).
    Uses the same 3-objective rule as the global front for consistency.
    """
    mask = pareto_mask_3d(df[["rmsre", "lut", "dsp"]].to_numpy())
    return df[mask]


# --- Data loading ----------------------------------------------------------

def load_combined() -> list[pd.DataFrame]:
    """Load every ``*_combined.csv`` into a list of tagged DataFrames.

    Files are sorted in reverse so the draw order matches the reference
    scripts. Each returned frame carries ``label`` (full file stem) and
    ``method`` (prefix before ``+``) columns.
    """
    files = sorted(DATA_DIR.glob("*_combined.csv"), reverse=True)
    if not files:
        raise SystemExit(f"No *_combined.csv files found in {DATA_DIR}")

    bounds, methods, pareto_per_method = load_filter()
    if pareto_per_method:
        print("Filter: showing per-method Pareto-optimal points only.")

    frames: list[pd.DataFrame] = []
    for path in files:
        label_full = path.name.replace("_combined.csv", "")
        method = label_full.split("+")[0]

        if methods is not None and method not in methods:
            print(f"Filtered out {path.name}: method '{method}' not in filter.")
            continue

        df = pd.read_csv(path)
        # Combined files use upper-case headers (NUM_NEWTON_STEPS, LUT, ...);
        # work with lower-case internally so the rest of the code is casing-agnostic.
        df.columns = df.columns.str.lower()

        missing = REQUIRED_COLS - set(df.columns)
        if missing:
            print(f"Skipping {path.name}: missing columns {missing}")
            continue

        # Apply the metric bounds. Filtered points are removed entirely, so the
        # Pareto fronts downstream are computed over what is actually shown.
        n_before = len(df)
        df = apply_filter(df, bounds)
        if df.empty:
            print(f"Filtered out {path.name}: no rows within bounds.")
            continue
        if len(df) < n_before:
            print(f"  {path.name}: kept {len(df)}/{n_before} rows after bounds.")

        # Optionally reduce to this method's own Pareto front.
        if pareto_per_method:
            n_pre_pareto = len(df)
            df = method_pareto_only(df)
            print(
                f"  {path.name}: kept {len(df)}/{n_pre_pareto} rows "
                f"(per-method Pareto)."
            )

        df["label"] = label_full
        df["method"] = method
        frames.append(df)

        unknown = sorted(set(df["dsp"].unique()) - set(DSP_TO_MARKER))
        if unknown:
            print(
                f"Warning: {path.name} has DSP values {unknown} with no marker; "
                f"using '{FALLBACK_MARKER}'."
            )

    if not frames:
        raise SystemExit("No loadable combined files with the required columns.")
    return frames


# --- Pareto helpers --------------------------------------------------------

def pareto_mask_2d(rmsre: np.ndarray, lut: np.ndarray) -> np.ndarray:
    """Boolean mask of the minimise-(rmsre, lut) Pareto front.

    A point is on the front if no other point has a smaller (or equal) LUT at a
    smaller-or-equal RMSRE while being strictly better in at least one axis.
    Computed by scanning in ascending RMSRE and tracking the running-minimum
    LUT, mirroring the staircase the reference draws.
    """
    order = np.lexsort((lut, rmsre))  # sort by rmsre, tie-break by lut
    mask = np.zeros(len(rmsre), dtype=bool)
    best_lut = np.inf
    for idx in order:
        if lut[idx] < best_lut:
            mask[idx] = True
            best_lut = lut[idx]
    return mask


def pareto_mask_3d(points: np.ndarray) -> np.ndarray:
    """Boolean mask of the minimise-all Pareto front for (rmsre, lut, dsp).

    ``points`` is an (n, 3) array. A point is dominated when another point is
    ``<=`` in every column and ``<`` in at least one; survivors form the front.
    """
    n = len(points)
    mask = np.ones(n, dtype=bool)
    for i in range(n):
        le = np.all(points <= points[i], axis=1)
        lt = np.any(points < points[i], axis=1)
        dominated = le & lt
        dominated[i] = False  # a point never dominates itself
        if dominated.any():
            mask[i] = False
    return mask


# --- Shared drawing helpers ------------------------------------------------

def marker_for(dsp_val: int) -> str:
    return DSP_TO_MARKER.get(dsp_val, FALLBACK_MARKER)


def scatter_group(ax, group: pd.DataFrame, color: str, marker: str,
                  pareto_mask: pd.Series | None) -> None:
    """Scatter one (method, DSP) group.

    With ``pareto_mask`` (a boolean Series aligned to ``group``): non-Pareto
    points are drawn faded/edgeless and Pareto points vibrant with a black edge.
    Without it: a single uniform scatter (used by ``diagram.png``).
    """
    if pareto_mask is None:
        ax.scatter(
            group["rmsre"], group["lut"],
            color=color, marker=marker, s=35, alpha=0.85,
            edgecolors="black", linewidths=0.3, zorder=2,
        )
        return

    others = group[~pareto_mask]
    front = group[pareto_mask]

    if not others.empty:
        ax.scatter(
            others["rmsre"], others["lut"],
            color=color, marker=marker, s=35, alpha=0.35,
            edgecolors="none", zorder=2,
        )
    if not front.empty:
        ax.scatter(
            front["rmsre"], front["lut"],
            color=color, marker=marker, s=50, alpha=1.0,
            edgecolors="black", linewidths=0.9, zorder=4,
        )


def add_legends(fig, ax, frames: list[pd.DataFrame]) -> None:
    """Add the twin Method + DSP legends used by all three figures.

    Only methods and DSP counts that are actually drawn get a legend entry, so
    methods without data yet (e.g. Bipartite) do not clutter the
    figure; both lists keep their canonical order (``METHOD_TO_COLOR`` /
    ``DSP_TO_MARKER``). DSP values without a catalogued marker are drawn with the
    fallback marker and are intentionally omitted from the DSP legend.
    """
    drawn_methods = {df["method"].iloc[0] for df in frames}
    drawn_dsp = {int(v) for df in frames for v in df["dsp"].unique()}

    rot_marker = MarkerStyle("d")
    rot_marker._transform = rot_marker.get_transform() + Affine2D().rotate_deg(90)

    method_handles = [
        Line2D([0], [0], marker=rot_marker, color="w", label=m,
               markerfacecolor=c, markeredgecolor="black", markersize=8)
        for m, c in METHOD_TO_COLOR.items() if m in drawn_methods
    ]
    dsp_handles = [
        Line2D([0], [0], marker=m, color="black", label=f"{n} DSP",
               linestyle="None", markersize=8)
        for n, m in DSP_TO_MARKER.items() if n in drawn_dsp
    ]

    legend1 = ax.legend(
        handles=method_handles, title="Method", loc="upper right",
        bbox_to_anchor=(1.0, 1.0), frameon=True,
        edgecolor="black", facecolor="white",
    )
    ax.add_artist(legend1)

    # Place the DSP legend directly left of the Method legend, tops aligned.
    # Measure the Method legend after a draw pass so placement adapts to its size.
    fig.canvas.draw()
    method_bbox = legend1.get_window_extent().transformed(ax.transAxes.inverted())
    ax.legend(
        handles=dsp_handles, title="DSP", loc="upper right",
        bbox_to_anchor=(method_bbox.x0 - 0.005, method_bbox.y1),
        frameon=True, edgecolor="black", facecolor="white",
    )


def format_axes(ax) -> None:
    """Common axis formatting: log-x RMSRE, LUT count, dashed grid."""
    ax.set_xlabel("RMSRE")
    ax.set_ylabel("LUT Count")
    ax.set_xscale("log")
    ax.set_ylim(bottom=0)
    ax.grid(True, which="major", axis="x", linestyle="--", linewidth=0.6, alpha=0.7)
    ax.grid(True, which="both", axis="y", linestyle="--", linewidth=0.6, alpha=0.7)


def finalize(fig, name: str) -> None:
    """Tight-layout, save at high DPI into the images dir, and close."""
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    out = IMAGE_DIR / name
    fig.savefig(out, dpi=600, bbox_inches="tight")
    plt.close(fig)
    print(f"  wrote {out.relative_to(PARETO_DIR)}")


# --- Figures ---------------------------------------------------------------

def plot_diagram(frames: list[pd.DataFrame]) -> None:
    """Raw scatter of every design point, no Pareto highlighting."""
    fig, ax = plt.subplots(figsize=(6, 4))
    for df in frames:
        color = METHOD_TO_COLOR.get(df["method"].iloc[0], "gray")
        for dsp_val, group in df.groupby("dsp"):
            scatter_group(ax, group, color, marker_for(dsp_val), pareto_mask=None)
    add_legends(fig, ax, frames)
    format_axes(ax)
    finalize(fig, "diagram.png")


def plot_pareto(frames: list[pd.DataFrame]) -> None:
    """2-D Pareto front over (RMSRE, LUT), highlighted with a staircase line."""
    combined = pd.concat(frames, ignore_index=True)
    combined["is_pareto"] = pareto_mask_2d(
        combined["rmsre"].to_numpy(), combined["lut"].to_numpy()
    )

    fig, ax = plt.subplots(figsize=(6, 4))
    for df in frames:
        color = METHOD_TO_COLOR.get(df["method"].iloc[0], "gray")
        sub = combined.loc[combined["label"] == df["label"].iloc[0]]
        for dsp_val, group in sub.groupby("dsp"):
            scatter_group(ax, group, color, marker_for(dsp_val),
                          pareto_mask=group["is_pareto"])

    # Pareto staircase across all methods.
    front = combined[combined["is_pareto"]].sort_values("rmsre")
    ax.step(front["rmsre"], front["lut"], where="post",
            color="black", linestyle="-", linewidth=1.2, alpha=0.7, zorder=3)

    add_legends(fig, ax, frames)
    format_axes(ax)
    finalize(fig, "pareto.png")


def plot_full_pareto(frames: list[pd.DataFrame]) -> None:
    """3-D Pareto front over (RMSRE, LUT, DSP); staircase per DSP group."""
    combined = pd.concat(frames, ignore_index=True)
    combined["is_pareto"] = pareto_mask_3d(
        combined[["rmsre", "lut", "dsp"]].to_numpy()
    )

    fig, ax = plt.subplots(figsize=(6, 4))
    for df in frames:
        color = METHOD_TO_COLOR.get(df["method"].iloc[0], "gray")
        sub = combined.loc[combined["label"] == df["label"].iloc[0]]
        for dsp_val, group in sub.groupby("dsp"):
            scatter_group(ax, group, color, marker_for(dsp_val),
                          pareto_mask=group["is_pareto"])

    # One staircase per DSP group, over that group's Pareto points.
    for dsp_val in DSP_TO_MARKER:
        group = combined[
            combined["is_pareto"] & (combined["dsp"] == dsp_val)
        ].sort_values("rmsre")
        if group.empty:
            continue
        ax.step(group["rmsre"], group["lut"], where="post",
                color="gray", linestyle="-", linewidth=0.9, alpha=0.6, zorder=3)

    add_legends(fig, ax, frames)
    format_axes(ax)
    finalize(fig, "full_pareto.png")


# --- Entry point -----------------------------------------------------------

def main() -> None:
    frames = load_combined()
    print(f"Rendering figures into {IMAGE_DIR.relative_to(PARETO_DIR)}/")
    plot_diagram(frames)
    plot_pareto(frames)
    plot_full_pareto(frames)
    print("Done: 3 figure(s) generated.")


if __name__ == "__main__":
    main()
