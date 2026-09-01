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
# report per configuration. plot_accuracy.py renders the 1-Newton RMSRE-vs-N
# log-log figure with a power-law fit; plot_resources.py fits LUT = m*N + n and
# renders it on a linear- and a log-x axis. Both scripts also record their fit
# into the shared data/fit_parameters.txt (each owns one [section]).
#
# Targets:
#   make            # build the accuracy CSVs and render every figure
#   make csv        # only (re)generate the accuracy CSVs
#   make plots      # only (re)render the PNGs + the fit-parameters file
#   make clean      # remove generated CSVs/PNGs/fit params (keeps resources.csv)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

EXTRACT        := $(SCRIPTS)/extract_accuracy.py
PLOT_ACCURACY  := $(SCRIPTS)/plot_accuracy.py
PLOT_RESOURCES := $(SCRIPTS)/plot_resources.py
# Shared fit-parameters writer imported by both plot scripts; a change to it must
# re-run both, so it is a prerequisite of each plot rule below.
FIT_REPORT     := $(SCRIPTS)/fit_report.py

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
RESOURCES_CMB_PNG := $(IMAGES)/resources_lut_combined.png
# Shared fit-parameters file: both plot scripts write their own [section] of it
# as a byproduct, so it is complete only once both have run.
FIT_TXT           := $(DATA)/fit_parameters.txt

.PHONY: all csv plots clean

all: csv plots

csv: $(ACCURACY_CSVS)

plots: $(ACCURACY_PNG) $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) $(RESOURCES_CMB_PNG) $(FIT_TXT)

# Static pattern rule: each accuracy CSV is extracted from its matching report.
$(ACCURACY_CSVS): $(DATA)/accuracy_%_newton.csv: $(DATA)/accuracy_%_newton.txt $(EXTRACT)
	$(PYTHON) $(EXTRACT) --input $< --output $@

# plot_accuracy.py resolves its own inputs (data/) and outputs (images/, data/),
# so it can be invoked from anywhere. It reads the 1-Newton accuracy CSV, renders
# accuracy.png and writes its [accuracy] section of fit_parameters.txt.
$(ACCURACY_PNG): $(PLOT_ACCURACY) $(FIT_REPORT) $(ACCURACY_CSVS)
	$(PYTHON) $(PLOT_ACCURACY)

# plot_resources.py renders all three LUT-vs-N figures from resources.csv in a
# single run and writes its [resources] section of fit_parameters.txt; the log-x
# and combined (two-panel) PNGs share that invocation with the linear-x PNG.
$(RESOURCES_LIN_PNG): $(PLOT_RESOURCES) $(FIT_REPORT) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT_RESOURCES)
$(RESOURCES_LOG_PNG): $(RESOURCES_LIN_PNG)
$(RESOURCES_CMB_PNG): $(RESOURCES_LIN_PNG)

# fit_parameters.txt is written as a byproduct of both plot runs (each script
# fills in its own [section]), so it is up to date once both PNGs are. No recipe
# of its own; depending on both plot outputs ties it to their invocations.
$(FIT_TXT): $(ACCURACY_PNG) $(RESOURCES_LIN_PNG)

clean:
	rm -f $(ACCURACY_CSVS) \
	      $(ACCURACY_PNG) $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) \
	      $(RESOURCES_CMB_PNG) \
	      $(FIT_TXT)
