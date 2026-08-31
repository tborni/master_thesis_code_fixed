"""Step 3 - plot the pareto-optimal softmax implementations.

This step consumes only the generated ``data/generated/softmax_SIMD_<v>.csv`` files and
helper_config, so it is decoupled from the shape of the raw input data.

Runs once per SIMD value (usage mirrors step 2):
  step3_plot.py            -> every value in helper_config.SIMD_SWEEP
  step3_plot.py <simd>     -> just that value

For each SIMD value it produces TWO figure sets under
images/SIMD_<v>/{dsp_only,method_dsp}/.  Each set holds the same three figures:

  diagram.png      - scatter only, no Pareto line
  pareto.png       - scatter + a single global 2D (RMSRE, LUT) Pareto staircase;
                     points off that 2D front are faded
  full_pareto.png  - scatter + one Pareto staircase per DSP group

The two sets differ only in how each point is coloured/shaped and in the
legend(s):

  method_dsp/  - marker COLOUR = DSP count, marker SHAPE = (exp, rec) method
                 pair; two legends ("DSP" + "Exp + Rec method")
  dsp_only/    - DSP count determines BOTH colour and shape; one "DSP" legend

x-axis : RMSRE (log scale)     y-axis : LUT Count

Note on the front: softmax.csv already contains *only* the full-precision 3D
Pareto front (step 2 filtered it), so for full_pareto.png every stored point is
a front point and is drawn vibrant.  We deliberately do NOT recompute the 3D
front here: the CSV stores RMSRE at 6 significant figures, and two genuinely
non-dominated points can round to equal RMSRE, which would spuriously fade one
of them.  The 2D front for pareto.png is a real geometric sub-selection in
(RMSRE, LUT) and is computed on the fly.
"""

from __future__ import annotations

import os
import sys
from collections import defaultdict
from typing import Callable, Dict, List, Tuple

import matplotlib
matplotlib.use("Agg")  # headless
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

import helper_config as C


# --------------------------------------------------------------------------- #
# Publication style (from the reference scripts)
# --------------------------------------------------------------------------- #
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

# Scatter drawing styles.
_PLAIN = dict(s=35, alpha=0.85, edgecolors="black", linewidths=0.3, zorder=3)
# Faded/vibrant split used by pareto.png / full_pareto.png.
_VIBRANT = dict(s=50, alpha=1.0, edgecolors="black", linewidths=0.9, zorder=4)
_FADED = dict(s=35, alpha=0.35, edgecolors="none", zorder=2)


# --------------------------------------------------------------------------- #
# Encoding modes
# --------------------------------------------------------------------------- #
# An "encoding" bundles everything that differs between the two figure sets:
#   style_of(row)  -> (colour, marker) for a data point
#   draw_legend(ax): draw the mode's legend(s)
#   paths          : {figure_name: output_path} for this mode
#   limits         : (xmin, xmax, ymax) to force onto every axis, or None to
#                    let each diagram auto-scale
class Encoding:
    def __init__(self, style_of: Callable[[dict], Tuple[str, str]],
                 draw_legend: Callable[[object], None], paths: Dict[str, str],
                 limits=None):
        self.style_of = style_of
        self.draw_legend = draw_legend
        self.paths = paths
        self.limits = limits


def _dsp_colors(rows: List[dict]) -> Dict[int, str]:
    """Map each DSP value (sorted low->high) to its colour.

    The palette is count-dependent (see helper_config.DSP_COLORS): orange/blue
    anchor the low end, green/red the high end, yellow/purple fill the middle.
    """
    dsp_values = sorted({r["dsp"] for r in rows})
    n = len(dsp_values)
    if n > C.MAX_DSP_COLORS:
        raise SystemExit(
            f"ERROR: {n} distinct DSP values {dsp_values} but the palette only "
            f"defines up to {C.MAX_DSP_COLORS} colours - extend "
            f"helper_config.DSP_COLORS.")
    palette = C.dsp_palette(n)
    return {d: palette[i] for i, d in enumerate(dsp_values)}


