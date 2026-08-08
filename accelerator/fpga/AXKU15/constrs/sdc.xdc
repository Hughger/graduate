# AXKU15版本引脚约束文件

# Clock signal - 200MHz差分时钟（只在输入端口定义主时钟）
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]
set_property PACKAGE_PIN AR32 [get_ports sys_clk_p]
set_property PACKAGE_PIN AT32 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_n]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets dut_io_pads_jtag_TCK_i_ival]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets IOBUF_jtag_TCK/O]

# 设置输入时钟抖动
set_input_jitter [get_clocks sys_clk] 0.1

# 定义MMCM输出时钟（派生时钟）
# 200MHz -> 16MHz: 200 * 2 / 25 = 16MHz
create_generated_clock -name clk_16M -source [get_ports sys_clk_p] -divide_by 25 -multiply_by 2 [get_pins ip_mmcm/inst/clk_out1]

# 32.768KHz时钟：16MHz / 488 ≈ 32.787KHz
# 暂时注释掉，如果需要可以手动添加
# create_generated_clock -name CLK32768KHZ -source [get_pins ip_mmcm/inst/clk_out1] -divide_by 488 [get_nets CLK32768KHZ]

# 添加时钟组约束，确保不同时钟域之间的正确处理
# set_clock_groups -asynchronous -group [get_clocks sys_clk] -group [get_clocks clk_16M]

# Reset - 使用用户按键作为复位信号（文档中有明确定义）
  # KEY1 -> fpga_rst
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports fpga_rst]
   # KEY2 -> mcu_rst
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports mcu_rst]

# QSPI Flash接口 - 使用正确的数组索引语法
# QSPI0_DQ0
set_property -dict {PACKAGE_PIN AM12 IOSTANDARD LVCMOS18} [get_ports {qspi0_dq[0]}]
# QSPI0_DQ1
set_property -dict {PACKAGE_PIN AN12 IOSTANDARD LVCMOS18} [get_ports {qspi0_dq[1]}]
# QSPI0_DQ2
set_property -dict {PACKAGE_PIN AR13 IOSTANDARD LVCMOS18} [get_ports {qspi0_dq[2]}]
# QSPI0_DQ3
set_property -dict {PACKAGE_PIN AR12 IOSTANDARD LVCMOS18} [get_ports {qspi0_dq[3]}]
# QSPI0_CS
set_property -dict {PACKAGE_PIN AV11 IOSTANDARD LVCMOS18} [get_ports qspi0_cs]

# JTAG连接（如果需要）
set_property -dict {PACKAGE_PIN K23 IOSTANDARD LVCMOS18} [get_ports mcu_TDO]
set_property -dict {PACKAGE_PIN K24 IOSTANDARD LVCMOS18} [get_ports mcu_TCK]
set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVCMOS18} [get_ports mcu_TDI]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS18} [get_ports mcu_TMS]
set_property KEEPER true [get_ports mcu_TMS]
# PMU唤醒信号 - 使用用户LED作为输出指示
   # LED1
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports pmu_paden]
  # LED2
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports pmu_padrst]
  # LED3
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVCMOS33} [get_ports mcu_wakeup]

# 异步复位路径约束
set_false_path -from [get_ports fpga_rst]
set_false_path -from [get_ports mcu_rst]

# Bitstream配置（参考LED例程）
set_property CONFIG_MODE SPIx8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]

# 调试串口配置 - 使用开发板专用串口引脚_cy
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports uart_rx]

# UART时序约束_cy (暂时注释掉，避免引用不存在的时钟)
# set_input_delay -clock [get_clocks clk_16M] -min 1.000 [get_ports uart_rx]
# set_input_delay -clock [get_clocks clk_16M] -max 3.000 [get_ports uart_rx]
# set_output_delay -clock [get_clocks clk_16M] -min 1.000 [get_ports uart_tx]
# set_output_delay -clock [get_clocks clk_16M] -max 3.000 [get_ports uart_tx]
