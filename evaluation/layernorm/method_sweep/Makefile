# Full-LayerNorm method-sweep data analysis.
#
#   make            run the whole pipeline: extract CSVs, compare against the
#                   InvSqrt-only accuracy, build the combined CSVs, render figures
#   make csv        only (re)extract data/accuracy_layernorm/*.csv from the reports
#   make compare    only (re)write data/compare_report.txt (LayerNorm vs InvSqrt)
#   make combined   only (re)generate data_combined/*_combined.csv
#   make plots      only (re)render images/*.png from the combined CSVs
#   make clean      remove every generated file (keeps the hand-authored inputs)
#
# PYTHON defaults to the repository virtualenv (consistent numpy/pandas/
# matplotlib); override on the command line, e.g. `make PYTHON=python3`.

ROOT   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PYTHON ?= $(ROOT)../../../.venv/bin/python

SCRIPTS   := scripts
DATA      := data
COMBINED  := data_combined
IMAGES    := images

# --- Scripts ----------------------------------------------------------------
EXTRACT_SCRIPT := $(SCRIPTS)/extract_accuracy.py
COMPARE_SCRIPT := $(SCRIPTS)/compare_accuracy.py
GEN_SCRIPT     := $(SCRIPTS)/generate_combined.py
PLOT_SCRIPT    := $(SCRIPTS)/plots.py
FILTER         := filter.toml

# --- Hand-authored inputs (never generated, never cleaned) ------------------
ACC_REPORTS  := $(wildcard $(DATA)/accuracy_layernorm/*.txt)
INVSQRT_CSV  := $(wildcard $(DATA)/accuracy_invsqrt/*.csv)
RESOURCE_CSV := $(wildcard $(DATA)/resources/*.csv)

# --- Generated artefacts ----------------------------------------------------
# Batch steps write several files at once, so a stamp file tracks each batch.
ACC_STAMP      := $(DATA)/accuracy_layernorm/.stamp
COMBINED_STAMP := $(COMBINED)/.stamp
COMPARE_REPORT := $(DATA)/compare_report.txt
FIGURES        := $(IMAGES)/diagram.png $(IMAGES)/pareto.png $(IMAGES)/full_pareto.png

.PHONY: all csv compare combined plots clean

all: csv compare combined plots

# --- Stage 1: extract accuracy reports into per-method CSVs ------------------
csv: $(ACC_STAMP)

$(ACC_STAMP): $(EXTRACT_SCRIPT) $(ACC_REPORTS)
	$(PYTHON) $(EXTRACT_SCRIPT)
	@touch $@

# --- Stage 2: compare full-LayerNorm vs InvSqrt-only accuracy ----------------
compare: $(COMPARE_REPORT)

$(COMPARE_REPORT): $(COMPARE_SCRIPT) $(ACC_STAMP) $(INVSQRT_CSV)
	$(PYTHON) $(COMPARE_SCRIPT) -o $@

# --- Stage 3: lift InvSqrt resources and join with accuracy -----------------
combined: $(COMBINED_STAMP)

$(COMBINED_STAMP): $(GEN_SCRIPT) $(ACC_STAMP) $(RESOURCE_CSV)
	$(PYTHON) $(GEN_SCRIPT)
	@touch $@

# --- Stage 4: render the Pareto figures -------------------------------------
plots: $(FIGURES)

$(FIGURES): $(PLOT_SCRIPT) $(FILTER) $(COMBINED_STAMP)
	$(PYTHON) $(PLOT_SCRIPT)

# --- Housekeeping -----------------------------------------------------------
# Removes only generated files; the hand-authored inputs (the .txt reports in
# data/accuracy_layernorm, plus data/accuracy_invsqrt and data/resources) stay.
clean:
	rm -f $(DATA)/accuracy_layernorm/*.csv $(ACC_STAMP)
	rm -f $(COMPARE_REPORT)
	rm -f $(COMBINED)/*_combined.csv $(COMBINED_STAMP)
	rm -f $(IMAGES)/*.png
	@rmdir $(COMBINED) 2>/dev/null || true
