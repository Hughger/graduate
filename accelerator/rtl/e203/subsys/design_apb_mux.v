// -----------------------------------------------------------------------------
// APB MUX for 3 peripherals, APB2.0
// Author: zhao yi
// Date: 2025/06/19
// -----------------------------------------------------------------------------

module design_apb_mux #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    //定义3个端口的使能信号，默认为1，保证每个slave端口信号能够输入
    parameter PORT0_ENABLE = 1,
    parameter PORT1_ENABLE = 1,
    parameter PORT2_ENABLE = 1
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

    //APB Slave Interface 0
    output wire [ADDR_WIDTH-1:0]   paddr0,
    output wire                    pwrite0,
    output wire                    pselx0,
    output wire                    penable0,
    output wire [DATA_WIDTH-1:0]   pwdata0,
    input  wire [DATA_WIDTH-1:0]   prdata0,

    //APB Slave Interface 1
    output wire [ADDR_WIDTH-1:0]   paddr1,
    output wire                    pwrite1,
    output wire                    pselx1,
    output wire                    penable1,
    output wire  [DATA_WIDTH-1:0]   pwdata1,
    input  wire [DATA_WIDTH-1:0]   prdata1,

    //APB Slave Interface 2
    output wire  [ADDR_WIDTH-1:0]   paddr2,
    output wire                    pwrite2,
    output wire                    pselx2,
    output wire                    penable2,
    output wire  [DATA_WIDTH-1:0]   pwdata2,
    input  wire [DATA_WIDTH-1:0]   prdata2
);

    // 产生使能信号，对应端口使能，默认1
    wire [2:0] en = {(PORT2_ENABLE == 1),(PORT1_ENABLE == 1),(PORT0_ENABLE == 1)};

    // 根据paddr的位进行译码选择不同的slave
    // * slave 0       : 0x0040 0000 -- 0x0040 1FFF
    // * slave 1       : 0x0041 0000 -- 0x0041 1FFF
    // * slave 2       : 0x0042 0000 -- 0x0042 1FFF
    wire [3:0] decode4BIT;
    assign decode4BIT = paddr[19:16];

    // 产生译码信号 。对应decode4bit编码值与相应的slave编码值一致
    wire [2:0] dec = {(decode4BIT == 4'd2),(decode4BIT == 4'd1),(decode4BIT == 4'd0)};

    // paddr,pwrite,penable,pwdata直接由master给到slave
    assign paddr0   = paddr;
    assign pwrite0  = pwrite;
    assign penable0 = penable;
    assign pwdata0  = pwdata;

    assign paddr1   = paddr;
    assign pwrite1  = pwrite;
    assign penable1 = penable;
    assign pwdata1  = pwdata;

    assign paddr2   = paddr;
    assign pwrite2  = pwrite;
    assign penable2 = penable;
    assign pwdata2  = pwdata;

    //pselx信号由psel、en、dec信号共同决定
    assign pselx0 = pselx & en[0] & dec[0];
    assign pselx1 = pselx & en[1] & dec[1];
    assign pselx2 = pselx & en[2] & dec[2];

    // 组合逻辑选择信号
    always @(*) begin
        if (pselx0 && penable && !pwrite)
            prdata = prdata0;
        else if (pselx1 && penable && !pwrite)
            prdata = prdata1;
        else if (pselx2 && penable && !pwrite)
            prdata = prdata2;
        else
            prdata = {DATA_WIDTH{1'b0}};
    end

endmodule