def _dsp_markers(rows: List[dict]) -> Dict[int, str]:
    """Marker per DSP value for dsp_only mode, tied to that value's colour so a
    colour always draws the same shape (see helper_config.DSP_MARKER_FOR_COLOR)."""
    colour_of = _dsp_colors(rows)
    return {d: C.DSP_MARKER_FOR_COLOR[c] for d, c in colour_of.items()}


def make_encoding(mode: str, rows: List[dict], simd: int,
                  aligned: bool = False, limits=None) -> Encoding:
    """Build the Encoding for ``mode``/``simd`` from the data present in ``rows``.

    ``aligned`` selects the images_aligned/ output tree; ``limits`` = (xmin,
    xmax, ymax) forces a common axis range (only used when aligned).
    """
    paths = C.image_paths(simd, mode, aligned)
    color_for = _dsp_colors(rows)
    dsp_values = sorted(color_for)

    if mode == "method_dsp":
        # Colour = DSP, shape = (exp, rec) method pair; two legends.
        pair_of = {id(r): C.softmax_methods(r["method"]) for r in rows}
        pairs = sorted(set(pair_of.values()))
        marker_for = {p: C.PAIR_MARKERS[i % len(C.PAIR_MARKERS)]
                      for i, p in enumerate(pairs)}

        def style_of(r):
            return color_for[r["dsp"]], marker_for[pair_of[id(r)]]

        def draw_legend(ax):
            _legend_method_dsp(ax, dsp_values, color_for, pairs, marker_for)

    elif mode == "dsp_only":
        # DSP determines both colour and shape; single DSP legend.
        marker_for = _dsp_markers(rows)

        def style_of(r):
            return color_for[r["dsp"]], marker_for[r["dsp"]]

        def draw_legend(ax):
            _legend_dsp_only(ax, dsp_values, color_for, marker_for)

    else:
        raise ValueError(f"unknown encoding mode: {mode!r}")

    return Encoding(style_of, draw_legend, paths, limits=limits)


# --------------------------------------------------------------------------- #
# Legends
# --------------------------------------------------------------------------- #
def _legend_dsp_only(ax, dsp_values, color_for, marker_for) -> None:
    """Single DSP legend: colour + shape both encode DSP."""
    handles = [
        Line2D([0], [0], marker=marker_for[d], color="w", label=f"{d} DSP",
               markerfacecolor=color_for[d], markeredgecolor="black",
               markersize=8, linestyle="None")
        for d in dsp_values
    ]
    ax.legend(handles, [h.get_label() for h in handles], title="DSP",
              loc="upper right", frameon=True, edgecolor="black",
              facecolor="white")


def _legend_method_dsp(ax, dsp_values, color_for, pairs, marker_for) -> None:
    """Two legends: Exp+Rec (shape, larger) on the right, DSP (colour) to its left."""
    # Legend 1 (right) - Exp + Rec method pair (shape). Black shapes so it reads
    # as a pure shape key (colour is reserved for DSP).
    pair_handles = [
        Line2D([0], [0], marker=marker_for[(el, rl)], color="black",
               label=f"{el} + {rl}", markersize=8, linestyle="None")
        for (el, rl) in pairs
    ]
    leg1 = ax.legend(pair_handles, [h.get_label() for h in pair_handles],
                     title="Exp + Rec method", loc="upper right",
                     bbox_to_anchor=(1.0, 1.0),
                     frameon=True, edgecolor="black", facecolor="white")
    ax.add_artist(leg1)

    # Legend 2 (left) - DSP (colour). Fixed circle swatch so only the colour
    # carries meaning (shape is reserved for the method pair).
    dsp_handles = [
        Line2D([0], [0], marker="o", color="w", label=f"{d} DSP",
               markerfacecolor=color_for[d], markeredgecolor="black",
               markersize=8, linestyle="None")
        for d in dsp_values
    ]
    ax.figure.canvas.draw()
    bb = leg1.get_window_extent().transformed(ax.transAxes.inverted())
    # Anchor the DSP legend's top-right corner at y=1.0 (same top as the method
    # legend) so both frame tops line up; x is just left of it with a small gap.
    ax.legend(dsp_handles, [h.get_label() for h in dsp_handles], title="DSP",
              loc="upper right", bbox_to_anchor=(bb.x0 - 0.008, 1.0),
              frameon=True, edgecolor="black", facecolor="white")


