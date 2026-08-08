# 综合/实现前执行一次（Tcl Console 或工程 synth_design.pre 钩子）：
#   source .../constrs_1/new/disable_clk_wiz_xdc.tcl
#
# 避免 clk_wiz_0.xdc 在 clk_in1 上与顶层 sys_clk 重复定义主时钟 (TIMING-2/4)

if {![llength [get_ips -quiet clk_wiz_0]]} {
  puts "WARN: clk_wiz_0 IP not found, skip disable_clk_wiz_xdc.tcl"
  return
}

set xdc_list [get_files -quiet -of_objects [get_ips clk_wiz_0] -filter {FILE_TYPE == XDC || NAME =~ *.xdc}]
foreach xdc $xdc_list {
  set_property USED_IN_SYNTHESIS false $xdc
  set_property USED_IN_IMPLEMENTATION false $xdc
  puts "INFO: Disabled for synth/impl: $xdc"
}
