// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: AXI to 256-bit BRAM Bridge
// Converts 64-bit AXI transactions to 256-bit BRAM operations
// Features: Data buffering, address alignment, burst handling

module axi2bram_128k (
    // AXI Clock and Reset
    input wire s_axi_aclk,
    input wire s_axi_aresetn,

    // AXI Read Address Channel
    input  wire [19:0] S_AXI_araddr,    // 20-bit for slave address space (0x0_0000~0xF_FFFF)
    input  wire [1:0]  S_AXI_arburst,
    input  wire [3:0]  S_AXI_arcache,
    input  wire [5:0]  S_AXI_arid,
    input  wire [7:0]  S_AXI_arlen,
    input  wire        S_AXI_arlock,
    input  wire [2:0]  S_AXI_arprot,
    output wire        S_AXI_arready,
    input  wire [2:0]  S_AXI_arsize,
    input  wire        S_AXI_arvalid,

    // AXI Write Address Channel
    input  wire [19:0] S_AXI_awaddr,
    input  wire [1:0]  S_AXI_awburst,
    input  wire [3:0]  S_AXI_awcache,
    input  wire [5:0]  S_AXI_awid,
    input  wire [7:0]  S_AXI_awlen,
    input  wire        S_AXI_awlock,
    input  wire [2:0]  S_AXI_awprot,
    output wire        S_AXI_awready,
    input  wire [2:0]  S_AXI_awsize,
    input  wire        S_AXI_awvalid,

    // AXI Write Data Channel
    input  wire [63:0] S_AXI_wdata,
    input  wire        S_AXI_wlast,
    output wire        S_AXI_wready,
    input  wire [7:0]  S_AXI_wstrb,
    input  wire        S_AXI_wvalid,

    // AXI Write Response Channel
    output wire [5:0]  S_AXI_bid,
    input  wire        S_AXI_bready,
    output wire [1:0]  S_AXI_bresp,
    output wire        S_AXI_bvalid,

    // AXI Read Data Channel
    output wire [63:0] S_AXI_rdata,
    output wire [5:0]  S_AXI_rid,
    output wire        S_AXI_rlast,
    input  wire        S_AXI_rready,
    output wire [1:0]  S_AXI_rresp,
    output wire        S_AXI_rvalid,

    // BRAM Interface 1 (Pseudo Dual-Port SRAM) - First RAM (0x0_0000~0x1_FFFF)
    output wire         bram1_clk,      // Common clock
    output wire         bram1_rst_n,    // Active low reset
    // Write port
    output wire [11:0]  bram1_w_addr,   // Write address
    output wire [255:0] bram1_w_din,    // Write data
    output wire         bram1_w_en,     // Write enable
    output wire [31:0]  bram1_w_we,     // Write byte enable
    // Read port
    output wire [11:0]  bram1_r_addr,   // Read address
    input  wire [255:0] bram1_r_dout,   // Read data
    output wire         bram1_r_en,     // Read enable

    // BRAM Interface 2 (Pseudo Dual-Port SRAM) - Second RAM (0x2_0000~0x3_FFFF)
    output wire         bram2_clk,      // Common clock
    output wire         bram2_rst_n,    // Active low reset
    // Write port
    output wire [11:0]  bram2_w_addr,   // Write address
    output wire [255:0] bram2_w_din,    // Write data
    output wire         bram2_w_en,     // Write enable
    output wire [31:0]  bram2_w_we,     // Write byte enable
    // Read port
    output wire [11:0]  bram2_r_addr,   // Read address
    input  wire [255:0] bram2_r_dout,   // Read data
    output wire         bram2_r_en,     // Read enable

    // Control interface for RamCtrlSwitch RAM1 (address 0xF_0000)
    output wire         ctrl_valid,     // Control write valid for RAM1
    output wire [31:0]  ctrl_data,      // Control data for RAM1 (bit[0] from write data)
    input  wire         ctrl_ready,     // Control ready for RAM1

    // Control interface for RamCtrlSwitch RAM2 (address 0xF_0000)
    output wire         ctrl2_valid,    // Control write valid for RAM2
    output wire [31:0]  ctrl2_data,     // Control data for RAM2 (bit[1] from write data)
    input  wire         ctrl2_ready     // Control ready for RAM2
);

