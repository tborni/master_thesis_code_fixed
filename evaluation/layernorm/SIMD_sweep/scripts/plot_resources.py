#!/usr/bin/env python3
"""Plot the LayerNorm SIMD-sweep LUT and DSP usage against SIMD, dual-axis.

Reads ``data/resources.csv`` (the hand-authored synthesis report, columns
``N, SIMD, clock_period, WNS, Critical path timing, Max frequency, REG, LUT,
DSP, BRAM, URAM``) and renders the LUT and DSP utilisation against the SIMD
unroll factor on a single figure with two independent linear y-axes::

    LUT ~= m_LUT * SIMD + n_LUT   (left y-axis,  blue circles)
    DSP ~= m_DSP * SIMD + n_DSP   (right y-axis, vermillion squares)

Each series carries its own least-squares affine fit, both taken over the *raw*
SIMD (not log SIMD), so each is a straight line in SIMD. Two figures are
produced, differing only in the x-axis scaling, both with linear y-axes::

    images/resources_linear.png   linear SIMD x-axis (the fits are straight lines)
    images/resources_log.png      base-2 log SIMD x-axis (the same fits render
                                   as log-shaped curves)

The fitted parameters themselves (slope, intercept and R^2 for each series) are
also written, freshly overwritten on every run, to a plain-text file::

    data/fit_parameters.txt

Rendering the identical ``m*SIMD + n`` models on both axes lets the reader judge
the fits under both viewpoints: the linear-x view shows the affine relationship
directly, while the log-x view spreads the densely-packed small-SIMD points
apart. Each fit is labelled simply "... linear fit" in the legend; the fitted
slopes, intercepts and coefficients of determination (R^2) are printed to stdout
and saved to ``data/fit_parameters.txt``.

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

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figures land in the right place regardless of the
# current working directory, matching the sibling N_sweep scripts.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

INPUT_CSV = DATA_DIR / "resources.csv"
OUTPUT_LINEAR_PNG = IMAGES_DIR / "resources_linear.png"
OUTPUT_LOG_PNG = IMAGES_DIR / "resources_log.png"
# The fitted affine parameters (slope + intercept, with R^2) for both series are
# written here, freshly overwritten, on every run.
OUTPUT_FIT_TXT = DATA_DIR / "fit_parameters.txt"

# Shared Okabe-Ito pair (matching rec/lookup/plot_coeff.py): LUT blue on the left
# axis, DSP vermillion on the right axis. Only each series' markers and fit line
# take this colour; the axis furniture (spines/ticks/labels) stays black, per
# standard academic convention.
COLOR_LUT = "#0072B2"   # blue       -> left y-axis (LUT)
COLOR_DSP = "#D55E00"   # vermillion -> right y-axis (DSP)

# Upper limit of the DSP (right) y-axis. Fixed rather than data-driven so the DSP
# curve is pushed down and sits clearly below the LUT curve, with no marker
# overlap: the largest DSP sample is 323, so 0..800 keeps the DSP trace in the
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


def format_fit_line(name: str, fit: tuple[float, float, float]) -> str:
    """Render one fitted series as a human-readable ``name = m * SIMD + n`` line.

    ``fit`` is the ``(slope, intercept, r_squared)`` triple from ``affine_fit``.
    Used for both the stdout report and the on-disk fit-parameters file, so the
    two never drift apart.
    """
    m, intercept, r_squared = fit
    return f"{name} = {m:.6g} * SIMD + {intercept:.6g}   (R^2 = {r_squared:.6f})"


def write_fit_parameters(
    path: Path,
    n_points: int,
    named_fits: list[tuple[str, tuple[float, float, float]]],
) -> None:
    """Write the fitted affine parameters for every series to ``path``.

    The file is overwritten on each run so it always reflects the current fit.
    A leading comment documents the model; each subsequent line is one series'
    ``name = slope * SIMD + intercept   (R^2 = ...)`` as printed to stdout.
    """
    lines = [
        "# LayerNorm SIMD-sweep resource fits: affine model  metric = slope * SIMD + intercept",
        f"# least-squares fit (numpy.polyfit) over {n_points} sampled SIMD points",
    ]
    lines.extend(format_fit_line(name, fit) for name, fit in named_fits)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Saved fit parameters to {path}")


def configure_style() -> None:
    """Apply the shared publication rcParams style (see N_sweep/plot_resources.py).

    ``axes.grid`` is left off here: on a dual-axis figure a grid drawn from both
    twinned axes would double up and misalign (the two y-scales differ), so the
    gridlines are added explicitly from the left axis only in ``plot_one``.
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

    ``lut_fit`` / ``dsp_fit`` are ``(m, n, r_squared)`` affine fits; the ``m*x+n``
    line is evaluated on a dense SIMD grid so it renders smoothly (straight on
    the linear axis, log-shaped on the log axis). ``log_x`` selects which
    x-scaling to use; both y-axes are always linear. The left y-axis carries LUT
    (blue), the right y-axis DSP (vermillion), and each axis is coloured to match
    its series so the reader can tell which curve belongs to which scale.
    """
    m_lut, n_lut, _ = lut_fit
    m_dsp, n_dsp, _ = dsp_fit

    fig, ax_lut = plt.subplots(figsize=(8.6, 5.2))
    ax_dsp = ax_lut.twinx()  # right y-axis sharing the SIMD x-axis.

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
    ax_lut.set_xlabel(r"SIMD")
    ax_lut.set_ylabel(r"LUT count")
    ax_dsp.set_ylabel(r"DSP count")

    # Linear y-axes, both from 0 so the affine intercepts and true magnitudes
    # are visible. The LUT (left) axis is auto-scaled to its data with headroom;
    # the DSP (right) axis is fixed to 0..DSP_YMAX so the DSP curve sits clearly
    # below the LUT curve rather than overlapping it.
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

    # Same (name, fit) list drives both the stdout report and the on-disk file.
    named_fits = [("LUT", lut_fit), ("DSP", dsp_fit)]
    print(f"Affine fits over {len(simd)} points:")
    for name, fit in named_fits:
        print(f"  {format_fit_line(name, fit)}")
    write_fit_parameters(OUTPUT_FIT_TXT, len(simd), named_fits)

    configure_style()
    plot_one(simd, lut, dsp, lut_fit, dsp_fit, OUTPUT_LINEAR_PNG, log_x=False)
    plot_one(simd, lut, dsp, lut_fit, dsp_fit, OUTPUT_LOG_PNG, log_x=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
