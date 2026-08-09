# AXKU15 XCKU15P-FFVE1517-2-i bring-up constraints.
# Pin data is cross-checked against AXKU15_V1.2_UG_final.md.
create_clock -name sys_clk -period 5.000 [get_ports sys_clk_p]
set_property PACKAGE_PIN G12 [get_ports sys_clk_p]
set_property PACKAGE_PIN G11 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sys_clk_p sys_clk_n}]
set_input_jitter sys_clk 0.100

# KEY1 is used as active-low reset for a safe board-level smoke test.
set_property PACKAGE_PIN A8 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]

set_property PACKAGE_PIN D8  [get_ports {led[0]}]
set_property PACKAGE_PIN D7  [get_ports {led[1]}]
set_property PACKAGE_PIN D11 [get_ports {led[2]}]
set_property PACKAGE_PIN D10 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
