# Makefile for the Softmax SIMD-sweep evaluation.
#
# Layout:
#   data/     input reports (accuracy_{large,small}_error.txt), the hand-authored
#             resources.csv, and the generated accuracy_{large,small}_error.csv
#   scripts/  python tools (extract_accuracy.py, plot_resources.py, fit_report.py)
#   images/   generated PNGs
#
# The sweep varies the SIMD unroll width (vector length N fixed at 64 in the
# resources report) and produces two accuracy reports, distinguished by the
# magnitude of the reference error they were measured against (large_error and
# small_error). extract_accuracy.py turns each report into a CSV (columns
# N, SIMD, RMSRE, MAX_REL_ERROR); plot_resources.py fits LUT = m*SIMD + n and
# DSP = m*SIMD + n and renders both series on a dual-axis figure (LUT on the left
# y-axis, DSP on the right), once with a linear-x axis, once with a log-x axis and
# once as a combined two-panel (linear | log) figure, recording the fits into the
# shared data/fit_parameters.txt (the [resources] section).
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
PLOT_RESOURCES := $(SCRIPTS)/plot_resources.py
# Shared fit-parameters writer imported by plot_resources.py; a change to it must
# re-run that plot, so it is a prerequisite of the resources rule below.
FIT_REPORT     := $(SCRIPTS)/fit_report.py

# One accuracy report per error-magnitude configuration.
ERROR_CASES   := large small
ACCURACY_TXTS := $(foreach c,$(ERROR_CASES),$(DATA)/accuracy_$(c)_error.txt)
ACCURACY_CSVS := $(foreach c,$(ERROR_CASES),$(DATA)/accuracy_$(c)_error.csv)

RESOURCES_CSV := $(DATA)/resources.csv

# plot_resources.py writes three PNGs (linear-x, log-x and a combined two-panel)
# in a single run. Each is tracked directly as a file target so it only re-renders
# when its inputs change; the "secondary" outputs of a single script run are tied
# to the primary one so the script is not invoked more than once.
RESOURCES_LIN_PNG  := $(IMAGES)/resources_lut_linear.png
RESOURCES_LOG_PNG  := $(IMAGES)/resources_lut_log.png
RESOURCES_CMB_PNG  := $(IMAGES)/resources_lut_combined.png
# Shared fit-parameters file: plot_resources.py writes its [resources] section as
# a byproduct, so it is produced by that plot's invocation.
FIT_TXT            := $(DATA)/fit_parameters.txt

.PHONY: all csv plots clean

all: csv plots

csv: $(ACCURACY_CSVS)

plots: $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) $(RESOURCES_CMB_PNG) $(FIT_TXT)

# Static pattern rule: each accuracy CSV is extracted from its matching report.
$(ACCURACY_CSVS): $(DATA)/accuracy_%_error.csv: $(DATA)/accuracy_%_error.txt $(EXTRACT)
	$(PYTHON) $(EXTRACT) --input $< --output $@

# plot_resources.py renders all three dual-axis LUT+DSP-vs-SIMD figures from
# resources.csv in a single run and writes its [resources] section of
# fit_parameters.txt; the log-x and combined (two-panel) PNGs and the
# fit-parameters file share that invocation with the linear-x PNG.
$(RESOURCES_LIN_PNG): $(PLOT_RESOURCES) $(FIT_REPORT) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT_RESOURCES)
$(RESOURCES_LOG_PNG): $(RESOURCES_LIN_PNG)
$(RESOURCES_CMB_PNG): $(RESOURCES_LIN_PNG)
$(FIT_TXT): $(RESOURCES_LIN_PNG)

clean:
	rm -f $(ACCURACY_CSVS) \
	      $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) \
	      $(RESOURCES_CMB_PNG) \
	      $(FIT_TXT)
