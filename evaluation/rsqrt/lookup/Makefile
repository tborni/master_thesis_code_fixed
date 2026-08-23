# Makefile for the rsqrt lookup evaluation.
#
# Layout:
#   data/     input + generated tables (accuracy.txt, accuracy.csv, resources.csv)
#   scripts/  python tools (extract_accuracy.py, plot.py)
#   images/   generated heatmap PNGs
#
# Targets:
#   make            # parse accuracy.txt -> accuracy.csv, then render heatmaps
#   make csv        # only regenerate data/accuracy.csv
#   make plots      # only (re)render the heatmap PNGs
#   make clean      # remove all generated files (CSV, PNGs, stamp)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

EXTRACT := $(SCRIPTS)/extract_accuracy.py
PLOT    := $(SCRIPTS)/plot.py

ACCURACY_TXT  := $(DATA)/accuracy.txt
ACCURACY_CSV  := $(DATA)/accuracy.csv
RESOURCES_CSV := $(DATA)/resources.csv

# plot.py writes several PNGs, so a stamp file tracks whether they are current.
PLOT_STAMP := $(IMAGES)/.plots.stamp

.PHONY: all csv plots clean

all: csv plots

csv: $(ACCURACY_CSV)

plots: $(PLOT_STAMP)

$(ACCURACY_CSV): $(EXTRACT) $(ACCURACY_TXT)
	$(PYTHON) $(EXTRACT) --input $(ACCURACY_TXT) --output $(ACCURACY_CSV)

# plot.py resolves its own inputs (data/) and outputs (images/), so it can be
# invoked from anywhere.
$(PLOT_STAMP): $(PLOT) $(ACCURACY_CSV) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT)
	touch $(PLOT_STAMP)

clean:
	rm -f $(ACCURACY_CSV) $(PLOT_STAMP) \
	      $(IMAGES)/resources.png \
	      $(IMAGES)/accuracy_newton0.png \
	      $(IMAGES)/accuracy_newton1.png \
	      $(IMAGES)/accuracy_newton2.png
