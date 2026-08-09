# Usage: vivado -mode batch -source scripts/build_bringup.tcl
# A non-project flow avoids version-specific project database state and is the
# canonical reproducible check used by CI and lab bring-up.
set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ..]]
set output_dir [file normalize [file join $root build bringup_nonproject]]
file mkdir $output_dir

read_verilog [file join $root rtl axku15_diffusion_bringup.v]
read_xdc [file join $root constrs axku15_bringup.xdc]
synth_design -top axku15_diffusion_bringup -part xcku15p-ffve1517-2-i
opt_design
place_design
phys_opt_design
route_design
report_drc -file [file join $output_dir drc.rpt]
report_timing_summary -file [file join $output_dir timing_summary.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
write_checkpoint -force [file join $output_dir axku15_diffusion_bringup.dcp]
write_bitstream -force [file join $output_dir axku15_diffusion_bringup.bit]
exit
