import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.markers import MarkerStyle
from matplotlib.transforms import Affine2D
import glob
import os

# --- Configuration ---
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

fig, ax = plt.subplots(figsize=(6, 4))

for file in files:
	try:
		label_full = os.path.basename(file).replace("_combined.csv", "")
		# Extract method name (assuming format Method+OtherStuff...)
		method = label_full.split("+")[0]
		df = pd.read_csv(file, comment='#')

		# Check for necessary columns
		required_cols = {'rmsre', 'lut', 'dsp'}
		if not required_cols.issubset(df.columns):
			print(f"Skipping {file}: missing columns {required_cols - set(df.columns)}")
			continue

		# Get color based on method
		color = method_to_color.get(method, "gray")

		# --- Group by DSP within the file ---
		for dsp_val, group in df.groupby('dsp'):
			marker = dsp_to_marker.get(dsp_val, "X")  # 'X' is a fallback for unknown DSP values

			ax.scatter(
				group['rmsre'],
				group['lut'],
				alpha=0.85,
				s=35,
				color=color,
				marker=marker,
				edgecolors='black',
				linewidths=0.3
			)

	except Exception as e:
		print(f"Error processing {file}: {e}")

marker = MarkerStyle('d')
marker._transform = marker.get_transform() + Affine2D().rotate_deg(90)
# --- Legend Construction ---
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

# --- Axes Formatting ---
ax.set_xlabel("RMSRE")
ax.set_ylabel("LUT Count")
ax.set_xscale("log")
ax.set_ylim(bottom=0)

# Grid: major lines on x, detailed on y
ax.grid(True, which="major", axis="x", linestyle="--", linewidth=0.6, alpha=0.7)
ax.grid(True, which="both", axis="y", linestyle="--", linewidth=0.6, alpha=0.7)

plt.tight_layout()

# Save
output_name = "diagram.png"
plt.savefig(output_name, dpi=600, bbox_inches="tight")
print(f"Plot saved as {output_name}")

plt.close()
