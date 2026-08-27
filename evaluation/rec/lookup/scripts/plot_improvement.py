#!/usr/bin/env python3
"""Render the RMSRE-improvement heatmap for the tuned coefficient over ``C = 2``.

Reads ``data/accuracy_newton_improvement.csv`` (as produced by
``extract_accuracy_improvement.py``) and draws a single heatmap of the relative
RMSRE improvement over the ``(addr_width, word_width)`` grid, one figure matching
the accuracy/resources heatmaps rendered by ``plot.py``.

Each cell is the percentage by which tuning the correction coefficient shrinks
the RMSRE relative to the nominal ``C = 2`` baseline::

    improvement% = (RMSRE_C2 - RMSRE_opt) / RMSRE_C2 * 100

so larger (brighter) cells mark configurations that benefit more from tuning.
The grid geometry, colour handling, fonts and cell annotations are reused from
``plot.py`` verbatim (via its :func:`plot_heatmap`), so this figure is stylistically
identical to its siblings; only the value column, its formatting (a percentage
with one decimal) and the colour direction (``viridis``, so more improvement reads
brighter) differ.

The script resolves its input (``data/``) and output (``images/``) relative to
its own location, so it can be run from any working directory.
"""

from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap

# Reuse plot.py's heatmap renderer and its data/image directory constants so the
# improvement figure is drawn by exactly the same code as the sibling heatmaps.
# plot_heatmap reads a handful of module-level globals (column indices, value
# scaling, label format); we set them on the plot module before calling, mirroring
# how plot.py's own __main__ configures each figure.
import plot

DATA_DIR = plot.DATA_DIR
IMAGES_DIR = plot.IMAGES_DIR

INPUT_CSV = DATA_DIR / "accuracy_newton_improvement.csv"
OUTPUT_PNG = IMAGES_DIR / "accuracy_newton_improvement.png"

# Column layout of accuracy_newton_improvement.csv (0-based indices):
#   NUM_NEWTON_STEPS, ADDR_WIDTH, WORD_WIDTH, RMSRE_C2, RMSRE_OPT, C_OPT,
#   RMSRE_IMPROVEMENT_PCT
#   -> addr_width is column 1, word_width column 2, improvement column 6.
XLABEL = "addr_width"
YLABEL = "word_width"
X_COL_IDX = 1           # addr_width
Y_COL_IDX = 2           # word_width
VALUE_IDX = 6           # RMSRE_IMPROVEMENT_PCT (already a percentage)

# The value floor (the 0.0% cells, where tuning found C=2 already optimal) maps to
# the bottom of the colour map. Plain viridis bottoms out at a near-black violet
# where the black cell text is hard to read, so we start the map partway up its
# range at a mid blue that keeps black text legible. 0.35 lands on viridis'
# blue (luminance ~0.38) while staying clearly the low end of the scale.
CMAP_FLOOR = 0.35


def truncated_viridis(floor: float = CMAP_FLOOR, samples: int = 256) -> ListedColormap:
    """Return viridis restricted to ``[floor, 1.0]`` of its colour range.

    Raising the floor lifts the darkest colour off near-black, so the lowest
    cells (0.0% improvement) render as a readable blue rather than dark violet,
    while the "larger value = brighter" progression is preserved.
    """
    base = plt.get_cmap("viridis")
    return ListedColormap(base(np.linspace(floor, 1.0, samples)))


def main() -> int:
    if not INPUT_CSV.is_file():
        print(f"error: input file not found: {INPUT_CSV}")
        return 1

    # Configure the shared renderer for this figure. The value column already
    # holds a percentage, so no scaling (VALUE_FACTOR = 1); it is a single NS=1
    # grid, so no row filter is needed.
    plot.XLABEL = XLABEL
    plot.YLABEL = YLABEL
    plot.X_COL_IDX = X_COL_IDX
    plot.Y_COL_IDX = Y_COL_IDX
    plot.VALUE_IDX = VALUE_IDX
    plot.VALUE_FACTOR = 1
    plot.DATATYPE = "percent_1"     # e.g. "24.9%"
    plot.FILTER_COL = None
    plot.FILTER_VAL = None

    plot.plot_heatmap(
        filepath=INPUT_CSV,
        output_path=OUTPUT_PNG,
        title="",
        xlabel=XLABEL,
        ylabel=YLABEL,
        # Colour scheme for the RMSRE-reduction heatmap: viridis (not the reversed
        # map the error heatmaps use, so a larger value reads brighter) with a low
        # PowerNorm gamma. The gamma of 0.25 stretches the colour range over the
        # high end where the improvements cluster (~18-28%), giving the cells more
        # visible contrast than the default 0.7. The map is truncated at its low
        # end (see truncated_viridis) so the 0.0% cells sit on a readable blue
        # instead of near-black violet. plot_heatmap passes this through
        # plt.get_cmap, which returns a Colormap object unchanged.
        cmap_name=truncated_viridis(),
        gamma=0.25,
        cell_width=2.6,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
