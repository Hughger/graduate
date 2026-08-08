//Copyright 2024 - AXI to BRAM Bridge (1MB)
//Based on axi2mem.sv from PULP Platform
//Modified for traditional Verilog and BRAM interface
//--------------------------------------------------------------------------------

module axi2bram1mb_asic (
    // AXI Clock and Reset
    input wire s_axi_aclk_0,
    input wire s_axi_aresetn_0,
    
    // AXI Read Address Channel
    input  wire [19:0] S_AXI_0_araddr,
    input  wire [1:0]  S_AXI_0_arburst,
    input  wire [3:0]  S_AXI_0_arcache,
    input  wire [5:0]  S_AXI_0_arid,
    input  wire [7:0]  S_AXI_0_arlen,
    input  wire        S_AXI_0_arlock,
    input  wire [2:0]  S_AXI_0_arprot,
    output wire        S_AXI_0_arready,
    input  wire [2:0]  S_AXI_0_arsize,
    input  wire        S_AXI_0_arvalid,
    
    // AXI Write Address Channel
    input  wire [19:0] S_AXI_0_awaddr,
    input  wire [1:0]  S_AXI_0_awburst,
    input  wire [3:0]  S_AXI_0_awcache,
    input  wire [5:0]  S_AXI_0_awid,
    input  wire [7:0]  S_AXI_0_awlen,
    input  wire        S_AXI_0_awlock,
    input  wire [2:0]  S_AXI_0_awprot,
    output wire        S_AXI_0_awready,
    input  wire [2:0]  S_AXI_0_awsize,
    input  wire        S_AXI_0_awvalid,
    
    // AXI Write Data Channel
    input  wire [63:0] S_AXI_0_wdata,
    input  wire        S_AXI_0_wlast,
    output wire        S_AXI_0_wready,
    input  wire [7:0]  S_AXI_0_wstrb,
    input  wire        S_AXI_0_wvalid,
    
    // AXI Write Response Channel
    output wire [5:0]  S_AXI_0_bid,
    input  wire        S_AXI_0_bready,
    output wire [1:0]  S_AXI_0_bresp,
    output wire        S_AXI_0_bvalid,
    
    // AXI Read Data Channel
    output wire [63:0] S_AXI_0_rdata,
    output wire [5:0]  S_AXI_0_rid,
    output wire        S_AXI_0_rlast,
    input  wire        S_AXI_0_rready,
    output wire [1:0]  S_AXI_0_rresp,
    output wire        S_AXI_0_rvalid,
    
    // BRAM Interface
    output wire [13:0] BRAM_PORTA_0_addr,
    output wire        BRAM_PORTA_0_clk,
    output wire [63:0] BRAM_PORTA_0_din,
    input  wire [63:0] BRAM_PORTA_0_dout,
    output wire        BRAM_PORTA_0_en,
    output wire        BRAM_PORTA_0_rst,
    output wire [7:0]  BRAM_PORTA_0_we
);

    // Parameters for AXI configuration
    localparam AXI_ID_WIDTH = 6;
    localparam AXI_ADDR_WIDTH = 20;
    localparam AXI_DATA_WIDTH = 64;
    localparam BRAM_ADDR_WIDTH = 14; // BRAM address width (word aligned)
    localparam LOG_NR_BYTES = 3; // $clog2(64/8) = 3

    // AXI Burst Types
    localparam [1:0] FIXED = 2'b00;
    localparam [1:0] INCR  = 2'b01;
    localparam [1:0] WRAP  = 2'b10;

    // State Machine States
    localparam [2:0] IDLE        = 3'b000;
    localparam [2:0] READ        = 3'b001;
    localparam [2:0] WRITE       = 3'b010;
    localparam [2:0] SEND_B      = 3'b011;
    localparam [2:0] WAIT_WVALID = 3'b100;

    // Internal registers
    reg [2:0] state_q, state_d;
    reg [5:0] ax_req_id_q, ax_req_id_d;
    reg [20:0] ax_req_addr_q, ax_req_addr_d;
    reg [7:0] ax_req_len_q, ax_req_len_d;
    reg [2:0] ax_req_size_q, ax_req_size_d;
    reg [1:0] ax_req_burst_q, ax_req_burst_d;
    reg [20:0] req_addr_q, req_addr_d;
    reg [7:0] cnt_q, cnt_d;

    // Internal signals
    wire [20:0] aligned_address;
    wire [20:0] wrap_boundary;
    wire [20:0] upper_wrap_boundary;
    wire [20:0] cons_addr;
    reg req_o, we_o;
    reg [20:0] addr_o;

    // BRAM Clock and Reset passthrough
    assign BRAM_PORTA_0_clk = s_axi_aclk_0;
    assign BRAM_PORTA_0_rst = ~s_axi_aresetn_0;

    // Address generation logic
    assign aligned_address = {ax_req_addr_q[20:3], 3'b000};
    assign cons_addr = aligned_address + (cnt_q << LOG_NR_BYTES);

    // Wrap boundary calculation (simplified for common cases)
    assign wrap_boundary = get_wrap_boundary(ax_req_addr_q, ax_req_len_q);
    assign upper_wrap_boundary = wrap_boundary + ((ax_req_len_q + 1) << LOG_NR_BYTES);

    // Wrap boundary function
    function [20:0] get_wrap_boundary;
        input [20:0] unaligned_address;
        input [7:0] len;
        begin
            get_wrap_boundary = 21'h0;
            if (len == 8'h01)
                get_wrap_boundary = {unaligned_address[20:4], 4'h0};
            else if (len == 8'h03)
                get_wrap_boundary = {unaligned_address[20:5], 5'h0};
            else if (len == 8'h07)
                get_wrap_boundary = {unaligned_address[20:6], 6'h0};
            else if (len == 8'h0F)
                get_wrap_boundary = {unaligned_address[20:7], 7'h0};
        end
    endfunction

    // BRAM Interface outputs
    // Convert 20-bit AXI address to 14-bit BRAM word address (word aligned)
    // For 64-bit data width, byte address to word address conversion: addr_word = addr_byte >> 3
    // So BRAM word address = addr_o[16:3] (take bits 16 down to 3 from byte address)
    assign BRAM_PORTA_0_addr = addr_o[16:3];  // Convert 20-bit AXI address to 14-bit BRAM word address
    assign BRAM_PORTA_0_din = S_AXI_0_wdata;
    assign BRAM_PORTA_0_en = req_o;
    assign BRAM_PORTA_0_we = we_o ? S_AXI_0_wstrb : 8'h00;

    // AXI outputs
    reg aw_ready, ar_ready, w_ready;
    reg r_valid, r_last, b_valid;
    reg [1:0] r_resp, b_resp;

    assign S_AXI_0_awready = aw_ready;
    assign S_AXI_0_arready = ar_ready;
    assign S_AXI_0_wready = w_ready;
    assign S_AXI_0_rvalid = r_valid;
    assign S_AXI_0_rdata = BRAM_PORTA_0_dout;
    assign S_AXI_0_rresp = r_resp;
    assign S_AXI_0_rlast = r_last;
    assign S_AXI_0_rid = ax_req_id_q;
    assign S_AXI_0_bvalid = b_valid;
    assign S_AXI_0_bresp = b_resp;
    assign S_AXI_0_bid = ax_req_id_q;

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
        
        // Control signals default
        req_o = 1'b0;
        we_o = 1'b0;
        addr_o = 20'h0;
        
        // AXI signals default
        aw_ready = 1'b0;
        ar_ready = 1'b0;
        w_ready = 1'b0;
        r_valid = 1'b0;
        r_resp = 2'b00; // OKAY
        r_last = 1'b0;
        b_valid = 1'b0;
        b_resp = 2'b00; // OKAY

        case (state_q)
            IDLE: begin
                // Wait for read or write request
                if (S_AXI_0_arvalid) begin
                    ar_ready = 1'b1;
                    // Sample AR channel
                    ax_req_id_d = S_AXI_0_arid;
                    ax_req_addr_d = S_AXI_0_araddr;
                    ax_req_len_d = S_AXI_0_arlen;
                    ax_req_size_d = S_AXI_0_arsize;
                    ax_req_burst_d = S_AXI_0_arburst;
                    state_d = READ;
                    // Start first read
                    req_o = 1'b1;
                    addr_o = S_AXI_0_araddr;
                    req_addr_d = S_AXI_0_araddr;
                    cnt_d = 8'h01;
                end else if (S_AXI_0_awvalid) begin
                    aw_ready = 1'b1;
                    w_ready = 1'b1;
                    addr_o = S_AXI_0_awaddr;
                    // Sample AW channel
                    ax_req_id_d = S_AXI_0_awid;
                    ax_req_addr_d = S_AXI_0_awaddr;
                    ax_req_len_d = S_AXI_0_awlen;
                    ax_req_size_d = S_AXI_0_awsize;
                    ax_req_burst_d = S_AXI_0_awburst;
                    
                    if (S_AXI_0_wvalid) begin
                        req_o = 1'b1;
                        we_o = 1'b1;
                        state_d = (S_AXI_0_wlast) ? SEND_B : WRITE;
                        cnt_d = 8'h01;
                    end else begin
                        state_d = WAIT_WVALID;
                    end
                end
            end

            WAIT_WVALID: begin
                w_ready = 1'b1;
                addr_o = ax_req_addr_q;
                if (S_AXI_0_wvalid) begin
                    req_o = 1'b1;
                    we_o = 1'b1;
                    state_d = (S_AXI_0_wlast) ? SEND_B : WRITE;
                    cnt_d = 8'h01;
                end
            end

            READ: begin
                req_o = 1'b1;
                addr_o = req_addr_q;
                r_valid = 1'b1;
                r_last = (cnt_q == ax_req_len_q + 1);

                if (S_AXI_0_rready) begin
                    // Address generation for next beat
                    case (ax_req_burst_q)
                        FIXED, INCR: addr_o = cons_addr;
                        WRAP: begin
                            if (cons_addr == upper_wrap_boundary) begin
                                addr_o = wrap_boundary;
                            end else if (cons_addr > upper_wrap_boundary) begin
                                addr_o = ax_req_addr_q + ((cnt_q - ax_req_len_q) << LOG_NR_BYTES);
                            end else begin
                                addr_o = cons_addr;
                            end
                        end
                    endcase

                    if (r_last) begin
                        state_d = IDLE;
                        req_o = 1'b0;
                    end
                    req_addr_d = addr_o;
                    cnt_d = cnt_q + 1;
                end
            end

            WRITE: begin
                w_ready = 1'b1;

                if (S_AXI_0_wvalid) begin
                    req_o = 1'b1;
                    we_o = 1'b1;
                    
                    // Address generation for next beat
                    case (ax_req_burst_q)
                        FIXED, INCR: addr_o = cons_addr;
                        WRAP: begin
                            if (cons_addr == upper_wrap_boundary) begin
                                addr_o = wrap_boundary;
                            end else if (cons_addr > upper_wrap_boundary) begin
                                addr_o = ax_req_addr_q + ((cnt_q - ax_req_len_q) << LOG_NR_BYTES);
                            end else begin
                                addr_o = cons_addr;
                            end
                        end
                    endcase

                    req_addr_d = addr_o;
                    cnt_d = cnt_q + 1;

                    if (S_AXI_0_wlast)
                        state_d = SEND_B;
                end
            end

            SEND_B: begin
                b_valid = 1'b1;
                if (S_AXI_0_bready)
                    state_d = IDLE;
            end

            default: state_d = IDLE;
        endcase
    end

    // Sequential logic
    always @(posedge s_axi_aclk_0 or negedge s_axi_aresetn_0) begin
        if (~s_axi_aresetn_0) begin
            state_q <= IDLE;
            ax_req_id_q <= 6'h0;
            ax_req_addr_q <= 20'h0;
            ax_req_len_q <= 8'h0;
            ax_req_size_q <= 3'h0;
            ax_req_burst_q <= 2'h0;
            req_addr_q <= 20'h0;
            cnt_q <= 8'h0;
        end else begin
            state_q <= state_d;
            ax_req_id_q <= ax_req_id_d;
            ax_req_addr_q <= ax_req_addr_d;
            ax_req_len_q <= ax_req_len_d;
            ax_req_size_q <= ax_req_size_d;
            ax_req_burst_q <= ax_req_burst_d;
            req_addr_q <= req_addr_d;
            cnt_q <= cnt_d;
        end
    end

endmodule
