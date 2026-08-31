# Softmax Pareto analysis pipeline (with SIMD sweep).
#
#   make            -> run the whole pipeline for every SIMD value
#   make components -> processed_data/{exp,rec}.csv                      (step 1)
#   make softmax    -> processed_data/softmax_SIMD_<v>.csv             (step 2)
#   make plots      -> images{,_aligned}/SIMD_<v>/{dsp_only,method_dsp}/*.png (step 3)
#   make clean      -> remove generated processed_data/ + images{,_aligned}/
#
# SIMD sweep values below MUST match helper_config.SIMD_SWEEP.  Each value must
# exist in resources/SIMD_sweep.csv.  Steps 2 and 3 run once per value; step 1
# (component extraction) is SIMD-independent and runs once for all.

# PYTHONDONTWRITEBYTECODE keeps the tree free of __pycache__ directories.
PYTHON ?= PYTHONDONTWRITEBYTECODE=1 python3

SCRIPTS   := scripts
PROCESSED := processed_data
IMAGES    := images
IMAGES_AL := images_aligned
MODES     := dsp_only method_dsp
FIGNAMES  := diagram.png pareto.png full_pareto.png

# SIMD sweep range - single source of truth is helper_config.SIMD_SWEEP; we read
# it here so the two can never drift apart.
SIMD_VALUES := $(shell $(PYTHON) -c "import sys; sys.path.insert(0,'$(SCRIPTS)'); import helper_config as C; print(' '.join(map(str, C.SIMD_SWEEP)))")
ifeq ($(strip $(SIMD_VALUES)),)
$(error Could not read SIMD_SWEEP from $(SCRIPTS)/helper_config.py)
endif

EXP_CSV := $(PROCESSED)/exp.csv
REC_CSV := $(PROCESSED)/rec.csv

CONFIG  := $(SCRIPTS)/helper_config.py
ACC     := $(wildcard accuracy/*.csv)
RES     := $(wildcard resources/*.csv)

# All per-SIMD softmax fronts.  The aligned figures need a common axis range
# computed from every front, so step 3 reads ALL of these regardless of which
# SIMD value it renders - hence every plot target depends on all of them.
ALL_SOFTMAX := $(foreach v,$(SIMD_VALUES),$(PROCESSED)/softmax_SIMD_$(v).csv)

# Per-SIMD outputs, accumulated by the eval loop below.
PLOTS :=

.PHONY: all components softmax plots clean
all: plots

# Step 1: extract pareto-optimal exp and rec components (SIMD-independent).
components: $(EXP_CSV)
$(EXP_CSV) $(REC_CSV): $(SCRIPTS)/step1_components.py $(CONFIG) $(ACC) $(RES)
	$(PYTHON) $(SCRIPTS)/step1_components.py

# Per-SIMD rules for steps 2 and 3, generated for each value in $(SIMD_VALUES).
define SIMD_rules
SOFTMAX_$(1) := $(PROCESSED)/softmax_SIMD_$(1).csv
# Both figure trees (images/ and images_aligned/) for this SIMD value.
PLOTS_$(1) := \
  $$(foreach m,$(MODES),$$(foreach n,$(FIGNAMES),$(IMAGES)/SIMD_$(1)/$$(m)/$$(n))) \
  $$(foreach m,$(MODES),$$(foreach n,$(FIGNAMES),$(IMAGES_AL)/SIMD_$(1)/$$(m)/$$(n)))
PLOTS += $$(PLOTS_$(1))

# Step 2: combine into the pareto-optimal softmax front for this SIMD value.
$$(SOFTMAX_$(1)): $(SCRIPTS)/step2_softmax.py $(CONFIG) $(EXP_CSV) $(REC_CSV) resources/SIMD_sweep.csv
	$(PYTHON) $(SCRIPTS)/step2_softmax.py $(1)

# Step 3: one script run emits all twelve PNGs for this SIMD value (six per
# tree). Depends on ALL softmax fronts because the aligned tree needs the global
# axis range.
$$(PLOTS_$(1)): $(SCRIPTS)/step3_plot.py $(CONFIG) $(ALL_SOFTMAX)
	$(PYTHON) $(SCRIPTS)/step3_plot.py $(1)
endef
$(foreach v,$(SIMD_VALUES),$(eval $(call SIMD_rules,$(v))))

softmax: $(ALL_SOFTMAX)
plots:   $(PLOTS)

clean:
	rm -rf $(PROCESSED) $(IMAGES) $(IMAGES_AL) $(SCRIPTS)/__pycache__
