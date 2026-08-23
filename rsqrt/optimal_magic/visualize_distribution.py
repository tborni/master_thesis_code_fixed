import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("fast_rsqrt_accuracy_sweep_results.csv", skiprows = 1)

df.hist(bins=50)

plt.show()
