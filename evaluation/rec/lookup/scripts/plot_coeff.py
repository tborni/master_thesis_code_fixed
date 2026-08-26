#!/usr/bin/env python3
"""Plot the rec_lookup correction-coefficient sweep as a publication figure.

Reads ``data/accuracy_newton_coeff.csv`` (columns ``C, RMSRE, MAX_REL_ERROR``,
as produced by ``extract_accuracy_coeff.py``) and renders a single scatter
figure with the correction coefficient on the x-axis and two series sharing one
linear y-axis: the RMS relative error (RMSRE) and the maximum relative error.

Design notes
------------
* Every measured point is drawn as a marker; there is no connecting line and no
  fitted curve, so the raw sweep is shown exactly as sampled.
* The sweep varies the coefficient over ``2.000000 .. 2.000066`` in steps of
  ``1e-6``. Raw values that close to 2 make for unreadable ticks, so the x-axis
  shows the offset from 2 in units of ``1e-6`` (labelled ``kappa - 2``); no
  information is hidden.
* Both error metrics live on the same order of magnitude (``~1e-5 .. 1.3e-4``),
  so they share a single linear y-axis. A twin axis would exaggerate their
  relative scale and is deliberately avoided.
* Colours are drawn from the Okabe-Ito colourblind-safe palette and the two
  series additionally differ in marker shape (circle vs. square), so they remain
  distinguishable in greyscale print.
* Text is rendered with matplotlib's built-in STIX mathtext fontset, which gives
  LaTeX-quality serif type without requiring a system LaTeX installation, so the
  figure builds reproducibly from the Makefile.

The script resolves its input (``data/``) and output (``images/``) relative to
its own location, so it can be run from any working directory.
"""

from __future__ import annotations

import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # headless-safe: render to file without a display server.

import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figure lands in the right place regardless of the
# current working directory, matching plot.py / extract_accuracy*.py.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

INPUT_CSV = DATA_DIR / "accuracy_newton_coeff.csv"
OUTPUT_PNG = IMAGES_DIR / "accuracy_newton_coeff.png"

# The sweep is a fine grid around C = 2; present the x-axis as an offset from
# this reference in the units below so the ticks stay legible.
C_REFERENCE = 2.0
C_UNIT = 1e-6            # x-axis is (C - C_REFERENCE) / C_UNIT
C_UNIT_LABEL = r"10^{-6}"
Y_UNIT = 1e-5           # y values are divided by this; label carries the factor
Y_UNIT_LABEL = r"10^{-5}"

# Value predicted by the design heuristic (see the data notes in accuracy.txt).
# The empirical RMSRE minimum lies one grid step away (C = 2.000022), so at this
# axis scale the heuristic effectively marks the RMSRE optimum; a vertical guide
# line makes that visible.
HEURISTIC_C = 2.000023

# Okabe-Ito colourblind-safe palette.
COLOR_RMSRE = "#0072B2"   # blue
COLOR_MAXRE = "#D55E00"   # vermillion
COLOR_GUIDE = "#444444"   # neutral grey for the heuristic guide line/label


def load_coeff_csv(path: Path) -> tuple[list[float], list[float], list[float]]:
    """Load ``(C, RMSRE, MAX_REL_ERROR)`` columns from ``path``.

    Returns three parallel lists sorted by ascending ``C`` (so the points are
    laid out in x-order regardless of the file's row order). Raises
    ``ValueError`` if the file is empty or missing the expected columns.
    """
    required = {"C", "RMSRE", "MAX_REL_ERROR"}
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            found = reader.fieldnames
            raise ValueError(f"expected columns {sorted(required)} in {path}, found {found}")
        rows = [
            (float(row["C"]), float(row["RMSRE"]), float(row["MAX_REL_ERROR"]))
            for row in reader
        ]
    if not rows:
        raise ValueError(f"no data rows in {path}")
    rows.sort(key=lambda r: r[0])
    c_vals, rmsre, max_rel = (list(col) for col in zip(*rows))
    return c_vals, rmsre, max_rel


