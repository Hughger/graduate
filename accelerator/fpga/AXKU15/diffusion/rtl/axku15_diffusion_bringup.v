// AXKU15 board bring-up top.  This deliberately has no DDR4 port: it is the
// first bitstream used to validate JTAG, the 200 MHz logic clock, reset and LEDs.
module axku15_diffusion_bringup (
    input  wire sys_clk_p,
    input  wire sys_clk_n,
    input  wire reset_n,
    output wire [3:0] led
);
    wire sys_clk;
    reg [27:0] counter = 28'd0;

    IBUFDS #(.IOSTANDARD("DIFF_SSTL12")) sysclk_ibuf (
        .I(sys_clk_p), .IB(sys_clk_n), .O(sys_clk)
    );

    always @(posedge sys_clk) begin
        if (!reset_n)
            counter <= 28'd0;
        else
            counter <= counter + 28'd1;
    end

    // LED1 pulses at about 0.75 Hz at 200 MHz; the remaining LEDs identify
    // that configuration completed and that reset has been released.
    assign led[0] = counter[27];
    assign led[1] = 1'b1;
    assign led[2] = reset_n;
    assign led[3] = counter[26];
endmodule
