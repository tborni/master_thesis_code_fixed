#!/usr/bin/env python3
"""Plot the Softmax SIMD-sweep LUT and DSP usage against SIMD, dual-axis.

Reads ``data/resources.csv`` (the hand-authored synthesis report, columns
``N, SIMD, clock_period, WNS, Critical path timing, Max frequency, REG, LUT,
DSP, BRAM, URAM``) and renders the LUT and DSP utilisation against the SIMD
unroll factor on a single figure with two independent linear y-axes::

    LUT ~= m_LUT * SIMD + n_LUT   (left y-axis,  blue circles)
    DSP ~= m_DSP * SIMD + n_DSP   (right y-axis, vermillion squares)

The vector length ``N`` is held fixed (N = 64) across this sweep, so SIMD is the
sole independent variable. Each series carries its own least-squares affine fit,
both taken over the *raw* SIMD (not log SIMD), so each is a straight line in
SIMD. Three figures are produced, all with linear y-axes::

    images/resources_lut_linear.png    linear SIMD x-axis (the fits are straight
                                        lines)
    images/resources_lut_log.png       base-2 log SIMD x-axis (the same fits
                                        render as log-shaped curves)
    images/resources_lut_combined.png  a linear-x panel beside a base-2 log-x
                                        panel, sharing both y-scales: the LUT
                                        (left) axis is ticked and labelled on the
                                        far-left panel only and the DSP (right)
                                        axis on the far-right panel only, so the
                                        two dual-axis panels read as one figure.
                                        The linear panel shows the fits are
                                        straight while the log panel keeps every
                                        sampled SIMD legible

Rendering the identical ``m*SIMD + n`` models on both axes lets the reader judge
the fits under both viewpoints: the linear-x view shows the affine relationship
directly, while the log-x view spreads the densely-packed small-SIMD points
apart. The combined figure places the two panels together so a reader gets both
the "they are linear" evidence (straight lines, left) and the "every point lies
on them across the full range" evidence (all SIMD legible, right) in one figure.
Each fit is labelled simply "... linear fit" in the legend; the fitted slopes,
intercepts and coefficients of determination (R^2) are printed to stdout and
recorded in the shared ``data/fit_parameters.txt`` under a ``[resources]``
section (written via ``fit_report``).

Design notes
------------
* This is a *dual-axis* figure (``twinx``): LUT and DSP have very different
  magnitudes (LUTs in the hundreds-to-thousands, DSPs in the tens-to-hundreds),
  so a shared axis would flatten one series. The axis furniture (spines, ticks,
  labels) stays black per standard academic convention; each y-axis label names
  its series, and the two curves are told apart by colour and marker shape.
* The two series use the shared Okabe-Ito pair (LUT blue ``#0072B2``, DSP
  vermillion ``#D55E00``, matching rec/lookup/plot_coeff.py) and *distinct*
  marker shapes (circle vs. square), so they stay distinguishable even in
  greyscale print. Each fit is a dashed line in its series' colour.
* Both fitted lines are evaluated on a dense SIMD grid spanning the sampled
  range, so they draw as smooth straight lines on the linear axis and smooth
  curves on the log axis (rather than coarse polylines through the sample SIMD).
* Both y-axes start at 0 so the affine intercepts and the true magnitude of the
  growth are visible. The DSP (right) axis is fixed to 0..``DSP_YMAX`` (800)
  rather than auto-scaled, which pushes the DSP curve into the lower part of the
  plot so it sits clearly below the LUT curve instead of overlapping it.
* A single combined legend gathers the handles from both axes (the two twinned
  axes would otherwise each render their own).
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
from matplotlib.ticker import MaxNLocator, NullLocator

# Local sibling module (same scripts/ dir): the shared fit-parameters writer.
import fit_report

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figures land in the right place regardless of the
# current working directory, matching extract_accuracy.py.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

INPUT_CSV = DATA_DIR / "resources.csv"
OUTPUT_LINEAR_PNG = IMAGES_DIR / "resources_lut_linear.png"
OUTPUT_LOG_PNG = IMAGES_DIR / "resources_lut_log.png"
# Two-panel comparison (linear x | base-2 log x) combining the two single-axis
# views into one dual-axis figure; see plot_pair for the layout rationale.
OUTPUT_PAIR_PNG = IMAGES_DIR / "resources_lut_combined.png"
# Shared fit-parameters file; this script owns its "[resources]" section.
# See fit_report.update_section.
OUTPUT_FIT_TXT = DATA_DIR / "fit_parameters.txt"
FIT_SECTION = "resources"

# Shared Okabe-Ito pair (matching rec/lookup/plot_coeff.py): LUT blue on the left
# axis, DSP vermillion on the right axis. Only each series' markers and fit line
# take this colour; the axis furniture (spines/ticks/labels) stays black, per
# standard academic convention.
COLOR_LUT = "#0072B2"   # blue       -> left y-axis (LUT)
COLOR_DSP = "#D55E00"   # vermillion -> right y-axis (DSP)

# Upper limit of the DSP (right) y-axis. Fixed rather than data-driven so the DSP
# curve is pushed down and sits clearly below the LUT curve, with no marker
# overlap: the largest DSP sample is 322, so 0..800 keeps the DSP trace in the
# lower ~40% of the axis, well below the LUT markers.
DSP_YMAX = 800.0

# Legend labels for the four drawn artists (two data series + two fit lines).
LABEL_LUT_DATA = "Synthesized LUTs"
LABEL_LUT_FIT = "LUT linear fit"
LABEL_DSP_DATA = "Synthesized DSPs"
LABEL_DSP_FIT = "DSP linear fit"


def load_resources_csv(
    path: Path,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load the ``(SIMD, LUT, DSP)`` columns from ``resources.csv``.

    Returns three parallel float arrays sorted by ascending ``SIMD``. Raises
    ``ValueError`` if the file is empty or missing the expected columns.
    """
    required = {"SIMD", "LUT", "DSP"}
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise ValueError(
                f"expected columns {sorted(required)} in {path}, found {reader.fieldnames}"
            )
        rows = [
            (float(row["SIMD"]), float(row["LUT"]), float(row["DSP"]))
            for row in reader
        ]
    if not rows:
        raise ValueError(f"no data rows in {path}")
    rows.sort(key=lambda r: r[0])
    simd = np.array([r[0] for r in rows], dtype=float)
    lut = np.array([r[1] for r in rows], dtype=float)
    dsp = np.array([r[2] for r in rows], dtype=float)
    return simd, lut, dsp


