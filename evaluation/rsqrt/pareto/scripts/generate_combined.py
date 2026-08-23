import os
import re
from collections import defaultdict
import pandas as pd

def clean_df(df):
	# Clean column names
	df.columns = [c.strip().lower() for c in df.columns]
	
	# Strip whitespace from string values
	for col in df.select_dtypes(include=['object', 'string']):
		df[col] = df[col].astype(str).str.strip()

	return df

pattern = re.compile(r'^([A-Za-z0-9_+-]+)_(resources|accuracy|combined)\.csv$')

files = [f for f in os.listdir('.') if f.endswith('.csv')]

groups = defaultdict(set)

# Step 1: Validate filenames and group them
for f in files:
	match = pattern.match(f)
	if not match:
		raise ValueError(f"Invalid filename format: {f}")
	
	key, category = match.groups()
	groups[key].add(category)

# Step 2: Check pairing rule for resources/accuracy
for key, categories in groups.items():
	has_resources = 'resources' in categories
	has_accuracy = 'accuracy' in categories

	if has_resources != has_accuracy:
		raise ValueError(
			f"Missing pair for '{key}': "
			f"{'resources' if not has_resources else 'accuracy'} file is missing"
		)

# Step 3: Iterate over valid pairs (ignore combined files)
for key, categories in groups.items():
	if 'resources' in categories and 'accuracy' in categories:
		resources_file = f"{key}_resources.csv"
		accuracy_file = f"{key}_accuracy.csv"
		output_file = f"{key}_combined.csv"

		df_res = clean_df(pd.read_csv(resources_file, comment='#'))
		df_acc = clean_df(pd.read_csv(accuracy_file, comment='#'))

		# Ensure required columns exist
		if 'lut' not in df_res.columns:
			raise ValueError(f"'LUT' column missing in {resources_file}")
		if 'dsp' not in df_res.columns:
			raise ValueError(f"'DSP' column missing in {resources_file}")
		if 'rmsre' not in df_acc.columns:
			raise ValueError(f"'rmsre' column missing in {accuracy_file}")

		# Determine matching columns (all except lut,dsp,rmsre)
		join_cols = list(
			set(df_res.columns).intersection(df_acc.columns) - {'lut', 'dsp', 'rmsre'}
		)

		if not join_cols:
			raise ValueError(f"No common columns to join on for '{key}'")

		# Merge on matching columns
		merged = pd.merge(
			df_res,
			df_acc,
			on=join_cols,
			how='inner'
		)

		result = merged[join_cols + ['lut', 'dsp', 'rmsre']]
		result.to_csv(output_file, index=False)
