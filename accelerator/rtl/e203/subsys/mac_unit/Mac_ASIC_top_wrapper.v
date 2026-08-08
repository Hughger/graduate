module Mac_ASIC_top_wrapper(
    input  clk,
    input  rst_n,
    inout  [63:0] dinout,
    input  [15:0] addr,
    input  en,
    input  wr_en,
    // Interrupt outputs from MacMachine
    output wire macMachineDone_interrupt,
    output wire macMachineerror_interrupt
);  

    // 双向数据总线
    wire [63:0] din;
    wire [63:0] dout;
    // 地址总线
    wire [15:0] addr_in;
    // 使能信号
    wire en_in;
    // 读写使能信号
    wire wr_en_in;
    // 中断信号
    wire macMachineDone_interrupt_out;
    wire macMachineerror_interrupt_out;
    // 时钟信号
    wire clk_in;
    // 复位信号
    wire rst_n_in;

    
    //bidirectional pad
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : gen_pads
            PDDW08SDGZ_H_G u_pad (
                .I   (dout[i]),
                .OEN (wr_en),
                .REN (1'b1),
                .PAD (dinout[i]),
                .C   (din[i])
            );
        end
    endgenerate

    // 请在这里基于3态门的纯输入实现，为addr信号创建PAD并连线
    genvar j;
    generate
        for (j = 0; j < 16; j = j + 1) begin : gen_addr_pads
            PDDW08SDGZ_H_G u_pad (
                .I   (),
                .OEN (1'b1),
                .REN (1'b1),
                .PAD (addr[j]),
                .C   (addr_in[j])
            );
        end
    endgenerate

    // 请在这里基于3态门的纯输入实现，为en信号创建PAD并连线
    PDDW08SDGZ_H_G u_pad_en (
                .I   (),
                .OEN (1'b1),
                .REN (1'b1),
                .PAD (en),
                .C   (en_in)
            );
    // 请在这里基于3态门的纯输入实现，为wr_en信号创建PAD并连线
    PDDW08SDGZ_H_G u_pad_wr (
                .I   (),
                .OEN (1'b1),
                .REN (1'b1),
                .PAD (wr_en),
                .C   (wr_en_in)
            );
    
    // 请在这里基于3态门的纯输出实现，为macMachineDone_interrupt信号创建PAD并连线
    PDDW08SDGZ_H_G u_pad_macMachineDone_interrupt (
                .I   (macMachineDone_interrupt_out),
                .OEN (1'b0),
                .REN (1'b1),
                .PAD (macMachineDone_interrupt),
                .C   ()
            );
    // 请在这里基于3态门的纯输出实现，为macMachineerror_interrupt信号创建PAD并连线
    PDDW08SDGZ_H_G u_pad_macMachineerror_interrupt (
                .I   (macMachineerror_interrupt_out),
                .OEN (1'b0),
                .REN (1'b1),
                .PAD (macMachineerror_interrupt),
                .C   ()
            );

    // 请在这里连接CLK到PAD
    PDXOEDG_H_G u_pad_clk (
                .E   (1'b1),
                .DS0 (1'b0),
                .DS1 (1'b0),
                .XIN (clk),
                .XOUT (),
                .XC   (clk_in)
            );
    // 请在这里基于3态门的纯输入实现，为rst_n信号创建PAD并连线
    PDDW08SDGZ_H_G u_pad_rst_n (
                .I   (),
                .OEN (1'b1),
                .REN (1'b1),
                .PAD (rst_n),
                .C   (rst_n_in)
            );

    Mac_ASIC_top u_mac_asic_top(
        .clk(clk_in),
        .rst_n(rst_n_in),
        .din(din),
        .dout(dout),
        .addr(addr_in),
        .en(en_in),
        .wr_en(wr_en_in),
        .macMachineDone_interrupt(macMachineDone_interrupt_out),
        .macMachineerror_interrupt(macMachineerror_interrupt_out)
    );

endmodule