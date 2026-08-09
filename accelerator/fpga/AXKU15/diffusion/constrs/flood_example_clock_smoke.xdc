# Minimal constraints for the FLOOD AXKU15 clock-reuse synthesis check.
#
# This is intentionally not a board implementation XDC: the historical top
# exposes a 64-bit FMC bus whose electrical mapping must be reviewed before it
# is connected to the diffusion accelerator. These constraints only prove the
# known 200 MHz board clock and regenerated Clocking Wizard configuration.

create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]
set_property PACKAGE_PIN AR32 [get_ports sys_clk_p]
set_property PACKAGE_PIN AT32 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_n]
set_input_jitter [get_clocks sys_clk] 0.100