def affine_fit(x: np.ndarray, y: np.ndarray) -> tuple[float, float, float]:
    """Least-squares affine fit ``y = m*x + n``; return ``(m, n, r_squared)``.

    ``r_squared`` is the coefficient of determination of the fit against the raw
    samples (1.0 = perfect, 0.0 = no better than the mean), so the figure can
    state honestly how well an affine model in SIMD describes the data.
    """
    m, intercept = np.polyfit(x, y, deg=1)
    predicted = m * x + intercept
    ss_res = float(np.sum((y - predicted) ** 2))
    ss_tot = float(np.sum((y - np.mean(y)) ** 2))
    r_squared = 1.0 - ss_res / ss_tot if ss_tot > 0 else float("nan")
    return float(m), float(intercept), r_squared


def configure_style() -> None:
    """Apply the shared publication rcParams style (see the sibling figures).

    ``axes.grid`` is left off here: on a dual-axis figure a grid drawn from both
    twinned axes would double up and misalign (the two y-scales differ), so the
    gridlines are added explicitly from the left axis only in ``draw_dual_axis``.
    """
    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": ["STIXGeneral", "DejaVu Serif"],
            "mathtext.fontset": "stix",
            "axes.unicode_minus": True,
            "font.size": 16,
            "axes.titlesize": 18,
            "axes.labelsize": 18,
            "xtick.labelsize": 15,
            "ytick.labelsize": 15,
            "legend.fontsize": 15,
            "axes.linewidth": 0.8,
            "axes.edgecolor": "black",
            "xtick.direction": "out",
            "ytick.direction": "out",
            "xtick.major.width": 0.8,
            "ytick.major.width": 0.8,
            "xtick.major.size": 4.0,
            "ytick.major.size": 4.0,
            # Grid drawn manually from the left axis (see docstring above).
            "axes.grid": False,
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