// Parameters
localparam AXI_ID_WIDTH = 6;
localparam AXI_DATA_WIDTH = 64;
localparam BRAM_DATA_WIDTH = 256;
localparam BRAM_BYTES = BRAM_DATA_WIDTH / 8;        // 32 bytes
localparam AXI_BYTES = AXI_DATA_WIDTH / 8;          // 8 bytes
localparam BURST_RATIO = BRAM_BYTES / AXI_BYTES;    // 4

// AXI Burst Types
localparam [1:0] FIXED = 2'b00;
localparam [1:0] INCR  = 2'b01;
localparam [1:0] WRAP  = 2'b10;

// State Machine States
localparam [3:0] IDLE         = 4'b0000;
localparam [3:0] READ_SETUP   = 4'b0001;
localparam [3:0] READ_BURST   = 4'b0010;
localparam [3:0] WRITE_SETUP  = 4'b0011;
localparam [3:0] WRITE_BURST  = 4'b0100;
localparam [3:0] WRITE_COMMIT = 4'b0101;
localparam [3:0] SEND_B       = 4'b0110;
localparam [3:0] READ_COMMIT  = 4'b0111;

// Internal registers
reg [3:0] state_q, state_d;
reg [5:0] ax_req_id_q, ax_req_id_d;
reg [19:0] ax_req_addr_q, ax_req_addr_d;  // AXI byte address (20-bit)
reg [7:0] ax_req_len_q, ax_req_len_d;
reg [2:0] ax_req_size_q, ax_req_size_d;
reg [1:0] ax_req_burst_q, ax_req_burst_d;
reg [11:0] req_addr_q, req_addr_d;        // SRAM word address (12-bit)
reg [7:0] cnt_q, cnt_d;
reg [1:0] burst_cnt_q, burst_cnt_d;       // Counter for 4-beat bursts (0-3)

// Data buffers for write operations (4 x 64-bit = 256-bit)
reg [63:0] write_buffer [0:3];
reg [7:0]  wstrb_buffer [0:3];

// BRAM interface signals - RAM1 (0x0_0000~0x1_FFFF)
reg [11:0] bram1_w_addr_o, bram1_r_addr_o;
reg [255:0] bram1_w_din_o;
reg         bram1_w_en_o, bram1_r_en_o;
reg [31:0]  bram1_w_we_o;

// BRAM interface signals - RAM2 (0x2_0000~0x3_FFFF)
reg [11:0] bram2_w_addr_o, bram2_r_addr_o;
reg [255:0] bram2_w_din_o;
reg         bram2_w_en_o, bram2_r_en_o;
reg [31:0]  bram2_w_we_o;

// AXI interface signals
reg aw_ready_o, ar_ready_o, w_ready_o;
reg r_valid_o, r_last_o, b_valid_o;
reg [1:0] r_resp_o, b_resp_o;
reg [63:0] rdata_o;

// Control interface signals - RAM1
reg ctrl_valid_o;
reg [31:0] ctrl_data_o;

// Control interface signals - RAM2
reg ctrl2_valid_o;
reg [31:0] ctrl2_data_o;

// BRAM Clock and Reset passthrough
assign bram1_clk = s_axi_aclk;
assign bram1_rst_n = s_axi_aresetn;
assign bram2_clk = s_axi_aclk;
assign bram2_rst_n = s_axi_aresetn;

// Function to determine which RAM to access (0=RAM1, 1=RAM2)
function is_ram2;
    input [19:0] axi_byte_addr;
    begin
        // RAM1: 0x0_0000 ~ 0x1_FFFF (bit[17] = 0)
        // RAM2: 0x2_0000 ~ 0x3_FFFF (bit[17] = 1)
        is_ram2 = axi_byte_addr[17];
    end
endfunction

// Function to convert AXI byte address to ASIC SRAM word address
function [11:0] axi_addr_to_sram_word;
    input [19:0] axi_byte_addr;
    reg [19:0] ram2_addr;
    begin
        if (axi_byte_addr[17]) begin
            // RAM2: subtract 0x20000 offset and use bits [16:5] for 128KB address space
            // 0x20000 -> 0x000, 0x3FFFF -> 0xFFF (4095)
            ram2_addr = axi_byte_addr[19:0] - 20'h20000;
            axi_addr_to_sram_word = ram2_addr[16:5];
        end else begin
            // RAM1: use bits [16:5] for 128KB address space
            axi_addr_to_sram_word = axi_byte_addr[16:5];
        end
    end
