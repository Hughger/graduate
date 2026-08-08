module b64_b256 (
    input clk,
    input rst_n,

    // mux interface
    input [63:0] w_data,
    input [12:0] w_addr,
    input en,
    input we,
    input [12:0] r_addr,
    output [63:0] r_data,

    // bram interface
    output reg [10:0] bram_w_addr,
    output reg [255:0] bram_w_data,
    output reg bram_w_en,
    output reg [31:0] bram_w_we, // 32位字节使能，要么全0要么全F
    output [10:0] bram_r_addr,
    input [255:0] bram_r_data,
    output bram_r_en
);

// 内部信号定义
reg [1:0] cnt; // 计数器，0-3，对应4个64bit数据
reg [255:0] data_buffer; // 256bit数据缓冲区
reg write_done; // 写完成标志
reg [12:0] w_addr_reg; // 保存上一轮的写地址
reg [12:0] r_addr_reg; // 保存上一拍的读地址
reg [12:0] r_addr_reg_d; // 打一拍

// 读数据直接从BRAM输出，根据打拍后的r_addr的低2位选择对应的64bit段
assign r_data = bram_r_data[r_addr_reg_d[1:0]*64 +: 64];

// 计数器逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 2'b0;
        write_done <= 1'b0;
    end else if (en && we) begin
        if (cnt == 2'd3) begin
            cnt <= 2'b0; // 计数器清零，开始下一轮
            write_done <= 1'b1; // 标记写完成
        end else begin
            cnt <= cnt + 1'b1;
            write_done <= 1'b0;
        end
    end else begin
        write_done <= 1'b0;
    end
end

// 地址寄存器逻辑 - 保存上一轮的写地址
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_addr_reg <= 13'b0;
    end else if (en && we) begin
        w_addr_reg <= w_addr;
    end
end

// 读地址寄存器逻辑 - 保存上一拍的读地址
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_addr_reg <= 13'b0;
    end else begin
        r_addr_reg <= r_addr;
    end
end

always @(posedge clk or negedge rst_n) begin // 打一拍
    if (!rst_n) begin
        r_addr_reg_d <= 13'b0;
    end else begin
        r_addr_reg_d <= r_addr_reg;
    end
end

// 数据缓冲区逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_buffer <= 256'b0;
    end else if (en && we) begin
        // 根据计数器将64bit数据写入到256bit缓冲区的对应位置
        case (cnt)
            2'd0: data_buffer[63:0] <= w_data;
            2'd1: data_buffer[127:64] <= w_data;
            2'd2: data_buffer[191:128] <= w_data;
            2'd3: data_buffer[255:192] <= w_data;
        endcase
    end
end

// BRAM写地址逻辑 - 使用保存的地址以避免时序问题
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bram_w_addr <= 11'b0;
    end else begin
        bram_w_addr <= w_addr_reg[12:2];
    end
end

// BRAM写数据逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bram_w_data <= 256'b0;
    end else if (write_done) begin
        bram_w_data <= data_buffer;
    end
end

// BRAM写使能逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bram_w_en <= 1'b0;
        bram_w_we <= 32'h00000000;
    end else begin
        bram_w_en <= write_done;
        bram_w_we <= write_done ? 32'hFFFFFFFF : 32'h00000000;
    end
end

// BRAM读地址逻辑（直接组合逻辑赋值）
assign bram_r_addr = r_addr[12:2]; // 地址需要除以4，因为256bit对应4个64bit地址

// BRAM读使能 - 直接组合逻辑赋值
assign bram_r_en = en && !we;

endmodule