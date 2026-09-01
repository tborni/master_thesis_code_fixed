#!/usr/bin/env python3
"""Plot the LayerNorm N-sweep LUT usage against N, with an affine linear fit.

Reads ``data/resources.csv`` (the hand-authored synthesis report, columns
``N, SIMD, clock_period, WNS, Critical path timing, Max frequency, REG, LUT,
DSP, BRAM, URAM``) and renders the LUT utilisation against the vector length
``N`` together with a least-squares affine fit::

    LUT ~= m * N + n

The fit is over the *raw* N (not log N), so it is a straight line in N. Three
figures are produced, all with a linear LUT y-axis::

    images/resources_lut_linear.png    linear N x-axis (the fit is a straight
                                        line), but with the major grid lines on a
                                        base-2 locus: one line per power of two
                                        (2, 4, ..., 1024), so they bunch toward
                                        the origin and spread out to the right
    images/resources_lut_log.png       base-2 log N x-axis (the same fit renders
                                        as a log-shaped curve)
    images/resources_lut_combined.png  a linear-x panel (round ticks) beside a
                                        base-2 log-x panel, sharing a y-axis: the
                                        linear panel shows the fit is straight
                                        (LUT is linear in N) while the log panel
                                        keeps every sampled N legible

Rendering the identical ``m*N + n`` model on both axes lets the reader judge the
fit under both viewpoints: the linear-x view shows the affine relationship
directly, while the log-x view spreads the densely-packed small-N points apart.
The combined figure places the two panels together so a reader gets both the
"it is linear" evidence (straight line, left) and the "every point lies on it
across the full range" evidence (all N legible, right) in one figure.
The fit is labelled simply "Linear Fit" in the legend; the fitted slope,
intercept and coefficient of determination (R^2) are printed to stdout and
recorded in the shared ``data/fit_parameters.txt`` under a ``[resources]``
section (written via ``fit_report``, alongside the accuracy script's section).

Design notes
------------
* The fitted line is evaluated on a dense N grid spanning the sampled range, so
  it draws as a smooth straight line on the linear axis and a smooth curve on
  the log axis (rather than a coarse polyline through the sample N only).
* The measured points are blue markers and the fit is a red dashed line, so
  data and model are easy to tell apart; they also differ as markers vs. a line,
  so they stay distinct in greyscale print.
* Text uses matplotlib's built-in STIX mathtext fontset (LaTeX-quality serif
  without a system LaTeX install), matching the sibling figures.

The script resolves its input (``data/``) and output (``images/``) relative to
its own location, so it can be run from any working directory.
"""

from __future__ import annotations

import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # headless-safe: render to file without a display server.

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import FixedLocator, MaxNLocator, NullLocator

# Local sibling module (same scripts/ dir): the shared fit-parameters writer.
import fit_report

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figures land in the right place regardless of the
# current working directory, matching extract_accuracy.py / plot_accuracy.py.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

INPUT_CSV = DATA_DIR / "resources.csv"
OUTPUT_LINEAR_PNG = IMAGES_DIR / "resources_lut_linear.png"
OUTPUT_LOG_PNG = IMAGES_DIR / "resources_lut_log.png"
# Two-panel comparison (linear x | base-2 log x, shared y) combining the two
# single-axis views into one figure; see plot_pair for the rationale.
OUTPUT_PAIR_PNG = IMAGES_DIR / "resources_lut_combined.png"
# Shared fit-parameters file; this script owns its "[resources]" section (the
# accuracy script owns "[accuracy]"). See fit_report.update_section.
OUTPUT_FIT_TXT = DATA_DIR / "fit_parameters.txt"
FIT_SECTION = "resources"

# Blue markers for the measured LUT points and a red line for the fit, so the
# two are easy to tell apart (they also differ as markers vs. a dashed line).
COLOR_DATA = "#0072B2"   # blue
COLOR_FIT = "red"        # red, to contrast with the blue data markers