endfunction

// Function to align AXI address to 256-bit boundary (for burst start)
function [19:0] align_to_256bit;
    input [19:0] addr;
    begin
        align_to_256bit = {addr[19:5], 5'b00000};  // Clear lower 5 bits (32-byte alignment)
    end
endfunction

// Function to get burst position within 256-bit word (0-3 for 4 x 64-bit chunks)
function [1:0] get_burst_position;
    input [19:0] axi_byte_addr;
    begin
        // 256-bit = 32 bytes, 64-bit chunks = 8 bytes each
        // Address bits [4:3] determine which 64-bit chunk within 256-bit word
        get_burst_position = axi_byte_addr[4:3];
    end
endfunction

// Function to convert AXI wstrb to BRAM byte enables for ASIC SRAM
// ASIC SRAM typically writes entire word, but we use byte enables for compatibility
function [31:0] axi_wstrb_to_bram_we;
    input [7:0] axi_wstrb;
    input [1:0] burst_pos;  // 0-3 indicating which 64-bit chunk
    begin
        case (burst_pos)
            2'b00: axi_wstrb_to_bram_we = {24'h0, axi_wstrb};        // Bytes 0-7
            2'b01: axi_wstrb_to_bram_we = {16'h0, axi_wstrb, 8'h0};  // Bytes 8-15
            2'b10: axi_wstrb_to_bram_we = {8'h0, axi_wstrb, 16'h0};  // Bytes 16-23
            2'b11: axi_wstrb_to_bram_we = {axi_wstrb, 24'h0};        // Bytes 24-31
            default: axi_wstrb_to_bram_we = 32'h0;
        endcase
    end
endfunction

// AXI outputs
assign S_AXI_awready = aw_ready_o;
assign S_AXI_arready = ar_ready_o;
assign S_AXI_wready = w_ready_o;
assign S_AXI_rvalid = r_valid_o;
assign S_AXI_rdata = rdata_o;
assign S_AXI_rresp = r_resp_o;
assign S_AXI_rlast = r_last_o;
assign S_AXI_rid = ax_req_id_q;
assign S_AXI_bvalid = b_valid_o;
assign S_AXI_bresp = b_resp_o;
assign S_AXI_bid = ax_req_id_q;

// BRAM1 outputs (First RAM: 0x0_0000~0x1_FFFF)
assign bram1_w_addr = bram1_w_addr_o;
assign bram1_w_din = bram1_w_din_o;
assign bram1_w_en = bram1_w_en_o;
assign bram1_w_we = bram1_w_we_o;
assign bram1_r_addr = bram1_r_addr_o;
assign bram1_r_en = bram1_r_en_o;

// BRAM2 outputs (Second RAM: 0x2_0000~0x3_FFFF)
assign bram2_w_addr = bram2_w_addr_o;
assign bram2_w_din = bram2_w_din_o;
assign bram2_w_en = bram2_w_en_o;
assign bram2_w_we = bram2_w_we_o;
assign bram2_r_addr = bram2_r_addr_o;
assign bram2_r_en = bram2_r_en_o;

// Control outputs - RAM1
assign ctrl_valid = ctrl_valid_o;
assign ctrl_data = ctrl_data_o;

// Control outputs - RAM2
assign ctrl2_valid = ctrl2_valid_o;
assign ctrl2_data = ctrl2_data_o;

