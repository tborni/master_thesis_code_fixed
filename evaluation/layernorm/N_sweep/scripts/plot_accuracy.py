#!/usr/bin/env python3
"""Plot the LayerNorm N-sweep accuracy as publication figures.

Reads the accuracy tables produced by ``extract_accuracy.py`` for the two
invsqrt configurations::

    data/accuracy_0_newton.csv   (0 Newton refinement steps)
    data/accuracy_1_newton.csv   (1 Newton refinement step)

each with columns ``N, SIMD, RMSRE, MAX_REL_ERROR``, and renders one log-log
figure per configuration of the RMS relative error (RMSRE) against the vector
length ``N`` (``images/accuracy_0_newton.png`` for 0 steps,
``accuracy_1_newton.png`` for 1 step).

Design notes
------------
* Both axes are logarithmic: ``N`` spans three decades (2 .. 16384, always a
  power of two) and RMSRE spans a wide range, so a log-log view keeps every
  point legible and makes power-law trends read as straight lines. The x-axis
  uses base 2 (``N`` is a power of two) with the actual N values as tick labels.
  Each figure's y-axis is autoscaled to its own series, so both read clearly
  despite the two configurations occupying different RMSRE ranges.
* Each measurement is drawn as a bare marker (no connecting line), so the raw
  sweep is shown exactly as sampled.
* Only the 1-Newton series is close to a straight line on these log-log axes
  (RMSRE grows with N as rounding error accumulates), so it alone gets a
  least-squares power-law fit ``log(RMSRE) = r*log(N) + n`` overlaid; it draws
  as a straight line here and its slope ``r`` is the empirical RMSRE-vs-N growth
  exponent. The fit is labelled simply "Power-law fit" in the legend; its
  coefficients (``r``, the log-intercept and R^2) are printed to stdout and
  recorded in the shared ``data/fit_parameters.txt`` under an ``[accuracy]``
  section (written via ``fit_report``, alongside the resources script's
  section). The 0-Newton series is an accuracy floor set by the base LUT
  approximation (RMSRE roughly flat, then declining, over N), which is not a
  power law, so it is plotted as measured points only with no fit line.
* The data markers are Okabe-Ito blue; the fit line is red so it contrasts
  clearly with the markers.
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
import numpy as np
from matplotlib.ticker import LogLocator, NullLocator

# Local sibling module (same scripts/ dir): the shared fit-parameters writer.
import fit_report

# ---------------------------------------------------------------------------
# Paths: resolve data/ (input) and images/ (output) relative to this script's
# directory (scripts/) so the figure lands in the right place regardless of the
# current working directory, matching extract_accuracy.py / plot_resources.py.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

# Shared fit-parameters file; this script owns its "[accuracy]" section (the
# resources script owns "[resources]"). See fit_report.update_section.
OUTPUT_FIT_TXT = DATA_DIR / "fit_parameters.txt"
FIT_SECTION = "accuracy"

# One figure per invsqrt configuration:
#   (csv filename, output png, legend label, colour, marker, fit).
# Okabe-Ito blue with a circle marker. ``fit`` selects which series gets an
# overlaid power-law fit line (log(RMSRE) = r*log(N) + n): the 1-Newton series is
# close to linear on the log-log axes (accumulating rounding error), so it is
# fitted; the 0-Newton series is a flat/declining accuracy floor (not a power
# law), so it is drawn as measured points only. Each figure is named after its
# configuration, ``accuracy_<steps>_newton.png``, mirroring the input CSVs.
SERIES = (
    ("accuracy_0_newton.csv", "accuracy_0_newton.png", "Measured Accuracy", "#0072B2", "o", False),
    ("accuracy_1_newton.csv", "accuracy_1_newton.png", "Measured Accuracy", "#0072B2", "o", True),
)

# Colour and style of the overlaid power-law fit line. Red and dashed, so it
# contrasts with the blue data markers and reads clearly as the fit.
COLOR_FIT = "red"


def pow2_label(n: int) -> str:
    """Format a sampled ``N`` as a base-2 power label for the log x-axis.

    Every sampled ``N`` is a power of two, so it is shown as ``2^k`` (rendered
    via mathtext, e.g. ``2^{10}`` for 1024) rather than the raw integer, matching
    the base-2 log axis. Falls back to the plain integer for the (unexpected)
    case of an ``N`` that is not an exact power of two.
    """
    exp = n.bit_length() - 1
    if n > 0 and (1 << exp) == n:  # exact power of two
        return rf"$2^{{{exp}}}$"
    return str(n)


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


def powerlaw_fit(n_vals: list[int], rmsre: list[float]) -> tuple[float, float, float]:
    """Least-squares power-law fit in log-log space; return ``(r, n, r_squared)``.

    Fits ``log(RMSRE) = r*log(N) + n`` (natural logs), i.e. the straight line the
    data traces on the log-log axes. ``r`` is the growth exponent and ``n`` the
    log-intercept; the fitted RMSRE is recovered as ``exp(n) * N**r``.
    ``r_squared`` is the coefficient of determination of the fit in log-log
    space, so the figure/report can state honestly how power-law-like the data is.
    """
    log_n = np.log(np.asarray(n_vals, dtype=float))
    log_rmsre = np.log(np.asarray(rmsre, dtype=float))
    r, intercept = np.polyfit(log_n, log_rmsre, deg=1)
    predicted = r * log_n + intercept
    ss_res = float(np.sum((log_rmsre - predicted) ** 2))
    ss_tot = float(np.sum((log_rmsre - np.mean(log_rmsre)) ** 2))
    r_squared = 1.0 - ss_res / ss_tot if ss_tot > 0 else float("nan")
    return float(r), float(intercept), r_squared


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
            "font.size": 20,
            "axes.titlesize": 22,
            "axes.labelsize": 22,
            "xtick.labelsize": 19,
            "ytick.labelsize": 19,
            "legend.fontsize": 20,
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


def plot(label: str, color: str, marker: str, fit: bool,
         n_vals: list[int], rmsre: list[float],
         fit_coeffs: tuple[float, float] | None,
         output_path: Path) -> None:
    """Render one log-log RMSRE-vs-N figure to ``output_path``.

    Draws a single Newton configuration's ``(n_vals, rmsre)`` as bare markers (no
    connecting line). If ``fit`` is set, an overlaid power-law fit line
    ``log(RMSRE) = r*log(N) + n`` is added using the precomputed
    ``fit_coeffs = (r, intercept)`` (so the drawn line matches the fit reported to
    stdout / the fit-parameters file exactly); otherwise only the measured points
    are shown. The y-axis autoscales to this series alone.
    """
    fig, ax = plt.subplots(figsize=(8.6, 5.2))

    # Bare markers for the series (no connecting line).
    ax.plot(
        n_vals, rmsre,
        color=color, marker=marker, linestyle="none",
        markersize=7, markeredgecolor="black",
        markeredgewidth=0.5, label=label, zorder=3,
    )

    # Overlay the power-law fit if this series is flagged for one. Evaluated on a
    # dense geometric N grid so it draws as a clean straight line across the
    # log-log axes; the fitted exponent r is the RMSRE-vs-N growth rate.
    if fit:
        assert fit_coeffs is not None  # main() computes it for every fitted series
        r, intercept = fit_coeffs
        grid = np.geomspace(min(n_vals), max(n_vals), 200)
        fit_curve = np.exp(intercept) * grid ** r
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

    # Show every sampled N as a major tick, labelled as a power of two (2^k) to
    # match the base-2 log axis, and suppress the base-2 minor ticks so the axis
    # stays uncluttered.
    all_n = sorted(set(n_vals))
    ax.set_xticks(all_n)
    ax.set_xticklabels([pow2_label(n) for n in all_n], rotation=45, ha="right")
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
    # Load every configured series (each renders to its own figure).
    series_data: list[tuple[str, str, str, bool, str, list[int], list[float]]] = []
    for filename, output_png, label, color, marker, fit in SERIES:
        path = DATA_DIR / filename
        if not path.is_file():
            print(f"error: input file not found: {path}")
            return 1
        n_vals, rmsre = load_accuracy_csv(path)
        series_data.append((output_png, label, color, marker, fit, n_vals, rmsre))

    # Fit each flagged series once here, so the drawn line, the stdout report and
    # the fit-parameters file all use the exact same coefficients. ``fits`` maps
    # a series' output filename -> its (r, intercept) for the plotter; the R^2 is
    # used only in the report line. Only fitted series get an entry.
    fits: dict[str, tuple[float, float]] = {}
    report_lines: list[str] = []
    n_points = 0
    for output_png, _label, _color, _marker, fit, n_vals, rmsre in series_data:
        if not fit:
            continue
        r, intercept, r_squared = powerlaw_fit(n_vals, rmsre)
        fits[output_png] = (r, intercept)
        n_points = len(n_vals)
        report_lines.append(
            fit_report.format_powerlaw_line("RMSRE", "N", r, intercept, r_squared)
        )

    # Report to stdout and record in the shared fit-parameters file under this
    # script's "[accuracy]" section (the resources script owns "[resources]").
    # Only the fitted (1-Newton) series contributes; the 0-Newton floor has no fit.
    if report_lines:
        print(f"Power-law fit over {n_points} points:")
        for line in report_lines:
            print(f"  {line}")
        fit_report.update_section(
            OUTPUT_FIT_TXT,
            FIT_SECTION,
            [
                "# power-law model  log(RMSRE) = slope * log(N) + intercept",
                f"# least-squares fit (numpy.polyfit) over {n_points} sampled N points",
                *report_lines,
            ],
        )

    configure_style()
    for output_png, label, color, marker, fit, n_vals, rmsre in series_data:
        plot(
            label, color, marker, fit,
            n_vals, rmsre,
            fits.get(output_png),
            IMAGES_DIR / output_png,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
