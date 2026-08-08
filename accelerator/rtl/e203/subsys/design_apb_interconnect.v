// -----------------------------------------------------------------------------
// APB Interconnect for two BRAMs, APB2.0
// Author: zhao yi
// Date: 2025/06/16
// -----------------------------------------------------------------------------

module design_apb_interconnect #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // APB Master Interface
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH-1:0]   paddr,
    input  wire                    pwrite,
    input  wire                    pselx,
    input  wire                    penable,
    input  wire [DATA_WIDTH-1:0]   pwdata,
    output reg  [DATA_WIDTH-1:0]   prdata,

    // BRAM0 Interface, clk和reset由外部给
    output wire [12:0]            bram0_addr,
    output wire [DATA_WIDTH-1:0]  bram0_din,
    input  wire [DATA_WIDTH-1:0]  bram0_dout,
    output wire                   bram0_en,
    output wire                   bram0_rst,
    output wire [3:0]             bram0_we,

    // BRAM1 Interface
    output wire [12:0]            bram1_addr,
    output wire [DATA_WIDTH-1:0]  bram1_din,
    input  wire [DATA_WIDTH-1:0]  bram1_dout,
    output wire                   bram1_en,
    output wire                   bram1_rst,
    output wire [3:0]             bram1_we
);

    // Address definitions
    localparam BRAM0_BASE = 32'h0004_0000;  // BRAM0 base address
    localparam BRAM1_BASE = 32'h0004_2000;  // BRAM1 base address
    localparam BRAM_SIZE  = 32'h0000_2000;  // 8K size for each BRAM

    // Address decode
    wire bram0_sel = (paddr >= BRAM0_BASE) && (paddr < (BRAM0_BASE + BRAM_SIZE));
    wire bram1_sel = (paddr >= BRAM1_BASE) && (paddr < (BRAM1_BASE + BRAM_SIZE));

    // BRAM0 connections
    assign bram0_addr = paddr[14:2];  // 使用paddr[14:2]作为13位BRAM地址
    assign bram0_din  = pwdata;
    assign bram0_en   = pselx && bram0_sel;
    assign bram0_rst  = ~rst_n;
    assign bram0_we   = (pwrite && pselx && penable) ? 4'hF : 4'h0;

    // BRAM1 connections
    assign bram1_addr = paddr[14:2];  // 使用paddr[14:2]作为13位BRAM地址
    assign bram1_din  = pwdata;
    assign bram1_en   = pselx && bram1_sel;
    assign bram1_rst  = ~rst_n;
    assign bram1_we   = (pwrite && pselx && penable) ? 4'hF : 4'h0;

    // Read data multiplexer
    always @(*) begin
        if (bram0_sel && pselx && penable && !pwrite)
            prdata = bram0_dout;
        else if (bram1_sel && pselx && penable && !pwrite)
            prdata = bram1_dout;
        else
            prdata = {DATA_WIDTH{1'b0}};
    end


endmodule