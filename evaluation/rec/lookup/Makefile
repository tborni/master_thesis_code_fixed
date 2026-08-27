# Makefile for the rec_lookup evaluation.
#
# Layout:
#   data/     input tables (accuracy.txt, resources.csv, ...) and the generated
#             accuracy.csv
#   scripts/  python tools (extract_accuracy.py, plot.py)
#   images/   generated heatmap PNGs
#
# Targets:
#   make             # build the CSVs and render every figure (heatmaps + sweeps)
#   make csv         # only regenerate data/accuracy.csv
#   make coeff-csv   # only regenerate data/accuracy_newton_coeff.csv
#   make improvement-csv  # only regenerate data/accuracy_newton_improvement.csv
#   make plots       # (re)render the heatmaps, the coeff-sweep line plot and the
#                    #   coefficient-tuning improvement heatmap
#   make clean       # remove generated CSV/PNGs/stamps (keeps resources.csv)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

EXTRACT             := $(SCRIPTS)/extract_accuracy.py
EXTRACT_COEFF       := $(SCRIPTS)/extract_accuracy_coeff.py
EXTRACT_IMPROVEMENT := $(SCRIPTS)/extract_accuracy_improvement.py
PLOT                := $(SCRIPTS)/plot.py
PLOT_COEFF          := $(SCRIPTS)/plot_coeff.py
PLOT_IMPROVEMENT    := $(SCRIPTS)/plot_improvement.py

ACCURACY_TXT      := $(DATA)/accuracy.txt
ACCURACY_CSV      := $(DATA)/accuracy.csv
COEFF_TXT         := $(DATA)/accuracy_newton_coeff_sweep_large.txt
COEFF_CSV         := $(DATA)/accuracy_newton_coeff.csv
# Improvement of the tuned coefficient over C=2: the C=2 baseline sweep compared
# against the tuned-C sweep (the NS=1 rows of accuracy.txt).
IMPROVEMENT_TXT   := $(DATA)/accuracy_newton_2_width_sweep.txt
IMPROVEMENT_CSV   := $(DATA)/accuracy_newton_improvement.csv
RESOURCES_CSV     := $(DATA)/resources.csv

# plot.py writes several PNGs, so a stamp file tracks whether they are current.
PLOT_STAMP  := $(IMAGES)/.plots.stamp
# plot_coeff.py writes a single named PNG, tracked directly as a file target.
COEFF_PNG   := $(IMAGES)/accuracy_newton_coeff.png
# plot_improvement.py likewise writes a single named PNG, tracked as a file target.
IMPROVEMENT_PNG := $(IMAGES)/accuracy_newton_improvement.png

NEWTON_STEPS := 0 1
ACCURACY_PNGS  := $(foreach n,$(NEWTON_STEPS),$(IMAGES)/accuracy_newton$(n).png)
RESOURCES_PNGS := $(foreach n,$(NEWTON_STEPS),$(IMAGES)/resources_newton$(n).png)

.PHONY: all csv coeff-csv improvement-csv plots clean

all: csv coeff-csv improvement-csv plots

csv: $(ACCURACY_CSV)

coeff-csv: $(COEFF_CSV)

improvement-csv: $(IMPROVEMENT_CSV)

plots: $(PLOT_STAMP) $(COEFF_PNG) $(IMPROVEMENT_PNG)

$(ACCURACY_CSV): $(EXTRACT) $(ACCURACY_TXT)
	$(PYTHON) $(EXTRACT) --input $(ACCURACY_TXT) --output $(ACCURACY_CSV)

$(COEFF_CSV): $(EXTRACT_COEFF) $(COEFF_TXT)
	$(PYTHON) $(EXTRACT_COEFF) --input $(COEFF_TXT) --output $(COEFF_CSV)

# The improvement table joins the C=2 baseline sweep against the tuned-C sweep
# (accuracy.txt), so it depends on both report files.
$(IMPROVEMENT_CSV): $(EXTRACT_IMPROVEMENT) $(IMPROVEMENT_TXT) $(ACCURACY_TXT)
	$(PYTHON) $(EXTRACT_IMPROVEMENT) --baseline $(IMPROVEMENT_TXT) \
	      --optimized $(ACCURACY_TXT) --output $(IMPROVEMENT_CSV)

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

# plot_improvement.py renders the coefficient-tuning improvement heatmap from the
# generated improvement CSV. It reuses plot.py's plot_heatmap (imported as a
# module), so it also depends on plot.py. Resolves its own paths, so
# cwd-independent.
$(IMPROVEMENT_PNG): $(PLOT_IMPROVEMENT) $(PLOT) $(IMPROVEMENT_CSV)
	$(PYTHON) $(PLOT_IMPROVEMENT)

clean:
	rm -f $(ACCURACY_CSV) $(COEFF_CSV) $(IMPROVEMENT_CSV) \
	      $(PLOT_STAMP) $(COEFF_PNG) $(IMPROVEMENT_PNG) \
	      $(ACCURACY_PNGS) $(RESOURCES_PNGS)
