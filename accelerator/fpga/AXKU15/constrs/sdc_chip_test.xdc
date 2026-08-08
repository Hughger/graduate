# =============================================================================
# 文件名：sdc_chip_test.xdc
# 功  能：FLOOD MAC加速器芯片测试约束（对应 system_chip_test.v）
# 硬件：AXKU15 FPGA开发板 + 芯片测试板（通过FMC1接口连接）
#
# 芯片信号通过 FMC1(J12) 连接，共90个信号引脚：
#   FMC1 LA信号 → FPGA BANK69/70（1.8V）：控制/地址/数据低40位
#   FMC1 HA信号 → FPGA BANK71（1.8V）    ：数据高24位 din[40:63]
# =============================================================================

# =============================================================================
# 【一】FPGA 板载时钟和复位（固定不变）
# =============================================================================
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]
set_property PACKAGE_PIN AR32 [get_ports sys_clk_p]
set_property PACKAGE_PIN AT32 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_n]
set_input_jitter [get_clocks sys_clk] 0.1

create_generated_clock -name clk_16M \
    -source [get_ports sys_clk_p] \
    -divide_by 25 -multiply_by 2 \
    [get_pins ip_mmcm/inst/clk_out1]

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports fpga_rst]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports mcu_rst]
set_false_path -from [get_ports fpga_rst]
set_false_path -from [get_ports mcu_rst]

# =============================================================================
# 【二】FPGA 板载 UART 和 LED（固定不变）
# =============================================================================
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN D8  IOSTANDARD LVCMOS33} [get_ports led_mmcm_ok]
set_property -dict {PACKAGE_PIN D7  IOSTANDARD LVCMOS33} [get_ports led_chip_ok]
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVCMOS33} [get_ports led_mac_done]

# =============================================================================
# 【三】FMC1 LA 信号（BANK69/70，1.8V）
#       → 时钟、复位、控制、状态、地址、数据[0:39]
#
# FMC1 LA引脚速查：
#   LA00_CC_P=E23  LA01_CC_P=F23  LA02_P=E21  LA02_N=D21
#   LA03_P=A23     LA03_N=A24     LA04_P=G22  LA04_N=F22
#   LA05_P=K20     LA05_N=K21     LA06_P=K23  LA06_N=K24
#   LA07_P=L21     LA07_N=L22     LA08_P=L23  LA08_N=L24
#   LA09_P=M19     LA09_N=M20     LA10_P=E20  LA10_N=D20
#   LA11_P=B24     LA11_N=B25     LA12_P=M21  LA12_N=M22
#   LA13_P=B21     LA13_N=A21     LA14_P=C22  LA14_N=C23
#   LA15_P=C20     LA15_N=B20     LA16_P=B22  LA16_N=A22
#   LA17_CC_P=E28  LA17_CC_N=E29  LA18_CC_P=F28 LA18_CC_N=F29
#   LA19_P=J22     LA19_N=H22     LA20_P=E26  LA20_N=D26
#   LA21_P=J27     LA21_N=H27     LA22_P=J25  LA22_N=H25
#   LA23_P=K26     LA23_N=J26     LA24_P=E31  LA24_N=D31
#   LA25_P=J20     LA25_N=J21     LA26_P=M25  LA26_N=M26
#   LA27_P=L26     LA27_N=L27     LA28_P=E30  LA28_N=D30
#   LA29_P=J30     LA29_N=J31     LA30_P=G27  LA30_N=F27
#   LA31_P=J28     LA31_N=H28     LA32_P=G31  LA32_N=F31
#   LA33_P=H29     LA33_N=H30
# =============================================================================

# ---- 时钟输出（CC差分对P脚，时钟质量最佳）----
# chip_clk_ic  → 芯片引脚46 (clk_ic)
set_property PACKAGE_PIN E23 [get_ports chip_clk_ic]
set_property IOSTANDARD LVCMOS18 [get_ports chip_clk_ic]
set_false_path -to [get_ports chip_clk_ic]

# chip_clk_core → 芯片引脚47 (clk_core)
set_property PACKAGE_PIN F23 [get_ports chip_clk_core]
set_property IOSTANDARD LVCMOS18 [get_ports chip_clk_core]
set_false_path -to [get_ports chip_clk_core]

# ---- 复位（低有效输出）----
# chip_rst_n_io → 芯片引脚54 (rst_n_io)
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS18} [get_ports chip_rst_n_io]
set_false_path -to [get_ports chip_rst_n_io]
# chip_rst_n_core → 芯片引脚55 (rst_n_core)
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS18} [get_ports chip_rst_n_core]
set_false_path -to [get_ports chip_rst_n_core]

# ---- 总线控制信号（输出）----
# chip_en → 芯片引脚63 (en)
set_property -dict {PACKAGE_PIN A23 IOSTANDARD LVCMOS18} [get_ports chip_en]
# chip_wr_en → 芯片引脚62 (wr_en)
set_property -dict {PACKAGE_PIN A24 IOSTANDARD LVCMOS18} [get_ports chip_wr_en]

