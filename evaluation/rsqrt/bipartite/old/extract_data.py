import re
import csv

input_file = "accuracy.txt"
output_file = "Bipartite_accuracy.csv"

# Regex pattern to capture all fields
pattern = re.compile(
	r"Test\s*\("
	r"Newton\s*=\s*(\d+),\s*"
	r"ADDR_0\s*=\s*(\d+),\s*"
	r"ADDR_1\s*=\s*(\d+),\s*"
	r"ADDR_2\s*=\s*(\d+),\s*"
	r"WORD\s*=\s*(\d+)\):\s*"
	r"RMSRE\s*=\s*([0-9.eE+-]+),\s*"
	r"MAX_REL_ERROR\s*=\s*([0-9.eE+-]+),\s*"
	r"WORST_INPUT\s*=\s*([0-9.eE+-]+)"
)

rows = []

with open(input_file, "r") as f:
	for line in f:
		line = line.strip()
		if not line:
			continue

		match = pattern.search(line)
		if match:
			rows.append(match.groups())
		else:
			print(f"Warning: could not parse line:\n{line}")

# Write CSV
with open(output_file, "w", newline="") as f:
	writer = csv.writer(f)
	writer.writerow([
		"NUM_NEWTON_STEPS",
		"ADDR_WIDTH_0",
		"ADDR_WIDTH_1",
		"ADDR_WIDTH_2",
		"WORD_WIDTH",
		"RMSRE",
		"MAX_REL_ERROR",
		"WORST_INPUT"
	])
	writer.writerows(rows)

print(f"Saved {len(rows)} rows to {output_file}")