# --------------------------------------------------------------------------- #
# Axes + scatter helpers (mode-agnostic)
# --------------------------------------------------------------------------- #
def _new_axes():
    fig, ax = plt.subplots(figsize=(6, 4))
    return fig, ax


def _finish_axes(ax, limits=None) -> None:
    """Axis labels, scale and grid (shared by every figure).

    If ``limits`` = (xmin, xmax, ymax) is given, force those ranges so every
    diagram is directly comparable (the images_aligned/ tree); otherwise the
    axes auto-scale (y still anchored at 0).
    """
    ax.set_xlabel("RMSRE")
    ax.set_ylabel("LUT Count")
    ax.set_xscale("log")
    if limits is not None:
        xmin, xmax, ymax = limits
        ax.set_xlim(xmin, xmax)
        ax.set_ylim(0, ymax)
    else:
        ax.set_ylim(bottom=0)
    ax.grid(True, which="major", axis="x", linestyle="--", linewidth=0.6, alpha=0.7)
    ax.grid(True, which="both", axis="y", linestyle="--", linewidth=0.6, alpha=0.7)


def _scatter(ax, rows, style_of, style) -> None:
    """Scatter ``rows`` grouped by their (colour, marker) so each group is one
    ``scatter`` call (scatter takes a single marker per call)."""
    groups: Dict[Tuple[str, str], List[dict]] = defaultdict(list)
    for r in rows:
        groups[style_of(r)].append(r)
    for (color, marker), grp in groups.items():
        ax.scatter([r["rmsre"] for r in grp], [r["lut"] for r in grp],
                   marker=marker, color=color, **style)


def _pareto_2d(rows: List[dict]) -> List[dict]:
    """Global 2D Pareto staircase vertices over (RMSRE, LUT), sorted by RMSRE."""
    pts = sorted(rows, key=lambda r: (r["rmsre"], r["lut"]))
    front: List[dict] = []
    best_lut = float("inf")
    for r in pts:
        if r["lut"] < best_lut:
            front.append(r)
            best_lut = r["lut"]
    return front


# --------------------------------------------------------------------------- #
# The three figures (each takes an Encoding)
# --------------------------------------------------------------------------- #
def plot_diagram(rows, enc: Encoding) -> None:
    """Scatter only, no Pareto line."""
    fig, ax = _new_axes()
    _scatter(ax, rows, enc.style_of, _PLAIN)
    _finish_axes(ax, enc.limits)
    enc.draw_legend(ax)
    fig.tight_layout()
    fig.savefig(enc.paths["diagram.png"], dpi=600, bbox_inches="tight")
    plt.close(fig)
    print(f"[PLOT] wrote {enc.paths['diagram.png']}")


def plot_pareto(rows, enc: Encoding) -> None:
    """Scatter + single global 2D Pareto staircase."""
    fig, ax = _new_axes()

    front = _pareto_2d(rows)
    front_ids = {id(r) for r in front}
    faded = [r for r in rows if id(r) not in front_ids]

    # Faded points first (behind), vibrant front points on top.
    _scatter(ax, faded, enc.style_of, _FADED)
    _scatter(ax, front, enc.style_of, _VIBRANT)

    # Single black staircase through the 2D front.
    ax.step([r["rmsre"] for r in front], [r["lut"] for r in front],
            where="post", color="black", linestyle="-", linewidth=1.2,
            alpha=0.7, zorder=3)

    _finish_axes(ax, enc.limits)
    enc.draw_legend(ax)
    fig.tight_layout()
    fig.savefig(enc.paths["pareto.png"], dpi=600, bbox_inches="tight")
    plt.close(fig)
    print(f"[PLOT] wrote {enc.paths['pareto.png']}  (2D front: {len(front)} pts, "
          f"faded: {len(faded)})")


