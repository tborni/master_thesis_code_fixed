import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.markers import MarkerStyle
from matplotlib.transforms import Affine2D
import glob
import os
import numpy as np

method_to_color = {
	"Bipartite": "#E69F00",
	"IP-Core" : "red",
	"Lookup": "#83C19D",
}


dsp_to_marker = {
	0: "o",
	2: "^",
	8:"P",
}

# --- Style for publication ---
plt.rcParams.update({
	"font.family": "serif",
	"font.size": 12,
	"axes.labelsize": 14,
	"axes.titlesize": 14,
	"legend.fontsize": 10,
	"xtick.labelsize": 12,
	"ytick.labelsize": 12,
	"figure.dpi": 300
})

files = sorted(glob.glob("*_combined.csv"), reverse=True)

if not files:
	print("No *_combined.csv files found.")
	exit()

# 1. First pass: load all data
all_points = []
file_data = []

for file in files:
	try:
		label_full = os.path.basename(file).replace("_combined.csv", "")
		method = label_full.split("+")[0]
		df = pd.read_csv(file)

		if 'rmsre' not in df.columns or 'lut' not in df.columns or 'dsp' not in df.columns:
			print(f"Skipping {file}: missing columns.")
			continue

		df['label'] = label_full
		df['method'] = method
		file_data.append(df)
		all_points.append(df[['rmsre', 'lut', 'dsp']])

	except Exception as e:
		print(f"Error loading {file}: {e}")

# 2. Calculate global 3D Pareto front (minimize rmsre, lut, dsp)
combined = pd.concat(all_points).drop_duplicates().reset_index(drop=True)
points = combined[['rmsre', 'lut', 'dsp']].values
n = len(points)
is_pareto = np.ones(n, dtype=bool)

for i in range(n):
	if not is_pareto[i]:
		continue
	# A point is dominated if another point is better or equal in ALL dims
	# AND strictly better in at least one dim.
	dominated = (
		(points[:, 0] <= points[i, 0]) &
		(points[:, 1] <= points[i, 1]) &
		(points[:, 2] <= points[i, 2]) &
		(
			(points[:, 0] < points[i, 0]) |
			(points[:, 1] < points[i, 1]) |
			(points[:, 2] < points[i, 2])
		)
	)
	# Check if any point in the dataset dominates point i
	if dominated.any():
		is_pareto[i] = False

pareto_set = set(map(tuple, points[is_pareto]))
combined['is_pareto'] = is_pareto

# 3. Plot scatter
fig, ax = plt.subplots(figsize=(6, 4))

for df in file_data:
	method = df['method'].iloc[0]
	color = method_to_color.get(method, "gray")

	# --- Group by DSP within each file ---
	for dsp_val, group in df.groupby('dsp'):
		marker = dsp_to_marker.get(dsp_val, "X")  # 'X' is a fallback for unknown DSP values

		# Determine which points in this group are part of the global Pareto set
		is_pareto_mask = group.apply(
			lambda r: (r['rmsre'], r['lut'], r['dsp']) in pareto_set, axis=1
		)
		df_pareto = group[is_pareto_mask]
		df_others = group[~is_pareto_mask]

		# Non-Pareto: faded, no edge
		if not df_others.empty:
			ax.scatter(
				df_others['rmsre'], df_others['lut'],
				color=color, marker=marker, s=35, alpha=0.35,
				edgecolors='none', zorder=2
			)

		# Pareto: vibrant, bold edge
		if not df_pareto.empty:
			ax.scatter(
				df_pareto['rmsre'], df_pareto['lut'],
				color=color, marker=marker, s=50, alpha=1.0,
				edgecolors='black', linewidths=0.9, zorder=4
			)

# 4. Staircase lines per DSP group (Pareto points only)
for dsp_val, marker in dsp_to_marker.items():
	group = combined[
		combined['is_pareto'] & (combined['dsp'] == dsp_val)
	].sort_values(by='rmsre')

	if group.empty:
		continue

	ax.step(
		group['rmsre'], group['lut'],
		where='post', color='gray', linestyle='-',
		linewidth=0.9, alpha=0.6, zorder=3
	)

# 5. Legends
marker = MarkerStyle('d')
marker._transform = marker.get_transform() + Affine2D().rotate_deg(90)
method_handles = [
	Line2D([0], [0], marker=marker, color='w', label=m,
		markerfacecolor=c, markeredgecolor='black', markersize=8)
	for m, c in method_to_color.items()
]

dsp_handles = [
	Line2D([0], [0], marker=m, color='black', label=f"{n} DSP",
		linestyle='None', markersize=8)
	for n, m in dsp_to_marker.items()
]

legend1 = ax.legend(
	handles=method_handles,
	title="Method",
	loc="upper right",
	bbox_to_anchor=(1.0, 1.0),
	frameon=True,
	edgecolor="black",
	facecolor="white"
)
ax.add_artist(legend1)

# Place DSP legend immediately to the left of the Method legend, top-aligned.
# Measure the Method legend's bounding box in axes coordinates after a draw
# pass, so the placement adapts if the number of methods changes.
fig.canvas.draw()
method_bbox = legend1.get_window_extent().transformed(ax.transAxes.inverted())

legend2 = ax.legend(
	handles=dsp_handles,
	title="DSP",
	loc="upper right",
	bbox_to_anchor=(method_bbox.x0 + 0.01, method_bbox.y1 + 0.023),
	frameon=True,
	edgecolor="black",
	facecolor="white"
)

# Axes
ax.set_xlabel("RMSRE")
ax.set_ylabel("LUT Count")
ax.set_xscale("log")
ax.set_ylim(bottom=0)

ax.grid(True, which="major", axis="x", linestyle="--", linewidth=0.6, alpha=0.7)
ax.grid(True, which="both", axis="y", linestyle="--", linewidth=0.6, alpha=0.7)

plt.tight_layout()
plt.savefig("full_pareto.png", dpi=600, bbox_inches="tight")
plt.close()
