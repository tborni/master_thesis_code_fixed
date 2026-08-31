#!/usr/bin/env python3
"""Plot the Softmax N-sweep accuracy as two publication figures.

Reads the two accuracy tables produced by ``extract_accuracy.py``::

    data/accuracy_large_error.csv   (large-error reference configuration)
    data/accuracy_small_error.csv   (small-error reference configuration)

each with columns ``N, SIMD, RMSRE, MAX_REL_ERROR``, and renders one figure per
table of the RMS relative error (RMSRE) against the vector length ``N``::

    images/accuracy_large_error.png
    images/accuracy_small_error.png

The two configurations are kept as *separate* figures rather than overlaid: their
RMSRE magnitudes differ by roughly two orders of magnitude (~1e-4 vs. ~1e-6), so a
shared linear y-axis would flatten one series into the baseline. One figure each,
with its own linear y-axis, keeps both readable at their native scale.

Design notes
------------
* The x-axis is logarithmic and the y-axis is linear (a semilog-x view). ``N``
  spans over three decades (2 .. 16384, always a power of two), so a log x-axis
  keeps the densely-packed small-N points legible; RMSRE varies only mildly
  across the sweep (well under one decade), so a *linear* y-axis shows those
  variations at their true relative size rather than compressing them the way a
  log y-axis would. The x-axis uses base 2 (``N`` is a power of two) with the
  actual N values as tick labels.
* Because the y-axis is linear and the series is not a clean power law, the raw
  measurements are drawn as bare markers (no connecting line and no fitted
  curve): the figure shows the sweep exactly as sampled. RMSRE is rescaled by a
  fixed power of ten (1e-4 for the large-error figure, 1e-6 for the small-error
  one) so the tick labels are small plain numbers, and that factor is written
  into the y-axis label -- ``RMSRE (x10^-4)`` -- rather than shown as a floating
  axis-offset multiplier, matching rec/lookup's accuracy_newton_coeff figure.
* Both figures use the same Okabe-Ito blue with black-edged markers, matching the
  palette shared across the thesis figures.
* Text uses matplotlib's built-in STIX mathtext fontset, which gives
  LaTeX-quality serif type without a system LaTeX install, so the figures build
  reproducibly from the Makefile.

The script resolves its input (``data/``) and output (``images/``) relative to
its own location, so it can be run from any working directory.
"""

from __future__ import annotations

import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # headless-safe: render to file without a display server.

import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator, NullLocator

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figures land in the right place regardless of the
# current working directory, matching extract_accuracy.py / plot_resources.py.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

# Okabe-Ito blue for the measured points in both figures.
COLOR_DATA = "#0072B2"

# The two series to plot, one per figure:
#   (csv filename, output png, y_unit, y_unit_label)
# RMSRE is scaled by ``y_unit`` so the tick labels are small plain numbers and the
# common power of ten is carried in the y-axis label instead (e.g. "RMSRE
# (x10^-4)"), matching rec/lookup's accuracy_newton_coeff figure. The large- and
# small-error series sit at ~1e-4 and ~1e-6 respectively, so each figure uses the
# factor natural to its own magnitude.
SERIES = (
    ("accuracy_large_error.csv", "accuracy_large_error.png", 1e-4, r"10^{-4}"),
    ("accuracy_small_error.csv", "accuracy_small_error.png", 1e-6, r"10^{-6}"),
)


def load_accuracy_csv(path: Path) -> tuple[list[int], list[float]]:
    """Load the ``(N, RMSRE)`` columns from an accuracy CSV.

    Returns two parallel lists sorted by ascending ``N`` (so the points are laid
    out in x-order regardless of the file's row order). Raises ``ValueError`` if
    the file is empty or missing the expected columns.
    """
    required = {"N", "RMSRE"}
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise ValueError(
                f"expected columns {sorted(required)} in {path}, found {reader.fieldnames}"
            )
        rows = [(int(row["N"]), float(row["RMSRE"])) for row in reader]
    if not rows:
        raise ValueError(f"no data rows in {path}")
    rows.sort(key=lambda r: r[0])
    n_vals = [r[0] for r in rows]
    rmsre = [r[1] for r in rows]
    return n_vals, rmsre


