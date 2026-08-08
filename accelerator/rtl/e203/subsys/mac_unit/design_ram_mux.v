// Project: Flood
// Author: Zhao Yi
// Date: 2025-09-16
// Description: RAM MUX for 6 RAMs
//--------------------------------------------------------------------------------

module design_ram_mux(
    // axi2bram_asic Interface
    input  wire        BRAM_PORTA_0_clk,
    input  wire        BRAM_PORTA_0_rstn,
    input  wire [15:0] BRAM_PORTA_0_addr,
    input  wire [63:0] BRAM_PORTA_0_din,
    output wire [63:0] BRAM_PORTA_0_dout,
    // inout  wire [63:0] BRAM_PORTA_0_dinout, 
    input  wire        BRAM_PORTA_0_en,     
    input  wire        BRAM_PORTA_0_we,     

    // axi2bram_64k Interface(6 Slave, only 2-5 are readable)
    output reg  [5 :0] RAM_sel,
    input  wire [63:0] RAM_2_rdata,
    input  wire [63:0] RAM_3_rdata,
    input  wire [63:0] RAM_4_rdata,
    input  wire [63:0] RAM_5_rdata,
    output wire [63:0] RAM_wdata,
    output wire        RAM_wen,
    output wire        RAM_we,
    output wire        RAM_ren,
    output wire [12:0] RAM_waddr,
    output wire [12:0] RAM_raddr,

    // Control signals for RAM switches (0x5006_0000)
    output wire        ram2_ctrl_valid,
    output wire [31:0] ram2_ctrl_data,
    output wire        ram3_ctrl_valid,
    output wire [31:0] ram3_ctrl_data,
    output wire        ram4_ctrl_valid,
    output wire [31:0] ram4_ctrl_data,
    output wire        ram5_ctrl_valid,
    output wire [31:0] ram5_ctrl_data
);

    // Delayed enable signals for synchronous BRAM timing
    reg BRAM_en_delayed;
    reg BRAM_we_delayed;
    reg BRAM_en_delayed_d;
    reg BRAM_we_delayed_d;

    assign RAM_wen = BRAM_PORTA_0_en && BRAM_PORTA_0_we;
    assign RAM_ren = BRAM_PORTA_0_en && !BRAM_PORTA_0_we;
    assign RAM_we = BRAM_PORTA_0_we;
    assign RAM_waddr = BRAM_PORTA_0_addr[12:0];
    assign RAM_raddr = BRAM_PORTA_0_addr[12:0];

    // Delay BRAM control signals to match synchronous BRAM timing
    always @(posedge BRAM_PORTA_0_clk or negedge BRAM_PORTA_0_rstn) begin
        if (!BRAM_PORTA_0_rstn) begin
            BRAM_en_delayed <= 1'b0;
            BRAM_we_delayed <= 1'b0;
            BRAM_en_delayed_d <= 1'b0;
            BRAM_we_delayed_d <= 1'b0;
        end else begin
            BRAM_en_delayed <= BRAM_PORTA_0_en;
            BRAM_we_delayed <= BRAM_PORTA_0_we;
            BRAM_en_delayed_d <= BRAM_en_delayed;
            BRAM_we_delayed_d <= BRAM_we_delayed;
        end
    end
    
    // according to the BRAM_PORTA_0_addr[15:13], select the ram
    // * RAM 0       : 0x5000 0000 -- 0x5000 FFFF
    // * RAM 1       : 0x5001 0000 -- 0x5001 FFFF
    // * RAM 2       : 0x5002 0000 -- 0x5002 FFFF
    // * RAM 3       : 0x5003 0000 -- 0x5003 FFFF
    // * RAM 4       : 0x5004 0000 -- 0x5004 FFFF
    // * RAM 5       : 0x5005 0000 -- 0x5005 FFFF
    // * CTRL Config : 0x5006 0000
    wire [2:0] decode3BIT;
    assign decode3BIT = BRAM_PORTA_0_addr[15:13];
    always @(*) begin
        case(decode3BIT)
            3'b000:  RAM_sel = 6'b000001;
            3'b001:  RAM_sel = 6'b000010;
            3'b010:  RAM_sel = 6'b000100;
            3'b011:  RAM_sel = 6'b001000;
            3'b100:  RAM_sel = 6'b010000;
            3'b101:  RAM_sel = 6'b100000;
            default: RAM_sel = 6'b000000;
        endcase
    end
    reg [5:0] RAM_sel_delayed;
    reg [5:0] RAM_sel_delayed_d;
    always @(posedge BRAM_PORTA_0_clk or negedge BRAM_PORTA_0_rstn) begin
        if (!BRAM_PORTA_0_rstn) begin
            RAM_sel_delayed <= 6'b000000;
            RAM_sel_delayed_d <= 6'b000000;
        end
        else begin
            RAM_sel_delayed <= RAM_sel;
            RAM_sel_delayed_d <= RAM_sel_delayed;
        end
    end

    // Control signal generation for 0x5006_0000 (decode3BIT = 3'b110)
    wire ctrl_addr_match;
    assign ctrl_addr_match = (decode3BIT == 3'b110) && BRAM_PORTA_0_en && BRAM_PORTA_0_we;

    // Extract 4 control bits from BRAM_PORTA_0_dinout[3:0]
    wire [3:0] ctrl_bits;
    // assign ctrl_bits = BRAM_PORTA_0_dinout[3:0];
    assign ctrl_bits = BRAM_PORTA_0_din[3:0];

    // Generate control signals for each RAM switch
    assign ram2_ctrl_valid = ctrl_addr_match;
    assign ram2_ctrl_data  = {31'b0, ctrl_bits[0]};  // bit 0 -> RAM2

    assign ram3_ctrl_valid = ctrl_addr_match;
    assign ram3_ctrl_data  = {31'b0, ctrl_bits[1]};  // bit 1 -> RAM3

    assign ram4_ctrl_valid = ctrl_addr_match;
    assign ram4_ctrl_data  = {31'b0, ctrl_bits[2]};  // bit 2 -> RAM4

    assign ram5_ctrl_valid = ctrl_addr_match;
    assign ram5_ctrl_data  = {31'b0, ctrl_bits[3]};  // bit 3 -> RAM5

    // according to the RAM_sel, mux the ram data
    // Use delayed signals to ensure data stability during synchronous BRAM timing
    reg [63:0] RAM_mux_rdata;
    always @(*) begin
        if (BRAM_en_delayed_d && !BRAM_we_delayed_d) begin  // read - use delayed signals
            case (RAM_sel_delayed_d)
                6'b000100: RAM_mux_rdata = RAM_2_rdata;
                6'b001000: RAM_mux_rdata = RAM_3_rdata;
                6'b010000: RAM_mux_rdata = RAM_4_rdata;
                6'b100000: RAM_mux_rdata = RAM_5_rdata;
                default:   RAM_mux_rdata = 64'h0;
            endcase
        end
        else begin
            RAM_mux_rdata = 64'h0;
        end
    end
    // assign BRAM_PORTA_0_dinout = (BRAM_en_delayed && !BRAM_we_delayed)? RAM_mux_rdata : 64'hz;
    assign BRAM_PORTA_0_dout = (BRAM_en_delayed_d && !BRAM_we_delayed_d)? RAM_mux_rdata : 64'h0;

    // according to the en&&we, output the ram_wdata
    reg [63:0] RAM_mux_wdata;
    assign RAM_wdata = RAM_mux_wdata;
    always @(*) begin
        if (BRAM_PORTA_0_en && BRAM_PORTA_0_we) begin   // write
            // RAM_mux_wdata = BRAM_PORTA_0_dinout;
            RAM_mux_wdata = BRAM_PORTA_0_din;
        end
        else begin
            RAM_mux_wdata = 64'h0;
        end
    end

endmodule