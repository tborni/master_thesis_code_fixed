import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

CSV_PATH = "optimal_magic_coarse_sweep_schraudolph_results.csv"
PNG_PATH = "optimal_magic_coarse_sweep_schraudolph_results.png"

df = pd.read_csv(CSV_PATH, skipinitialspace=True, comment="#")
df.columns = df.columns.str.strip()

df["magic_constant"] = pd.to_numeric(df["magic_constant"], errors="coerce")
df["RMSRE"]          = pd.to_numeric(df["RMSRE"],          errors="coerce")
df = df.dropna(subset=["magic_constant", "RMSRE"]).reset_index(drop=True)

x = df["magic_constant"]
y = df["RMSRE"]

plt.style.use("seaborn-v0_8-whitegrid")
fig, ax = plt.subplots(figsize=(9, 5.5), dpi=150)

ax.plot(x, y,
        linewidth=1.2,
        color="#1f77b4",
        alpha=0.9,
        zorder=2)

X_SCALE      = 1e6
X_SCALE_EXP  = 6

ax.xaxis.set_major_formatter(
    FuncFormatter(lambda v, _pos: f"{v / X_SCALE:g}")
)
ax.set_xlabel(rf"magic constant $c$ ($\times 10^{{{X_SCALE_EXP}}}$)")
ax.set_ylabel("RMSRE")
ax.grid(True, which="both", linestyle="-", linewidth=0.5, alpha=0.6)

fig.tight_layout()
fig.savefig(PNG_PATH, bbox_inches="tight")
print(f"saved {PNG_PATH}")
