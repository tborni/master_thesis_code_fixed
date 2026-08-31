#!/usr/bin/env python3
"""Plot the Softmax SIMD-sweep LUT usage against SIMD, with an affine linear fit.

Reads ``data/resources.csv`` (the hand-authored synthesis report, columns
``N, SIMD, clock_period, WNS, Critical path timing, Max frequency, REG, LUT,
DSP, BRAM, URAM``) and renders the LUT utilisation against the SIMD unroll factor
together with a least-squares affine fit::

    LUT ~= m * SIMD + n

The vector length ``N`` is held fixed (N = 64) across this sweep, so SIMD is the
sole independent variable and the figure plots LUT against it. The fit is over
the *raw* SIMD (not log SIMD), so it is a straight line in SIMD. Two figures are
produced, differing only in the x-axis scaling, both with a linear LUT y-axis::

    images/resources_lut_linear.png   linear SIMD x-axis (the fit is a straight line)
    images/resources_lut_log.png      base-2 log SIMD x-axis (the same fit renders
                                       as a log-shaped curve)

Rendering the identical ``m*SIMD + n`` model on both axes lets the reader judge
the fit under both viewpoints: the linear-x view shows the affine relationship
directly, while the log-x view spreads the densely-packed small-SIMD points
apart. The fit is labelled simply "Linear fit" in the legend; the fitted slope,
intercept and coefficient of determination (R^2) are printed to stdout and
recorded in the shared ``data/fit_parameters.txt`` under a ``[resources]``
section (written via ``fit_report``).

Design notes
------------
* The fitted line is evaluated on a dense SIMD grid spanning the sampled range,
  so it draws as a smooth straight line on the linear axis and a smooth curve on
  the log axis (rather than a coarse polyline through the sample SIMD only).
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
# Shared fit-parameters file; this script owns its "[resources]" section.
# See fit_report.update_section.
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
LABEL_FIT = "Linear fit"


def load_resources_csv(path: Path) -> tuple[np.ndarray, np.ndarray]:
    """Load the ``(SIMD, LUT)`` columns from ``resources.csv``.

    Returns two parallel float arrays sorted by ascending ``SIMD``. Raises
    ``ValueError`` if the file is empty or missing the expected columns.
    """
    required = {"SIMD", "LUT"}
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise ValueError(
                f"expected columns {sorted(required)} in {path}, found {reader.fieldnames}"
            )
        rows = [(float(row["SIMD"]), float(row["LUT"])) for row in reader]
    if not rows:
        raise ValueError(f"no data rows in {path}")
    rows.sort(key=lambda r: r[0])
    simd = np.array([r[0] for r in rows], dtype=float)
    lut = np.array([r[1] for r in rows], dtype=float)
    return simd, lut


def affine_fit(simd: np.ndarray, lut: np.ndarray) -> tuple[float, float, float]:
    """Least-squares affine fit ``LUT = m*SIMD + n``; return ``(m, n, r_squared)``.

    ``r_squared`` is the coefficient of determination of the fit against the raw
    LUT samples (1.0 = perfect, 0.0 = no better than the mean), so the figure can
    state honestly how well an affine model in SIMD describes the data.
    """
    m, intercept = np.polyfit(simd, lut, deg=1)
    predicted = m * simd + intercept
    ss_res = float(np.sum((lut - predicted) ** 2))
    ss_tot = float(np.sum((lut - np.mean(lut)) ** 2))
    r_squared = 1.0 - ss_res / ss_tot if ss_tot > 0 else float("nan")
    return float(m), float(intercept), r_squared


def configure_style() -> None:
    """Apply the shared publication rcParams style (see the sibling figures)."""
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


def plot_one(
    simd: np.ndarray,
    lut: np.ndarray,
    m: float,
    intercept: float,
    output_path: Path,
    log_x: bool,
) -> None:
    """Render a single LUT-vs-SIMD figure (linear or log x-axis) to ``output_path``.

    The affine fit ``m*SIMD + n`` is evaluated on a dense SIMD grid so it renders
    smoothly: a straight line on the linear axis, a log-shaped curve on the log
    axis. ``log_x`` selects which x-scaling to use; the y-axis is always linear.
    """
    fig, ax = plt.subplots(figsize=(8.6, 5.2))

    # Dense SIMD grid for a smooth fit line across the sampled range. On the log
    # axis a geometric grid keeps the curve smooth where points bunch up at
    # small SIMD; on the linear axis a uniform grid is used.
    simd_min, simd_max = float(simd.min()), float(simd.max())
    if log_x:
        grid = np.geomspace(simd_min, simd_max, 400)
    else:
        grid = np.linspace(simd_min, simd_max, 400)
    fit_curve = m * grid + intercept

    # Fitted line first (drawn under the markers).
    ax.plot(
        grid, fit_curve,
        color=COLOR_FIT, linestyle="--", linewidth=1.8,
        label=LABEL_FIT, zorder=2,
    )
    # Synthesized LUT points on top.
    ax.plot(
        simd, lut,
        color=COLOR_DATA, marker="o", linestyle="none",
        markersize=8, markeredgecolor="black", markeredgewidth=0.5,
        label=LABEL_DATA, zorder=3,
    )

    ax.set_xlabel(r"SIMD")
    ax.set_ylabel(r"LUT count")

    # Linear LUT y-axis in both figures, starting at 0 so the affine intercept
    # and the true magnitude of the LUT growth are visible.
    ax.set_ylim(bottom=0, top=float(lut.max()) * 1.12)

    if log_x:
        # Base-2 log x-axis (SIMD is a power of two): one major tick per sampled
        # SIMD, labelled with its integer value, base-2 minor ticks suppressed.
        ax.set_xscale("log", base=2)
        ax.set_xticks(simd)
        ax.set_xticklabels([str(int(s)) for s in simd])
        ax.xaxis.set_minor_locator(NullLocator())
    else:
        # Linear x-axis: use evenly-spaced round ticks chosen by matplotlib.
        # Marking every sampled SIMD here would pile the small-SIMD values (1, 2,
        # 4, 8, 16) on top of each other near the origin; the measured points are
        # still visible as markers, so regular linear ticks read far cleaner.
        ax.set_xlim(left=0, right=simd_max * 1.03)
        ax.xaxis.set_major_locator(MaxNLocator(nbins=8, integer=True))

    ax.grid(True, which="major", linestyle="--", linewidth=0.6, alpha=0.7)

    # Data legend entry before the fit entry (markers above the line reference).
    handles, labels = ax.get_legend_handles_labels()
    order = sorted(range(len(labels)), key=lambda i: labels[i] != LABEL_DATA)
    ax.legend(
        [handles[i] for i in order], [labels[i] for i in order],
        loc="upper left", ncol=1, handlelength=2.2,
        borderpad=0.6, labelspacing=0.7,
        frameon=True, fancybox=True, edgecolor="black", facecolor="white",
    )

    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def main() -> int:
    if not INPUT_CSV.is_file():
        print(f"error: input file not found: {INPUT_CSV}")
        return 1

    simd, lut = load_resources_csv(INPUT_CSV)
    m, intercept, r_squared = affine_fit(simd, lut)

    # Report the fit to stdout and to the shared fit-parameters file, using the
    # same formatted line for both so they can never drift. This script owns the
    # "[resources]" section.
    fit_line = fit_report.format_affine_line("LUT", "SIMD", m, intercept, r_squared)
    print(f"Affine fit over {len(simd)} points: {fit_line}")
    fit_report.update_section(
        OUTPUT_FIT_TXT,
        FIT_SECTION,
        [
            f"# affine model  LUT = slope * SIMD + intercept",
            f"# least-squares fit (numpy.polyfit) over {len(simd)} sampled SIMD points",
            fit_line,
        ],
    )

    configure_style()
    plot_one(simd, lut, m, intercept, OUTPUT_LINEAR_PNG, log_x=False)
    plot_one(simd, lut, m, intercept, OUTPUT_LOG_PNG, log_x=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
