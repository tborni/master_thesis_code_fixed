# =============================================================================
# Portable out-of-context build for the BERT-L1 FINN stitched design.
#
#   Target part : xcvc1902-vsva2197-2MP-e-S  (VCK190 / Versal)
#   Vivado      : 2025.2
#   Top module  : finn_design_wrapper
#
# Run from THIS directory (relative $readmemh weight paths resolve against the
# current working directory):
#
#   cd titus_portable_bert_l1
#   vivado -mode batch -source build_synth.tcl
#
# Quick elaboration/synthesis-only check (skips the long place & route), either:
#   vivado -mode batch -source build_synth.tcl -tclargs synth_only
#   SYNTH_ONLY=1 vivado -mode batch -source build_synth.tcl
#
# Outputs (written to ./results):
#   post_synth.dcp                synthesized checkpoint
#   finn_design_wrapper_routed.dcp  placed+routed checkpoint
#   post_synth_util.rpt / timing   synthesis reports
#   post_route_util.rpt / timing   implementation reports
#
# NOTE (HLS LayerNorm/Softmax): the LayerNorm_rtl_{0,1} and HWSoftmax_rtl_0
# operators are now Vitis-HLS cores (layernorm_top / softmax_top). Those cores
# instantiate Xilinx "floating_point" IP that must be created with create_ip
# before synthesis. This requires a project context, so the flow below runs
# inside an in-memory project. Each ip/*_ip.tcl sets
# generate_synth_checkpoint=false, so the IP is elaborated/synthesized inline
# (global synthesis) together with finn_design_wrapper -- no per-IP OOC DCP.
# =============================================================================

set PART      "xcvc1902-vsva2197-2MP-e-S"
set TOP       "finn_design_wrapper"
set SRCLIST   "rtl_sources.f"
set IPDIR     "ip"
set XDC       "constraints/finn_design_ooc.xdc"
set OUTDIR    "results"
set JOBS      8

# ---- optional synthesis-only mode (via -tclargs synth_only or SYNTH_ONLY=1) --
set SYNTH_ONLY 0
if {[info exists ::argv] && ([lsearch -exact $::argv "synth_only"] >= 0)} { set SYNTH_ONLY 1 }
if {[info exists ::env(SYNTH_ONLY)] && ($::env(SYNTH_ONLY) ne "0") && ($::env(SYNTH_ONLY) ne "")} { set SYNTH_ONLY 1 }

file mkdir $OUTDIR

# ---- in-memory project (needed for create_ip / managed IP) ------------------
# All RTL, IP and constraints are added to this transient project; nothing is
# written to disk except the IP generation products (under ./$OUTDIR/ip) and
# the requested checkpoints/reports.
create_project -in_memory -part $PART
set_property target_language Verilog [current_project]
# Keep generated IP products out of the source tree.
file mkdir $OUTDIR/ip
set_property ip_output_repo $OUTDIR/ip [current_project]

# ---- create the floating-point IP cores used by the HLS operators -----------
# Each script does: create_ip -> set CONFIG -> generate_synth_checkpoint false
# -> generate_target {synthesis simulation}. Order among them is irrelevant
# (the cores are independent), so a sorted glob is fine.
set iptcls [lsort [glob -nocomplain -directory $IPDIR *_ip.tcl]]
if {[llength $iptcls] == 0} {
    error "no IP scripts found in $IPDIR/ (expected the *_ip.tcl for the HLS FP cores)"
}
puts "INFO: creating [llength $iptcls] floating-point IP core(s) from $IPDIR/"
foreach ipt $iptcls {
    puts "INFO:   sourcing IP script [file tail $ipt]"
    source $ipt
}

# Fail loudly here (rather than with a cryptic missing-module error at
# synth_design) if IP creation did not produce the expected cores.
set made_ips [get_ips -quiet]
puts "INFO: created IP cores: $made_ips"
if {[llength $made_ips] != [llength $iptcls]} {
    error "expected [llength $iptcls] IP core(s) but only [llength $made_ips] were created: $made_ips"
}

# ---- read all RTL sources (Verilog + SystemVerilog, mixed) ------------------
if {![file exists $SRCLIST]} { error "source list not found: $SRCLIST (run from this directory)" }
set fh [open $SRCLIST r]
set files [split [string trim [read $fh]] "\n"]
close $fh

set vfiles  [list]
set svfiles [list]
foreach f $files {
    set f [string trim $f]
    if {$f eq ""}               { continue }
    if {[string match "#*" $f]} { continue }
    if {![file exists $f]} { error "source not found: $f" }
    if {[string match "*.sv" $f]} { lappend svfiles $f } else { lappend vfiles $f }
}
puts "INFO: reading [llength $vfiles] Verilog + [llength $svfiles] SystemVerilog files"

if {[llength $vfiles]  > 0} { read_verilog          $vfiles  }
if {[llength $svfiles] > 0} { read_verilog -sv      $svfiles }

read_xdc $XDC

# ---- out-of-context synthesis ----------------------------------------------
# Global synthesis: with generate_synth_checkpoint=false the floating_point IP
# is synthesized together with the top, so its *_ip modules resolve here.
synth_design -top $TOP -part $PART -mode out_of_context
write_checkpoint -force $OUTDIR/post_synth.dcp
report_utilization -hierarchical -file $OUTDIR/post_synth_util.rpt
report_timing_summary          -file $OUTDIR/post_synth_timing.rpt

if {$SYNTH_ONLY} {
    puts "INFO: SYNTH_ONLY set -- stopping after synthesis. Checkpoint + reports in $OUTDIR/"
    return
}

# ---- place & route ----------------------------------------------------------
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force $OUTDIR/${TOP}_routed.dcp
report_utilization -hierarchical -file $OUTDIR/post_route_util.rpt
report_timing_summary          -file $OUTDIR/post_route_timing.rpt

puts "INFO: build complete -- checkpoints and reports in $OUTDIR/"