def plot_full_pareto(rows, enc: Encoding) -> None:
    """Scatter + one Pareto staircase per DSP group.

    Every stored point is on the (full-precision) 3D front by construction, so
    all points are drawn vibrant and each DSP group gets its own staircase.
    """
    fig, ax = _new_axes()
    _scatter(ax, rows, enc.style_of, _VIBRANT)

    for d in sorted({r["dsp"] for r in rows}):
        grp = sorted((r for r in rows if r["dsp"] == d), key=lambda r: r["rmsre"])
        if not grp:
            continue
        ax.step([r["rmsre"] for r in grp], [r["lut"] for r in grp],
                where="post", color="gray", linestyle="-", linewidth=0.9,
                alpha=0.6, zorder=3)

    _finish_axes(ax, enc.limits)
    enc.draw_legend(ax)
    fig.tight_layout()
    fig.savefig(enc.paths["full_pareto.png"], dpi=600, bbox_inches="tight")
    plt.close(fig)
    print(f"[PLOT] wrote {enc.paths['full_pareto.png']}")


def plot(simd: int) -> None:
    """Render both figure sets for one SIMD value from its softmax.csv.

    Each set is rendered twice: once with auto-scaled axes (images/) and once
    with the global common axis range (images_aligned/), so aligned diagrams are
    directly comparable across SIMD values.
    """
    softmax_path = C.softmax_csv(simd)
    rows = C.read_components(softmax_path)
    if not rows:
        raise SystemExit(f"ERROR: {softmax_path} is empty - nothing to plot.")
    print(f"[PLOT] SIMD={simd}: {len(rows)} points, "
          f"DSP values {sorted({r['dsp'] for r in rows})}")

    limits = global_limits()

    for mode in C.IMAGE_MODES:
        # Unaligned tree: each diagram auto-scales.
        os.makedirs(C.image_dir(simd, mode, aligned=False), exist_ok=True)
        enc = make_encoding(mode, rows, simd, aligned=False)
        print(f"[PLOT] === SIMD={simd} / {mode} (images) ===")
        plot_diagram(rows, enc)
        plot_pareto(rows, enc)
        plot_full_pareto(rows, enc)

        # Aligned tree: common axis range across all SIMD values.
        os.makedirs(C.image_dir(simd, mode, aligned=True), exist_ok=True)
        enc_a = make_encoding(mode, rows, simd, aligned=True, limits=limits)
        print(f"[PLOT] === SIMD={simd} / {mode} (images_aligned) ===")
        plot_diagram(rows, enc_a)
        plot_pareto(rows, enc_a)
        plot_full_pareto(rows, enc_a)


def global_limits():
    """Common (xmin, xmax, ymax) across the softmax fronts of every SIMD value.

    The aligned figures use one shared range so plots are comparable: e.g. if
    SIMD=4 has the highest LUT, that y-top is used for SIMD=1 too.  A small
    margin is added to match the breathing room matplotlib gives auto-scaled
    axes (multiplicative in log-x, additive headroom in y).
    """
    xs: List[float] = []
    ys: List[int] = []
    for simd in C.SIMD_SWEEP:
        rows = C.read_components(C.softmax_csv(simd))
        xs.extend(r["rmsre"] for r in rows)
        ys.extend(r["lut"] for r in rows)
    xmin, xmax = min(xs), max(xs)
    ymax = max(ys)
    # log-space margin on x (~2% of a decade each side); 4% headroom on y.
    xpad = (xmax / xmin) ** 0.02
    return (xmin / xpad, xmax * xpad, ymax * 1.04)


def main() -> None:
    if len(sys.argv) > 1:
        simds = [int(sys.argv[1])]
    else:
        simds = C.SIMD_SWEEP
    for simd in simds:
        plot(simd)


if __name__ == "__main__":
    sys.exit(main())
