# Check the only currently Vivado-supported candidate; it does not generate a
# board bitstream and must not be mistaken for an 80-bit AXKU15 DDR4 solution.
set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ..]]
set project_dir [file normalize [file join $root build mig_candidate_check]]

create_project axku15_mig_candidate_check $project_dir -part xcku15p-ffve1517-2-i -force
create_ip -name ddr4 -vendor xilinx.com -library ip -module_name axku15_ddr4_candidate
set ip [get_ips axku15_ddr4_candidate]
set_property -dict [list \
  CONFIG.C0.DDR4_MemoryPart {MT40A512M16LY-075} \
  CONFIG.C0.DDR4_DataWidth {64} \
  CONFIG.C0.DDR4_AxiDataWidth {512} \
  CONFIG.C0.DDR4_AxiAddressWidth {32} \
  CONFIG.C0.DDR4_InputClockPeriod {5000} \
  CONFIG.C0.DDR4_TimePeriod {750} \
  CONFIG.C0.DDR4_PhyClockRatio {4:1} \
  CONFIG.C0.DDR4_DataMask {DM_NO_DBI} \
  CONFIG.Reference_Clock {Differential} \
  CONFIG.System_Clock {Differential}] $ip

foreach {property expected} {
  CONFIG.C0.DDR4_MemoryPart MT40A512M16LY-075
  CONFIG.C0.DDR4_DataWidth 64
  CONFIG.C0.DDR4_AxiDataWidth 512
  CONFIG.C0.DDR4_AxiAddressWidth 32
} {
  set observed [get_property $property $ip]
  if {$observed ne $expected} {
    error "MIG candidate mismatch: $property expected $expected, got $observed"
  }
}
puts "AXKU15_MIG_CANDIDATE_VERIFIED"
puts "This is a 64-bit development candidate, not an approved 80-bit board configuration."
exit