// Main FSM
always @(*) begin
    // Default assignments
    state_d = state_q;
    ax_req_id_d = ax_req_id_q;
    ax_req_addr_d = ax_req_addr_q;
    ax_req_len_d = ax_req_len_q;
    ax_req_size_d = ax_req_size_q;
    ax_req_burst_d = ax_req_burst_q;
    req_addr_d = req_addr_q;
    cnt_d = cnt_q;
    burst_cnt_d = burst_cnt_q;

    // AXI signals default
    aw_ready_o = 1'b0;
    ar_ready_o = 1'b0;
    w_ready_o = 1'b0;
    r_valid_o = 1'b0;
    r_resp_o = 2'b00; // OKAY
    r_last_o = 1'b0;
    b_valid_o = 1'b0;
    b_resp_o = 2'b00; // OKAY
    rdata_o = 64'h0;

    // BRAM1 signals default
    bram1_w_addr_o = 12'h0;
    bram1_w_din_o = 256'h0;
    bram1_w_en_o = 1'b0;
    bram1_w_we_o = 32'h0;
    bram1_r_addr_o = 12'h0;
    bram1_r_en_o = 1'b0;

    // BRAM2 signals default
    bram2_w_addr_o = 12'h0;
    bram2_w_din_o = 256'h0;
    bram2_w_en_o = 1'b0;
    bram2_w_we_o = 32'h0;
    bram2_r_addr_o = 12'h0;
    bram2_r_en_o = 1'b0;

    // Control signals default - RAM1
    ctrl_valid_o = 1'b0;
    ctrl_data_o = 32'h0;

    // Control signals default - RAM2
    ctrl2_valid_o = 1'b0;
    ctrl2_data_o = 32'h0;

    case (state_q)
        IDLE: begin
            // Wait for read or write request
            if (S_AXI_arvalid) begin
                ar_ready_o = 1'b1;
                // Sample AR channel
                ax_req_id_d = S_AXI_arid;
                ax_req_addr_d = S_AXI_araddr;
                ax_req_len_d = S_AXI_arlen;
                ax_req_size_d = S_AXI_arsize;
                ax_req_burst_d = S_AXI_arburst;
                state_d = READ_SETUP;
                req_addr_d = axi_addr_to_sram_word(align_to_256bit(S_AXI_araddr));
                cnt_d = 8'h0;
                burst_cnt_d = get_burst_position(S_AXI_araddr);  // Initialize based on address offset
            end else if (S_AXI_awvalid) begin
                aw_ready_o = 1'b1;
                // Sample AW channel
                ax_req_id_d = S_AXI_awid;
                ax_req_addr_d = S_AXI_awaddr;
                ax_req_len_d = S_AXI_awlen;
                ax_req_size_d = S_AXI_awsize;
                ax_req_burst_d = S_AXI_awburst;
                state_d = WRITE_SETUP;
                req_addr_d = axi_addr_to_sram_word(align_to_256bit(S_AXI_awaddr));
                cnt_d = 8'h0;
                burst_cnt_d = get_burst_position(S_AXI_awaddr);  // Initialize based on address offset
            end
        end

        READ_SETUP: begin
            // Prepare to read from BRAM based on address
            if (is_ram2(align_to_256bit(ax_req_addr_q))) begin
                // Access RAM2 read port
                bram2_r_en_o = 1'b1;
                bram2_r_addr_o = req_addr_d;
            end else begin
                // Access RAM1 read port
                bram1_r_en_o = 1'b1;
                bram1_r_addr_o = req_addr_d;
            end
            state_d = READ_COMMIT;
        end

        READ_COMMIT: begin
            // BRAM read data is available
            state_d = READ_BURST;
        end

        READ_BURST: begin
            // Send AXI read data (64-bit chunks from 256-bit BRAM data)
            r_valid_o = 1'b1;

            // Select data from appropriate BRAM
            if (is_ram2(align_to_256bit(ax_req_addr_q))) begin
                // Read from RAM2
                case (burst_cnt_q)
                    2'b00: rdata_o = bram2_r_dout[63:0];
                    2'b01: rdata_o = bram2_r_dout[127:64];
                    2'b10: rdata_o = bram2_r_dout[191:128];
                    2'b11: rdata_o = bram2_r_dout[255:192];
                endcase
            end else begin
                // Read from RAM1
                case (burst_cnt_q)
                    2'b00: rdata_o = bram1_r_dout[63:0];
                    2'b01: rdata_o = bram1_r_dout[127:64];
                    2'b10: rdata_o = bram1_r_dout[191:128];
                    2'b11: rdata_o = bram1_r_dout[255:192];
                endcase
            end

            r_last_o = (cnt_q == ax_req_len_q);

            if (S_AXI_rready) begin
                if (r_last_o) begin
                    state_d = IDLE;
                end else begin
                    // Check if we need next 256-bit word
                    if (burst_cnt_q == 2'b11) begin
                        // Need next 256-bit word
                        req_addr_d = req_addr_q + 12'd1;   // Next SRAM word address
                        burst_cnt_d = 2'b00;
                        state_d = READ_SETUP;
                    end else begin
                        burst_cnt_d = burst_cnt_q + 1'b1;
                    end
                    cnt_d = cnt_q + 1'b1;
                end
            end
        end

        WRITE_SETUP: begin
            // Wait for write data
            w_ready_o = 1'b1;
            if (S_AXI_wvalid) begin
                // Check if this is a control register write (address 0xF_0000)
                if (ax_req_addr_q == 20'hF_0000) begin
                    // This is a control register write for dual RAM switching
                    // bit[0] controls RAM1, bit[1] controls RAM2
                    ctrl_valid_o = 1'b1;
                    ctrl_data_o = {31'h0, S_AXI_wdata[0]};   // bit[0] for RAM1 control

                    ctrl2_valid_o = 1'b1;
                    ctrl2_data_o = {31'h0, S_AXI_wdata[1]};  // bit[1] for RAM2 control

                    state_d = SEND_B;  // Skip BRAM write, go directly to response
                end else begin
                    // Normal BRAM write
                    // Store write data in buffer
                    write_buffer[burst_cnt_q] = S_AXI_wdata;
                    wstrb_buffer[burst_cnt_q] = S_AXI_wstrb;

                    if (burst_cnt_q == 2'b11) begin
                        // Buffer full (4 x 64-bit = 256-bit), commit to BRAM
                        state_d = WRITE_COMMIT;
                    end else if (S_AXI_wlast) begin
                        // Last beat but buffer not full, still need to commit partial data
                        state_d = WRITE_COMMIT;
                    end else begin
                        // Continue receiving data
                        burst_cnt_d = burst_cnt_q + 1'b1;
                        cnt_d = cnt_q + 1'b1;
                    end
                end
            end
        end

        WRITE_COMMIT: begin
            // Write to appropriate BRAM based on address
            if (is_ram2(align_to_256bit(ax_req_addr_q))) begin
                // Write to RAM2 write port
                bram2_w_en_o = 1'b1;
                bram2_w_addr_o = req_addr_d;
                bram2_w_din_o = {write_buffer[3], write_buffer[2], write_buffer[1], write_buffer[0]};
                bram2_w_we_o = axi_wstrb_to_bram_we(wstrb_buffer[0], 2'b00) |
                              axi_wstrb_to_bram_we(wstrb_buffer[1], 2'b01) |
                              axi_wstrb_to_bram_we(wstrb_buffer[2], 2'b10) |
                              axi_wstrb_to_bram_we(wstrb_buffer[3], 2'b11);
            end else begin
                // Write to RAM1 write port
                bram1_w_en_o = 1'b1;
                bram1_w_addr_o = req_addr_d;
                bram1_w_din_o = {write_buffer[3], write_buffer[2], write_buffer[1], write_buffer[0]};
                bram1_w_we_o = axi_wstrb_to_bram_we(wstrb_buffer[0], 2'b00) |
                              axi_wstrb_to_bram_we(wstrb_buffer[1], 2'b01) |
                              axi_wstrb_to_bram_we(wstrb_buffer[2], 2'b10) |
                              axi_wstrb_to_bram_we(wstrb_buffer[3], 2'b11);
            end

            if (S_AXI_wlast) begin
                // This is the last BRAM write operation
                state_d = SEND_B;
            end else begin
                // More data coming, prepare for next 256-bit write
                req_addr_d = req_addr_q + 12'd1;  // Next BRAM word address
                burst_cnt_d = 2'b00;              // Reset burst counter for next 4 chunks
                state_d = WRITE_SETUP;            // Continue receiving data
            end
        end

        SEND_B: begin
            b_valid_o = 1'b1;
            if (S_AXI_bready) begin
                state_d = IDLE;
            end
        end

        default: state_d = IDLE;
    endcase
end

// Sequential logic
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (~s_axi_aresetn) begin
        state_q <= IDLE;
        ax_req_id_q <= 6'h0;
        ax_req_addr_q <= 20'h0;
        ax_req_len_q <= 8'h0;
        ax_req_size_q <= 3'h0;
        ax_req_burst_q <= 2'h0;
        req_addr_q <= 12'h0;
        cnt_q <= 8'h0;
        burst_cnt_q <= 2'b0;
    end else begin
        state_q <= state_d;
        ax_req_id_q <= ax_req_id_d;
        ax_req_addr_q <= ax_req_addr_d;
        ax_req_len_q <= ax_req_len_d;
        ax_req_size_d <= ax_req_size_d;
        ax_req_burst_q <= ax_req_burst_d;
        req_addr_q <= req_addr_d;
        cnt_q <= cnt_d;
        burst_cnt_q <= burst_cnt_d;
    end
end

endmodule
