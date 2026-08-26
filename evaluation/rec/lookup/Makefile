# Makefile for the rec_lookup evaluation.
#
# Layout:
#   data/     input tables (accuracy.txt, resources.csv, ...) and the generated
#             accuracy.csv
#   scripts/  python tools (extract_accuracy.py, plot.py)
#   images/   generated heatmap PNGs
#
# Targets:
#   make            # build the CSVs and render every figure (heatmaps + coeff sweep)
#   make csv        # only regenerate data/accuracy.csv
#   make coeff-csv  # only regenerate data/accuracy_newton_coeff.csv
#   make plots      # only (re)render the heatmaps and the coeff-sweep line plot
#   make clean      # remove generated CSV/PNGs/stamps (keeps resources.csv)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

EXTRACT       := $(SCRIPTS)/extract_accuracy.py
EXTRACT_COEFF := $(SCRIPTS)/extract_accuracy_coeff.py
PLOT          := $(SCRIPTS)/plot.py
PLOT_COEFF    := $(SCRIPTS)/plot_coeff.py

ACCURACY_TXT   := $(DATA)/accuracy.txt
ACCURACY_CSV   := $(DATA)/accuracy.csv
COEFF_TXT      := $(DATA)/accuracy_newton_coeff_sweep_large.txt
COEFF_CSV      := $(DATA)/accuracy_newton_coeff.csv
RESOURCES_CSV  := $(DATA)/resources.csv

# plot.py writes several PNGs, so a stamp file tracks whether they are current.
PLOT_STAMP  := $(IMAGES)/.plots.stamp
# plot_coeff.py writes a single named PNG, tracked directly as a file target.
COEFF_PNG   := $(IMAGES)/accuracy_newton_coeff.png

NEWTON_STEPS := 0 1
ACCURACY_PNGS  := $(foreach n,$(NEWTON_STEPS),$(IMAGES)/accuracy_newton$(n).png)
RESOURCES_PNGS := $(foreach n,$(NEWTON_STEPS),$(IMAGES)/resources_newton$(n).png)

.PHONY: all csv coeff-csv plots clean

all: csv coeff-csv plots

csv: $(ACCURACY_CSV)

coeff-csv: $(COEFF_CSV)

plots: $(PLOT_STAMP) $(COEFF_PNG)

$(ACCURACY_CSV): $(EXTRACT) $(ACCURACY_TXT)
	$(PYTHON) $(EXTRACT) --input $(ACCURACY_TXT) --output $(ACCURACY_CSV)

$(COEFF_CSV): $(EXTRACT_COEFF) $(COEFF_TXT)
	$(PYTHON) $(EXTRACT_COEFF) --input $(COEFF_TXT) --output $(COEFF_CSV)

# plot.py resolves its own inputs (data/) and outputs (images/), so it can be
# invoked from anywhere. Depends on the generated accuracy table and the
# pre-built resources table.
$(PLOT_STAMP): $(PLOT) $(ACCURACY_CSV) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT)
	touch $(PLOT_STAMP)

# plot_coeff.py renders the correction-coefficient sweep (RMSRE + max_rel_error
# vs C) from the generated coeff CSV. Resolves its own paths, so cwd-independent.
$(COEFF_PNG): $(PLOT_COEFF) $(COEFF_CSV)
	$(PYTHON) $(PLOT_COEFF)

clean:
	rm -f $(ACCURACY_CSV) $(COEFF_CSV) $(PLOT_STAMP) $(COEFF_PNG) \
	      $(ACCURACY_PNGS) $(RESOURCES_PNGS)
