# =============================================================================
# sdc_chip_test_clocks_late.xdc
# 须在网表/elaborate 之后解析 MMCM 引脚；与主 XDC 一并加入 constrs_1（自动加载）
# =============================================================================
set_property PROCESSING_ORDER LATE [current_file]

# MMCM 实例：顶层 clk_wiz_0 ip_mmcm → 子模块 inst (clk_wiz_0_clk_wiz)
set mmcm_clkout1 [get_pins -quiet {ip_mmcm/inst/clkout1_buf/O}]
set mmcm_clkout2 [get_pins -quiet {ip_mmcm/inst/clkout2_buf/O}]
set mmcm_clkin   [get_pins -quiet {ip_mmcm/inst/mmcme4_adv_inst/CLKIN1}]

if {$mmcm_clkout1 ne "" && $mmcm_clkin ne "" && [llength [get_clocks -quiet sys_clk]]} {
  create_generated_clock -name clk_16M \
    -source $mmcm_clkin \
    -master_clock [get_clocks sys_clk] \
    -multiply_by 2 -divide_by 25 \
    $mmcm_clkout1
}

if {$mmcm_clkout2 ne "" && $mmcm_clkin ne "" && [llength [get_clocks -quiet sys_clk]]} {
  create_generated_clock -name clk_50M \
    -source $mmcm_clkin \
    -master_clock [get_clocks sys_clk] \
    -multiply_by 1 -divide_by 4 \
    $mmcm_clkout2
}

# ILA 用 clk_50M；与 FSM 域 clk_16M 异步
if {[llength [get_clocks -quiet clk_16M]] && [llength [get_clocks -quiet clk_50M]]} {
  set_clock_groups -asynchronous \
    -group [get_clocks clk_16M] \
    -group [get_clocks clk_50M]
}