# Legend labels. LABEL_DATA is also used to sort the data entry ahead of the fit
# entry in the legend. The fitted slope/intercept are printed to stdout rather
# than shown in the legend, so the label is a plain descriptor.
LABEL_DATA = "Synthesized LUTs"
LABEL_FIT = "Linear Fit"


def load_resources_csv(path: Path) -> tuple[np.ndarray, np.ndarray]:
    """Load the ``(N, LUT)`` columns from ``resources.csv``.

    Returns two parallel float arrays sorted by ascending ``N``. Raises
    ``ValueError`` if the file is empty or missing the expected columns.
    """
    required = {"N", "LUT"}
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise ValueError(
                f"expected columns {sorted(required)} in {path}, found {reader.fieldnames}"
            )
        rows = [(float(row["N"]), float(row["LUT"])) for row in reader]
    if not rows:
        raise ValueError(f"no data rows in {path}")
    rows.sort(key=lambda r: r[0])
    n_vals = np.array([r[0] for r in rows], dtype=float)
    lut = np.array([r[1] for r in rows], dtype=float)
    return n_vals, lut


def affine_fit(n_vals: np.ndarray, lut: np.ndarray) -> tuple[float, float, float]:
    """Least-squares affine fit ``LUT = m*N + n``; return ``(m, n, r_squared)``.

    ``r_squared`` is the coefficient of determination of the fit against the raw
    LUT samples (1.0 = perfect, 0.0 = no better than the mean), so the figure can
    state honestly how well an affine model in N describes the data.
    """
    m, intercept = np.polyfit(n_vals, lut, deg=1)
    predicted = m * n_vals + intercept
    ss_res = float(np.sum((lut - predicted) ** 2))
    ss_tot = float(np.sum((lut - np.mean(lut)) ** 2))
    r_squared = 1.0 - ss_res / ss_tot if ss_tot > 0 else float("nan")
    return float(m), float(intercept), r_squared


def configure_style() -> None:
    """Apply the shared publication rcParams style (see plot_accuracy.py)."""
    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": ["STIXGeneral", "DejaVu Serif"],
            "mathtext.fontset": "stix",
            "axes.unicode_minus": True,
            "font.size": 20,
            "axes.titlesize": 22,
            "axes.labelsize": 26,
            "xtick.labelsize": 19,
            "ytick.labelsize": 19,
            "legend.fontsize": 24,
            "axes.linewidth": 0.8,
            "axes.edgecolor": "black",
            "xtick.direction": "out",
            "ytick.direction": "out",
            "xtick.major.width": 0.8,
            "ytick.major.width": 0.8,
            "xtick.major.size": 4.0,
            "ytick.major.size": 4.0,
            # Extra padding below the x tick labels so the horizontal 2^k labels
            # sit clear of the axis line/grid above them (default ~3.5pt).
            "xtick.major.pad": 6.0,
            "axes.grid": True,
            "grid.linestyle": "--",
            "grid.linewidth": 0.6,
            "grid.alpha": 0.7,
            "legend.frameon": True,
            "legend.framealpha": 1.0,
            "legend.edgecolor": "black",
            "legend.facecolor": "white",
            "legend.fancybox": True,
            "figure.dpi": 300,
            "savefig.dpi": 300,
        }
    )


def pow2_label(n: float) -> str:
    """Format a sampled ``N`` as a base-2 power label for the log x-axis.

    Every sampled ``N`` is a power of two, so on the base-2 log axis it is shown
    as ``2^k`` (rendered via mathtext, e.g. ``2^{10}`` for 1024) rather than the
    raw integer. Falls back to the plain integer for the (unexpected) case of an
    ``N`` that is not an exact power of two.
    """
    value = int(round(n))
    exp = value.bit_length() - 1
    if value > 0 and (1 << exp) == value:  # exact power of two
        return rf"$2^{{{exp}}}$"
    return str(value)


