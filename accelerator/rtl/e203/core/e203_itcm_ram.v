 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
// Designer   : Bob Hu
//
// Description:
//  The ITCM-SRAM module to implement ITCM SRAM
//  Modified to support program initialization
//
// ====================================================================

`include "e203_defines.v"

// FPGA特定宏定义 - 启用程序自动加载功能
`define FPGA_SOURCE

  `ifdef E203_HAS_ITCM //{
module e203_itcm_ram(

  input                              sd,
  input                              ds,
  input                              ls,

  input                              cs,  
  input                              we,  
  input  [`E203_ITCM_RAM_AW-1:0] addr, 
  input  [`E203_ITCM_RAM_MW-1:0] wem,
  input  [`E203_ITCM_RAM_DW-1:0] din,          
  output [`E203_ITCM_RAM_DW-1:0] dout,
  input                              rst_n,
  input                              clk

);


`ifdef FPGA_SOURCE
    // FPGA实现：使用Block RAM with 初始化
    // 内存数组定义
    reg [`E203_ITCM_RAM_DW-1:0] mem_r [0:`E203_ITCM_RAM_DP-1];
    reg [`E203_ITCM_RAM_AW-1:0] addr_r;
    
    // 初始化程序到ITCM
    integer init_i;  // 预声明循环变量
    initial begin
`ifdef ITCM_PRELOAD_HEX
        $display("ITCM: Initializing memory (with internal preload)...");
        // 清零整个ITCM（仅当内部预加载启用时）
        for (init_i = 0; init_i < `E203_ITCM_RAM_DP; init_i = init_i + 1) begin
            mem_r[init_i] = 64'h0;
        end
        // 直接加载程序到 ITCM
        $readmemh("F:/Flood/flood_accelerator_jtag/c/apb_test/jtag_test.hex", mem_r);
        $display("ITCM: Preloaded program into ITCM (via $readmemh)");
        
        // 显示加载的前几个地址内容
        $display("ITCM[0] = 0x%016x", mem_r[0]);
        $display("ITCM[1] = 0x%016x", mem_r[1]);
        $display("ITCM[2] = 0x%016x", mem_r[2]);
        $display("ITCM[3] = 0x%016x", mem_r[3]);
`else
        $display("ITCM: No internal preload. Expecting testbench to load ITCM.");
`endif
    end
    
    // 读地址寄存器
    always @(posedge clk) begin
        if (cs && !we) begin
            addr_r <= addr;
        end
    end
    
    // 写操作
    genvar i;
    generate
        for (i = 0; i < `E203_ITCM_RAM_MW; i = i+1) begin : mem_write
            always @(posedge clk) begin
                if (cs && we && wem[i]) begin
                    if ((8*i+8) > `E203_ITCM_RAM_DW) begin
                        mem_r[addr][`E203_ITCM_RAM_DW-1:8*i] <= din[`E203_ITCM_RAM_DW-1:8*i];
                    end
                    else begin
                        mem_r[addr][8*i+7:8*i] <= din[8*i+7:8*i];
                    end
                end
            end
        end
    endgenerate
    
    // 读输出
    assign dout = mem_r[addr_r];
    
`else 
  // 仿真模式：使用原始模块
  sirv_gnrl_ram #(
      `ifndef E203_HAS_ECC//{
    .FORCE_X2ZERO(0),
      `endif//}
    .DP(`E203_ITCM_RAM_DP),
    .DW(`E203_ITCM_RAM_DW),
    .MW(`E203_ITCM_RAM_MW),
    .AW(`E203_ITCM_RAM_AW) 
  ) u_e203_itcm_gnrl_ram(
  .sd  (sd  ),
  .ds  (ds  ),
  .ls  (ls  ),

  .rst_n (rst_n ),
  .clk (clk ),
  .cs  (cs  ),
  .we  (we  ),
  .addr(addr),
  .din (din ),
  .wem (wem ),
  .dout(dout)
  );
`endif
                                                      
endmodule
  `endif//}
