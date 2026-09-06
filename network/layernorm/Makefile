#############################################################################
# Makefile — HLS C-synthesis (HLS -> RTL) of the layernorm_top component.
#
#   make          run Vitis HLS synthesis (default target)
#   make clean    remove generated project + logs
#############################################################################

VITIS_HLS ?= vitis_hls
TCL       ?= run_hls.tcl
PROJECT   ?= layernorm_prj

.PHONY: all clean

all:
	$(VITIS_HLS) -f $(TCL)

clean:
	rm -rf $(PROJECT) vitis_hls.log *.log
