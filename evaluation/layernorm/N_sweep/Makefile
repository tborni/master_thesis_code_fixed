# Makefile for the LayerNorm N-sweep evaluation.
#
# Layout:
#   data/     input reports (accuracy_{0,1}_newton.txt), the hand-authored
#             resources.csv, and the generated accuracy_{0,1}_newton.csv
#   scripts/  python tools (extract_accuracy.py, plot_accuracy.py,
#             plot_resources.py)
#   images/   generated PNGs
#
# The sweep varies the vector length N (SIMD fixed) for two invsqrt
# configurations (0 and 1 Newton refinement steps), so there is one accuracy
# report per configuration. plot_accuracy.py overlays both as an RMSRE-vs-N
# log-log figure; plot_resources.py fits LUT = m*N + n and renders it on a
# linear- and a log-x axis.
#
# Targets:
#   make            # build the accuracy CSVs and render every figure
#   make csv        # only (re)generate the accuracy CSVs
#   make plots      # only (re)render the PNGs
#   make clean      # remove generated CSVs/PNGs (keeps resources.csv)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

EXTRACT        := $(SCRIPTS)/extract_accuracy.py
PLOT_ACCURACY  := $(SCRIPTS)/plot_accuracy.py
PLOT_RESOURCES := $(SCRIPTS)/plot_resources.py

# One accuracy report per Newton-step configuration.
NEWTON_STEPS  := 0 1
ACCURACY_TXTS := $(foreach n,$(NEWTON_STEPS),$(DATA)/accuracy_$(n)_newton.txt)
ACCURACY_CSVS := $(foreach n,$(NEWTON_STEPS),$(DATA)/accuracy_$(n)_newton.csv)

RESOURCES_CSV := $(DATA)/resources.csv

# plot_accuracy.py writes one PNG; plot_resources.py writes two. Each is tracked
# directly as a file target so it only re-renders when its inputs change.
ACCURACY_PNG      := $(IMAGES)/accuracy.png
RESOURCES_LIN_PNG := $(IMAGES)/resources_lut_linear.png
RESOURCES_LOG_PNG := $(IMAGES)/resources_lut_log.png

.PHONY: all csv plots clean

all: csv plots

csv: $(ACCURACY_CSVS)

plots: $(ACCURACY_PNG) $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG)

# Static pattern rule: each accuracy CSV is extracted from its matching report.
$(ACCURACY_CSVS): $(DATA)/accuracy_%_newton.csv: $(DATA)/accuracy_%_newton.txt $(EXTRACT)
	$(PYTHON) $(EXTRACT) --input $< --output $@

# plot_accuracy.py resolves its own inputs (data/) and outputs (images/), so it
# can be invoked from anywhere. It reads both accuracy CSVs.
$(ACCURACY_PNG): $(PLOT_ACCURACY) $(ACCURACY_CSVS)
	$(PYTHON) $(PLOT_ACCURACY)

# plot_resources.py renders both LUT-vs-N figures from resources.csv in a single
# run; the log-x PNG shares that invocation with the linear-x PNG.
$(RESOURCES_LIN_PNG): $(PLOT_RESOURCES) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT_RESOURCES)
$(RESOURCES_LOG_PNG): $(RESOURCES_LIN_PNG)

clean:
	rm -f $(ACCURACY_CSVS) \
	      $(ACCURACY_PNG) $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG)
