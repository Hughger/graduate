//Copyright 2018-2020 Nuclei System Technology, Inc.
//Licensed under the Apache License, Version 2.0 (the "License");
//
// Designer   : LanXin
// Description: 32-bit width, 8K depth, 1 cycle read latency BRAM module
//              Compatible with Xilinx BRAM interface
//====================================================================

`include "e203_defines.v"

module e203_bram_8k (
    // BRAM Interface
    input  [12:0]   bram_addr,    // 13-bit address for 8K depth
    input           bram_clk,     // Clock
    input  [31:0]   bram_din,     // Data input
    output [31:0]   bram_dout,    // Data output
    input           bram_en,      // Enable
    input           bram_rst,     // Reset
    input  [3:0]    bram_we,      // Write enable (byte-wise)
    
    // System signals
    input           rst_n         // Global reset
);

    // 32-bit width, 8K depth RAM array
    // 8K = 8192 entries, requires 13-bit address
    reg [31:0] ram_array [0:8191];
    reg [31:0] rdata_r;
    
    // RAM timing logic with 1 cycle read latency
    always @(posedge bram_clk) begin
        if (!rst_n || bram_rst) begin
            rdata_r <= 32'h0;
        end else begin
            if (bram_en) begin
                // Write operation with byte-wise write enable
                if (bram_we[0]) ram_array[bram_addr][7:0]   <= bram_din[7:0];
                if (bram_we[1]) ram_array[bram_addr][15:8]  <= bram_din[15:8];
                if (bram_we[2]) ram_array[bram_addr][23:16] <= bram_din[23:16];
                if (bram_we[3]) ram_array[bram_addr][31:24] <= bram_din[31:24];
                
                // Read operation (1 cycle latency)
                rdata_r <= ram_array[bram_addr];
            end
        end
    end
    
    // Connect output
    assign bram_dout = rdata_r;

endmodule 