def _fit_grid(simd: np.ndarray, log_x: bool) -> np.ndarray:
    """Dense SIMD grid for a smooth fit line across the sampled range.

    A geometric grid on the log axis keeps the curve smooth where points bunch
    up at small SIMD; a uniform grid on the linear axis.
    """
    simd_min, simd_max = float(simd.min()), float(simd.max())
    if log_x:
        return np.geomspace(simd_min, simd_max, 400)
    return np.linspace(simd_min, simd_max, 400)


def draw_dual_axis(
    ax_lut,
    ax_dsp,
    simd: np.ndarray,
    lut: np.ndarray,
    dsp: np.ndarray,
    lut_fit: tuple[float, float, float],
    dsp_fit: tuple[float, float, float],
    log_x: bool,
    show_lut_labels: bool = True,
    show_dsp_labels: bool = True,
    add_legend: bool = True,
) -> None:
    """Draw the dual-axis LUT+DSP-vs-SIMD panel onto the twinned axes ``ax_lut``/``ax_dsp``.

    Everything that defines a single dual-axis panel lives here -- both series'
    fit lines and markers, the y-limits, the x scaling/ticks/grid and the combined
    legend -- so both the stand-alone figures (:func:`plot_one`) and the
    side-by-side comparison (:func:`plot_pair`) render identical panels from one
    code path. The caller owns the figure and must pass an ``ax_lut`` together with
    its ``ax_dsp = ax_lut.twinx()``; this routine does *not* create or save a
    figure.

    ``lut_fit`` / ``dsp_fit`` are ``(m, n, r_squared)`` affine fits; the ``m*x+n``
    line is evaluated on a dense SIMD grid so it renders smoothly (straight on the
    linear axis, log-shaped on the log axis). ``log_x`` selects which x-scaling to
    use; both y-axes are always linear. The left y-axis carries LUT (blue), the
    right y-axis DSP (vermillion).

    ``show_lut_labels`` / ``show_dsp_labels`` / ``add_legend`` let a shared-axis
    caller (the two-panel figure) place the LUT y-axis furniture on the far-left
    panel only, the DSP y-axis furniture on the far-right panel only, and the
    legend on one panel only; the stand-alone figures leave all three on.
    """
    m_lut, n_lut, _ = lut_fit
    m_dsp, n_dsp, _ = dsp_fit

    grid = _fit_grid(simd, log_x)

    # --- Left axis: LUT (blue) -------------------------------------------------
    # Fit first (drawn under the markers), then the measured points.
    ax_lut.plot(
        grid, m_lut * grid + n_lut,
        color=COLOR_LUT, linestyle="--", linewidth=1.8,
        label=LABEL_LUT_FIT, zorder=2,
    )
    ax_lut.plot(
        simd, lut,
        color=COLOR_LUT, marker="o", linestyle="none",
        markersize=8, markeredgecolor="black", markeredgewidth=0.5,
        label=LABEL_LUT_DATA, zorder=4,
    )

    # --- Right axis: DSP (vermillion) -----------------------------------------
    ax_dsp.plot(
        grid, m_dsp * grid + n_dsp,
        color=COLOR_DSP, linestyle="--", linewidth=1.8,
        label=LABEL_DSP_FIT, zorder=3,
    )
    ax_dsp.plot(
        simd, dsp,
        color=COLOR_DSP, marker="s", linestyle="none",
        markersize=8, markeredgecolor="black", markeredgewidth=0.5,
        label=LABEL_DSP_DATA, zorder=5,
    )

    # --- Axis labels and limits -----------------------------------------------
    # Standard academic convention: the axes themselves (spines, ticks, labels)
    # stay black. The two series remain distinguishable by their marker/line
    # colour and shape, and each y-axis label names its series so the axis <->
    # curve mapping is still explicit without colouring the axis furniture.
    #
    # In the two-panel figure the LUT (left) axis furniture is shown on the
    # far-left panel only and the DSP (right) axis furniture on the far-right
    # panel only; the inner copies keep the same limits but hide their tick
    # labels so the panels read as one shared pair of y-scales.
    ax_lut.set_xlabel(r"SIMD")
    if show_lut_labels:
        ax_lut.set_ylabel(r"LUT Count")
    else:
        ax_lut.tick_params(axis="y", labelleft=False)
    if show_dsp_labels:
        ax_dsp.set_ylabel(r"DSP count")
    else:
        ax_dsp.tick_params(axis="y", labelright=False)

    # Linear y-axes, both from 0 so the affine intercepts and true magnitudes
    # are visible. The LUT (left) axis is auto-scaled to its data with headroom;
    # the DSP (right) axis is fixed to 0..DSP_YMAX so the DSP curve sits clearly
    # below the LUT curve rather than overlapping it. Both limits are identical
    # across the two panels, so the shared y-scales line up despite the inner
    # tick labels being hidden.
    ax_lut.set_ylim(bottom=0, top=float(lut.max()) * 1.12)
    ax_dsp.set_ylim(bottom=0, top=DSP_YMAX)

    # --- X-axis ---------------------------------------------------------------
    if log_x:
        # Base-2 log x-axis (SIMD is a power of two): one major tick per sampled
        # SIMD, labelled with its integer value, base-2 minor ticks suppressed.
        ax_lut.set_xscale("log", base=2)
        ax_lut.set_xticks(simd)
        ax_lut.set_xticklabels([str(int(s)) for s in simd])
        ax_lut.xaxis.set_minor_locator(NullLocator())
    else:
        # Linear x-axis: evenly-spaced integer ticks chosen by matplotlib. The
        # measured points stay visible as markers, so regular ticks read cleaner
        # than piling every sampled SIMD (1, 2, 4, 8, ...) near the origin.
        ax_lut.set_xlim(left=0, right=float(simd.max()) * 1.03)
        ax_lut.xaxis.set_major_locator(MaxNLocator(nbins=8, integer=True))

    # Grid from the left (LUT) axis only, to avoid the double/misaligned grid a
    # second twinned axis would draw. Neutral grey so it favours neither series.
    ax_lut.grid(
        True, which="major", axis="both",
        color="0.5", linestyle="--", linewidth=0.6, alpha=0.7, zorder=0,
    )

    # --- Combined legend ------------------------------------------------------
    # Gather handles from both axes into one legend, ordered LUT data, LUT fit,
    # DSP data, DSP fit so each series' marker sits above its fit line.
    if add_legend:
        h_lut, l_lut = ax_lut.get_legend_handles_labels()
        h_dsp, l_dsp = ax_dsp.get_legend_handles_labels()
        order = [
            LABEL_LUT_DATA, LABEL_LUT_FIT, LABEL_DSP_DATA, LABEL_DSP_FIT,
        ]
        handle_by_label = dict(zip(l_lut + l_dsp, h_lut + h_dsp))
        ordered = [(handle_by_label[lbl], lbl) for lbl in order if lbl in handle_by_label]
        ax_lut.legend(
            [h for h, _ in ordered], [lbl for _, lbl in ordered],
            loc="upper left", ncol=1, handlelength=2.2,
            borderpad=0.6, labelspacing=0.7,
            frameon=True, fancybox=True, edgecolor="black", facecolor="white",
        ).set_zorder(6)


