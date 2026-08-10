# Usage: vivado -mode batch -source scripts/elaborate_diffusion_accel_top.tcl
#
# Structural check for the real DiffusionAccelTop.  Unlike the companion
# OOC synthesis script, -rtl avoids technology mapping and implementation. It
# still performs Vivado RTL optimization after parsing and elaboration, so this
# is a bounded feasibility check rather than an instantaneous syntax command.
set script_dir [file dirname [file normalize [info script]]]
set board_root [file normalize [file join $script_dir ..]]
set accelerator_root [file normalize [file join $board_root .. .. ..]]
set generated_top [file join $accelerator_root target generated diffusion-accel-top DiffusionAccelTop.v]
set output_dir [file normalize [file join $board_root build diffusion_accel_rtl_elaboration]]

if {![file exists $generated_top]} {
  error "Missing $generated_top. Run: sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelTopVerilog'"
}

file mkdir $output_dir
read_verilog $generated_top
synth_design -top DiffusionAccelTop -part xcku15p-ffve1517-2-i -rtl
report_drc -file [file join $output_dir elaborated_drc.rpt]
write_checkpoint -force [file join $output_dir diffusion_accel_top_elaborated.dcp]
puts "DIFFUSION_ACCEL_TOP_RTL_ELABORATION_OK"
puts "This validates RTL hierarchy and RTL optimization; use synth_diffusion_accel_top.tcl for full resource mapping."
exit