# ---- 状态/中断输入（芯片→FPGA）----
# chip_input_full → 芯片引脚48 (input_full)
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS18} [get_ports chip_input_full]
set_false_path -from [get_ports chip_input_full]
# chip_output_empty → 芯片引脚49 (output_empty)
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS18} [get_ports chip_output_empty]
set_false_path -from [get_ports chip_output_empty]
# chip_mac_done → 芯片引脚56 (macDone_interrupt)
set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVCMOS18} [get_ports chip_mac_done]
set_false_path -from [get_ports chip_mac_done]
# chip_mac_err → 芯片引脚57 (macErr_interrput)
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS18} [get_ports chip_mac_err]
set_false_path -from [get_ports chip_mac_err]

# ---- 地址总线 add[0:15]（输出，16位）----
# add[0:1] ← LA06
set_property -dict {PACKAGE_PIN K23 IOSTANDARD LVCMOS18} [get_ports {chip_add[0]}]
set_property -dict {PACKAGE_PIN K24 IOSTANDARD LVCMOS18} [get_ports {chip_add[1]}]
# add[2:3] ← LA07
set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVCMOS18} [get_ports {chip_add[2]}]
set_property -dict {PACKAGE_PIN L22 IOSTANDARD LVCMOS18} [get_ports {chip_add[3]}]
# add[4:5] ← LA08
set_property -dict {PACKAGE_PIN L23 IOSTANDARD LVCMOS18} [get_ports {chip_add[4]}]
set_property -dict {PACKAGE_PIN L24 IOSTANDARD LVCMOS18} [get_ports {chip_add[5]}]
# add[6:7] ← LA09
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS18} [get_ports {chip_add[6]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS18} [get_ports {chip_add[7]}]
# add[8:9] ← LA10
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS18} [get_ports {chip_add[8]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS18} [get_ports {chip_add[9]}]
# add[10:11] ← LA11
set_property -dict {PACKAGE_PIN B24 IOSTANDARD LVCMOS18} [get_ports {chip_add[10]}]
set_property -dict {PACKAGE_PIN B25 IOSTANDARD LVCMOS18} [get_ports {chip_add[11]}]
# add[12:13] ← LA12
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS18} [get_ports {chip_add[12]}]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS18} [get_ports {chip_add[13]}]
# add[14:15] ← LA13
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS18} [get_ports {chip_add[14]}]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS18} [get_ports {chip_add[15]}]

# ---- 数据总线 din[0:39]（双向，LA14~LA33，共40位）----
# din[0:1] ← LA14
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS18} [get_ports {chip_din[0]}]
set_property -dict {PACKAGE_PIN C23 IOSTANDARD LVCMOS18} [get_ports {chip_din[1]}]
# din[2:3] ← LA15
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS18} [get_ports {chip_din[2]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS18} [get_ports {chip_din[3]}]
# din[4:5] ← LA16
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS18} [get_ports {chip_din[4]}]
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS18} [get_ports {chip_din[5]}]
# din[6:7] ← LA17_CC（CC对用作数据，无妨）
set_property -dict {PACKAGE_PIN E28 IOSTANDARD LVCMOS18} [get_ports {chip_din[6]}]
set_property -dict {PACKAGE_PIN E29 IOSTANDARD LVCMOS18} [get_ports {chip_din[7]}]
# din[8:9] ← LA18_CC
set_property -dict {PACKAGE_PIN F28 IOSTANDARD LVCMOS18} [get_ports {chip_din[8]}]
set_property -dict {PACKAGE_PIN F29 IOSTANDARD LVCMOS18} [get_ports {chip_din[9]}]
# din[10:11] ← LA19
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS18} [get_ports {chip_din[10]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS18} [get_ports {chip_din[11]}]
# din[12:13] ← LA20
set_property -dict {PACKAGE_PIN E26 IOSTANDARD LVCMOS18} [get_ports {chip_din[12]}]
set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVCMOS18} [get_ports {chip_din[13]}]
# din[14:15] ← LA21
set_property -dict {PACKAGE_PIN J27 IOSTANDARD LVCMOS18} [get_ports {chip_din[14]}]
set_property -dict {PACKAGE_PIN H27 IOSTANDARD LVCMOS18} [get_ports {chip_din[15]}]
# din[16:17] ← LA22
set_property -dict {PACKAGE_PIN J25 IOSTANDARD LVCMOS18} [get_ports {chip_din[16]}]
set_property -dict {PACKAGE_PIN H25 IOSTANDARD LVCMOS18} [get_ports {chip_din[17]}]
# din[18:19] ← LA23
set_property -dict {PACKAGE_PIN K26 IOSTANDARD LVCMOS18} [get_ports {chip_din[18]}]
set_property -dict {PACKAGE_PIN J26 IOSTANDARD LVCMOS18} [get_ports {chip_din[19]}]
# din[20:21] ← LA24
set_property -dict {PACKAGE_PIN E31 IOSTANDARD LVCMOS18} [get_ports {chip_din[20]}]
set_property -dict {PACKAGE_PIN D31 IOSTANDARD LVCMOS18} [get_ports {chip_din[21]}]
# din[22:23] ← LA25
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS18} [get_ports {chip_din[22]}]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS18} [get_ports {chip_din[23]}]
# din[24:25] ← LA26
set_property -dict {PACKAGE_PIN M25 IOSTANDARD LVCMOS18} [get_ports {chip_din[24]}]
set_property -dict {PACKAGE_PIN M26 IOSTANDARD LVCMOS18} [get_ports {chip_din[25]}]
# din[26:27] ← LA27
set_property -dict {PACKAGE_PIN L26 IOSTANDARD LVCMOS18} [get_ports {chip_din[26]}]
set_property -dict {PACKAGE_PIN L27 IOSTANDARD LVCMOS18} [get_ports {chip_din[27]}]
# din[28:29] ← LA28
set_property -dict {PACKAGE_PIN E30 IOSTANDARD LVCMOS18} [get_ports {chip_din[28]}]
set_property -dict {PACKAGE_PIN D30 IOSTANDARD LVCMOS18} [get_ports {chip_din[29]}]
# din[30:31] ← LA29
set_property -dict {PACKAGE_PIN J30 IOSTANDARD LVCMOS18} [get_ports {chip_din[30]}]
set_property -dict {PACKAGE_PIN J31 IOSTANDARD LVCMOS18} [get_ports {chip_din[31]}]
# din[32:33] ← LA30
set_property -dict {PACKAGE_PIN G27 IOSTANDARD LVCMOS18} [get_ports {chip_din[32]}]
set_property -dict {PACKAGE_PIN F27 IOSTANDARD LVCMOS18} [get_ports {chip_din[33]}]
# din[34:35] ← LA31
set_property -dict {PACKAGE_PIN J28 IOSTANDARD LVCMOS18} [get_ports {chip_din[34]}]
set_property -dict {PACKAGE_PIN H28 IOSTANDARD LVCMOS18} [get_ports {chip_din[35]}]
# din[36:37] ← LA32
set_property -dict {PACKAGE_PIN G31 IOSTANDARD LVCMOS18} [get_ports {chip_din[36]}]
set_property -dict {PACKAGE_PIN F31 IOSTANDARD LVCMOS18} [get_ports {chip_din[37]}]
# din[38:39] ← LA33
set_property -dict {PACKAGE_PIN H29 IOSTANDARD LVCMOS18} [get_ports {chip_din[38]}]
set_property -dict {PACKAGE_PIN H30 IOSTANDARD LVCMOS18} [get_ports {chip_din[39]}]