def plot_one(
    simd: np.ndarray,
    lut: np.ndarray,
    dsp: np.ndarray,
    lut_fit: tuple[float, float, float],
    dsp_fit: tuple[float, float, float],
    output_path: Path,
    log_x: bool,
) -> None:
    """Render a single dual-axis LUT+DSP-vs-SIMD figure to ``output_path``.

    Thin wrapper over :func:`draw_dual_axis`: it owns the figure lifecycle (create
    the axis + its twin, tight-layout, save) while the shared routine draws the
    panel, so the two stand-alone figures stay identical to the two-panel figure's
    panels.
    """
    fig, ax_lut = plt.subplots(figsize=(8.6, 5.2))
    ax_dsp = ax_lut.twinx()  # right y-axis sharing the SIMD x-axis.
    draw_dual_axis(
        ax_lut, ax_dsp, simd, lut, dsp, lut_fit, dsp_fit, log_x=log_x,
    )
    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def plot_pair(
    simd: np.ndarray,
    lut: np.ndarray,
    dsp: np.ndarray,
    lut_fit: tuple[float, float, float],
    dsp_fit: tuple[float, float, float],
    output_path: Path,
) -> None:
    """Render the two-panel dual-axis comparison (linear | base-2 log) side by side.

    Both panels draw the same two affine fits (LUT left, DSP right) and share both
    y-scales. The panels exist to resolve a genuine tension no single x-axis can:

    * Left (linear x-axis): the fits are straight lines, so the *linearity* of
      LUT- and DSP-in-SIMD is shown directly -- but the geometrically-sampled
      small-SIMD points crowd against the origin.
    * Right (base-2 log x-axis): every sampled SIMD is legible and sits on the
      fits, confirming the sweep spans a wide range -- but here the same affine
      fits necessarily render as curves (an affine function is not straight vs.
      log SIMD).

    Because the figure is dual-axis, each panel has its own LUT (left) and DSP
    (right) y-axis. To keep it readable the outer spines carry the labels/ticks
    and the inner ones are de-labelled: the LUT axis is ticked and labelled on the
    far-left panel only, the DSP axis on the far-right panel only, and both panels
    use identical y-limits so the shared scales line up. Short panel titles name
    each x-axis so the straight-vs-curved contrast is not mistaken for different
    fits; the combined legend appears once, on the left panel.
    """
    fig, (ax_lin, ax_log) = plt.subplots(1, 2, figsize=(13.4, 5.2))
    ax_lin_dsp = ax_lin.twinx()  # right (DSP) axis of the linear panel.
    ax_log_dsp = ax_log.twinx()  # right (DSP) axis of the log panel.

    # Left: linear x-axis -> straight-line fits (the linearity claim). Shows the
    # LUT (left) y-axis furniture and the combined legend; its DSP (right, inner)
    # axis keeps the shared limits but hides its tick labels.
    draw_dual_axis(
        ax_lin, ax_lin_dsp, simd, lut, dsp, lut_fit, dsp_fit,
        log_x=False, show_lut_labels=True, show_dsp_labels=False, add_legend=True,
    )
    ax_lin.set_title("Linear SIMD axis")

    # Right: base-2 log x-axis -> all points legible (fits render as curves).
    # Shows the DSP (right) y-axis furniture on the far right; its LUT (left,
    # inner) axis keeps the shared limits but hides its tick labels, and the
    # legend is omitted (the left panel carries it).
    draw_dual_axis(
        ax_log, ax_log_dsp, simd, lut, dsp, lut_fit, dsp_fit,
        log_x=True, show_lut_labels=False, show_dsp_labels=True, add_legend=False,
    )
    ax_log.set_title(r"Base-2 log SIMD axis")

    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def main() -> int:
    if not INPUT_CSV.is_file():
        print(f"error: input file not found: {INPUT_CSV}")
        return 1

    simd, lut, dsp = load_resources_csv(INPUT_CSV)
    lut_fit = affine_fit(simd, lut)
    dsp_fit = affine_fit(simd, dsp)

    # Report both fits to stdout and to the shared fit-parameters file, using the
    # same formatted lines for both so they can never drift. This script owns the
    # "[resources]" section.
    lut_m, lut_n, lut_r2 = lut_fit
    dsp_m, dsp_n, dsp_r2 = dsp_fit
    lut_line = fit_report.format_affine_line("LUT", "SIMD", lut_m, lut_n, lut_r2)
    dsp_line = fit_report.format_affine_line("DSP", "SIMD", dsp_m, dsp_n, dsp_r2)
    print(f"Affine fits over {len(simd)} points:")
    print(f"  {lut_line}")
    print(f"  {dsp_line}")
    fit_report.update_section(
        OUTPUT_FIT_TXT,
        FIT_SECTION,
        [
            f"# affine model  metric = slope * SIMD + intercept",
            f"# least-squares fit (numpy.polyfit) over {len(simd)} sampled SIMD points",
            lut_line,
            dsp_line,
        ],
    )

    configure_style()
    plot_one(simd, lut, dsp, lut_fit, dsp_fit, OUTPUT_LINEAR_PNG, log_x=False)
    plot_one(simd, lut, dsp, lut_fit, dsp_fit, OUTPUT_LOG_PNG, log_x=True)
    plot_pair(simd, lut, dsp, lut_fit, dsp_fit, OUTPUT_PAIR_PNG)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
