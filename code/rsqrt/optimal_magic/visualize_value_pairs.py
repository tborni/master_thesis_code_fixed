import pandas as pd
import matplotlib.pyplot as plt


df = pd.read_csv("optimal_magic_coarse_sweep_results.csv")
df.columns = df.columns.str.strip()

df = df[(df['optimal_magic_constant'] >= 1597300000) & (df['optimal_magic_constant'] <= 1597400000)]

x = df['optimal_magic_constant']
y = df['optimal_RMSRE']

plt.figure()
plt.plot(x, y, marker='o', markersize = 1, linewidth=0)
plt.grid()
plt.xlabel("magic constant")
plt.ylabel("RMSRE")

plt.show()
