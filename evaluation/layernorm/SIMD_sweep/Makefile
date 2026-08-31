# Makefile for the LayerNorm SIMD-sweep evaluation.
#
# Layout:
#   data/     input reports (accuracy_{0,1}_newton.txt) and the hand-authored
#             resources.csv
#   scripts/  python tools (plot_resources.py)
#   images/   generated PNGs
#
# The sweep varies the SIMD unroll factor (N fixed) and records the synthesis
# resource usage in resources.csv. plot_resources.py fits LUT = m*SIMD + n and
# DSP = m*SIMD + n and renders both series on a dual-axis figure (LUT on the
# left y-axis, DSP on the right), once with a linear-x and once with a log-x
# axis; it also writes the fitted parameters to data/fit_parameters.txt. The
# accuracy_{0,1}_newton.txt reports are left untouched.
#
# Targets:
#   make            # render the figures and write the fit parameters (== plots)
#   make plots      # (re)render the PNGs + (re)write data/fit_parameters.txt
#   make clean      # remove generated PNGs + fit_parameters.txt (keeps resources.csv)

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data
IMAGES  := $(ROOT)images

PLOT_RESOURCES := $(SCRIPTS)/plot_resources.py

RESOURCES_CSV := $(DATA)/resources.csv

# plot_resources.py writes two PNGs and the fit-parameters text file in a single
# run. Each is tracked as a file target so they only regenerate when the script
# or resources.csv change.
RESOURCES_LIN_PNG := $(IMAGES)/resources_linear.png
RESOURCES_LOG_PNG := $(IMAGES)/resources_log.png
FIT_TXT           := $(DATA)/fit_parameters.txt

.PHONY: all plots clean

all: plots

plots: $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) $(FIT_TXT)

# plot_resources.py resolves its own inputs (data/) and outputs (images/, data/),
# so it can be invoked from anywhere. It renders both figures and writes
# fit_parameters.txt in one run; the log-x PNG and the fit file share that single
# invocation with the linear-x PNG.
$(RESOURCES_LIN_PNG): $(PLOT_RESOURCES) $(RESOURCES_CSV)
	$(PYTHON) $(PLOT_RESOURCES)
$(RESOURCES_LOG_PNG): $(RESOURCES_LIN_PNG)
$(FIT_TXT): $(RESOURCES_LIN_PNG)

clean:
	rm -f $(RESOURCES_LIN_PNG) $(RESOURCES_LOG_PNG) $(FIT_TXT)
