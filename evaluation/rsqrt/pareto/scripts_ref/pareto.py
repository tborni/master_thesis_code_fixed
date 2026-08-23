import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.markers import MarkerStyle
from matplotlib.transforms import Affine2D
import glob
import os

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
		all_points.append(df[['rmsre', 'lut']])

	except Exception as e:
		print(f"Error loading {file}: {e}")

# 2. Calculate global Pareto front (rmsre, lut)
combined = pd.concat(all_points).sort_values(by='rmsre')
pareto_set = set()
min_lut = float('inf')

for _, row in combined.iterrows():
	if row['lut'] < min_lut:
		pareto_set.add((row['rmsre'], row['lut']))
		min_lut = row['lut']

# 3. Plot
fig, ax = plt.subplots(figsize=(6, 4))

for df in file_data:
	method = df['method'].iloc[0]
	color = method_to_color.get(method, "gray")

	# Flag Pareto points within this specific dataframe
	df['is_pareto'] = df.apply(lambda r: (r['rmsre'], r['lut']) in pareto_set, axis=1)

	# --- Group by dsp to ensure correct markers ---
	for dsp_val, group in df.groupby('dsp'):
		marker = dsp_to_marker.get(dsp_val, "X")  # 'X' is a fallback for unknown DSP values

		df_pareto = group[group['is_pareto']]
		df_others = group[~group['is_pareto']]

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

# 4. Pareto staircase line
pareto_points = combined[combined.apply(lambda r: (r['rmsre'], r['lut']) in pareto_set, axis=1)]
ax.step(pareto_points['rmsre'], pareto_points['lut'], where='post',
		color='black', linestyle='-', linewidth=1.2, alpha=0.7, zorder=3)

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
plt.savefig("pareto.png", dpi=600, bbox_inches="tight")
plt.close()
