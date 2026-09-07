# =============================================================================
# Portable out-of-context build for the BERT-L1 FINN stitched design.
#
#   Target part : xcvc1902-vsva2197-2MP-e-S  (VCK190 / Versal)
#   Vivado      : 2025.2
#   Top module  : finn_design_wrapper
#
# This design has had its SoftMax and both LayerNorm compute cores replaced
# with custom fp32 streaming implementations:
#   * SoftMax   : module `softmax`         (N=128, SIMD=4)  in rtl/softmax.sv
#   * LayerNorm : module `layernorm` (x2)  (N=384, SIMD=4)  in rtl/layernorm.sv
# The FINN wrappers rtl/HWSoftmax_rtl_0.v and rtl/LayerNorm_rtl_{0,1}.v
# instantiate these cores; their supporting modules (exp_bipartite,
# rec_bipartite, range_reduction, rsqrt_bipartite, accuf, binopf, queue) are
# read from rtl_sources.f.  The DSP paths map onto the Versal DSPFP32 primitive
# (provided by the unisim library at synthesis; no behavioral override).
#
# Run from THIS directory (relative $readmemh weight paths resolve against the
# current working directory):
#
#   cd my_rtl
#   vivado -mode batch -source build_synth.tcl
#
# Quick elaboration/synthesis-only check (skips the long place & route), either:
#   vivado -mode batch -source build_synth.tcl -tclargs synth_only
#   SYNTH_ONLY=1 vivado -mode batch -source build_synth.tcl
#
# Outputs (written to ./results):
#   post_synth.dcp                    synthesized checkpoint
#   finn_design_wrapper_routed.dcp    placed+routed checkpoint
#   post_synth_util.rpt / timing      synthesis reports
#   post_route_util.rpt / timing      implementation reports
# =============================================================================

set PART      "xcvc1902-vsva2197-2MP-e-S"
set TOP       "finn_design_wrapper"
set SRCLIST   "rtl_sources.f"
set XDC       "constraints/finn_design_ooc.xdc"
set OUTDIR    "results"
set JOBS      8

# ---- optional synthesis-only mode (via -tclargs synth_only or SYNTH_ONLY=1) --
set SYNTH_ONLY 0
if {[info exists ::argv] && ([lsearch -exact $::argv "synth_only"] >= 0)} { set SYNTH_ONLY 1 }
if {[info exists ::env(SYNTH_ONLY)] && ($::env(SYNTH_ONLY) ne "0") && ($::env(SYNTH_ONLY) ne "")} { set SYNTH_ONLY 1 }

file mkdir $OUTDIR

# ---- read all RTL sources (Verilog + SystemVerilog, mixed) ------------------
if {![file exists $SRCLIST]} { error "source list not found: $SRCLIST (run from the my_rtl directory)" }
set fh [open $SRCLIST r]
set files [split [string trim [read $fh]] "\n"]
close $fh

set vfiles  [list]
set svfiles [list]
foreach f $files {
    set f [string trim $f]
    if {$f eq ""}                { continue }
    if {[string match "#*" $f]}  { continue }
    if {![file exists $f]} { error "source not found: $f" }
    if {[string match "*.sv" $f]} { lappend svfiles $f } else { lappend vfiles $f }
}
puts "INFO: reading [llength $vfiles] Verilog + [llength $svfiles] SystemVerilog files"

if {[llength $vfiles]  > 0} { read_verilog          $vfiles  }
if {[llength $svfiles] > 0} { read_verilog -sv      $svfiles }

read_xdc $XDC

# ---- out-of-context synthesis ----------------------------------------------
puts "INFO: synthesizing top '$TOP' for part '$PART' (out_of_context)"
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
