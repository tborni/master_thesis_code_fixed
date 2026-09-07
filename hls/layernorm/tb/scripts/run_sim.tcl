################################################################################
# Behavioral simulation of the HLS-generated LayerNorm core (N=64, SIMD=2)
# against the full-precision reference embedded in the testbench.
#
# Tool: Vivado / Vitis 2023.1, batch mode:
#     vivado -mode batch -source run_sim.tcl
#
# What it does
#   1. Creates a throw-away project for the target part.
#   2. Sources the six floating_point IP .tcl files -> creates the fp IP cores
#      the HLS netlist instantiates (fadd/fsub/fmul/fmadd/fdiv/fsqrt). This is
#      the "handle the IP cores accordingly" step: the IP must exist in the
#      project so its simulation model is generated and compiled.
#   3. Reads the HLS Verilog netlist (*.v), the SV wrapper and the SV testbench.
#   4. Runs behavioral simulation to completion ($finish in the TB) via xsim.
#      Project-mode launch_simulation compiles the IP simulation models and the
#      required Xilinx sim libraries automatically -- no manual -L flags.
#
# Layout: this script lives in scripts/; all HDL and IP sources live in ../src/.
# The Vivado project and simulation artifacts are created here in scripts/.
################################################################################

set script_dir [file dirname [file normalize [info script]]]
set src_dir     [file normalize [file join $script_dir .. src]]

# ---- Configuration ----------------------------------------------------------
set top      layernorm_wrap_accuracy_tb
set part     xcvc1902-vsva2197-2MP-e-S
set proj     sim_layernorm_wrap
set proj_dir [file join $script_dir $proj.vivado]

# ---- Fresh project ----------------------------------------------------------
create_project -force $top $proj_dir -part $part

# ---- Floating-point IP cores (must precede reading the netlist that uses them)
# Each .tcl runs create_ip + set_property for one floating_point instance.
foreach f [glob -nocomplain [file join $src_dir *_ip.tcl]] {
    puts "\[run_sim\] sourcing IP: [file tail $f]"
    source $f
}

# ---- Design sources (go to the design fileset; sim_1 inherits them) ---------
# HLS Verilog netlist (top + all sub-modules + fp primitive wrappers + FIFOs)
# plus the SV wrapper (module `layernorm`, adapts the HLS core to the reference
# interface). These are design-side so they are visible to both synth and sim.
add_files -norecurse [glob [file join $src_dir *.v]]
add_files -norecurse [file join $src_dir layernorm_wrap.sv]

# ---- Simulation-only source: the testbench ----------------------------------
add_files -fileset sim_1 -norecurse [file join $src_dir layernorm_wrap_accuracy_tb.sv]

# Treat .sv files as SystemVerilog.
set_property file_type SystemVerilog [get_files [file join $src_dir layernorm_wrap.sv]]
set_property file_type SystemVerilog [get_files [file join $src_dir layernorm_wrap_accuracy_tb.sv]]

# ---- Set the testbench as the simulation top --------------------------------
set_property top $top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run xsim until the TB's $finish (not the default 1000ns window). "-all" makes
# the generated xsim .tcl issue `run all` so the whole stimulus/drain completes.
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]

# ---- Generate IP outputs + user files, then simulate -------------------------
# Ensure every IP has its simulation target generated before the sim is built.
generate_target simulation [get_ips]
export_ip_user_files -no_script -force -quiet

# Run behavioral simulation with xsim; -runall drives it to the TB's $finish.
# The TB prints:
#   Test (N = 64, SIMD = 2): RMSRE = ..., MAX_REL_ERROR = ..., WORST_INPUT = ...
launch_simulation -mode behavioral

# launch_simulation returns after the run completes (TB calls $finish). If your
# flow needs an explicit run, uncomment the next line (harmless if already done):
# run all

puts "\[run_sim\] simulation finished"
quit
