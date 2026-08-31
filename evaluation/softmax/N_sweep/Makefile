# Makefile for the Softmax N-sweep evaluation.
#
# Layout:
#   data/     input reports (accuracy_{large,small}_error.txt), the hand-authored
#             resources.csv, and the generated accuracy_{large,small}_error.csv
#   scripts/  python tools (extract_accuracy.py, plot_accuracy.py,
#             plot_resources.py, fit_report.py)
#   images/   generated PNGs
#
# The sweep varies the vector length N (SIMD fixed) and produces two accuracy
# reports, distinguished by the magnitude of the reference error they were
# measured against (large_error and small_error). extract_accuracy.py turns each
# report into a CSV; plot_accuracy.py renders one RMSRE-vs-N figure per report
# (linear y-axis, base-2 log x-axis); plot_resources.py fits LUT = m*N + n and
# renders it on a linear- and a log-x axis, recording the fit into the shared
# data/fit_parameters.txt (the [resources] section).
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
# Shared fit-parameters writer imported by plot_resources.py; a change to it must
# re-run that plot, so it is a prerequisite of the resources rule below.
FIT_REPORT     := $(SCRIPTS)/fit_report.py

# One accuracy report per error-magnitude configuration.
ERROR_CASES   := large small
ACCURACY_TXTS := $(foreach c,$(ERROR_CASES),$(DATA)/accuracy_$(c)_error.txt)
ACCURACY_CSVS := $(foreach c,$(ERROR_CASES),$(DATA)/accuracy_$(c)_error.csv)

RESOURCES_CSV := $(DATA)/resources.csv

# plot_accuracy.py writes one PNG per error case; plot_resources.py writes two.
# Each is tracked directly as a file target so it only re-renders when its inputs
# change; the "secondary" outputs of a single script run are tied to the primary
# one so the script is not invoked more than once.
ACCURACY_LARGE_PNG := $(IMAGES)/accuracy_large_error.png
ACCURACY_SMALL_PNG := $(IMAGES)/accuracy_small_error.png
RESOURCES_LIN_PNG  := $(IMAGES)/resources_lut_linear.png
RESOURCES_LOG_PNG  := $(IMAGES)/resources_lut_log.png
# Shared fit-parameters file: plot_resources.py writes its [resources] section as
# a byproduct, so it is produced by that plot's invocation.
FIT_TXT            := $(DATA)/fit_parameters.txt

.PHONY: all csv plots clean

all: csv plots

csv: $(ACCURACY_CSVS)

plots: $(ACCURACY_LARGE_PNG) $(ACCURACY_SMALL_PNG) \
       $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) $(FIT_TXT)

# Static pattern rule: each accuracy CSV is extracted from its matching report.
$(ACCURACY_CSVS): $(DATA)/accuracy_%_error.csv: $(DATA)/accuracy_%_error.txt $(EXTRACT)
	$(PYTHON) $(EXTRACT) --input $< --output $@

# plot_accuracy.py resolves its own inputs (data/) and outputs (images/), so it
# can be invoked from anywhere. It reads both accuracy CSVs and renders both
# RMSRE-vs-N figures in a single run; the small-error PNG shares that invocation
# with the large-error PNG.
$(ACCURACY_LARGE_PNG): $(PLOT_ACCURACY) $(ACCURACY_CSVS)
	$(PYTHON) $(PLOT_ACCURACY)
$(ACCURACY_SMALL_PNG): $(ACCURACY_LARGE_PNG)

# plot_resources.py renders both LUT-vs-N figures from resources.csv in a single
# run and writes its [resources] section of fit_parameters.txt; the log-x PNG and
# the fit-parameters file share that invocation with the linear-x PNG.
$(RESOURCES_LIN_PNG): $(PLOT_RESOURCES) $(FIT_REPORT) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT_RESOURCES)
$(RESOURCES_LOG_PNG): $(RESOURCES_LIN_PNG)
$(FIT_TXT): $(RESOURCES_LIN_PNG)

clean:
	rm -f $(ACCURACY_CSVS) \
	      $(ACCURACY_LARGE_PNG) $(ACCURACY_SMALL_PNG) \
	      $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) \
	      $(FIT_TXT)
