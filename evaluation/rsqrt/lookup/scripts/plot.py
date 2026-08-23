from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import PowerNorm

def load_triplets(filepath):
	"""Load (x, y, value) triplets from a file.

	Supported formats (one triplet per line):
	  x,y,value
	  x y value
	  x\ty\tvalue
	Lines starting with '#' are treated as comments.

	Columns are selected via the X_COL_IDX / Y_COL_IDX / VALUE_IDX globals.
	If FILTER_COL is not None, only rows whose FILTER_COL column equals
	FILTER_VAL are kept; this lets a single (x, y) grid be extracted from a
	file that also varies along a third parameter (e.g. num_newton_steps).
	"""
	need = max(X_COL_IDX, Y_COL_IDX, VALUE_IDX, FILTER_COL if FILTER_COL is not None else 0)
	triplets = []
	with open(filepath, 'r') as f:
		for lineno, line in enumerate(f, 1):
			line = line.strip()
			if not line or line.startswith('#'):
				continue
			parts = line.replace(',', ' ').replace('\t', ' ').split()
			if len(parts) <= need:
				raise ValueError(f"Line {lineno}: need at least {need + 1} columns, got {len(parts)}: '{line}'")
			try:
				x, y = float(parts[X_COL_IDX]), float(parts[Y_COL_IDX])
				v = float(parts[VALUE_IDX])
				f_val = float(parts[FILTER_COL]) if FILTER_COL is not None else None
			except ValueError:
				if lineno == 1:
					continue	# skip header row
				raise ValueError(f"Line {lineno}: non-numeric value in '{line}'")
			if FILTER_COL is not None and f_val != FILTER_VAL:
				continue
			triplets.append((x, y, v))
	if not triplets:
		raise ValueError("No data found in file.")
	return triplets


def plot_heatmap(filepath, output_path=None, title=None, xlabel="x", ylabel="y", cmap_name='viridis_r', gamma=0.7,
				 fontsize_data=28, fontsize_labels=30, fontsize_ticks=25, cell_width=1.8, cell_height=1.2):
	triplets = load_triplets(filepath)

	# Determine axis tick labels from the data
	x_vals = sorted(set(t[0] for t in triplets))
	y_vals = sorted(set(t[1] for t in triplets))

	# Build data matrix (rows = y, cols = x, origin='lower')
	x_idx = {v: i for i, v in enumerate(x_vals)}
	y_idx = {v: i for i, v in enumerate(y_vals)}
	data = np.full((len(y_vals), len(x_vals)), np.nan)
	for x, y, v in triplets:
		data[y_idx[y], x_idx[x]] = v * VALUE_FACTOR

	vmin = np.nanmin(data)
	vmax = np.nanmax(data)*1.3	# Adjust for better image

	linear = False
	cmap = plt.get_cmap(cmap_name)
	if linear:
		norm = plt.Normalize(vmin=vmin, vmax=vmax)
	else:
		norm = PowerNorm(gamma=gamma, vmin=vmin, vmax=vmax)

	fig, ax = plt.subplots(figsize=(max(5, len(x_vals) * cell_width + 2), max(4, len(y_vals) * cell_height + 1)))
	ax.imshow(data, cmap=cmap, norm=norm, origin='lower', aspect='auto')

	ax.set_xticks(np.arange(len(x_vals)))
	ax.set_yticks(np.arange(len(y_vals)))

	ax.set_xticklabels([v for v in x_vals], fontsize=fontsize_ticks)
	ax.set_yticklabels([v for v in y_vals], fontsize=fontsize_ticks)
	ax.set_xlabel(xlabel, fontsize=fontsize_labels)
	ax.set_ylabel(ylabel, fontsize=fontsize_labels)

	if title:
		ax.set_title(title, fontsize=fontsize_labels + 1)

	for i in range(data.shape[0]):
		for j in range(data.shape[1]):
			v = data[i, j]
			if not np.isnan(v):
				if DATATYPE == "int":
					label = str(int(v))
				elif DATATYPE == "percent":
					label = f'{v:.4f}%'
				elif DATATYPE == "sci":
					label = f'{v:.2e}'
				else:	# "float_1"
					label = f'{v:.1f}'
				ax.text(j, i, label, ha='center', va='center', color='black', fontsize=fontsize_data)

	plt.tight_layout()

	if output_path:
		plt.savefig(output_path, bbox_inches='tight', pad_inches=0.1)
		print(f"Saved to {output_path}")
	else:
		plt.show()


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Resolve data/ (inputs) and images/ (outputs) relative to this script's
# directory (scripts/) so the plots land in the right place regardless of the
# current working directory.
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"
IMAGES_DIR = PROJECT_ROOT / "images"

# Column layout of the CSVs consumed below (0-based indices):
#   resources.csv : num_newton_steps, addr_width, word_width, LUT, BRAM
#   accuracy.csv  : num_newton_steps, addr_width, word_width, RMSRE, max_rel_error
XLABEL = "addr_width"
YLABEL = "word_width"
X_COL_IDX = 1
Y_COL_IDX = 2
VALUE_IDX = 3
VALUE_FACTOR = 1
DATATYPE = "int"	# "int", "float_1" (1 digit after the point), "percent", "sci"
# Optional row filter: keep only rows where column FILTER_COL == FILTER_VAL.
# Used to pin a single num_newton_steps when the file spans several.
FILTER_COL = None
FILTER_VAL = None
# num_newton_steps to plot accuracy for (column 0 in both CSVs).
NEWTON_STEPS = (0, 1, 2)
# ---------------------------------------------------------------------------

if __name__ == '__main__':

	# Plot resources: LUT usage over the (addr_width, word_width) grid.
	# resources.csv only contains num_newton_steps == 0, so no filter is needed.
	XLABEL = "addr_width"
	YLABEL = "word_width"
	X_COL_IDX = 1
	Y_COL_IDX = 2
	VALUE_IDX = 3			# LUT column
	VALUE_FACTOR = 1
	DATATYPE = "int"
	FILTER_COL = None
	FILTER_VAL = None
	plot_heatmap(
				filepath=DATA_DIR / "resources.csv",
				output_path=IMAGES_DIR / "resources.png",
				title="",
				xlabel=XLABEL,
				ylabel=YLABEL,
				cell_width=2.6
			)

	# Plot accuracy: RMSRE over the (addr_width, word_width) grid, one figure per
	# num_newton_steps so the three sweeps present in accuracy.csv do not
	# overwrite each other in the same cells. Labels show RMSRE as a percentage
	# with 4 decimals.
	XLABEL = "addr_width"
	YLABEL = "word_width"
	X_COL_IDX = 1			# addr_width
	Y_COL_IDX = 2			# word_width
	VALUE_IDX = 3			# RMSRE column
	VALUE_FACTOR = 100
	DATATYPE = "percent"
	FILTER_COL = 0			# num_newton_steps column
	for FILTER_VAL in NEWTON_STEPS:
		plot_heatmap(
					filepath=DATA_DIR / "accuracy.csv",
					output_path=IMAGES_DIR / f"accuracy_newton{FILTER_VAL}.png",
					title="",
					xlabel=XLABEL,
					ylabel=YLABEL,
					cell_width=2.6
				)