def power_of_two_ticks(hi: float) -> np.ndarray:
    """Return the powers of two ``2, 4, 8, ...`` up to and including ``hi``.

    Used to place the linear-x grid lines on a base-2 (log-spaced) locus while
    keeping the axis itself linear, so the sampled N (all powers of two) each get
    a grid line. ``hi`` is the largest N to cover; the smallest tick is 2 (=2**1),
    matching the sampled range (N >= 2).
    """
    if hi < 2:
        return np.array([], dtype=float)
    top = int(np.floor(np.log2(hi)))
    return np.array([2.0 ** k for k in range(1, top + 1)], dtype=float)


def sparse_labels(ticks: np.ndarray, axis_min: float, axis_max: float,
                  min_frac: float = 0.045) -> list[str]:
    """Label only ticks that are far enough apart to stay legible; blank the rest.

    On a *linear* axis the low powers of two (2, 4, 8, 16, ...) collapse toward
    the origin, so labelling every one would overprint an unreadable smear at the
    left. This walks the ticks left-to-right and keeps a label only when the tick
    is at least ``min_frac`` of the axis span past the previous *labelled* tick;
    intervening ticks still draw a grid line but carry an empty label. The largest
    tick is always labelled so the axis states its full extent. Kept ticks are
    labelled as powers of two (``2^k``) to match the base-2 grid locus. Returns a
    label string per tick (``""`` for the suppressed ones), parallel to ``ticks``.
    """
    span = axis_max - axis_min
    if span <= 0 or ticks.size == 0:
        return [pow2_label(t) for t in ticks]
    min_gap = min_frac * span
    labels = [""] * ticks.size
    last_labelled = -np.inf
    for i, t in enumerate(ticks):
        if t - last_labelled >= min_gap:
            labels[i] = pow2_label(t)
            last_labelled = t
    # Guarantee the largest tick is labelled (it anchors the axis extent); if the
    # greedy pass already labelled it this is a no-op.
    labels[-1] = pow2_label(ticks[-1])
    return labels


