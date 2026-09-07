#############################################################################
# Makefile — HLS C-synthesis (HLS -> RTL) of the softmax_top component.
#
# Design parameters (edit in softmax_top.hpp):
#   N = 128, SIMD = 4, TI = TO = float (FP32)
#
#   make            run Vitis HLS synthesis (default target)
#   make package    tar the generated RTL + .tcl + reports for easy retrieval
#   make clean      remove generated project + logs
#   make distclean  clean + remove the packaged tarball
#
# Typical remote flow:
#   make && make package        # synthesize, then bundle artifacts
#   # then, from your local machine:
#   scp <remote>:.../softmax_artifacts.tar.gz .
#############################################################################

VITIS_HLS ?= vitis_hls
TCL       ?= run_hls.tcl
PROJECT   ?= softmax_prj
SOLUTION  ?= sol_versal
TARBALL   ?= softmax_artifacts.tar.gz

# Where csynth_design drops the generated RTL, .tcl scripts and reports.
SYN_DIR   := $(PROJECT)/$(SOLUTION)/syn

.PHONY: all package clean distclean

all:
	$(VITIS_HLS) -f $(TCL)

# Bundle the synthesis outputs (Verilog + VHDL RTL, generated .tcl scripts and
# reports) into a single tarball that is trivial to copy off the remote host.
# Packaged defensively: only the syn/ sub-dirs that actually exist are added,
# so the target still succeeds if the flow emits e.g. Verilog but no VHDL.
package:
	@test -d "$(SYN_DIR)" || { \
		echo "ERROR: '$(SYN_DIR)' not found — run 'make' first."; exit 1; }
	@paths=""; \
	for d in verilog vhdl report; do \
		[ -d "$(SYN_DIR)/$$d" ] && paths="$$paths $(SYN_DIR)/$$d"; \
	done; \
	for t in $(PROJECT)/$(SOLUTION)/*.tcl; do \
		[ -f "$$t" ] && paths="$$paths $$t"; \
	done; \
	tar -czf $(TARBALL) $$paths; \
	echo "Packaged RTL + tcl + reports -> $(TARBALL)"

clean:
	rm -rf $(PROJECT) vitis_hls.log *.log

distclean: clean
	rm -f $(TARBALL)
