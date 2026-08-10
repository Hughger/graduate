# Usage: vivado -mode batch -source scripts/synth_diffusion_accel_top.tcl
#
# This is an out-of-context synthesis check for the actual Chisel accelerator
# top.  It intentionally has no DDR4 pin constraints or MIG instance: the
# AXKU15 board's 80-bit DDR4 interface is not yet closed with Vivado MIG.
set script_dir [file dirname [file normalize [info script]]]
set board_root [file normalize [file join $script_dir ..]]
set accelerator_root [file normalize [file join $board_root .. .. ..]]
set generated_top [file join $accelerator_root target generated diffusion-accel-top DiffusionAccelTop.v]
set output_dir [file normalize [file join $board_root build diffusion_accel_ooc_synth]]

if {![file exists $generated_top]} {
  error "Missing $generated_top. Run: sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelTopVerilog'"
}

file mkdir $output_dir
read_verilog $generated_top
synth_design -top DiffusionAccelTop -part xcku15p-ffve1517-2-i -mode out_of_context
report_utilization -file [file join $output_dir utilization_synth.rpt]
report_timing_summary -file [file join $output_dir timing_summary_synth.rpt]
write_checkpoint -force [file join $output_dir diffusion_accel_top_synth.dcp]
puts "DIFFUSION_ACCEL_TOP_OOC_SYNTHESIS_OK"
puts "This is an OOC feasibility check, not a DDR4-capable board bitstream."
exit
