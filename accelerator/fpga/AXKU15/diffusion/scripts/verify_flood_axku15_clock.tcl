# Regenerate the only stale IP in the checked-in FLOOD chip-test example and
# synthesize its top for the AXKU15P target. This is a source-compatibility
# check, not an implementation or bitstream build.
set script_dir [file dirname [file normalize [info script]]]
set board_root [file normalize [file join $script_dir ..]]
set repo_root [file normalize [file join $board_root .. .. .. ..]]
set example_root [file join $repo_root integrations chip-test-vivado]
set source [file join $example_root system_chip_test.srcs sources_1 new chip_test_cursor_1.v]
set constraints [file join $board_root constrs flood_example_clock_smoke.xdc]
set project_dir [file join $board_root build flood_clock_reuse_check]
set generated_ip_dir [file join $project_dir flood_clock_reuse_check.gen sources_1 ip clk_wiz_0]

foreach required [list $source $constraints] {
  if {![file exists $required]} {
    error "Required FLOOD example file is missing: $required"
  }
}

create_project flood_clock_reuse_check $project_dir -part xcku15p-ffve1517-2-i -force
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0
set ip [get_ips clk_wiz_0]
set_property -dict [list \
  CONFIG.PRIM_IN_FREQ {200.000} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {16.000} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} \
  CONFIG.RESET_TYPE {ACTIVE_HIGH}] $ip
generate_target synthesis $ip

set wrapper [file join $generated_ip_dir clk_wiz_0.v]
set core [file join $generated_ip_dir clk_wiz_0_clk_wiz.v]
foreach generated [list $wrapper $core] {
  if {![file exists $generated]} {
    error "Clock Wizard generation did not produce: $generated"
  }
}

# The historical project was non-portable because its checked-in .xci was
# locked to an Artix-7/2022.2 context. Read freshly generated wrappers
# explicitly so this check does not depend on a GUI project's file set.
read_verilog $core
read_verilog $wrapper
read_verilog $source
read_xdc $constraints
synth_design -top chip_test_cursor_1 -part xcku15p-ffve1517-2-i
report_utilization -file [file join $project_dir flood_clock_reuse_utilization.rpt]
report_timing_summary -file [file join $project_dir flood_clock_reuse_timing.rpt]
write_checkpoint -force [file join $project_dir flood_clock_reuse_synth.dcp]
puts "FLOOD_AXKU15_CLOCK_REUSE_SYNTHESIS_OK"
puts "This check is synthesis-only; do not use it as a board bitstream build."
exit