# =============================================================================
# 【四】FMC1 HA 信号（BANK71，1.8V）
#       → 数据总线高位 din[40:63]（共24位）
#
# FMC1 HA引脚速查：
#   HA00_CC_P=F19  HA00_CC_N=F18  HA01_CC_P=G17  HA01_CC_N=G16
#   HA02_P=B19     HA02_N=A19     HA03_P=H19     HA03_N=G19
#   HA04_P=B16     HA04_N=B15     HA05_P=C18     HA05_N=C17
#   HA06_P=H14     HA06_N=G14     HA07_P=K15     HA07_N=K14
#   HA08_P=E19     HA08_N=E18     HA09_P=D18     HA09_N=D17
#   HA10_P=H18     HA10_N=H17     HA11_P=E16     HA11_N=E15
# =============================================================================

# din[40:41] ← HA00_CC
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS18} [get_ports {chip_din[40]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS18} [get_ports {chip_din[41]}]
# din[42:43] ← HA01_CC
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS18} [get_ports {chip_din[42]}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS18} [get_ports {chip_din[43]}]
# din[44:45] ← HA02
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS18} [get_ports {chip_din[44]}]
set_property -dict {PACKAGE_PIN A19 IOSTANDARD LVCMOS18} [get_ports {chip_din[45]}]
# din[46:47] ← HA03
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS18} [get_ports {chip_din[46]}]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS18} [get_ports {chip_din[47]}]
# din[48:49] ← HA04
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS18} [get_ports {chip_din[48]}]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS18} [get_ports {chip_din[49]}]
# din[50:51] ← HA05
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS18} [get_ports {chip_din[50]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS18} [get_ports {chip_din[51]}]
# din[52:53] ← HA06
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS18} [get_ports {chip_din[52]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS18} [get_ports {chip_din[53]}]
# din[54:55] ← HA07
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS18} [get_ports {chip_din[54]}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS18} [get_ports {chip_din[55]}]
# din[56:57] ← HA08
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS18} [get_ports {chip_din[56]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS18} [get_ports {chip_din[57]}]
# din[58:59] ← HA09
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS18} [get_ports {chip_din[58]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS18} [get_ports {chip_din[59]}]
# din[60:61] ← HA10
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS18} [get_ports {chip_din[60]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS18} [get_ports {chip_din[61]}]
# din[62:63] ← HA11
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS18} [get_ports {chip_din[62]}]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS18} [get_ports {chip_din[63]}]

# =============================================================================
# 【五】比特流配置（AXKU15固定参数）
# =============================================================================
set_property CONFIG_MODE SPIx8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]
