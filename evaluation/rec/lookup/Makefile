# Makefile for the rsqrt lookup evaluation.
#
# Layout:
#   data/     input + generated tables (accuracy.txt, accuracy.csv, resources.csv,
#             and the extra Lookup+Newton*_resources.csv exports)
#   scripts/  python tools (extract_accuracy.py, merge_resources.py, plot.py)
#   images/   generated heatmap PNGs
#
# Targets:
#   make            # build accuracy.csv, merge extra resources, render heatmaps
#   make csv        # only regenerate data/accuracy.csv
#   make resources  # only merge the extra resource exports into resources.csv
#   make plots      # only (re)render the heatmap PNGs
#   make clean      # remove generated CSV/PNGs/stamps (keeps resources.csv)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

EXTRACT := $(SCRIPTS)/extract_accuracy.py
MERGE   := $(SCRIPTS)/merge_resources.py
PLOT    := $(SCRIPTS)/plot.py

ACCURACY_TXT   := $(DATA)/accuracy.txt
ACCURACY_CSV   := $(DATA)/accuracy.csv
RESOURCES_CSV  := $(DATA)/resources.csv
EXTRA_RESOURCES := $(DATA)/Lookup+Newton_resources.csv $(DATA)/Lookup+Newton2_resources.csv

# merge_resources.py edits resources.csv in place, so a stamp tracks whether the
# merge is current instead of using the mutated file as its own target.
MERGE_STAMP := $(DATA)/.resources.stamp
# plot.py writes several PNGs, so a stamp file tracks whether they are current.
PLOT_STAMP  := $(IMAGES)/.plots.stamp

NEWTON_STEPS := 0 1 2
ACCURACY_PNGS  := $(foreach n,$(NEWTON_STEPS),$(IMAGES)/accuracy_newton$(n).png)
RESOURCES_PNGS := $(foreach n,$(NEWTON_STEPS),$(IMAGES)/resources_newton$(n).png)

.PHONY: all csv resources plots clean

all: csv resources plots

csv: $(ACCURACY_CSV)

resources: $(MERGE_STAMP)

plots: $(PLOT_STAMP)

$(ACCURACY_CSV): $(EXTRACT) $(ACCURACY_TXT)
	$(PYTHON) $(EXTRACT) --input $(ACCURACY_TXT) --output $(ACCURACY_CSV)

# Merge the extra resource exports into resources.csv. Idempotent: re-running
# without changed inputs is a no-op.
$(MERGE_STAMP): $(MERGE) $(EXTRA_RESOURCES)
	$(PYTHON) $(MERGE)
	touch $(MERGE_STAMP)

# plot.py resolves its own inputs (data/) and outputs (images/), so it can be
# invoked from anywhere. Depends on the merged resources table.
$(PLOT_STAMP): $(PLOT) $(ACCURACY_CSV) $(RESOURCES_CSV) $(MERGE_STAMP)
	$(PYTHON) $(PLOT)
	touch $(PLOT_STAMP)

clean:
	rm -f $(ACCURACY_CSV) $(PLOT_STAMP) $(MERGE_STAMP) \
	      $(ACCURACY_PNGS) $(RESOURCES_PNGS)
