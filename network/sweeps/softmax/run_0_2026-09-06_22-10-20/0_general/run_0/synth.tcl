set script_dir [file dirname [info script]]
set util_report_path [file join $script_dir "util_report.rpt"]
set timing_report_path [file join $script_dir "timing_report.rpt"]

set top softmax_top

create_project -force $top $top.vivado -part xcvc1902-vsva2197-2MP-e-S

set_property top $top [current_fileset]
foreach f [glob -nocomplain ../src/*.v]  { read_verilog $f }
foreach f [glob -nocomplain ../src/*.sv] { read_verilog -sv $f }
foreach f [glob -nocomplain ../src/*_ip.tcl] { source $f }

set_property generic {
	
} [current_fileset]

set synth [current_run -synthesis]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects $synth
launch_runs $synth -jobs 32
wait_on_runs $synth
open_run $synth

create_clock -period 4.0 -name ap_clk [get_ports ap_clk]

set impl [get_runs impl_1]
launch_runs $impl -jobs 32
wait_on_runs $impl
open_run $impl

report_utilization -file $util_report_path -quiet
report_timing_summary -file $timing_report_path -quiet

quit
