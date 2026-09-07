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
# Outputs (written to ./results):
#   post_synth.dcp                synthesized checkpoint
#   finn_design_wrapper_routed.dcp  placed+routed checkpoint
#   post_synth_util.rpt / timing   synthesis reports
#   post_route_util.rpt / timing   implementation reports
# =============================================================================

set PART      "xcvc1902-vsva2197-2MP-e-S"
set TOP       "finn_design_wrapper"
set SRCLIST   "rtl_sources.f"
set XDC       "constraints/finn_design_ooc.xdc"
set OUTDIR    "results"
set JOBS      8

file mkdir $OUTDIR

# ---- read all RTL sources (Verilog + SystemVerilog, mixed) ------------------
set fh [open $SRCLIST r]
set files [split [string trim [read $fh]] "\n"]
close $fh

set vfiles  [list]
set svfiles [list]
foreach f $files {
    set f [string trim $f]
    if {$f eq ""} { continue }
    if {![file exists $f]} { error "source not found: $f" }
    if {[string match "*.sv" $f]} { lappend svfiles $f } else { lappend vfiles $f }
}
puts "INFO: reading [llength $vfiles] Verilog + [llength $svfiles] SystemVerilog files"

if {[llength $vfiles]  > 0} { read_verilog          $vfiles  }
if {[llength $svfiles] > 0} { read_verilog -sv      $svfiles }

read_xdc $XDC

# ---- out-of-context synthesis ----------------------------------------------
synth_design -top $TOP -part $PART -mode out_of_context
write_checkpoint -force $OUTDIR/post_synth.dcp
report_utilization -hierarchical -file $OUTDIR/post_synth_util.rpt
report_timing_summary          -file $OUTDIR/post_synth_timing.rpt

# ---- place & route ----------------------------------------------------------
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force $OUTDIR/${TOP}_routed.dcp
report_utilization -hierarchical -file $OUTDIR/post_route_util.rpt
report_timing_summary          -file $OUTDIR/post_route_timing.rpt

puts "INFO: build complete -- checkpoints and reports in $OUTDIR/"
