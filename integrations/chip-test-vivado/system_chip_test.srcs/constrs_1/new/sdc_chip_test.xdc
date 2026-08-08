# =============================================================================
# sdc_chip_test.xdc — 顶层 system_chip_test 约束（AXKU15）
#
# 引脚依据：
#   - 《AXKU15_V1.2_UG》扩展板连接器章节中 J4 与 FPGA 引脚对照表
#     （仓库内可参考 fpga/AXKU15/AXKU15_V1.2_UG_final.md 约 850~920 行一带）
#   - 与 fpga/system_chip_test.v 中 FMC1_LAxx 注释逐项核对一致
#
# 说明：
#   - Fan_Out_Netlabel_P1_*.csv：芯片侧网络名（CLK_IC0、ADDR*、DINOUT*、EN/WR_EN 等）；
#     本文件给出的是各 RTL 端口在 FMC1(J12) 上对应的 FPGA PACKAGE_PIN（经测试板互连）。
#   - FMC 区域使用 BANK69/BANK70（HP），手册中 VCCIO_69/70 供电；与 system_chip_test
#     注释一致时 IOSTANDARD 使用 LVCMOS18。若底板跳线/LDO 为 3V3，须改为 LVCMOS33。
#   - 若实际插接的是另一路 FMC（非本表对应的连接器），需按手册整表替换 PACKAGE_PIN。
# =============================================================================

# -----------------------------------------------------------------------------
# 主时钟：200 MHz 差分（与原版 sdc.xdc 相同）
# -----------------------------------------------------------------------------
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]

set_property PACKAGE_PIN AR32 [get_ports sys_clk_p]
set_property PACKAGE_PIN AT32 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_n]

set_input_jitter [get_clocks sys_clk] 0.100

# 禁止 clk_wiz_0.xdc 在 MMCM 输入网 clk_in1 上再建主时钟（与 sys_clk 重复 → TIMING-2/4）
set_property USED_IN_SYNTHESIS false [get_files -quiet */clk_wiz_0/clk_wiz_0.xdc]
set_property USED_IN_IMPLEMENTATION false [get_files -quiet */clk_wiz_0/clk_wiz_0.xdc]

# MMCM 生成时钟（clk_16M / clk_50M）与异步时钟组已移至
# sdc_chip_test_clocks_late.xdc（PROCESSING_ORDER LATE），
# 确保 MMCM 网表展开后再创建，避免与主 XDC 提前求值冲突。

# 可选：经 ODDR 送到芯片的单端时钟（用于对 FMC 输出做更细约束时取消注释并微调）
# create_generated_clock -name chip_hfclk_gen -source [get_pins u_oddr_hfclk/C] -divide_by 1 [get_ports chip_hfclk]
# create_generated_clock -name chip_lfclk_gen -source [get_pins u_oddr_lfclk/C] -divide_by 1 [get_ports chip_lfclk]

# -----------------------------------------------------------------------------
# 按键复位（低有效）：KEY1 / KEY2 — 与原版 sdc.xdc 相同
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports fpga_rst]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports mcu_rst]

# # -----------------------------------------------------------------------------
# # USB 串口（CP2102）— 与原版 sdc.xdc 相同
# # -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports uart_rx]

# # -----------------------------------------------------------------------------
# # 用户 LED（状态指示）
# # -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports led_mmcm_ok]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports led_chip_ok]
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVCMOS33} [get_ports led_mac_done]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports led_chip_output_empty]

# -----------------------------------------------------------------------------
# FMC1：测试板网络名与 Fan_Out pinNumber 对齐（与 J12 PACKAGE_PIN 同名则直连）
# -----------------------------------------------------------------------------

# CLK_IC0 (chip D8, LA00_CC_P)
set_property -dict {PACKAGE_PIN F23 IOSTANDARD LVCMOS18} [get_ports chip_clk_ic]

# CLK_CORE0 (chip G6, LA01_CC_P)
set_property -dict {PACKAGE_PIN E23 IOSTANDARD LVCMOS18} [get_ports chip_clk_core]

# RST_N_IO (chip F5, LA02_P)
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS18} [get_ports chip_rst_n_io]

# RST_N_CORE (chip F4, LA02_N)
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS18} [get_ports chip_rst_n_core]

# EN (chip J15, HA20_P)
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS18} [get_ports chip_en]

