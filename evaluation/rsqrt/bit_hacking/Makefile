# Makefile for the rsqrt bit-hacking evaluation.
#
# Layout:
#   data/     input + generated tables (accuracy.txt, accuracy.csv, resources.csv)
#   scripts/  python tools (extract_accuracy.py)
#
# Targets:
#   make            # parse accuracy.txt -> accuracy.csv
#   make csv        # same as the default
#   make clean      # remove the generated CSV

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data

EXTRACT := $(SCRIPTS)/extract_accuracy.py

ACCURACY_TXT := $(DATA)/accuracy.txt
ACCURACY_CSV := $(DATA)/accuracy.csv

.PHONY: all csv clean

all: csv

csv: $(ACCURACY_CSV)

$(ACCURACY_CSV): $(EXTRACT) $(ACCURACY_TXT)
	$(PYTHON) $(EXTRACT) --input $(ACCURACY_TXT) --output $(ACCURACY_CSV)

clean:
	rm -f $(ACCURACY_CSV)
