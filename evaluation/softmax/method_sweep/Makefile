# Makefile for the Softmax method-sweep evaluation.
#
# This folder holds TWO independent analyses over the same measured data:
#
#   A) Accuracy comparison  (theory vs. measured softmax RMSRE)
#      combine_accuracy.py cross-references each measured setup in
#      data/accuracy_softmax/accuracy.txt with the component RMSRE recorded in
#      the combined per-method CSVs and tabulates the measured softmax RMSRE
#      against the theoretical model, writing
#      data/accuracy_softmax/theory_accuracy_comparison.csv. verify_combined.py
#      independently re-derives every value from hand-transcribed ground truth
#      and asserts the CSV matches.
#
#   B) Pareto pipeline      (component -> softmax -> plots), a 3-step pipeline
#      over this folder's COMBINED data files (each method's params + LUT + DSP
#      + RMSRE live together in one data/{exp,rec}/*.csv, so there is no
#      accuracy<->resource join):
#        step1_components.py -> data/generated/{exp,rec}.csv
#        step2_softmax.py    -> data/generated/softmax_SIMD_<v>.csv
#        step3_plot.py       -> images{,_aligned}/SIMD_<v>/{dsp_only,method_dsp}/*.png
#      Which component points feed the pipeline is controlled by filter.toml
#      (metric bounds + per-method y/n include flags), read by step 1.
#
# Layout:
#   data/accuracy_softmax/  the measured report (accuracy.txt), the
#                    correction_factor.txt notes, and the generated
#                    theory_accuracy_comparison.csv
#   data/exp/, data/rec/    the per-method COMBINED component CSVs (inputs)
#   data/resources_SIMD.csv total softmax resources vs. SIMD (base build)
#   data/generated/  generated fronts: {exp,rec,softmax_SIMD_<v>}.csv (analysis B)
#   filter.toml      selects which component points feed analysis B
#   scripts/         python tools (both analyses)
#   images/, images_aligned/  generated PNGs                (analysis B)
#
# Targets:
#   make            # run BOTH analyses: comparison CSV + all Pareto plots
#   make csv        # (A) (re)generate the accuracy comparison CSV
#   make verify     # (A) regenerate the CSV, then independently verify it
#   make components # (B) data/generated/{exp,rec}.csv                  (step 1)
#   make softmax    # (B) data/generated/softmax_SIMD_<v>.csv           (step 2)
#   make plots      # (B) images{,_aligned}/SIMD_<v>/*/*.png            (step 3)
#   make clean      # remove ALL generated artifacts; keeps every input

# Directory of this Makefile, so `make` works from any working directory.
ROOT    := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# PYTHONDONTWRITEBYTECODE keeps the tree free of __pycache__ directories.
PYTHON  := PYTHONDONTWRITEBYTECODE=1 $(ROOT)../../../.venv/bin/python
SCRIPTS := $(ROOT)scripts
DATA    := $(ROOT)data

# --------------------------------------------------------------------------- #
# Analysis A: accuracy comparison
# --------------------------------------------------------------------------- #
COMBINE := $(SCRIPTS)/combine_accuracy.py
VERIFY  := $(SCRIPTS)/verify_combined.py

# Inputs to the combine step: the measured report plus the component CSVs it
# actually looks up. A change to any of them must re-generate the combined
# table. These are listed explicitly rather than globbed: the sweep only uses
# the bit-hacking/lookup/bipartite/splitting methods (not IP-core), and the
# IP-core file names contain a space, which a $(wildcard) prerequisite list
# would split into broken targets.
ACCURACY_TXT   := $(DATA)/accuracy_softmax/accuracy.txt
COMPONENT_CSVS := \
	$(DATA)/exp/Bit-hacking_combined.csv \
	$(DATA)/exp/Lookup_combined.csv \
	$(DATA)/exp/Bipartite_combined.csv \
	$(DATA)/exp/Splitting_combined.csv \
	$(DATA)/rec/Lookup_combined.csv \
	$(DATA)/rec/Bipartite_combined.csv

COMPARISON_CSV := $(DATA)/accuracy_softmax/theory_accuracy_comparison.csv

# --------------------------------------------------------------------------- #
# Analysis B: Pareto pipeline
# --------------------------------------------------------------------------- #
# Generated CSVs land in their own data/generated/ subfolder (exp.csv, rec.csv,
# softmax_SIMD_<v>.csv), kept separate from the raw inputs under data/.  clean
# removes that whole subfolder, never the input data/exp/, data/rec/ files.
OUTPUT    := $(DATA)/generated
IMAGES    := $(ROOT)images
IMAGES_AL := $(ROOT)images_aligned
MODES     := dsp_only method_dsp
FIGNAMES  := diagram.png pareto.png full_pareto.png

CONFIG  := $(SCRIPTS)/helper_config.py
STEP1   := $(SCRIPTS)/step1_components.py
STEP2   := $(SCRIPTS)/step2_softmax.py
STEP3   := $(SCRIPTS)/step3_plot.py
# filter.toml selects which component points feed the pipeline; step 1 reads it,
# so a change to it must re-run the whole pipeline.
FILTER  := $(ROOT)filter.toml

