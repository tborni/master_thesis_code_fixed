#!/usr/bin/env python3
"""Plot the LayerNorm N-sweep accuracy as a publication figure.

Reads the 1-Newton-step accuracy table produced by ``extract_accuracy.py``::

    data/accuracy_1_newton.csv   (1 Newton refinement step)

with columns ``N, SIMD, RMSRE, MAX_REL_ERROR``, and renders a single log-log
figure of the RMS relative error (RMSRE) against the vector length ``N``.

Design notes
------------
* Both axes are logarithmic: ``N`` spans three decades (2 .. 16384, always a
  power of two) and RMSRE spans two-plus decades, so a log-log view keeps every
  point legible and makes power-law trends read as straight lines. The x-axis
  uses base 2 (``N`` is a power of two) with the actual N values as tick labels.
* Each measurement is drawn as a bare marker (no connecting line), so the raw
  sweep is shown exactly as sampled. The series is close to a straight line on
  these log-log axes, so a least-squares power-law fit
  ``log(RMSRE) = r*log(N) + n`` is overlaid; it draws as a straight line here and
  its slope ``r`` (shown in the legend) is the empirical RMSRE-vs-N growth
  exponent.
* The data markers are Okabe-Ito blue; the fit line is red so it contrasts
  clearly with the markers.
* Text uses matplotlib's built-in STIX mathtext fontset, which gives
  LaTeX-quality serif type without a system LaTeX install, so the figure builds
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
import numpy as np
from matplotlib.ticker import LogLocator, NullLocator

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figure lands in the right place regardless of the
# current working directory, matching extract_accuracy.py / plot_resources.py.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

OUTPUT_PNG = IMAGES_DIR / "accuracy.png"

# The series to plot: (csv filename, legend label, colour, marker, fit).
# Okabe-Ito blue with a circle marker. ``fit`` selects which series gets an
# overlaid power-law fit line (log(RMSRE) = m*log(N) + n); the 1-Newton series is
# close to linear on the log-log axes, so it is fitted.
SERIES = (
    ("accuracy_1_newton.csv", "Measured Accuracy", "#0072B2", "o", True),
)

# Colour and style of the overlaid power-law fit line. Red and dashed, so it
# contrasts with the blue data markers and reads clearly as the fit.
COLOR_FIT = "red"


def load_accuracy_csv(path: Path) -> tuple[list[float], list[float]]:
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
    n_vals, rmsre = ([r[0] for r in rows], [r[1] for r in rows])
    return n_vals, rmsre


def powerlaw_fit(n_vals: list[int], rmsre: list[float]) -> tuple[float, float]:
    """Least-squares power-law fit in log-log space; return ``(m, n)``.

    Fits ``log(RMSRE) = m*log(N) + n`` (natural logs), i.e. the straight line the
    data traces on the log-log axes. ``m`` is the growth exponent and ``n`` the
    log-intercept; the fitted RMSRE is recovered as ``exp(n) * N**m``.
    """
    log_n = np.log(np.asarray(n_vals, dtype=float))
    log_rmsre = np.log(np.asarray(rmsre, dtype=float))
    m, intercept = np.polyfit(log_n, log_rmsre, deg=1)
    return float(m), float(intercept)


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


def plot(series_data: list[tuple[str, str, str, bool, list[int], list[float]]],
         output_path: Path) -> None:
    """Render the log-log RMSRE-vs-N figure to ``output_path``.

    ``series_data`` is a list of ``(label, colour, marker, fit, n_vals, rmsre)``
    tuples, one per Newton configuration. Data points are drawn as bare markers
    (no connecting line); series with ``fit`` set additionally get an overlaid
    power-law fit line ``log(RMSRE) = m*log(N) + n``.
    """
    fig, ax = plt.subplots(figsize=(8.6, 5.2))

    # Bare markers per series (no connecting line).
    for label, color, marker, _fit, n_vals, rmsre in series_data:
        ax.plot(
            n_vals, rmsre,
            color=color, marker=marker, linestyle="none",
            markersize=7, markeredgecolor="black",
            markeredgewidth=0.5, label=label, zorder=3,
        )

    # Overlay a power-law fit for each flagged series. Evaluated on a dense
    # geometric N grid so it draws as a clean straight line across the log-log
    # axes; the slope m (the RMSRE-vs-N growth exponent) is shown in the label.
    for _label, color, _marker, fit, n_vals, rmsre in series_data:
        if not fit:
            continue
        m, intercept = powerlaw_fit(n_vals, rmsre)
        grid = np.geomspace(min(n_vals), max(n_vals), 200)
        fit_curve = np.exp(intercept) * grid ** m
        ax.plot(
            grid, fit_curve,
            color=COLOR_FIT, linestyle="--", linewidth=1.8, zorder=2,
            label="Power-law fit",
        )

    # Log-log axes. N is a power of two, so use a base-2 log x-axis and label the
    # ticks with the actual N values; RMSRE uses a standard base-10 log y-axis.
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")

    ax.set_xlabel(r"$N$")
    ax.set_ylabel(r"RMSRE")

    # Show every sampled N as a major tick, labelled with its integer value,
    # and suppress the base-2 minor ticks so the axis stays uncluttered.
    all_n = sorted({n for *_, n_vals, _ in series_data for n in n_vals})
    ax.set_xticks(all_n)
    ax.set_xticklabels([str(n) for n in all_n], rotation=45, ha="right")
    ax.xaxis.set_minor_locator(NullLocator())

    # Decade major grid on the y-axis plus faint minor dec.-subdivisions so the
    # two-plus decade RMSRE span stays readable.
    ax.yaxis.set_major_locator(LogLocator(base=10.0))
    ax.yaxis.set_minor_locator(LogLocator(base=10.0, subs=tuple(range(2, 10))))
    ax.grid(True, which="major", linestyle="--", linewidth=0.6, alpha=0.7)
    ax.grid(True, which="minor", axis="y", linestyle=":", linewidth=0.4, alpha=0.4)

    ax.legend(
        loc="best", ncol=1, handlelength=2.2,
        borderpad=0.6, labelspacing=0.6,
        frameon=True, fancybox=True, edgecolor="black", facecolor="white",
    )

    fig.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight", pad_inches=0.05)
    plt.close(fig)
    print(f"Saved to {output_path}")


def main() -> int:
    series_data: list[tuple[str, str, str, bool, list[int], list[float]]] = []
    for filename, label, color, marker, fit in SERIES:
        path = DATA_DIR / filename
        if not path.is_file():
            print(f"error: input file not found: {path}")
            return 1
        n_vals, rmsre = load_accuracy_csv(path)
        series_data.append((label, color, marker, fit, n_vals, rmsre))

    configure_style()
    plot(series_data, OUTPUT_PNG)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
