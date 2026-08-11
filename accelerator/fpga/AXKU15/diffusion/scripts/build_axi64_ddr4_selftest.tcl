# Usage:
# vivado -mode batch -source scripts/build_axi64_ddr4_selftest.tcl -tclargs \
#   -ddr4-xci <path/to/ddr4_core.xci> -ddr4-xdc <path/to/ddr4_test.xdc> \
#   -selftest-rtl <path/to/Axi64DdrSelfTest.v> [-run-impl]
#
# The external XCI/XDC are read-only inputs.  Generated reports and optional
# implementation products are written only beneath this repository's build/.
proc require_option {options_name name} {
  upvar 1 $options_name options
  if {![info exists options($name)] || $options($name) eq ""} {
    error "Missing required option $name"
  }
  return $options($name)
}

array set options {run_impl 0}
set index 0
while {$index < [llength $argv]} {
  set arg [lindex $argv $index]
  switch -- $arg {
    -ddr4-xci - -ddr4-xdc - -selftest-rtl {
      incr index
      if {$index >= [llength $argv]} { error "Option $arg requires a path" }
      set options([string range $arg 1 end]) [file normalize [lindex $argv $index]]
    }
    -run-impl { set options(run_impl) 1 }
    default { error "Unknown option $arg" }
  }
  incr index
}

set ddr4_xci [require_option options ddr4-xci]
set ddr4_xdc [require_option options ddr4-xdc]
set selftest_rtl [require_option options selftest-rtl]
foreach required_file [list $ddr4_xci $ddr4_xdc $selftest_rtl] {
  if {![file exists $required_file]} { error "Missing input file $required_file" }
}

set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ..]]
set output_dir [file normalize [file join $root build axi64_ddr4_selftest]]
file mkdir $output_dir

set_part xcku15p-ffve1517-2-i
set ddr4_dir [file dirname $ddr4_xci]
set ddr4_dcp [file join $ddr4_dir ddr4_core.dcp]
set ddr4_ip_xdc [file join $ddr4_dir par ddr4_core.xdc]
set ddr4_manifest [file join $ddr4_dir manifest.json]
foreach owned_artifact [list $ddr4_dcp $ddr4_ip_xdc $ddr4_manifest] {
  if {![file isfile $owned_artifact]} {
    error "Missing project-owned DDR4 artifact $owned_artifact"
  }
}
# Vivado 2024.2 can stall when read_ip automatically associates the upgraded
# DDR4 OOC checkpoint.  Attach the generated checkpoint explicitly, then read
# its generated constraint file after the board-level XDC.
read_verilog $selftest_rtl
read_verilog [file join $root rtl axku15_axi64_ddr4_selftest.v]
read_xdc $ddr4_xdc
read_checkpoint -cell u_ddr4_core/inst $ddr4_dcp
read_xdc $ddr4_ip_xdc

if {$options(run_impl)} {
  synth_design -top axku15_axi64_ddr4_selftest -part xcku15p-ffve1517-2-i
  opt_design
  place_design
  route_design
  report_drc -file [file join $output_dir drc.rpt]
  report_timing_summary -file [file join $output_dir timing_summary.rpt]
  report_utilization -file [file join $output_dir utilization.rpt]
  write_checkpoint -force [file join $output_dir axku15_axi64_ddr4_selftest.dcp]
  write_bitstream -force [file join $output_dir axku15_axi64_ddr4_selftest.bit]
} else {
  synth_design -rtl -top axku15_axi64_ddr4_selftest -part xcku15p-ffve1517-2-i
  puts "RTL elaboration completed; implementation reports require -run-impl."
}
exit