# SIMD sweep range - single source of truth is helper_config.SIMD_SWEEP; we read
# it here so the two can never drift apart.  Every value must exist in
# data/resources_SIMD.csv.
SIMD_VALUES := $(shell $(PYTHON) -c "import sys; sys.path.insert(0,'$(SCRIPTS)'); import helper_config as C; print(' '.join(map(str, C.SIMD_SWEEP)))")
ifeq ($(strip $(SIMD_VALUES)),)
$(error Could not read SIMD_SWEEP from $(SCRIPTS)/helper_config.py)
endif

# Combined per-method component CSVs feeding step 1.  Same space-in-filename
# caveat as above (IP core), so list the step-1 inputs explicitly.  These are
# the files whose RMSRE/LUT/DSP determine the fronts.
STEP1_INPUTS := \
	$(DATA)/exp/Bipartite_combined.csv \
	$(DATA)/exp/Lookup_combined.csv \
	$(DATA)/exp/Splitting_combined.csv \
	$(DATA)/exp/Bit-hacking_combined.csv \
	$(DATA)/exp/IP\ core_combined.csv \
	$(DATA)/rec/Bipartite_combined.csv \
	$(DATA)/rec/Lookup_combined.csv \
	$(DATA)/rec/IP\ core_combined.csv

EXP_CSV := $(OUTPUT)/exp.csv
REC_CSV := $(OUTPUT)/rec.csv

# Reciprocal folding characterisation.  step 2 reads it to correct the resources
# of no-Newton reciprocal components (delta = folding[SI=1] - folding[SI=N/SIMD]),
# so editing it must re-run the softmax combination (and hence the plots).
FOLDING := $(DATA)/resources_sweep_over_folding.csv

# All per-SIMD softmax fronts.  The aligned figures need a common axis range
# computed from every front, so step 3 reads ALL of these regardless of which
# SIMD value it renders - hence every plot target depends on all of them.
ALL_SOFTMAX := $(foreach v,$(SIMD_VALUES),$(OUTPUT)/softmax_SIMD_$(v).csv)

# Per-SIMD plot outputs, accumulated by the eval loop below.
PLOTS :=

.PHONY: all csv verify components softmax plots clean

# --------------------------------------------------------------------------- #
# Default: run both analyses end to end.
# --------------------------------------------------------------------------- #
all: csv plots

# --------------------------------------------------------------------------- #
# Analysis A rules
# --------------------------------------------------------------------------- #
csv: $(COMPARISON_CSV)

# combine_accuracy.py resolves its own inputs (data/) and output, so it can be
# invoked from anywhere.
$(COMPARISON_CSV): $(COMBINE) $(ACCURACY_TXT) $(COMPONENT_CSVS)
	$(PYTHON) $(COMBINE)

# Independent check of the generated CSV. Phony so it always re-runs the
# verifier; it first ensures the CSV is up to date.
verify: $(COMPARISON_CSV)
	$(PYTHON) $(VERIFY)

# --------------------------------------------------------------------------- #
# Analysis B rules
# --------------------------------------------------------------------------- #
# Step 1: extract pareto-optimal exp and rec components (SIMD-independent).
# A single run writes both CSVs; the grouped-target form ties them to one recipe.
components: $(EXP_CSV) $(REC_CSV)
$(EXP_CSV) $(REC_CSV): $(STEP1) $(CONFIG) $(FILTER) $(STEP1_INPUTS)
	$(PYTHON) $(STEP1)

# Per-SIMD rules for steps 2 and 3, generated for each value in $(SIMD_VALUES).
define SIMD_rules
SOFTMAX_$(1) := $(OUTPUT)/softmax_SIMD_$(1).csv
# Both figure trees (images/ and images_aligned/) for this SIMD value.
PLOTS_$(1) := \
  $$(foreach m,$(MODES),$$(foreach n,$(FIGNAMES),$(IMAGES)/SIMD_$(1)/$$(m)/$$(n))) \
  $$(foreach m,$(MODES),$$(foreach n,$(FIGNAMES),$(IMAGES_AL)/SIMD_$(1)/$$(m)/$$(n)))
PLOTS += $$(PLOTS_$(1))

# Step 2: combine into the pareto-optimal softmax front for this SIMD value.
# Depends on the folding CSV (no-Newton reciprocal correction) and on step 1's
# module, which step 2 imports for the pre-filter safety check.
$$(SOFTMAX_$(1)): $(STEP2) $(STEP1) $(CONFIG) $(EXP_CSV) $(REC_CSV) $(DATA)/resources_SIMD.csv $(FOLDING)
	$(PYTHON) $(STEP2) $(1)

# Step 3: one script run emits all twelve PNGs for this SIMD value (six per
# tree). Depends on ALL softmax fronts because the aligned tree needs the global
# axis range.
$$(PLOTS_$(1)): $(STEP3) $(CONFIG) $(ALL_SOFTMAX)
	$(PYTHON) $(STEP3) $(1)
endef
$(foreach v,$(SIMD_VALUES),$(eval $(call SIMD_rules,$(v))))

softmax: $(ALL_SOFTMAX)
plots:   $(PLOTS)

# --------------------------------------------------------------------------- #
# Clean: remove every generated artifact from both analyses; keep all inputs.
# The generated component/softmax CSVs live in their own data/generated/
# subfolder, so removing it leaves the data/exp/, data/rec/ inputs and
# data/resources_SIMD.csv untouched.
# --------------------------------------------------------------------------- #
clean:
	rm -f $(COMPARISON_CSV)
	rm -rf $(OUTPUT) $(IMAGES) $(IMAGES_AL) $(SCRIPTS)/__pycache__