def draw_lut_axis(
    ax,
    n_vals: np.ndarray,
    lut: np.ndarray,
    m: float,
    intercept: float,
    log_x: bool,
    add_ylabel: bool = True,
    add_legend: bool = True,
    linear_grid: str = "pow2",
) -> None:
    """Draw the LUT-vs-N data + affine fit onto an existing axes ``ax``.

    Everything that defines a single LUT panel lives here -- the fit line, the
    measured markers, the axis scaling/ticks/grid and the legend -- so both the
    stand-alone figures (:func:`plot_one`) and the side-by-side comparison
    (:func:`plot_pair`) render identical panels from one code path. This routine
    does *not* create or save a figure; the caller owns that.

    The affine fit ``m*N + n`` is evaluated on a dense N grid so it renders
    smoothly: a straight line on a linear x-axis, a log-shaped curve on a base-2
    log x-axis. ``log_x`` selects the x-scaling; the y-axis is always linear.
    ``add_ylabel`` / ``add_legend`` let a shared-axis caller (the two-panel
    figure) place the y-label and legend on one panel only.

    ``linear_grid`` selects the x ticks/grid *when* ``log_x`` is False (it is
    ignored on the log axis):

    * ``"pow2"``  -- grid line at every power of two (2, 4, ..., 1024) on the
      linear axis, so the grid sits on the sampled N; used by the stand-alone
      ``resources_lut_linear.png``.
    * ``"round"`` -- evenly-spaced round ticks chosen by matplotlib (0, 256, 512,
      ...); used by the combined figure's linear panel, where the *log* panel
      already carries the every-N base-2 grid, so the linear panel is kept
      uncluttered and the two panels divide labour.
    """
    if linear_grid not in ("pow2", "round"):
        raise ValueError(f"linear_grid must be 'pow2' or 'round', got {linear_grid!r}")
    # Dense N grid for a smooth fit line across the sampled range. On the log
    # axis a geometric grid keeps the curve smooth where points bunch up at
    # small N; on the linear axis a uniform grid is used.
    n_min, n_max = float(n_vals.min()), float(n_vals.max())
    if log_x:
        grid = np.geomspace(n_min, n_max, 400)
    else:
        grid = np.linspace(n_min, n_max, 400)
    fit_curve = m * grid + intercept

    # Fitted line first (drawn under the markers).
    ax.plot(
        grid, fit_curve,
        color=COLOR_FIT, linestyle="--", linewidth=1.8,
        label=LABEL_FIT, zorder=2,
    )
    # Synthesized LUT points on top.
    ax.plot(
        n_vals, lut,
        color=COLOR_DATA, marker="o", linestyle="none",
        markersize=8, markeredgecolor="black", markeredgewidth=0.5,
        label=LABEL_DATA, zorder=3,
    )

    ax.set_xlabel(r"$N$")
    if add_ylabel:
        ax.set_ylabel(r"LUT Count")

    # Linear LUT y-axis in both figures, starting at 0 so the affine intercept
    # and the true magnitude of the LUT growth are visible.
    ax.set_ylim(bottom=0, top=float(lut.max()) * 1.12)

    if log_x:
        # Base-2 log x-axis (N is a power of two): one major tick per sampled N,
        # labelled as a power of two (2^k) to match the base-2 axis, base-2 minor
        # ticks suppressed. Labels sit horizontally (the 2^k form is compact
        # enough not to need slanting).
        ax.set_xscale("log", base=2)
        ax.set_xticks(n_vals)
        ax.set_xticklabels([pow2_label(n) for n in n_vals])
        ax.xaxis.set_minor_locator(NullLocator())
    elif linear_grid == "pow2":
        # Linear x-axis with a base-2 (log-spaced) grid: the axis scale stays
        # linear -- so the affine fit remains a straight line and the intercept
        # at N=0 is visible -- but the major grid lines are placed at every power
        # of two (2, 4, ..., 1024), the locus the sampled N actually live on.
        # On a linear axis those powers bunch toward the origin and spread out to
        # the right; that is the intended "logarithmic grid on a linear axis"
        # view. Ticks are drawn at every power of two (each gets a grid line),
        # but only the well-separated ones are labelled so the crowded low end
        # does not overprint an unreadable smear of text.
        ax.set_xlim(left=0, right=n_max * 1.03)
        pow2 = power_of_two_ticks(n_max)
        ax.xaxis.set_major_locator(FixedLocator(pow2))
        ax.set_xticklabels(sparse_labels(pow2, 0.0, n_max * 1.03))
        ax.xaxis.set_minor_locator(NullLocator())
    else:  # linear_grid == "round"
        # Linear x-axis with evenly-spaced round ticks chosen by matplotlib
        # (0, 256, 512, ...). Used by the combined figure's linear panel: the
        # sibling log panel already shows every sampled N on a base-2 grid, so
        # here the small-N points (2 .. 32) are simply left to bunch near the
        # origin as markers and the axis stays uncluttered.
        ax.set_xlim(left=0, right=n_max * 1.03)
        ax.xaxis.set_major_locator(MaxNLocator(nbins=8, integer=True))

    ax.grid(True, which="major", linestyle="--", linewidth=0.6, alpha=0.7)

    if add_legend:
        # Data legend entry before the fit entry (markers above the line ref.).
        handles, labels = ax.get_legend_handles_labels()
        order = sorted(range(len(labels)), key=lambda i: labels[i] != LABEL_DATA)
        ax.legend(
            [handles[i] for i in order], [labels[i] for i in order],
            loc="upper left", ncol=1, handlelength=2.2,
            borderpad=0.6, labelspacing=0.7,
            frameon=True, fancybox=True, edgecolor="black", facecolor="white",
        )


