# Pareto figures for the rsqrt evaluation.
#
#   make            generate combined CSVs, then render the three figures
#   make combined   only (re)generate pareto/data_combined/*_combined.csv
#   make images     only (re)render pareto/images/*.png from existing CSVs
#   make clean      remove all generated combined CSVs and images
#
# PYTHON defaults to the repository virtualenv (consistent numpy/pandas/
# matplotlib); override on the command line, e.g. `make PYTHON=python3`.

PYTHON ?= ../../../.venv/bin/python

SCRIPTS      := scripts
DATA_DIR     := data_combined
IMAGE_DIR    := images

GEN_SCRIPT   := $(SCRIPTS)/generate_combined.py
PLOT_SCRIPT  := $(SCRIPTS)/plots.py
FILTER       := filter.toml

# Source data: every method's accuracy/resources pair drives the combined files.
SOURCE_CSV   := $(wildcard ../*/data/accuracy.csv ../*/data/resources.csv)
COMBINED_CSV := $(wildcard $(DATA_DIR)/*_combined.csv)
IMAGES       := $(IMAGE_DIR)/diagram.png $(IMAGE_DIR)/pareto.png $(IMAGE_DIR)/full_pareto.png

.PHONY: all combined images clean

all: combined images

# --- Stage 1: combined CSVs -------------------------------------------------
# A stamp file tracks the batch generation (the script writes several outputs).
combined: $(DATA_DIR)/.stamp

$(DATA_DIR)/.stamp: $(GEN_SCRIPT) $(SOURCE_CSV)
	$(PYTHON) $(GEN_SCRIPT)
	@touch $@

# --- Stage 2: figures -------------------------------------------------------
images: $(IMAGES)

$(IMAGES): $(PLOT_SCRIPT) $(FILTER) $(DATA_DIR)/.stamp
	$(PYTHON) $(PLOT_SCRIPT)

# --- Housekeeping -----------------------------------------------------------
clean:
	rm -f $(DATA_DIR)/*_combined.csv $(DATA_DIR)/.stamp
	rm -f $(IMAGE_DIR)/*.png
