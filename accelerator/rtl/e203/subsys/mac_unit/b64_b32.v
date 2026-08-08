module b64_b32 (
    input clk,
    input rst_n,

    // mux interface
    input [63:0] w_data,
    input [12:0] w_addr,
    input en,
    input we,
    input [12:0] r_addr,
    output [63:0] r_data,

    // config interface
    output  [31:0]  io_configBus_data,
    output  [31:0]  io_configBus_addr,
    output          io_configBus_en
);

// Direct wire connections for configuration bus
// Extract low 32 bits from 64-bit write data
assign io_configBus_data = w_data[31:0];

assign io_configBus_addr = {17'h0, w_addr[12:0]};

// Enable signal passthrough
assign io_configBus_en = en;

// Read data always returns 0 (config bus is write-only)
assign r_data = 64'h0;

endmodule