def plot_one(
    n_vals: np.ndarray,
    lut: np.ndarray,
    m: float,
    intercept: float,
    output_path: Path,
    log_x: bool,
) -> None:
    """Render a single LUT-vs-N figure (linear or log x-axis) to ``output_path``.

    Thin wrapper over :func:`draw_lut_axis`: it owns the figure lifecycle (create,
    tight-layout, save) while the shared routine draws the panel, so the two
    stand-alone figures stay identical to the two-panel figure's panels.
    """
    fig, ax = plt.subplots(figsize=(8.6, 5.2))
    draw_lut_axis(ax, n_vals, lut, m, intercept, log_x=log_x)
    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def plot_pair(
    n_vals: np.ndarray,
    lut: np.ndarray,
    m: float,
    intercept: float,
    output_path: Path,
) -> None:
    """Render the two-panel LUT-vs-N comparison (linear | base-2 log) side by side.

    A single affine fit ``LUT = m*N + n`` is drawn on both panels, which share a
    y-axis. The panels exist to resolve a genuine tension no single axis can:

    * Left (linear x-axis): the fit is a straight line, so the *linearity* of
      LUT-in-N is shown directly -- but the geometrically-sampled small-N points
      (2 .. 32) crowd against the origin.
    * Right (base-2 log x-axis): every sampled N is legible and sits on the fit,
      confirming the sweep spans a wide range -- but here the same affine fit
      necessarily renders as a curve (an affine function is not straight vs.
      log N).

    Seen together, the reader gets both the "it is linear" evidence and the
    "every point is on it across the full range" evidence. Short panel titles name
    each x-axis so the straight-vs-curved contrast is not mistaken for two
    different fits; the y-label and legend appear once, on the left panel.
    """
    fig, (ax_lin, ax_log) = plt.subplots(
        1, 2, figsize=(13.4, 5.2), sharey=True
    )

    # Left: linear x-axis -> straight-line fit (the linearity claim). Carries the
    # shared y-label and the legend. Uses plain round ticks (not the base-2 grid)
    # since the log panel already shows every sampled N, so this panel stays
    # uncluttered and the two panels divide labour.
    draw_lut_axis(
        ax_lin, n_vals, lut, m, intercept,
        log_x=False, add_ylabel=True, add_legend=True, linear_grid="round",
    )
    ax_lin.set_title("Linear $N$ axis")

    # Right: base-2 log x-axis -> all points legible (fit renders as a curve).
    # No y-label/legend: the shared y-axis and the left panel's legend cover it.
    draw_lut_axis(
        ax_log, n_vals, lut, m, intercept,
        log_x=True, add_ylabel=False, add_legend=False,
    )
    ax_log.set_title(r"Base-2 log $N$ axis")

    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def main() -> int:
    if not INPUT_CSV.is_file():
        print(f"error: input file not found: {INPUT_CSV}")
        return 1

    n_vals, lut = load_resources_csv(INPUT_CSV)
    m, intercept, r_squared = affine_fit(n_vals, lut)

    # Report the fit to stdout and to the shared fit-parameters file, using the
    # same formatted line for both so they can never drift. This script owns the
    # "[resources]" section; the accuracy script owns "[accuracy]".
    fit_line = fit_report.format_affine_line("LUT", "N", m, intercept, r_squared)
    print(f"Affine fit over {len(n_vals)} points: {fit_line}")
    fit_report.update_section(
        OUTPUT_FIT_TXT,
        FIT_SECTION,
        [
            f"# affine model  LUT = slope * N + intercept",
            f"# least-squares fit (numpy.polyfit) over {len(n_vals)} sampled N points",
            fit_line,
        ],
    )

    configure_style()
    plot_one(n_vals, lut, m, intercept, OUTPUT_LINEAR_PNG, log_x=False)
    plot_one(n_vals, lut, m, intercept, OUTPUT_LOG_PNG, log_x=True)
    plot_pair(n_vals, lut, m, intercept, OUTPUT_PAIR_PNG)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
