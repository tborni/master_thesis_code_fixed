# Makefile for the Softmax method-sweep evaluation.
#
# Layout:
#   data/            input report (accuracy.txt) and the per-method component
#                    RMSRE CSVs under data/exp/ and data/rec/; the generated
#                    theory_accuracy_comparison.csv
#   scripts/         python tools (combine_accuracy.py, verify_combined.py)
#   images/          generated PNGs (none yet)
#
# The sweep measures the full softmax RMSRE for every combination of an exp
# approximation method (EXP) and a reciprocal approximation method (REC), at
# fixed N=64, SIMD=2. combine_accuracy.py cross-references each measured setup in
# data/accuracy.txt with the component RMSRE recorded in data/exp/ and data/rec/,
# then tabulates the measured softmax RMSRE against the theoretical model
# sqrt(RMSRE(exp)^2 + RMSRE(rec)^2) and their relative difference, writing
# data/theory_accuracy_comparison.csv. verify_combined.py independently
# re-derives every value from hand-transcribed ground truth and asserts the CSV
# matches.
#
# Targets:
#   make            # (re)generate the comparison CSV
#   make csv        # same as `make`
#   make verify     # regenerate the CSV, then independently verify it
#   make clean      # remove the generated CSV; keeps all inputs

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON  := $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data

COMBINE := $(SCRIPTS)/combine_accuracy.py
VERIFY  := $(SCRIPTS)/verify_combined.py

# Inputs to the combine step: the measured report plus the component CSVs it
# actually looks up. A change to any of them must re-generate the combined
# table. These are listed explicitly rather than globbed: the sweep only uses
# the bit-hacking/lookup/bipartite/splitting methods (not IP-core), and the
# IP-core file names contain a space, which a $(wildcard) prerequisite list
# would split into broken targets.
ACCURACY_TXT   := $(DATA)/accuracy.txt
COMPONENT_CSVS := \
	$(DATA)/exp/Bit-hacking_combined.csv \
	$(DATA)/exp/Lookup_combined.csv \
	$(DATA)/exp/Bipartite_combined.csv \
	$(DATA)/exp/Splitting_combined.csv \
	$(DATA)/rec/Lookup_combined.csv \
	$(DATA)/rec/Bipartite_combined.csv

COMPARISON_CSV := $(DATA)/theory_accuracy_comparison.csv

.PHONY: all csv verify clean

all: csv

csv: $(COMPARISON_CSV)

# combine_accuracy.py resolves its own inputs (data/) and output, so it can be
# invoked from anywhere.
$(COMPARISON_CSV): $(COMBINE) $(ACCURACY_TXT) $(COMPONENT_CSVS)
	$(PYTHON) $(COMBINE)

# Independent check of the generated CSV. Phony so it always re-runs the
# verifier; it first ensures the CSV is up to date.
verify: $(COMPARISON_CSV)
	$(PYTHON) $(VERIFY)

clean:
	rm -f $(COMPARISON_CSV)
