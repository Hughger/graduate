# Usage:
# vivado -mode batch -source upgrade_ddr4_core_2024_2.tcl -tclargs \
#   -source-xci <official/ddr4_core.xci> -output-dir <owned/ip/directory>
#
# This command copies the supplied XCI before upgrading it.  It never writes
# into the official demo directory and never runs implementation.

proc require_option {options_name name} {
  upvar 1 $options_name options
  if {![info exists options($name)] || $options($name) eq ""} {
    error "Missing required option -$name"
  }
  return $options($name)
}

array set options {}
set index 0
while {$index < [llength $argv]} {
  set option [lindex $argv $index]
  if {$option ni {-source-xci -output-dir}} {
    error "Unknown option $option"
  }
  incr index
  if {$index >= [llength $argv]} {
    error "Option $option requires a path"
  }
  set options([string range $option 1 end]) [file normalize [lindex $argv $index]]
  incr index
}

set source_xci [require_option options source-xci]
set output_dir [require_option options output-dir]
if {![file isfile $source_xci]} {
  error "Missing input file $source_xci"
}

file mkdir $output_dir
set copied_xci [file join $output_dir ddr4_core.xci]
file copy -force $source_xci $copied_xci

set handle [open $copied_xci r]
set xci_contents [read $handle]
close $handle
set inherited_output_dir "../../../../ddr_test.gen/sources_1/ip/ddr4_core"
if {[regexp -all -- $inherited_output_dir $xci_contents] != 2} {
  error "Expected exactly two inherited DDR4 output directory fields"
}
set handle [open $copied_xci w]
puts -nonewline $handle [string map [list $inherited_output_dir "."] $xci_contents]
close $handle

create_project -in_memory ddr4_core_2024_2 -part xcku15p-ffve1517-2-i
read_ip $copied_xci
set loaded_ips [get_ips]
if {[llength $loaded_ips] != 1} {
  error "Expected exactly one DDR4 IP, got [llength $loaded_ips]"
}
set ddr4_ip [lindex $loaded_ips 0]
upgrade_ip $ddr4_ip
if {[get_property IS_LOCKED $ddr4_ip]} {
  error "Upgraded IP remains locked: $copied_xci"
}
generate_target all $ddr4_ip
synth_ip $ddr4_ip
write_ip_tcl -force $ddr4_ip [file join $output_dir recreate_ddr4_core_2024_2.tcl]
puts "UPGRADED_XCI=$copied_xci"
puts "UPGRADED_IP=$ddr4_ip"
exit