def configure_style() -> None:
    """Apply a restrained, publication-oriented rcParams style."""
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
            # Full black frame (all four spines) with outward ticks, matching
            # the pareto figures.
            "axes.linewidth": 0.8,
            "axes.edgecolor": "black",
            "xtick.direction": "out",
            "ytick.direction": "out",
            "xtick.major.width": 0.8,
            "ytick.major.width": 0.8,
            "xtick.major.size": 4.0,
            "ytick.major.size": 4.0,
            # Dashed grid, matching the pareto figures' style.
            "axes.grid": True,
            "grid.linestyle": "--",
            "grid.linewidth": 0.6,
            "grid.alpha": 0.7,
            # Legend box: rounded corners (fancybox) with a solid black frame on
            # a white face, as used by the pareto plots.
            "legend.frameon": True,
            "legend.framealpha": 1.0,
            "legend.edgecolor": "black",
            "legend.facecolor": "white",
            "legend.fancybox": True,
            "figure.dpi": 300,
            "savefig.dpi": 300,
        }
    )


def plot(
    c_vals: list[float],
    rmsre: list[float],
    max_rel: list[float],
    output_path: Path,
) -> None:
    """Render the scatter figure to ``output_path``."""
    # X-axis as the offset from the reference in units of 1e-6, i.e. kappa - 2
    # scaled by 1e-6 -> 0 .. 66 for this sweep.
    x = [(c - C_REFERENCE) / C_UNIT for c in c_vals]

    # Scale y to units of 1e-5 so tick labels are small integers/decimals; the
    # axis label carries the multiplier. Both series share this scaling, so
    # their relative heights are preserved exactly.
    y_rmsre = [v / Y_UNIT for v in rmsre]
    y_maxre = [v / Y_UNIT for v in max_rel]

    fig, ax = plt.subplots(figsize=(8.6, 4.6))

    # One marker per data point, no connecting line and no fit.
    ax.scatter(
        x, y_maxre,
        color=COLOR_MAXRE, marker="s", s=26, linewidths=0,
        label=r"Max Rel. Err.", zorder=3,
    )
    ax.scatter(
        x, y_rmsre,
        color=COLOR_RMSRE, marker="o", s=26, linewidths=0,
        label=r"RMSRE", zorder=4,
    )

    ax.set_xlabel(rf"$\kappa - 2\ \ (\times\,{C_UNIT_LABEL})$")
    ax.set_ylabel(rf"Relative Error  $(\times\,{Y_UNIT_LABEL})$")

    # Origin at the bottom-left corner: both axes start exactly at 0. A small
    # right-hand pad keeps the last point (x = 66) off the frame.
    ax.set_xlim(0, max(x) + 2.0)
    y_top = max(y_maxre) * 1.08
    ax.set_ylim(0, y_top)

    # Light dashed guide at the heuristic prediction. It falls in the RMSRE
    # trough, so the reader can see at a glance that the heuristic hits the RMSRE
    # minimum. Kept faint/thin so it reads as a reference, not a data series.
    x_heuristic = (HEURISTIC_C - C_REFERENCE) / C_UNIT
    ax.axvline(x_heuristic, color=COLOR_GUIDE, linestyle="--", linewidth=1.5,
               alpha=0.8, zorder=1)
    # Annotation to the left of the line, with a purely horizontal arrow that
    # points right at the line (text anchor and arrow tip share a y). A white box
    # keeps the text readable over the grid. The text is offset far enough left
    # that a clear arrow shaft is visible between the box and the line.
    y_annot = y_top * 0.60
    ax.annotate(
        # The star is placed as a lowered superscript (empty group + subscript)
        # so it sits at a natural height rather than top-aligned above kappa.
        "Estimated optimal\n" r"value $\kappa^{{}_{*}}$",
        xy=(x_heuristic, y_annot),
        xytext=(x_heuristic - 12.0, y_annot),
        ha="center", va="center", fontsize=16, color="black",
        bbox=dict(boxstyle="round,pad=0.35", facecolor="white",
                  edgecolor=COLOR_GUIDE, linewidth=0.8),
        arrowprops=dict(arrowstyle="-|>", color=COLOR_GUIDE, linewidth=1.1,
                        shrinkA=3, shrinkB=3),
        zorder=6,
    )

    # Stacked (single-column) legend in the top-right corner. Rounded corners
    # (fancybox) with a solid black frame on white, as in the pareto plots.
    ax.legend(
        loc="upper right", ncol=1, handlelength=1.6,
        borderpad=0.6, labelspacing=0.6,
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
    c_vals, rmsre, max_rel = load_coeff_csv(INPUT_CSV)
    configure_style()
    plot(c_vals, rmsre, max_rel, OUTPUT_PNG)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