# WR_EN (chip J16, HA20_N)
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS18} [get_ports chip_wr_en]

# INPUT_FULL (HA11_N)
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS18} [get_ports chip_input_full]

# OUTPUT_EMPTY (HA11_P)
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS18} [get_ports chip_output_empty]

# MACMACHINE_DONE (HA00_CC_P)
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS18} [get_ports chip_mac_done]

# MACMACHINE_ERROR (chip ball F20)
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS18} [get_ports chip_mac_err]

# ADDR0~15
# chip_add[0] <- E2: ADDR0 chip ball E2
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS18} [get_ports {chip_add[0]}]
# chip_add[1] <- E3: ADDR1 chip ball E3
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS18} [get_ports {chip_add[1]}]
# chip_add[2] <- F7: ADDR2 chip ball F7
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS18} [get_ports {chip_add[2]}]
# chip_add[3] <- F8: ADDR3 chip ball F8
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS18} [get_ports {chip_add[3]}]
# chip_add[4] <- E6: ADDR4 chip ball E6
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS18} [get_ports {chip_add[4]}]
# chip_add[5] <- E7: ADDR5 chip ball E7
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS18} [get_ports {chip_add[5]}]
# chip_add[6] <- F10: ADDR6 chip ball F10
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS18} [get_ports {chip_add[6]}]
# chip_add[7] <- F11: ADDR7 chip ball F11
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS18} [get_ports {chip_add[7]}]
# chip_add[8] <- E9: ADDR8 chip ball E9
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS18} [get_ports {chip_add[8]}]
# chip_add[9] <- E10: ADDR9 chip ball E10
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS18} [get_ports {chip_add[9]}]
# chip_add[10] <- F13: ADDR10 chip ball F13
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS18} [get_ports {chip_add[10]}]
# chip_add[11] <- F14: ADDR11 chip ball F14
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS18} [get_ports {chip_add[11]}]
# chip_add[12] <- E12: ADDR12 chip ball E12
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS18} [get_ports {chip_add[12]}]
# chip_add[13] <- E13: ADDR13 chip ball E13
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS18} [get_ports {chip_add[13]}]
# chip_add[14] <- F16: ADDR14 chip ball F16
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS18} [get_ports {chip_add[14]}]
# chip_add[15] <- F17: ADDR15 chip ball F17
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS18} [get_ports {chip_add[15]}]

