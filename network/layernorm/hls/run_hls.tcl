#############################################################################
# Vitis HLS 2023.1 — C-synthesis (HLS -> RTL) of the layernorm_top component.
# Component only: NO testbench, NO C-simulation.
# Target: Versal (VCK190 default part).
#
# Run with:   vitis_hls -f run_hls.tcl
#############################################################################

# --- project / solution -----------------------------------------------------
open_project  -reset layernorm_prj
set_top       layernorm_top

# Design source only. layernorm_top.cpp -> layernorm.hpp -> util.hpp (same dir,
# resolved automatically via the "..." include search path). No -tb files.
add_files     layernorm_top.cpp

open_solution -reset -flow_target vitis "sol_versal"

# --- target device + clock ---------------------------------------------------
set_part      xcvc1902-vsva2197-2MP-e-S      ;# VCK190 Versal; change to your part
create_clock  -period 3.3 -name default      ;# 3.3 ns == ~300 MHz

# --- HLS -> RTL --------------------------------------------------------------
csynth_design                                ;# generates Verilog + VHDL

exit