def configure_style() -> None:
    """Apply a restrained, publication-oriented rcParams style.

    Mirrors the style used by the sibling line plots (rec/lookup/plot_coeff.py)
    so every figure in the thesis shares one visual language.
    """
    plt.rcParams.update(
        {
            # Serif text + matching math, no external LaTeX dependency.
            "font.family": "serif",
            "font.serif": ["STIXGeneral", "DejaVu Serif"],
            "mathtext.fontset": "stix",
            "axes.unicode_minus": True,
            # Typographic sizes tuned for a ~half-to-full text-width figure.
            "font.size": 16,
            "axes.titlesize": 18,
            "axes.labelsize": 18,
            "xtick.labelsize": 15,
            "ytick.labelsize": 15,
            "legend.fontsize": 16,
            # Full black frame (all four spines) with outward ticks.
            "axes.linewidth": 0.8,
            "axes.edgecolor": "black",
            "xtick.direction": "out",
            "ytick.direction": "out",
            "xtick.major.width": 0.8,
            "ytick.major.width": 0.8,
            "xtick.major.size": 4.0,
            "ytick.major.size": 4.0,
            # Dashed grid, matching the pareto/coeff figures' style.
            "axes.grid": True,
            "grid.linestyle": "--",
            "grid.linewidth": 0.6,
            "grid.alpha": 0.7,
            # Legend box: rounded corners with a solid black frame on white.
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
    n_vals: list[int],
    rmsre: list[float],
    y_unit: float,
    y_unit_label: str,
    output_path: Path,
) -> None:
    """Render a single RMSRE-vs-N figure (linear y, base-2 log x) to ``output_path``.

    The measurements are drawn as bare black-edged blue markers (no connecting
    line, no fit): on a linear y-axis the sweep is shown exactly as sampled. The
    x-axis is a base-2 log axis with one tick per sampled ``N``. RMSRE is scaled
    by ``y_unit`` so the tick labels are small plain numbers, with the common
    power of ten (``y_unit_label``) carried in the y-axis label instead of a
    floating axis-offset multiplier.
    """
    fig, ax = plt.subplots(figsize=(8.6, 5.2))

    # Scale RMSRE into units of ``y_unit`` (e.g. 1e-4) so the tick labels are
    # small numbers; the axis label carries the factor. This preserves the shape
    # of the series exactly (a common linear rescaling of the y-axis).
    y_scaled = [v / y_unit for v in rmsre]

    ax.plot(
        n_vals, y_scaled,
        color=COLOR_DATA, marker="o", linestyle="none",
        markersize=8, markeredgecolor="black", markeredgewidth=0.5,
        label="Measured Accuracy", zorder=3,
    )

    # Base-2 log x-axis (N is a power of two); linear y-axis for RMSRE.
    ax.set_xscale("log", base=2)
    ax.set_yscale("linear")

    ax.set_xlabel(r"$N$")
    # Factor next to the metric, as in rec/lookup's accuracy_newton_coeff figure.
    ax.set_ylabel(rf"RMSRE  $(\times\,{y_unit_label})$")

    # Show every sampled N as a major tick, labelled with its integer value, and
    # suppress the base-2 minor ticks so the axis stays uncluttered.
    ax.set_xticks(n_vals)
    ax.set_xticklabels([str(n) for n in n_vals], rotation=45, ha="right")
    ax.xaxis.set_minor_locator(NullLocator())

    # Linear y-axis: start at 0 so the RMSRE magnitude is read honestly against a
    # true zero baseline, with a small headroom above the largest point. With the
    # values rescaled by ``y_unit`` the default tick labels are already small,
    # legible numbers, so no special formatter is needed.
    ax.set_ylim(bottom=0.0, top=max(y_scaled) * 1.12)
    ax.yaxis.set_major_locator(MaxNLocator(nbins=6))

    ax.grid(True, which="major", linestyle="--", linewidth=0.6, alpha=0.7)

    # Legend in the lower-right corner: that region is empty in both figures, so
    # it never overlaps a measurement point (the large-error series in particular
    # rises toward the upper-right, which "best" would otherwise collide with).
    ax.legend(
        loc="lower right", ncol=1, handlelength=1.6,
        borderpad=0.6, labelspacing=0.6,
        frameon=True, fancybox=True, edgecolor="black", facecolor="white",
    )

    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def main() -> int:
    configure_style()
    for filename, out_png, y_unit, y_unit_label in SERIES:
        path = DATA_DIR / filename
        if not path.is_file():
            print(f"error: input file not found: {path}")
            return 1
        n_vals, rmsre = load_accuracy_csv(path)
        plot_one(n_vals, rmsre, y_unit, y_unit_label, IMAGES_DIR / out_png)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