# DINOUT0~63 (chip_din[n] <- DINOUTn)
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS18} [get_ports {chip_din[0]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS18} [get_ports {chip_din[1]}]
set_property -dict {PACKAGE_PIN A23 IOSTANDARD LVCMOS18} [get_ports {chip_din[2]}]
set_property -dict {PACKAGE_PIN A24 IOSTANDARD LVCMOS18} [get_ports {chip_din[3]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS18} [get_ports {chip_din[4]}]
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS18} [get_ports {chip_din[5]}]
set_property -dict {PACKAGE_PIN L23 IOSTANDARD LVCMOS18} [get_ports {chip_din[6]}]
set_property -dict {PACKAGE_PIN L24 IOSTANDARD LVCMOS18} [get_ports {chip_din[7]}]
set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVCMOS18} [get_ports {chip_din[8]}]
set_property -dict {PACKAGE_PIN L22 IOSTANDARD LVCMOS18} [get_ports {chip_din[9]}]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS18} [get_ports {chip_din[10]}]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS18} [get_ports {chip_din[11]}]
set_property -dict {PACKAGE_PIN B24 IOSTANDARD LVCMOS18} [get_ports {chip_din[12]}]
set_property -dict {PACKAGE_PIN B25 IOSTANDARD LVCMOS18} [get_ports {chip_din[13]}]
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS18} [get_ports {chip_din[14]}]
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS18} [get_ports {chip_din[15]}]
set_property -dict {PACKAGE_PIN K23 IOSTANDARD LVCMOS18} [get_ports {chip_din[16]}]
set_property -dict {PACKAGE_PIN K24 IOSTANDARD LVCMOS18} [get_ports {chip_din[17]}]
set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVCMOS18} [get_ports {chip_din[18]}]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS18} [get_ports {chip_din[19]}]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS18} [get_ports {chip_din[20]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS18} [get_ports {chip_din[21]}]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS18} [get_ports {chip_din[22]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS18} [get_ports {chip_din[23]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS18} [get_ports {chip_din[24]}]
set_property -dict {PACKAGE_PIN C23 IOSTANDARD LVCMOS18} [get_ports {chip_din[25]}]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS18} [get_ports {chip_din[26]}]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS18} [get_ports {chip_din[27]}]
set_property -dict {PACKAGE_PIN F28 IOSTANDARD LVCMOS18} [get_ports {chip_din[28]}]
set_property -dict {PACKAGE_PIN F29 IOSTANDARD LVCMOS18} [get_ports {chip_din[29]}]
set_property -dict {PACKAGE_PIN E28 IOSTANDARD LVCMOS18} [get_ports {chip_din[30]}]
set_property -dict {PACKAGE_PIN E29 IOSTANDARD LVCMOS18} [get_ports {chip_din[31]}]
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS18} [get_ports {chip_din[32]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS18} [get_ports {chip_din[33]}]
set_property -dict {PACKAGE_PIN E26 IOSTANDARD LVCMOS18} [get_ports {chip_din[34]}]
set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVCMOS18} [get_ports {chip_din[35]}]
set_property -dict {PACKAGE_PIN J27 IOSTANDARD LVCMOS18} [get_ports {chip_din[36]}]
set_property -dict {PACKAGE_PIN H27 IOSTANDARD LVCMOS18} [get_ports {chip_din[37]}]
set_property -dict {PACKAGE_PIN J25 IOSTANDARD LVCMOS18} [get_ports {chip_din[38]}]
set_property -dict {PACKAGE_PIN H25 IOSTANDARD LVCMOS18} [get_ports {chip_din[39]}]
set_property -dict {PACKAGE_PIN E31 IOSTANDARD LVCMOS18} [get_ports {chip_din[40]}]
set_property -dict {PACKAGE_PIN D31 IOSTANDARD LVCMOS18} [get_ports {chip_din[41]}]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS18} [get_ports {chip_din[42]}]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS18} [get_ports {chip_din[43]}]
set_property -dict {PACKAGE_PIN E30 IOSTANDARD LVCMOS18} [get_ports {chip_din[44]}]
set_property -dict {PACKAGE_PIN D30 IOSTANDARD LVCMOS18} [get_ports {chip_din[45]}]
set_property -dict {PACKAGE_PIN J30 IOSTANDARD LVCMOS18} [get_ports {chip_din[46]}]
set_property -dict {PACKAGE_PIN J31 IOSTANDARD LVCMOS18} [get_ports {chip_din[47]}]
set_property -dict {PACKAGE_PIN L26 IOSTANDARD LVCMOS18} [get_ports {chip_din[48]}]
set_property -dict {PACKAGE_PIN L27 IOSTANDARD LVCMOS18} [get_ports {chip_din[49]}]
set_property -dict {PACKAGE_PIN K26 IOSTANDARD LVCMOS18} [get_ports {chip_din[50]}]
set_property -dict {PACKAGE_PIN J26 IOSTANDARD LVCMOS18} [get_ports {chip_din[51]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS18} [get_ports {chip_din[52]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS18} [get_ports {chip_din[53]}]
set_property -dict {PACKAGE_PIN M25 IOSTANDARD LVCMOS18} [get_ports {chip_din[54]}]
set_property -dict {PACKAGE_PIN M26 IOSTANDARD LVCMOS18} [get_ports {chip_din[55]}]
set_property -dict {PACKAGE_PIN G27 IOSTANDARD LVCMOS18} [get_ports {chip_din[56]}]
set_property -dict {PACKAGE_PIN F27 IOSTANDARD LVCMOS18} [get_ports {chip_din[57]}]
set_property -dict {PACKAGE_PIN J28 IOSTANDARD LVCMOS18} [get_ports {chip_din[58]}]
set_property -dict {PACKAGE_PIN H28 IOSTANDARD LVCMOS18} [get_ports {chip_din[59]}]
set_property -dict {PACKAGE_PIN G31 IOSTANDARD LVCMOS18} [get_ports {chip_din[60]}]
set_property -dict {PACKAGE_PIN F31 IOSTANDARD LVCMOS18} [get_ports {chip_din[61]}]
set_property -dict {PACKAGE_PIN H29 IOSTANDARD LVCMOS18} [get_ports {chip_din[62]}]
set_property -dict {PACKAGE_PIN H30 IOSTANDARD LVCMOS18} [get_ports {chip_din[63]}]

# -----------------------------------------------------------------------------
# 时序例外（上板初调常用；后续可改为真实 input/output delay）
# -----------------------------------------------------------------------------
set_false_path -from [get_ports fpga_rst]
set_false_path -from [get_ports mcu_rst]

# 来自芯片的异步输入（初调放宽；若与 clk_16M 做同步器后可删）
set_false_path -from [get_ports uart_rx]
set_false_path -from [get_ports chip_input_full]
set_false_path -from [get_ports chip_output_empty]
set_false_path -from [get_ports chip_mac_done]
set_false_path -from [get_ports chip_mac_err]
set_false_path -from [get_ports {chip_din[*]}]

# -----------------------------------------------------------------------------
# Bitstream / SPI Flash（与原版 sdc.xdc 一致，用于 FPGA 自身配置）
# -----------------------------------------------------------------------------
set_property CONFIG_MODE SPIx8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]

# -----------------------------------------------------------------------------
# 可选：UART 与 FMC 输出相对 clk_16M 的 IO 延迟（需要时再打开并调数值）
# -----------------------------------------------------------------------------
# set_input_delay  -clock [get_clocks clk_16M] -min 0.5 [get_ports uart_rx]
# set_input_delay  -clock [get_clocks clk_16M] -max 2.0 [get_ports uart_rx]
# set_output_delay -clock [get_clocks clk_16M] -min 0.5 [get_ports uart_tx]
# set_output_delay -clock [get_clocks clk_16M] -max 2.0 [get_ports uart_tx]


# ILA核配置：使用Verilog代码中的(* mark_debug = "true" *)标记自动生成
# Vivado会自动创建ILA核并连接标记的信号，无需手动配置
# 如需手动配置ILA核，请取消以下注释并确保不与mark_debug冲突

# create_debug_core u_ila_0 ila
# set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
# set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
# set_property C_TRIGGER_COMPARE_VALUE 0 [get_debug_cores u_ila_0]
# set_property C_TRIGGER_MASK 0 [get_debug_cores u_ila_0]
# set_property C_TRIGGER_TYPE basic [get_debug_cores u_ila_0]
# set_property port_width 1 [get_debug_ports u_ila_0/clk]
# connect_debug_port u_ila_0/clk [get_nets ip_mmcm/inst/clk_out1]
#
# # 探针0：状态信号（8位）
# set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe0]
# set_property port_width 8 [get_debug_ports u_ila_0/probe0]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_mmcm_locked]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_chip_rst_ok]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_mac_done]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_mac_err]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_input_full]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_output_empty]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_test_active]
# connect_debug_port u_ila_0/probe0 [get_nets dbg_chip_en]
#
# # 探针1：总线信号（82位）
# set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe1]
# set_property port_width 82 [get_debug_ports u_ila_0/probe1]
# connect_debug_port u_ila_0/probe1 [get_nets dbg_chip_wr_en]
# connect_debug_port u_ila_0/probe1 [get_nets dbg_chip_addr]
# connect_debug_port u_ila_0/probe1 [get_nets dbg_chip_data]
#
# # 探针2：FSM状态（8位）
# set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe2]
# set_property port_width 8 [get_debug_ports u_ila_0/probe2]
# connect_debug_port u_ila_0/probe2 [get_nets dbg_fsm_state]
#
# 以下 create_debug_core / connect_debug_port 须在核创建之后书写。
# 勿在 create_debug_core 之前 connect；勿引用未创建的 u_ila_1 或 RTL 中不存在的 dbg_* 网。


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_50M]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dbg_fsm_state[0]} {dbg_fsm_state[1]} {dbg_fsm_state[2]} {dbg_fsm_state[3]} {dbg_fsm_state[4]} {dbg_fsm_state[5]} {dbg_fsm_state[6]} {dbg_fsm_state[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 64 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dbg_chip_data[0]} {dbg_chip_data[1]} {dbg_chip_data[2]} {dbg_chip_data[3]} {dbg_chip_data[4]} {dbg_chip_data[5]} {dbg_chip_data[6]} {dbg_chip_data[7]} {dbg_chip_data[8]} {dbg_chip_data[9]} {dbg_chip_data[10]} {dbg_chip_data[11]} {dbg_chip_data[12]} {dbg_chip_data[13]} {dbg_chip_data[14]} {dbg_chip_data[15]} {dbg_chip_data[16]} {dbg_chip_data[17]} {dbg_chip_data[18]} {dbg_chip_data[19]} {dbg_chip_data[20]} {dbg_chip_data[21]} {dbg_chip_data[22]} {dbg_chip_data[23]} {dbg_chip_data[24]} {dbg_chip_data[25]} {dbg_chip_data[26]} {dbg_chip_data[27]} {dbg_chip_data[28]} {dbg_chip_data[29]} {dbg_chip_data[30]} {dbg_chip_data[31]} {dbg_chip_data[32]} {dbg_chip_data[33]} {dbg_chip_data[34]} {dbg_chip_data[35]} {dbg_chip_data[36]} {dbg_chip_data[37]} {dbg_chip_data[38]} {dbg_chip_data[39]} {dbg_chip_data[40]} {dbg_chip_data[41]} {dbg_chip_data[42]} {dbg_chip_data[43]} {dbg_chip_data[44]} {dbg_chip_data[45]} {dbg_chip_data[46]} {dbg_chip_data[47]} {dbg_chip_data[48]} {dbg_chip_data[49]} {dbg_chip_data[50]} {dbg_chip_data[51]} {dbg_chip_data[52]} {dbg_chip_data[53]} {dbg_chip_data[54]} {dbg_chip_data[55]} {dbg_chip_data[56]} {dbg_chip_data[57]} {dbg_chip_data[58]} {dbg_chip_data[59]} {dbg_chip_data[60]} {dbg_chip_data[61]} {dbg_chip_data[62]} {dbg_chip_data[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 16 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dbg_chip_addr[0]} {dbg_chip_addr[1]} {dbg_chip_addr[2]} {dbg_chip_addr[3]} {dbg_chip_addr[4]} {dbg_chip_addr[5]} {dbg_chip_addr[6]} {dbg_chip_addr[7]} {dbg_chip_addr[8]} {dbg_chip_addr[9]} {dbg_chip_addr[10]} {dbg_chip_addr[11]} {dbg_chip_addr[12]} {dbg_chip_addr[13]} {dbg_chip_addr[14]} {dbg_chip_addr[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list dbg_mac_done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list dbg_test_active]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list dbg_chip_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 64 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {data_out_to_chip[0]} {data_out_to_chip[1]} {data_out_to_chip[2]} {data_out_to_chip[3]} {data_out_to_chip[4]} {data_out_to_chip[5]} {data_out_to_chip[6]} {data_out_to_chip[7]} {data_out_to_chip[8]} {data_out_to_chip[9]} {data_out_to_chip[10]} {data_out_to_chip[11]} {data_out_to_chip[12]} {data_out_to_chip[13]} {data_out_to_chip[14]} {data_out_to_chip[15]} {data_out_to_chip[16]} {data_out_to_chip[17]} {data_out_to_chip[18]} {data_out_to_chip[19]} {data_out_to_chip[20]} {data_out_to_chip[21]} {data_out_to_chip[22]} {data_out_to_chip[23]} {data_out_to_chip[24]} {data_out_to_chip[25]} {data_out_to_chip[26]} {data_out_to_chip[27]} {data_out_to_chip[28]} {data_out_to_chip[29]} {data_out_to_chip[30]} {data_out_to_chip[31]} {data_out_to_chip[32]} {data_out_to_chip[33]} {data_out_to_chip[34]} {data_out_to_chip[35]} {data_out_to_chip[36]} {data_out_to_chip[37]} {data_out_to_chip[38]} {data_out_to_chip[39]} {data_out_to_chip[40]} {data_out_to_chip[41]} {data_out_to_chip[42]} {data_out_to_chip[43]} {data_out_to_chip[44]} {data_out_to_chip[45]} {data_out_to_chip[46]} {data_out_to_chip[47]} {data_out_to_chip[48]} {data_out_to_chip[49]} {data_out_to_chip[50]} {data_out_to_chip[51]} {data_out_to_chip[52]} {data_out_to_chip[53]} {data_out_to_chip[54]} {data_out_to_chip[55]} {data_out_to_chip[56]} {data_out_to_chip[57]} {data_out_to_chip[58]} {data_out_to_chip[59]} {data_out_to_chip[60]} {data_out_to_chip[61]} {data_out_to_chip[62]} {data_out_to_chip[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list dbg_chip_wr_en]]
set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_50M]
