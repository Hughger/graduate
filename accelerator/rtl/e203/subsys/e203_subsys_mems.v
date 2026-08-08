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
//
// Designer   : Bob Hu
//
// Description:
//  The system memory bus and the ROM instance 
//
// ====================================================================


`include "e203_defines.v"


module e203_subsys_mems(
  input                          mem_icb_cmd_valid,
  output                         mem_icb_cmd_ready,
  input  [`E203_ADDR_SIZE-1:0]   mem_icb_cmd_addr, 
  input                          mem_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        mem_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      mem_icb_cmd_wmask,
  //
  output                         mem_icb_rsp_valid,
  input                          mem_icb_rsp_ready,
  output                         mem_icb_rsp_err,
  output [`E203_XLEN-1:0]        mem_icb_rsp_rdata,
  
  //////////////////////////////////////////////////////////
  // DMA interrupt outputs
  output                         dma_done_irq,           // DMA完成中断输出
  output                         dma_err_irq,            // DMA错误中断输出

  //////////////////////////////////////////////////////////
  // MAC interrupt outputs
  output                         mac_done_irq,           // MAC完成中断输出
  output                         mac_err_irq,            // MAC错误中断输出
  
  //////////////////////////////////////////////////////////
  output                         sysmem_icb_cmd_valid,
  input                          sysmem_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   sysmem_icb_cmd_addr, 
  output                         sysmem_icb_cmd_read, 
  output [`E203_XLEN-1:0]        sysmem_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      sysmem_icb_cmd_wmask,
  //
  input                          sysmem_icb_rsp_valid,
  output                         sysmem_icb_rsp_ready,
  input                          sysmem_icb_rsp_err,
  input  [`E203_XLEN-1:0]        sysmem_icb_rsp_rdata,

    //////////////////////////////////////////////////////////
  output                         qspi0_ro_icb_cmd_valid,
  input                          qspi0_ro_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   qspi0_ro_icb_cmd_addr, 
  output                         qspi0_ro_icb_cmd_read, 
  output [`E203_XLEN-1:0]        qspi0_ro_icb_cmd_wdata,
  //
  input                          qspi0_ro_icb_rsp_valid,
  output                         qspi0_ro_icb_rsp_ready,
  input                          qspi0_ro_icb_rsp_err,
  input  [`E203_XLEN-1:0]        qspi0_ro_icb_rsp_rdata,


    //////////////////////////////////////////////////////////
  output                         dm_icb_cmd_valid,
  input                          dm_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   dm_icb_cmd_addr, 
  output                         dm_icb_cmd_read, 
  output [`E203_XLEN-1:0]        dm_icb_cmd_wdata,
  //
  input                          dm_icb_rsp_valid,
  output                         dm_icb_rsp_ready,
  input  [`E203_XLEN-1:0]        dm_icb_rsp_rdata,

  input  clk,
  input  bus_rst_n,
  input  rst_n
  );



      
  wire                         mrom_icb_cmd_valid;
  wire                         mrom_icb_cmd_ready;
  wire [`E203_ADDR_SIZE-1:0]   mrom_icb_cmd_addr; 
  wire                         mrom_icb_cmd_read; 
  
  wire                         mrom_icb_rsp_valid;
  wire                         mrom_icb_rsp_ready;
  wire                         mrom_icb_rsp_err  ;
  wire [`E203_XLEN-1:0]        mrom_icb_rsp_rdata;

  wire                     expl_axi_icb_cmd_valid;
  wire                     expl_axi_icb_cmd_ready;
  wire [32-1:0]            expl_axi_icb_cmd_addr; 
  wire                     expl_axi_icb_cmd_read; 
  wire [32-1:0]            expl_axi_icb_cmd_wdata;
  wire [4 -1:0]            expl_axi_icb_cmd_wmask;
  
  wire                     expl_axi_icb_rsp_valid;
  wire                     expl_axi_icb_rsp_ready;
  wire [32-1:0]            expl_axi_icb_rsp_rdata;
  wire                     expl_axi_icb_rsp_err;

  // BRAM signals for axi2bram1mb_wrapper_s1 (128KB BRAM)
  wire [13:0]              bram_1m_s1_addr;   // 14位地址（字对齐，适配e203_bram_1m）
  wire                     bram_1m_s1_clk;
  wire [63:0]              bram_1m_s1_din;
  wire [63:0]              bram_1m_s1_dout;
  wire                     bram_1m_s1_en;
  wire                     bram_1m_s1_rst;
  wire [7:0]               bram_1m_s1_we;
  // APB signals (zy)
  wire                     expl_apb_icb_cmd_valid;
  wire                     expl_apb_icb_cmd_ready;
  wire [32-1:0]            expl_apb_icb_cmd_addr; 
  wire                     expl_apb_icb_cmd_read; 
  wire [32-1:0]            expl_apb_icb_cmd_wdata;
  wire [4 -1:0]            expl_apb_icb_cmd_wmask;
  
  wire                     expl_apb_icb_rsp_valid;
  wire                     expl_apb_icb_rsp_ready;
  wire [32-1:0]            expl_apb_icb_rsp_rdata;
  wire                     expl_apb_icb_rsp_err;


  // BRAM signals for design_1_wrapper
  /*wire [12:0]              bram_addr;
  wire                     bram_clk;
  wire [31:0]              bram_din;
  wire [31:0]              bram_dout;
  wire                     bram_en;
  wire                     bram_rst;
  wire [3:0]               bram_we;*/

  // S1接口信号 - 连接bus_top和design_wrapper_1
  // 写地址通道
  wire                     s1_awvalid;
  wire [31:0]              s1_awaddr;
  wire [5:0]               s1_awid;
  wire [7:0]               s1_awlen;
  wire [2:0]               s1_awsize;
  wire [1:0]               s1_awburst;
  wire                     s1_awlock;
  wire [3:0]               s1_awcache;
  wire [2:0]               s1_awprot;
  wire                     s1_awready;
  
  // 写数据通道
  wire                     s1_wvalid;
  wire [63:0]              s1_wdata;
  wire [7:0]               s1_wstrb;
  wire                     s1_wlast;
  wire                     s1_wready;
  
  // 写响应通道
  wire                     s1_bvalid;
  wire [5:0]               s1_bid;
  wire [1:0]               s1_bresp;
  wire                     s1_bready;
  
  // 读地址通道
  wire                     s1_arvalid;
  wire [5:0]               s1_arid;
  wire [31:0]              s1_araddr;
  wire [7:0]               s1_arlen;
  wire [2:0]               s1_arsize;
  wire [1:0]               s1_arburst;
  wire                     s1_arlock;
  wire [3:0]               s1_arcache;
  wire [2:0]               s1_arprot;
  wire                     s1_arready;
  
  // 读数据通道
  wire                     s1_rvalid;
  wire [5:0]               s1_rid;
  wire [63:0]              s1_rdata;
  wire [1:0]               s1_rresp;
  wire                     s1_rlast;
  wire                     s1_rready;

  // BRAM_2 signals for u_design_apb_mux (zy)  
  wire [31:0]              bram_2_addr;
  wire [31:0]              bram_2_wdata;
  wire [31:0]              bram_2_rdata;
  wire                     bram_2_enable;
  wire                     bram_2_rst;
  wire [3:0]               bram_2_we;
  wire                     bram_2_sel;      // APB选择信号
  wire                     bram_2_write;    // APB写使能信号

  // BRAM_3 signals for u_design_apb_mux (zy)  
  wire [31:0]              bram_3_addr;
  wire [31:0]              bram_3_wdata;
  wire [31:0]              bram_3_rdata;
  wire                     bram_3_enable;
  wire                     bram_3_rst;
  wire [3:0]               bram_3_we;
  wire                     bram_3_sel;      // APB选择信号
  wire                     bram_3_write;    // APB写使能信号

  // DMA signals for dma_top (替换原来的BRAM_4)
  wire                     dma_intr_done;      // DMA完成中断
  wire                     dma_intr_err;       // DMA错误中断
  wire                     dma_psel;           // APB选择信号
  wire                     dma_penable;        // APB使能信号
  wire                     dma_pwrite;         // APB写使能信号
  wire [10:0]              dma_paddr;          // APB地址信号
  wire [31:0]              dma_pwdata;         // APB写数据信号
  wire [31:0]              dma_prdata;         // APB读数据信号
  wire                     dma_pready;         // APB就绪信号
  wire                     dma_pslverr;        // APB从设备错误信号

  wire [31:0]              dma_paddr_full;     // for apb mux connection
  assign dma_paddr = dma_paddr_full[11:0];

  // DMA AXI Master signals
  wire                     dma_axim_awlock;    // AXI写地址锁信号
  wire [3:0]               dma_axim_awcache;   // AXI写地址缓存信号
  wire [2:0]               dma_axim_awprot;    // AXI写地址保护信号
  wire [3:0]               dma_axim_awqos;     // AXI写地址QoS信号
  wire [31:0]              dma_axim_awaddr;    // AXI写地址
  wire [7:0]               dma_axim_awlen;     // AXI写突发长度
  wire [2:0]               dma_axim_awsize;    // AXI写突发大小
  wire [1:0]               dma_axim_awburst;   // AXI写突发类型
  wire                     dma_axim_awvalid;   // AXI写地址有效
  wire                     dma_axim_awready;   // AXI写地址就绪
  wire [63:0]              dma_axim_wdata;     // AXI写数据
  wire [7:0]               dma_axim_wstrb;     // AXI写数据选通
  wire                     dma_axim_wlast;     // AXI写数据最后
  wire                     dma_axim_wvalid;    // AXI写数据有效
  wire                     dma_axim_wready;    // AXI写数据就绪
  wire [1:0]               dma_axim_bresp;     // AXI写响应
  wire                     dma_axim_bvalid;    // AXI写响应有效
  wire                     dma_axim_bready;    // AXI写响应就绪
  wire                     dma_axim_arlock;    // AXI读地址锁信号
  wire [3:0]               dma_axim_arcache;   // AXI读地址缓存信号
  wire [2:0]               dma_axim_arprot;    // AXI读地址保护信号
  wire [3:0]               dma_axim_arqos;     // AXI读地址QoS信号
  wire [31:0]              dma_axim_araddr;    // AXI读地址
  wire [7:0]               dma_axim_arlen;     // AXI读突发长度
  wire [2:0]               dma_axim_arsize;    // AXI读突发大小
  wire [1:0]               dma_axim_arburst;   // AXI读突发类型
  wire                     dma_axim_arvalid;   // AXI读地址有效
  wire                     dma_axim_arready;   // AXI读地址就绪
  wire [63:0]              dma_axim_rdata;     // AXI读数据
  wire [1:0]               dma_axim_rresp;     // AXI读响应
  wire                     dma_axim_rlast;     // AXI读数据最后
  wire                     dma_axim_rvalid;    // AXI读数据有效
  wire                     dma_axim_rready;    // AXI读数据就绪
  wire [7:0]               dma_axim_awid;      // AXI写ID
  wire [7:0]               dma_axim_bid;       // AXI写响应ID
  wire [7:0]               dma_axim_arid;      // AXI读ID
  wire [7:0]               dma_axim_rid;       // AXI读响应ID

  assign bram_2_we = (bram_2_sel && bram_2_write && bram_2_enable)? 4'b1111:4'b0000;
  assign bram_3_we = (bram_3_sel && bram_3_write && bram_3_enable)? 4'b1111:4'b0000;
  
  // DMA中断信号连接到输出端口
  assign dma_done_irq = dma_intr_done;
  assign dma_err_irq  = dma_intr_err;
  // MAC interrupt signals from Mac_ASIC_top
  wire         mac_done_interrupt;
  wire         mac_error_interrupt;
  // MAC中断信号连接到输出端口
  assign mac_done_irq = mac_done_interrupt;
  assign mac_err_irq  = mac_error_interrupt;

  // S2接口信号 - 连接bus_top和axi2bram_asic
  // 写地址通道
  wire                     s2_awvalid;
  wire [31:0]              s2_awaddr;
  wire [5:0]               s2_awid;
  wire [7:0]               s2_awlen;
  wire [2:0]               s2_awsize;
  wire [1:0]               s2_awburst;
  wire                     s2_awlock;
  wire [3:0]               s2_awcache;
  wire [2:0]               s2_awprot;
  wire                     s2_awready;
  
  // 写数据通道
  wire                     s2_wvalid;
  wire [63:0]              s2_wdata;
  wire [7:0]               s2_wstrb;
  wire                     s2_wlast;
  wire                     s2_wready;
  
  // 写响应通道
  wire                     s2_bvalid;
  wire [5:0]               s2_bid;
  wire [1:0]               s2_bresp;
  wire                     s2_bready;
  
  // 读地址通道
  wire                     s2_arvalid;
  wire [5:0]               s2_arid;
  wire [31:0]              s2_araddr;
  wire [7:0]               s2_arlen;
  wire [2:0]               s2_arsize;
  wire [1:0]               s2_arburst;
  wire                     s2_arlock;
  wire [3:0]               s2_arcache;
  wire [2:0]               s2_arprot;
  wire                     s2_arready;
  
  // 读数据通道
  wire                     s2_rvalid;
  wire [5:0]               s2_rid;
  wire [63:0]              s2_rdata;
  wire [1:0]               s2_rresp;
  wire                     s2_rlast;
  wire                     s2_rready;

  // BRAM接口信号
  wire [15:0]              bram_addr;
  wire                     bram_clk;
  wire [63:0]              bram_dinout;
  wire                     bram_en;
  wire                     bram_rstn;
  wire                     bram_we;

  // S3接口信号 - 连接bus_top和axi2bram_64k_s3
  // 写地址通道
  wire                     s3_awvalid;
  wire [31:0]              s3_awaddr;
  wire [5:0]               s3_awid;
  wire [7:0]               s3_awlen;
  wire [2:0]               s3_awsize;
  wire [1:0]               s3_awburst;
  wire                     s3_awlock;
  wire [3:0]               s3_awcache;
  wire [2:0]               s3_awprot;
  wire                     s3_awready;

  // 写数据通道
  wire                     s3_wvalid;
  wire [63:0]              s3_wdata;
  wire [7:0]               s3_wstrb;
  wire                     s3_wlast;
  wire                     s3_wready;

  // 写响应通道
  wire                     s3_bvalid;
  wire [5:0]               s3_bid;
  wire [1:0]               s3_bresp;
  wire                     s3_bready;

  // 读地址通道
  wire                     s3_arvalid;
  wire [5:0]               s3_arid;
  wire [31:0]              s3_araddr;
  wire [7:0]               s3_arlen;
  wire [2:0]               s3_arsize;
  wire [1:0]               s3_arburst;
  wire                     s3_arlock;
  wire [3:0]               s3_arcache;
  wire [2:0]               s3_arprot;
  wire                     s3_arready;

  // 读数据通道
  wire                     s3_rvalid;
  wire [5:0]               s3_rid;
  wire [63:0]              s3_rdata;
  wire [1:0]               s3_rresp;
  wire                     s3_rlast;
  wire                     s3_rready;

  // S4接口信号 - 连接bus_top和axi2bram_64k_s4
  // 写地址通道
  wire                     s4_awvalid;
  wire [31:0]              s4_awaddr;
  wire [5:0]               s4_awid;
  wire [7:0]               s4_awlen;
  wire [2:0]               s4_awsize;
  wire [1:0]               s4_awburst;
  wire                     s4_awlock;
  wire [3:0]               s4_awcache;
  wire [2:0]               s4_awprot;
  wire                     s4_awready;

  // 写数据通道
  wire                     s4_wvalid;
  wire [63:0]              s4_wdata;
  wire [7:0]               s4_wstrb;
  wire                     s4_wlast;
  wire                     s4_wready;

  // 写响应通道
  wire                     s4_bvalid;
  wire [5:0]               s4_bid;
  wire [1:0]               s4_bresp;
  wire                     s4_bready;

  // 读地址通道
  wire                     s4_arvalid;
  wire [5:0]               s4_arid;
  wire [31:0]              s4_araddr;
  wire [7:0]               s4_arlen;
  wire [2:0]               s4_arsize;
  wire [1:0]               s4_arburst;
  wire                     s4_arlock;
  wire [3:0]               s4_arcache;
  wire [2:0]               s4_arprot;
  wire                     s4_arready;

  // 读数据通道
  wire                     s4_rvalid;
  wire [5:0]               s4_rid;
  wire [63:0]              s4_rdata;
  wire [1:0]               s4_rresp;
  wire                     s4_rlast;
  wire                     s4_rready;

  // BRAM_64K signals for axi2bram_64k (64KB BRAM) - Pseudo dual-port
  // Write port
  wire [10:0]              bram_64k_w_addr;
  wire                     bram_64k_clk;
  wire                     bram_64k_rst_n;
  wire [255:0]             bram_64k_w_din;
  wire                     bram_64k_w_en;
  wire [31:0]              bram_64k_w_we;
  // Read port
  wire [10:0]              bram_64k_r_addr;
  wire [255:0]             bram_64k_r_dout;
  wire                     bram_64k_r_en;

  // BRAM_64K signals for axi2bram_64k_s3 (64KB BRAM) - Pseudo dual-port
  // Write port
  wire [10:0]              bram_64k_s3_w_addr;
  wire                     bram_64k_s3_clk;
  wire                     bram_64k_s3_rst_n;
  wire [255:0]             bram_64k_s3_w_din;
  wire                     bram_64k_s3_w_en;
  wire [31:0]              bram_64k_s3_w_we;
  // Read port
  wire [10:0]              bram_64k_s3_r_addr;
  wire [255:0]             bram_64k_s3_r_dout;
  wire                     bram_64k_s3_r_en;

  // BRAM_64K signals for axi2bram_64k_s4 (64KB BRAM) - Pseudo dual-port
  // Write port
  wire [10:0]              bram_64k_s4_w_addr;
  wire                     bram_64k_s4_clk;
  wire                     bram_64k_s4_rst_n;
  wire [255:0]             bram_64k_s4_w_din;
  wire                     bram_64k_s4_w_en;
  wire [31:0]              bram_64k_s4_w_we;
  // Read port
  wire [10:0]              bram_64k_s4_r_addr;
  wire [255:0]             bram_64k_s4_r_dout;
  wire                     bram_64k_s4_r_en;

 localparam MROM_AW = 12  ;
 localparam MROM_DP = 1024;
  // There are several slaves for Mem bus, including:
  //  * DM        : 0x0000 0000 -- 0x0000 0FFF
  //  * MROM      : 0x0000 1000 -- 0x0000 1FFF
  //  * QSPI0-RO  : 0x2000 0000 -- 0x3FFF FFFF
  //  * SysMem    : 0x8000 0000 -- 0xFFFF FFFF
  //  * AXI       : 0x4000 0000 -- 0x5FFF FFFF
  //  * APB       : 0x0040 0000 -- 0x007F_FFFF（zy）
    // * slave 0       : 0x0040 0000 -- 0x0040 1FFF 
    // * slave 1       : 0x0041 0000 -- 0x0041 1FFF
    // * slave 2       : 0x0042 0000 -- 0x0042 1FFF

  sirv_icb1to8_bus # (
  .ICB_FIFO_DP        (2),// We add a ping-pong buffer here to cut down the timing path
  .ICB_FIFO_CUT_READY (1),// We configure it to cut down the back-pressure ready signal
  .AW                   (32),
  .DW                   (`E203_XLEN),
  .SPLT_FIFO_OUTS_NUM   (1),// The Mem only allow 1 oustanding
  .SPLT_FIFO_CUT_READY  (1),// The Mem always cut ready
  //  * DM        : 0x0000 0000 -- 0x0000 0FFF
  .O0_BASE_ADDR       (32'h0000_0000),       
  .O0_BASE_REGION_LSB (12),
  //  * MROM      : 0x0000 1000 -- 0x0000 1FFF
  .O1_BASE_ADDR       (32'h0000_1000),       
  .O1_BASE_REGION_LSB (12),
  //  * Not used  : 0x0002 0000 -- 0x0003 FFFF
  .O2_BASE_ADDR       (32'h0002_0000),       
  .O2_BASE_REGION_LSB (17),
  //  * QSPI0-RO  : 0x2000 0000 -- 0x3FFF FFFF
  .O3_BASE_ADDR       (32'h2000_0000),       
  .O3_BASE_REGION_LSB (29),
  //  * SysMem    : 0x8000 0000 -- 0xFFFF FFFF
  //    Actually since the 0xFxxx xxxx have been occupied by FIO, 
  //    sysmem have no chance to access it
  .O4_BASE_ADDR       (32'h8000_0000),       
  .O4_BASE_REGION_LSB (31),

      // * Here is an example AXI Peripheral
  .O5_BASE_ADDR       (32'h4000_0000),       
  .O5_BASE_REGION_LSB (29), // 0x4000_0000 ~ 0x5FFF_FFFF (512MB)
  
      // * Here is an example APB Peripheral, 4MB (zy)
  .O6_BASE_ADDR       (32'h0040_0000),       
  .O6_BASE_REGION_LSB (22), // 0x0040_0000 ~ 0x007F_FFFF (4MB)
  
      // Not used
  .O7_BASE_ADDR       (32'h0000_0000),       
  .O7_BASE_REGION_LSB (0)

  )u_sirv_mem_fab(

    .i_icb_cmd_valid  (mem_icb_cmd_valid),
    .i_icb_cmd_ready  (mem_icb_cmd_ready),
    .i_icb_cmd_addr   (mem_icb_cmd_addr ),
    .i_icb_cmd_read   (mem_icb_cmd_read ),
    .i_icb_cmd_wdata  (mem_icb_cmd_wdata),
    .i_icb_cmd_wmask  (mem_icb_cmd_wmask),
    .i_icb_cmd_lock   (1'b0 ),
    .i_icb_cmd_excl   (1'b0 ),
    .i_icb_cmd_size   (2'b0 ),
    .i_icb_cmd_burst  (2'b0),
    .i_icb_cmd_beat   (2'b0 ),
    
    .i_icb_rsp_valid  (mem_icb_rsp_valid),
    .i_icb_rsp_ready  (mem_icb_rsp_ready),
    .i_icb_rsp_err    (mem_icb_rsp_err  ),
    .i_icb_rsp_excl_ok(),
    .i_icb_rsp_rdata  (mem_icb_rsp_rdata),
    
  //  * DM
    .o0_icb_enable     (1'b1),

    .o0_icb_cmd_valid  (dm_icb_cmd_valid),
    .o0_icb_cmd_ready  (dm_icb_cmd_ready),
    .o0_icb_cmd_addr   (dm_icb_cmd_addr ),
    .o0_icb_cmd_read   (dm_icb_cmd_read ),
    .o0_icb_cmd_wdata  (dm_icb_cmd_wdata),
    .o0_icb_cmd_wmask  (),
    .o0_icb_cmd_lock   (),
    .o0_icb_cmd_excl   (),
    .o0_icb_cmd_size   (),
    .o0_icb_cmd_burst  (),
    .o0_icb_cmd_beat   (),
    
    .o0_icb_rsp_valid  (dm_icb_rsp_valid),
    .o0_icb_rsp_ready  (dm_icb_rsp_ready),
    .o0_icb_rsp_err    (1'b0),
    .o0_icb_rsp_excl_ok(1'b0),
    .o0_icb_rsp_rdata  (dm_icb_rsp_rdata),

  //  * MROM      
    .o1_icb_enable     (1'b1),

    .o1_icb_cmd_valid  (mrom_icb_cmd_valid),
    .o1_icb_cmd_ready  (mrom_icb_cmd_ready),
    .o1_icb_cmd_addr   (mrom_icb_cmd_addr ),
    .o1_icb_cmd_read   (mrom_icb_cmd_read ),
    .o1_icb_cmd_wdata  (),
    .o1_icb_cmd_wmask  (),
    .o1_icb_cmd_lock   (),
    .o1_icb_cmd_excl   (),
    .o1_icb_cmd_size   (),
    .o1_icb_cmd_burst  (),
    .o1_icb_cmd_beat   (),
    
    .o1_icb_rsp_valid  (mrom_icb_rsp_valid),
    .o1_icb_rsp_ready  (mrom_icb_rsp_ready),
    .o1_icb_rsp_err    (mrom_icb_rsp_err),
    .o1_icb_rsp_excl_ok(1'b0  ),
    .o1_icb_rsp_rdata  (mrom_icb_rsp_rdata),

  //  * Not used    
    .o2_icb_enable     (1'b0),

    .o2_icb_cmd_valid  (),
    .o2_icb_cmd_ready  (1'b0),
    .o2_icb_cmd_addr   (),
    .o2_icb_cmd_read   (),
    .o2_icb_cmd_wdata  (),
    .o2_icb_cmd_wmask  (),
    .o2_icb_cmd_lock   (),
    .o2_icb_cmd_excl   (),
    .o2_icb_cmd_size   (),
    .o2_icb_cmd_burst  (),
    .o2_icb_cmd_beat   (),
    
    .o2_icb_rsp_valid  (1'b0),
    .o2_icb_rsp_ready  (),
    .o2_icb_rsp_err    (1'b0  ),
    .o2_icb_rsp_excl_ok(1'b0  ),
    .o2_icb_rsp_rdata  (`E203_XLEN'b0),


  //  * QSPI0-RO  
    .o3_icb_enable     (1'b1),

    .o3_icb_cmd_valid  (qspi0_ro_icb_cmd_valid),
    .o3_icb_cmd_ready  (qspi0_ro_icb_cmd_ready),
    .o3_icb_cmd_addr   (qspi0_ro_icb_cmd_addr ),
    .o3_icb_cmd_read   (qspi0_ro_icb_cmd_read ),
    .o3_icb_cmd_wdata  (qspi0_ro_icb_cmd_wdata),
    .o3_icb_cmd_wmask  (),
    .o3_icb_cmd_lock   (),
    .o3_icb_cmd_excl   (),
    .o3_icb_cmd_size   (),
    .o3_icb_cmd_burst  (),
    .o3_icb_cmd_beat   (),
    
    .o3_icb_rsp_valid  (qspi0_ro_icb_rsp_valid),
    .o3_icb_rsp_ready  (qspi0_ro_icb_rsp_ready),
    .o3_icb_rsp_err    (qspi0_ro_icb_rsp_err),
    .o3_icb_rsp_excl_ok(1'b0  ),
    .o3_icb_rsp_rdata  (qspi0_ro_icb_rsp_rdata),


  //  * SysMem
    .o4_icb_enable     (1'b1),

    .o4_icb_cmd_valid  (sysmem_icb_cmd_valid),
    .o4_icb_cmd_ready  (sysmem_icb_cmd_ready),
    .o4_icb_cmd_addr   (sysmem_icb_cmd_addr ),
    .o4_icb_cmd_read   (sysmem_icb_cmd_read ),
    .o4_icb_cmd_wdata  (sysmem_icb_cmd_wdata),
    .o4_icb_cmd_wmask  (sysmem_icb_cmd_wmask),
    .o4_icb_cmd_lock   (),
    .o4_icb_cmd_excl   (),
    .o4_icb_cmd_size   (),
    .o4_icb_cmd_burst  (),
    .o4_icb_cmd_beat   (),
    
    .o4_icb_rsp_valid  (sysmem_icb_rsp_valid),
    .o4_icb_rsp_ready  (sysmem_icb_rsp_ready),
    .o4_icb_rsp_err    (sysmem_icb_rsp_err    ),
    .o4_icb_rsp_excl_ok(1'b0),
    .o4_icb_rsp_rdata  (sysmem_icb_rsp_rdata),

   //  * Example AXI    
    .o5_icb_enable     (1'b1),

    .o5_icb_cmd_valid  (expl_axi_icb_cmd_valid),
    .o5_icb_cmd_ready  (expl_axi_icb_cmd_ready),
    .o5_icb_cmd_addr   (expl_axi_icb_cmd_addr ),
    .o5_icb_cmd_read   (expl_axi_icb_cmd_read ),
    .o5_icb_cmd_wdata  (expl_axi_icb_cmd_wdata),
    .o5_icb_cmd_wmask  (expl_axi_icb_cmd_wmask),
    .o5_icb_cmd_lock   (),
    .o5_icb_cmd_excl   (),
    .o5_icb_cmd_size   (),
    .o5_icb_cmd_burst  (),
    .o5_icb_cmd_beat   (),
    
    .o5_icb_rsp_valid  (expl_axi_icb_rsp_valid),
    .o5_icb_rsp_ready  (expl_axi_icb_rsp_ready),
    .o5_icb_rsp_err    (expl_axi_icb_rsp_err),
    .o5_icb_rsp_excl_ok(1'b0  ),
    .o5_icb_rsp_rdata  (expl_axi_icb_rsp_rdata),


        //  * Example APB (zy)
    .o6_icb_enable     (1'b1),

    .o6_icb_cmd_valid  (expl_apb_icb_cmd_valid),
    .o6_icb_cmd_ready  (expl_apb_icb_cmd_ready),
    .o6_icb_cmd_addr   (expl_apb_icb_cmd_addr),
    .o6_icb_cmd_read   (expl_apb_icb_cmd_read),
    .o6_icb_cmd_wdata  (expl_apb_icb_cmd_wdata),
    .o6_icb_cmd_wmask  (expl_apb_icb_cmd_wmask),
    .o6_icb_cmd_lock   (),
    .o6_icb_cmd_excl   (),
    .o6_icb_cmd_size   (),
    .o6_icb_cmd_burst  (),
    .o6_icb_cmd_beat   (),
    
    .o6_icb_rsp_valid  (expl_apb_icb_rsp_valid),
    .o6_icb_rsp_ready  (expl_apb_icb_rsp_ready),
    .o6_icb_rsp_err    (expl_apb_icb_rsp_err),
    .o6_icb_rsp_excl_ok(1'b0  ),
    .o6_icb_rsp_rdata  (expl_apb_icb_rsp_rdata),

        //  * Not used
    .o7_icb_enable     (1'b0),

    .o7_icb_cmd_valid  (),
    .o7_icb_cmd_ready  (1'b0),
    .o7_icb_cmd_addr   (),
    .o7_icb_cmd_read   (),
    .o7_icb_cmd_wdata  (),
    .o7_icb_cmd_wmask  (),
    .o7_icb_cmd_lock   (),
    .o7_icb_cmd_excl   (),
    .o7_icb_cmd_size   (),
    .o7_icb_cmd_burst  (),
    .o7_icb_cmd_beat   (),
    
    .o7_icb_rsp_valid  (1'b0),
    .o7_icb_rsp_ready  (),
    .o7_icb_rsp_err    (1'b0  ),
    .o7_icb_rsp_excl_ok(1'b0  ),
    .o7_icb_rsp_rdata  (`E203_XLEN'b0),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );

  sirv_mrom_top #(
    .AW(MROM_AW),
    .DW(32),
    .DP(MROM_DP)
  )u_sirv_mrom_top(

    .rom_icb_cmd_valid  (mrom_icb_cmd_valid),
    .rom_icb_cmd_ready  (mrom_icb_cmd_ready),
    .rom_icb_cmd_addr   (mrom_icb_cmd_addr [MROM_AW-1:0]),
    .rom_icb_cmd_read   (mrom_icb_cmd_read ),
    
    .rom_icb_rsp_valid  (mrom_icb_rsp_valid),
    .rom_icb_rsp_ready  (mrom_icb_rsp_ready),
    .rom_icb_rsp_err    (mrom_icb_rsp_err  ),
    .rom_icb_rsp_rdata  (mrom_icb_rsp_rdata),

    .clk           (clk  ),
    .rst_n         (rst_n) 
  );

      // * AXI SmartConnect Interface - Connected to Vivado IP
  wire expl_axi_arvalid;
  wire expl_axi_arready;
  wire [`E203_ADDR_SIZE-1:0] expl_axi_araddr;
  wire [3:0] expl_axi_arcache;
  wire [2:0] expl_axi_arprot;
  wire [1:0] expl_axi_arlock;
  wire [1:0] expl_axi_arburst;
  wire [3:0] expl_axi_arlen;
  wire [2:0] expl_axi_arsize;

  wire expl_axi_awvalid;
  wire expl_axi_awready;
  wire [`E203_ADDR_SIZE-1:0] expl_axi_awaddr;
  wire [3:0] expl_axi_awcache;
  wire [2:0] expl_axi_awprot;
  wire [1:0] expl_axi_awlock;
  wire [1:0] expl_axi_awburst;
  wire [3:0] expl_axi_awlen;
  wire [2:0] expl_axi_awsize;

  wire expl_axi_rvalid;
  wire expl_axi_rready;
  wire [`E203_XLEN-1:0] expl_axi_rdata;
  wire [1:0] expl_axi_rresp;
  wire expl_axi_rlast;

  wire expl_axi_wvalid;
  wire expl_axi_wready;
  wire [`E203_XLEN-1:0] expl_axi_wdata;
  wire [(`E203_XLEN/8)-1:0] expl_axi_wstrb;
  wire expl_axi_wlast;

  wire expl_axi_bvalid;
  wire expl_axi_bready;
  wire [1:0] expl_axi_bresp;
   
sirv_gnrl_icb2axi # (
  .AXI_FIFO_DP (2), // We just add ping-pong buffer here to avoid any potential timing loops
                    //   User can change it to 0 if dont care
  .AXI_FIFO_CUT_READY (1), // This is to cut the back-pressure signal if you set as 1
  .AW   (32),
  .FIFO_OUTS_NUM (4),// We only allow 4 oustandings at most for mem, user can configure it to any value
  .FIFO_CUT_READY(1),
  .DW   (`E203_XLEN) 
) u_expl_axi_icb2axi(
    .i_icb_cmd_valid (expl_axi_icb_cmd_valid),
    .i_icb_cmd_ready (expl_axi_icb_cmd_ready),
    .i_icb_cmd_addr  (expl_axi_icb_cmd_addr ),
    .i_icb_cmd_read  (expl_axi_icb_cmd_read ),
    .i_icb_cmd_wdata (expl_axi_icb_cmd_wdata),
    .i_icb_cmd_wmask (expl_axi_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (expl_axi_icb_rsp_valid),
    .i_icb_rsp_ready (expl_axi_icb_rsp_ready),
    .i_icb_rsp_rdata (expl_axi_icb_rsp_rdata),
    .i_icb_rsp_err   (expl_axi_icb_rsp_err),

    .o_axi_arvalid   (expl_axi_arvalid),
    .o_axi_arready   (expl_axi_arready),
    .o_axi_araddr    (expl_axi_araddr ),
    .o_axi_arcache   (expl_axi_arcache),
    .o_axi_arprot    (expl_axi_arprot ),
    .o_axi_arlock    (expl_axi_arlock ),
    .o_axi_arburst   (expl_axi_arburst),
    .o_axi_arlen     (expl_axi_arlen  ),
    .o_axi_arsize    (expl_axi_arsize ),
                      
    .o_axi_awvalid   (expl_axi_awvalid),
    .o_axi_awready   (expl_axi_awready),
    .o_axi_awaddr    (expl_axi_awaddr ),
    .o_axi_awcache   (expl_axi_awcache),
    .o_axi_awprot    (expl_axi_awprot ),
    .o_axi_awlock    (expl_axi_awlock ),
    .o_axi_awburst   (expl_axi_awburst),
    .o_axi_awlen     (expl_axi_awlen  ),
    .o_axi_awsize    (expl_axi_awsize ),
                     
    .o_axi_rvalid    (expl_axi_rvalid ),
    .o_axi_rready    (expl_axi_rready ),
    .o_axi_rdata     (expl_axi_rdata  ),
    .o_axi_rresp     (expl_axi_rresp  ),
    .o_axi_rlast     (expl_axi_rlast  ),
                    
    .o_axi_wvalid    (expl_axi_wvalid ),
    .o_axi_wready    (expl_axi_wready ),
    .o_axi_wdata     (expl_axi_wdata  ),
    .o_axi_wstrb     (expl_axi_wstrb  ),
    .o_axi_wlast     (expl_axi_wlast  ),
                   
    .o_axi_bvalid    (expl_axi_bvalid ),
    .o_axi_bready    (expl_axi_bready ),
    .o_axi_bresp     (expl_axi_bresp  ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );

// Commented out Vivado SmartConnect IP
/*
design_1_wrapper u_axi_smartconnect_wrapper (
    // BRAM Port A Interface
    .BRAM_PORTA_0_addr     (bram_addr),
    .BRAM_PORTA_0_clk      (bram_clk),
    .BRAM_PORTA_0_din      (bram_din),
    .BRAM_PORTA_0_dout     (bram_dout),
    .BRAM_PORTA_0_en       (bram_en),
    .BRAM_PORTA_0_rst      (bram_rst),
    .BRAM_PORTA_0_we       (bram_we),
    
         // BRAM Port A1 Interface
     .BRAM_PORTA_1_addr     (bram_1_addr),
     .BRAM_PORTA_1_clk      (bram_1_clk),
     .BRAM_PORTA_1_din      (bram_1_din),
     .BRAM_PORTA_1_dout     (bram_1_dout),
     .BRAM_PORTA_1_en       (bram_1_en),
     .BRAM_PORTA_1_rst      (bram_1_rst),
     .BRAM_PORTA_1_we       (bram_1_we),
    
         // AXI4 Slave Interface (S00_AXI_0)
     .S00_AXI_0_araddr  (expl_axi_araddr),           // Use full 32-bit address
     .S00_AXI_0_arburst (expl_axi_arburst),
     .S00_AXI_0_arcache (expl_axi_arcache),
     .S00_AXI_0_arlen   ({1'b0, expl_axi_arlen, 3'b000}),  // Convert 4-bit to 8-bit
     .S00_AXI_0_arlock  (expl_axi_arlock[0:0]),      // Convert 2-bit to 1-bit
     .S00_AXI_0_arprot  (expl_axi_arprot),
     .S00_AXI_0_arqos   (4'b0000),                   // Add QoS signal
     .S00_AXI_0_arready (expl_axi_arready),
     .S00_AXI_0_arsize  (expl_axi_arsize),
     .S00_AXI_0_arvalid (expl_axi_arvalid),

     .S00_AXI_0_awaddr  (expl_axi_awaddr),           // Use full 32-bit address
     .S00_AXI_0_awburst (expl_axi_awburst),
     .S00_AXI_0_awcache (expl_axi_awcache),
     .S00_AXI_0_awlen   ({1'b0, expl_axi_awlen, 3'b000}),  // Convert 4-bit to 8-bit
     .S00_AXI_0_awlock  (expl_axi_awlock[0:0]),      // Convert 2-bit to 1-bit
     .S00_AXI_0_awprot  (expl_axi_awprot),
     .S00_AXI_0_awqos   (4'b0000),                   // Add QoS signal
     .S00_AXI_0_awready (expl_axi_awready),
     .S00_AXI_0_awsize  (expl_axi_awsize),
     .S00_AXI_0_awvalid (expl_axi_awvalid),

     .S00_AXI_0_bready  (expl_axi_bready),
     .S00_AXI_0_bresp   (expl_axi_bresp),
     .S00_AXI_0_bvalid  (expl_axi_bvalid),

     .S00_AXI_0_rdata   (expl_axi_rdata),
     .S00_AXI_0_rlast   (expl_axi_rlast),
     .S00_AXI_0_rready  (expl_axi_rready),
     .S00_AXI_0_rresp   (expl_axi_rresp),
     .S00_AXI_0_rvalid  (expl_axi_rvalid),

     .S00_AXI_0_wdata   (expl_axi_wdata),
     .S00_AXI_0_wlast   (expl_axi_wlast),
     .S00_AXI_0_wready  (expl_axi_wready),
     .S00_AXI_0_wstrb   (expl_axi_wstrb),
     .S00_AXI_0_wvalid  (expl_axi_wvalid),

     // Clock and Reset
     .clk               (clk),
     .rst_n             (rst_n)
   );

  // Commented out BRAM modules
  // Instantiate first 8K BRAM module
  e203_bram_8k u_bram_8k_0 (
    .bram_addr  (bram_addr),
    .bram_clk   (bram_clk),
    .bram_din   (bram_din),
    .bram_dout  (bram_dout),
    .bram_en    (bram_en),
    .bram_rst   (bram_rst),
    .bram_we    (bram_we),
    .rst_n      (rst_n)
  );

  // Instantiate second 8K BRAM module
  e203_bram_8k u_bram_8k_1 (
    .bram_addr  (bram_1_addr),
    .bram_clk   (bram_1_clk),
    .bram_din   (bram_1_din),
    .bram_dout  (bram_1_dout),
    .bram_en    (bram_1_en),
    .bram_rst   (bram_1_rst),
    .bram_we    (bram_1_we),
    .rst_n      (rst_n)
  );
*/

// Replace with bus_top connection 
bus_top u_bus_top (
    // System signals
    .aclk       (clk),
    .aresetn    (rst_n),

    // Master1 (32-bit) interface - Connected to E203 AXI
    // ==================== AXI4 写地址通道 (Write Address Channel) ====================
    .awvalid_m1 (expl_axi_awvalid),        // 写地址有效信号：master发起写传输时置高
    .awaddr_m1  (expl_axi_awaddr),         // 写地址：32位物理地址，指向要写入的位置
    .awid_m1    (4'b0000),                 // 写地址ID：E203不支持ID，固定为0（用于事务标识）
    .awlen_m1   ({4'b0000, expl_axi_awlen}), // 突发长度：4位扩展为8位，表示传输个数-1
    .awsize_m1  (expl_axi_awsize),         // 突发大小：每次传输的字节数（2^awsize）
    .awburst_m1 (expl_axi_awburst),        // 突发类型：FIXED/INCR/WRAP（0/1/2）
    .awlock_m1  (expl_axi_awlock[0]),      // 原子锁：2位转1位，用于原子操作锁定
    .awcache_m1 (expl_axi_awcache),        // 缓存属性：控制缓存、缓冲特性
    .awprot_m1  (expl_axi_awprot),         // 保护类型：特权/安全/指令访问属性
    .awready_m1 (expl_axi_awready),        // 写地址就绪：slave可接受地址时置高

    // ==================== AXI4 写数据通道 (Write Data Channel) ====================
    .wvalid_m1  (expl_axi_wvalid),         // 写数据有效：master提供有效写数据时置高
    .wdata_m1   (expl_axi_wdata),          // 写数据：32位实际要写入的数据
    .wstrb_m1   (expl_axi_wstrb),          // 写字节选通：4位，每位对应一个字节使能
    .wlast_m1   (expl_axi_wlast),          // 写数据最后：突发传输的最后一个数据
    .wready_m1  (expl_axi_wready),         // 写数据就绪：slave可接受数据时置高

    // ==================== AXI4 写响应通道 (Write Response Channel) ====================
    .bvalid_m1  (expl_axi_bvalid),         // 写响应有效：slave完成写操作后置高
    .bid_m1     (),                        // 写响应ID：E203不支持ID，端口悬空
    .bresp_m1   (expl_axi_bresp),          // 写响应状态：OKAY/EXOKAY/SLVERR/DECERR
    .bready_m1  (expl_axi_bready),         // 写响应就绪：master准备接收响应时置高

    // ==================== AXI4 读地址通道 (Read Address Channel) ====================
    .arvalid_m1 (expl_axi_arvalid),        // 读地址有效：master发起读传输时置高
    .arid_m1    (4'b0000),                 // 读地址ID：E203不支持ID，固定为0
    .araddr_m1  (expl_axi_araddr),         // 读地址：32位物理地址，指向要读取的位置
    .arlen_m1   ({4'b0000, expl_axi_arlen}), // 突发长度：4位扩展为8位，表示传输个数-1
    .arsize_m1  (expl_axi_arsize),         // 突发大小：每次传输的字节数（2^arsize）
    .arburst_m1 (expl_axi_arburst),        // 突发类型：FIXED/INCR/WRAP（0/1/2）
    .arlock_m1  (expl_axi_arlock[0]),      // 原子锁：2位转1位，用于原子操作锁定
    .arcache_m1 (expl_axi_arcache),        // 缓存属性：控制缓存、缓冲特性
    .arprot_m1  (expl_axi_arprot),         // 保护类型：特权/安全/指令访问属性
    .arready_m1 (expl_axi_arready),        // 读地址就绪：slave可接受地址时置高

    // ==================== AXI4 读数据通道 (Read Data Channel) ====================
    .rvalid_m1  (expl_axi_rvalid),         // 读数据有效：slave提供有效读数据时置高
    .rid_m1     (),                        // 读数据ID：E203不支持ID，端口悬空
    .rdata_m1   (expl_axi_rdata),          // 读数据：32位从slave读取的数据
    .rresp_m1   (expl_axi_rresp),          // 读响应状态：OKAY/EXOKAY/SLVERR/DECERR
    .rlast_m1   (expl_axi_rlast),          // 读数据最后：突发传输的最后一个数据
    .rready_m1  (expl_axi_rready),         // 读数据就绪：master准备接收数据时置高

    // Master2 (64-bit) interface - Connected to DMA AXI Master
    .awvalid_m2 (dma_axim_awvalid),
    .awaddr_m2  (dma_axim_awaddr),
    .awid_m2    (dma_axim_awid[3:0]),     // 8位转4位
    .awlen_m2   (dma_axim_awlen),
    .awsize_m2  (dma_axim_awsize),
    .awburst_m2 (dma_axim_awburst),
    .awlock_m2  (dma_axim_awlock),
    .awcache_m2 (dma_axim_awcache),
    .awprot_m2  (dma_axim_awprot),
    .awready_m2 (dma_axim_awready),

    .wvalid_m2  (dma_axim_wvalid),
    .wdata_m2   (dma_axim_wdata),
    .wstrb_m2   (dma_axim_wstrb),
    .wlast_m2   (dma_axim_wlast),
    .wready_m2  (dma_axim_wready),

    .bvalid_m2  (dma_axim_bvalid),
    .bid_m2     (dma_axim_bid[3:0]),      // 8位转4位
    .bresp_m2   (dma_axim_bresp),
    .bready_m2  (dma_axim_bready),

    .arvalid_m2 (dma_axim_arvalid),
    .arid_m2    (dma_axim_arid[3:0]),     // 8位转4位
    .araddr_m2  (dma_axim_araddr),
    .arlen_m2   (dma_axim_arlen),
    .arsize_m2  (dma_axim_arsize),
    .arburst_m2 (dma_axim_arburst),
    .arlock_m2  (dma_axim_arlock),
    .arcache_m2 (dma_axim_arcache),
    .arprot_m2  (dma_axim_arprot),
    .arready_m2 (dma_axim_arready),

    .rvalid_m2  (dma_axim_rvalid),
    .rid_m2     (dma_axim_rid[3:0]),      // 8位转4位
    .rdata_m2   (dma_axim_rdata),
    .rresp_m2   (dma_axim_rresp),
    .rlast_m2   (dma_axim_rlast),
    .rready_m2  (dma_axim_rready),

    // Master3 (64-bit) interface - Not used, tie to inactive
    .awvalid_m3 (1'b0),
    .awaddr_m3  (32'h0),
    .awid_m3    (4'h0),
    .awlen_m3   (8'h0),
    .awsize_m3  (3'h0),
    .awburst_m3 (2'h0),
    .awlock_m3  (1'b0),
    .awcache_m3 (4'h0),
    .awprot_m3  (3'h0),
    .awready_m3 (),

    .wvalid_m3  (1'b0),
    .wdata_m3   (64'h0),
    .wstrb_m3   (8'h0),
    .wlast_m3   (1'b0),
    .wready_m3  (),

    .bvalid_m3  (),
    .bid_m3     (),
    .bresp_m3   (),
    .bready_m3  (1'b0),

    .arvalid_m3 (1'b0),
    .arid_m3    (4'h0),
    .araddr_m3  (32'h0),
    .arlen_m3   (8'h0),
    .arsize_m3  (3'h0),
    .arburst_m3 (2'h0),
    .arlock_m3  (1'b0),
    .arcache_m3 (4'h0),
    .arprot_m3  (3'h0),
    .arready_m3 (),

    .rvalid_m3  (),
    .rid_m3     (),
    .rdata_m3   (),
    .rresp_m3   (),
    .rlast_m3   (),
    .rready_m3  (1'b0),

    // ==================== Slave1接口 - 连接到axi2bram1mb_wrapper (128KB BRAM) ====================
    // 地址：0x4000_0000 -- 0x4001_FFFF (实际128KB，AXI地址空间1MB但BRAM只有128KB)
  
    // AXI4 写地址通道 (Write Address Channel)
    .awvalid_s1 (s1_awvalid),              // 写地址有效：从master传来的写地址有效信号
    .awaddr_s1  (s1_awaddr),               // 写地址：32位地址，从master传来
    .awid_s1    (s1_awid),                 // 写地址ID：6位事务标识符
    .awlen_s1   (s1_awlen),                // 突发长度：8位，表示传输个数-1
    .awsize_s1  (s1_awsize),               // 突发大小：3位，每次传输的字节数
    .awburst_s1 (s1_awburst),              // 突发类型：2位，FIXED/INCR/WRAP
    .awlock_s1  (s1_awlock),               // 原子锁：1位，用于原子操作
    .awcache_s1 (s1_awcache),              // 缓存属性：4位，控制缓存特性
    .awprot_s1  (s1_awprot),               // 保护类型：3位，特权/安全访问属性
    .awready_s1 (s1_awready),              // 写地址就绪：slave可接受地址时置高

    // AXI4 写数据通道 (Write Data Channel)
    .wvalid_s1  (s1_wvalid),               // 写数据有效：master提供有效写数据时置高
    .wdata_s1   (s1_wdata),                // 写数据：64位实际要写入的数据
    .wstrb_s1   (s1_wstrb),                // 写字节选通：8位，每位对应一个字节使能
    .wlast_s1   (s1_wlast),                // 写数据最后：突发传输的最后一个数据
    .wready_s1  (s1_wready),               // 写数据就绪：slave可接受数据时置高

    // AXI4 写响应通道 (Write Response Channel)
    .bvalid_s1  (s1_bvalid),               // 写响应有效：slave完成写操作后置高
    .bid_s1     (s1_bid),                  // 写响应ID：6位，与awid对应
    .bresp_s1   (s1_bresp),                // 写响应状态：2位，OKAY/EXOKAY/SLVERR/DECERR
    .bready_s1  (s1_bready),               // 写响应就绪：master准备接收响应时置高

    // AXI4 读地址通道 (Read Address Channel)
    .arvalid_s1 (s1_arvalid),              // 读地址有效：master发起读传输时置高
    .arid_s1    (s1_arid),                 // 读地址ID：6位事务标识符
    .araddr_s1  (s1_araddr),               // 读地址：32位地址，从master传来
    .arlen_s1   (s1_arlen),                // 突发长度：8位，表示传输个数-1
    .arsize_s1  (s1_arsize),               // 突发大小：3位，每次传输的字节数
    .arburst_s1 (s1_arburst),              // 突发类型：2位，FIXED/INCR/WRAP
    .arlock_s1  (s1_arlock),               // 原子锁：1位，用于原子操作
    .arcache_s1 (s1_arcache),              // 缓存属性：4位，控制缓存特性
    .arprot_s1  (s1_arprot),               // 保护类型：3位，特权/安全访问属性
    .arready_s1 (s1_arready),              // 读地址就绪：slave可接受地址时置高

    // AXI4 读数据通道 (Read Data Channel)
    .rvalid_s1  (s1_rvalid),               // 读数据有效：slave提供有效读数据时置高
    .rid_s1     (s1_rid),                  // 读数据ID：6位，与arid对应
    .rdata_s1   (s1_rdata),                // 读数据：64位从slave读取的数据
    .rresp_s1   (s1_rresp),                // 读响应状态：2位，OKAY/EXOKAY/SLVERR/DECERR
    .rlast_s1   (s1_rlast),                // 读数据最后：突发传输的最后一个数据
    .rready_s1  (s1_rready),               // 读数据就绪：master准备接收数据时置高

    // ==================== Slave2接口 - 连接到axi2bram_asic  ==============================
    // 地址：0x5000_0000 -- 0x502F_FFFF

    // AXI4 写地址通道 (Write Address Channel)
    .awvalid_s2 (s2_awvalid),              // 写地址有效：从master传来的写地址有效信号
    .awaddr_s2  (s2_awaddr),               // 写地址：32位地址，从master传来
    .awid_s2    (s2_awid),                 // 写地址ID：6位事务标识符
    .awlen_s2   (s2_awlen),                // 突发长度：8位，表示传输个数-1
    .awsize_s2  (s2_awsize),               // 突发大小：3位，每次传输的字节数
    .awburst_s2 (s2_awburst),              // 突发类型：2位，FIXED/INCR/WRAP
    .awlock_s2  (s2_awlock),               // 原子锁：1位，用于原子操作
    .awcache_s2 (s2_awcache),              // 缓存属性：4位，控制缓存特性
    .awprot_s2  (s2_awprot),               // 保护类型：3位，特权/安全访问属性
    .awready_s2 (s2_awready),              // 写地址就绪：slave可接受地址时置高

    // AXI4 写数据通道 (Write Data Channel)
    .wvalid_s2  (s2_wvalid),               // 写数据有效：master提供有效写数据时置高
    .wdata_s2   (s2_wdata),                // 写数据：64位实际要写入的数据
    .wstrb_s2   (s2_wstrb),                // 写字节选通：8位，每位对应一个字节使能
    .wlast_s2   (s2_wlast),                // 写数据最后：突发传输的最后一个数据
    .wready_s2  (s2_wready),               // 写数据就绪：slave可接受数据时置高

    // AXI4 写响应通道 (Write Response Channel)
    .bvalid_s2  (s2_bvalid),               // 写响应有效：slave完成写操作后置高
    .bid_s2     (s2_bid),                  // 写响应ID：6位，与awid对应
    .bresp_s2   (s2_bresp),                // 写响应状态：2位，OKAY/EXOKAY/SLVERR/DECERR
    .bready_s2  (s2_bready),               // 写响应就绪：master准备接收响应时置高

    // AXI4 读地址通道 (Read Address Channel)
    .arvalid_s2 (s2_arvalid),              // 读地址有效：master发起读传输时置高
    .arid_s2    (s2_arid),                 // 读地址ID：6位事务标识符
    .araddr_s2  (s2_araddr),               // 读地址：32位地址，从master传来
    .arlen_s2   (s2_arlen),                // 突发长度：8位，表示传输个数-1
    .arsize_s2  (s2_arsize),               // 突发大小：3位，每次传输的字节数
    .arburst_s2 (s2_arburst),              // 突发类型：2位，FIXED/INCR/WRAP
    .arlock_s2  (s2_arlock),               // 原子锁：1位，用于原子操作
    .arcache_s2 (s2_arcache),              // 缓存属性：4位，控制缓存特性
    .arprot_s2  (s2_arprot),               // 保护类型：3位，特权/安全访问属性
    .arready_s2 (s2_arready),              // 读地址就绪：slave可接受地址时置高

    // AXI4 读数据通道 (Read Data Channel)
    .rvalid_s2  (s2_rvalid),               // 读数据有效：slave提供有效读数据时置高
    .rid_s2     (s2_rid),                  // 读数据ID：6位，与arid对应
    .rdata_s2   (s2_rdata),                // 读数据：64位从slave读取的数据
    .rresp_s2   (s2_rresp),                // 读响应状态：2位，OKAY/EXOKAY/SLVERR/DECERR
    .rlast_s2   (s2_rlast),                // 读数据最后：突发传输的最后一个数据
    .rready_s2  (s2_rready)                // 读数据就绪：master准备接收数据时置高

    /*// ==================== Slave3接口 - 连接到axi2bram_64k_s3 (64KB BRAM) ====================
    // 地址：0x5008_0000 -- 0x500F_FFFF

    .awvalid_s3 (s3_awvalid),
    .awaddr_s3  (s3_awaddr),
    .awid_s3    (s3_awid),
    .awlen_s3   (s3_awlen),
    .awsize_s3  (s3_awsize),
    .awburst_s3 (s3_awburst),
    .awlock_s3  (s3_awlock),
    .awcache_s3 (s3_awcache),
    .awprot_s3  (s3_awprot),
    .awready_s3 (s3_awready),

    .wvalid_s3  (s3_wvalid),
    .wdata_s3   (s3_wdata),
    .wstrb_s3   (s3_wstrb),
    .wlast_s3   (s3_wlast),
    .wready_s3  (s3_wready),

    .bvalid_s3  (s3_bvalid),
    .bid_s3     (s3_bid),
    .bresp_s3   (s3_bresp),
    .bready_s3  (s3_bready),

    .arvalid_s3 (s3_arvalid),
    .arid_s3    (s3_arid),
    .araddr_s3  (s3_araddr),
    .arlen_s3   (s3_arlen),
    .arsize_s3  (s3_arsize),
    .arburst_s3 (s3_arburst),
    .arlock_s3  (s3_arlock),
    .arcache_s3 (s3_arcache),
    .arprot_s3  (s3_arprot),
    .arready_s3 (s3_arready),

    .rvalid_s3  (s3_rvalid),
    .rid_s3     (s3_rid),
    .rdata_s3   (s3_rdata),
    .rresp_s3   (s3_rresp),
    .rlast_s3   (s3_rlast),
    .rready_s3  (s3_rready),

    // ==================== Slave4接口 - 连接到axi2bram_64k_s4 (64KB BRAM) ====================
    // 地址：0x5010_0000 -- 0x5017_FFFF

    .awvalid_s4 (s4_awvalid),
    .awaddr_s4  (s4_awaddr),
    .awid_s4    (s4_awid),
    .awlen_s4   (s4_awlen),
    .awsize_s4  (s4_awsize),
    .awburst_s4 (s4_awburst),
    .awlock_s4  (s4_awlock),
    .awcache_s4 (s4_awcache),
    .awprot_s4  (s4_awprot),
    .awready_s4 (s4_awready),

    .wvalid_s4  (s4_wvalid),
    .wdata_s4   (s4_wdata),
    .wstrb_s4   (s4_wstrb),
    .wlast_s4   (s4_wlast),
    .wready_s4  (s4_wready),

    .bvalid_s4  (s4_bvalid),
    .bid_s4     (s4_bid),
    .bresp_s4   (s4_bresp),
    .bready_s4  (s4_bready),

    .arvalid_s4 (s4_arvalid),
    .arid_s4    (s4_arid),
    .araddr_s4  (s4_araddr),
    .arlen_s4   (s4_arlen),
    .arsize_s4  (s4_arsize),
    .arburst_s4 (s4_arburst),
    .arlock_s4  (s4_arlock),
    .arcache_s4 (s4_arcache),
    .arprot_s4  (s4_arprot),
    .arready_s4 (s4_arready),

    .rvalid_s4  (s4_rvalid),
    .rid_s4     (s4_rid),
    .rdata_s4   (s4_rdata),
    .rresp_s4   (s4_rresp),
    .rlast_s4   (s4_rlast),
    .rready_s4  (s4_rready)*/

);

// ==================== axi2bram1mb_wrapper_s1实例化 (128KB BRAM控制器 - 连接到S1) ====================
axi2bram1mb_wrapper u_axi2bram1mb_wrapper_s1 (
    // BRAM Port A接口 - 连接到128KB BRAM (S1)
    .BRAM_PORTA_0_addr  (bram_1m_s1_addr),     // BRAM地址：14位（字对齐，AXI地址[16:3]映射）
    .BRAM_PORTA_0_clk   (bram_1m_s1_clk),      // BRAM时钟
    .BRAM_PORTA_0_din   (bram_1m_s1_din),      // BRAM写数据：64位
    .BRAM_PORTA_0_dout  (bram_1m_s1_dout),     // BRAM读数据：64位
    .BRAM_PORTA_0_en    (bram_1m_s1_en),       // BRAM使能信号
    .BRAM_PORTA_0_rst   (bram_1m_s1_rst),      // BRAM复位信号
    .BRAM_PORTA_0_we    (bram_1m_s1_we),       // BRAM写使能：8位字节使能

    // AXI4 Slave接口 - 连接到bus_top的S1 (支持6位ID)
    // 写地址通道 (Write Address Channel)
    .S_AXI_0_awaddr   (s1_awaddr[19:0]),    // 写地址：20位，1MB地址空间（实际BRAM只有128KB）
    .S_AXI_0_awburst  (s1_awburst),         // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_0_awcache  (s1_awcache),         // 缓存属性：4位
    .S_AXI_0_awid     (s1_awid),            // 写地址ID：6位 ✅ 现在支持!
    .S_AXI_0_awlen    (s1_awlen),           // 突发长度：8位
    .S_AXI_0_awlock   (s1_awlock),          // 原子锁：1位
    .S_AXI_0_awprot   (s1_awprot),          // 保护类型：3位
    .S_AXI_0_awready  (s1_awready),         // 写地址就绪
    .S_AXI_0_awsize   (s1_awsize),          // 突发大小：3位
    .S_AXI_0_awvalid  (s1_awvalid),         // 写地址有效

    // 写数据通道 (Write Data Channel)
    .S_AXI_0_wdata    (s1_wdata),           // 写数据：64位
    .S_AXI_0_wlast    (s1_wlast),           // 写数据最后
    .S_AXI_0_wready   (s1_wready),          // 写数据就绪
    .S_AXI_0_wstrb    (s1_wstrb),           // 写字节选通：8位
    .S_AXI_0_wvalid   (s1_wvalid),          // 写数据有效

    // 写响应通道 (Write Response Channel) ✅ 现在支持ID!
    .S_AXI_0_bid      (s1_bid),             // 写响应ID：6位 ✅ 现在支持!
    .S_AXI_0_bready   (s1_bready),          // 写响应就绪
    .S_AXI_0_bresp    (s1_bresp),           // 写响应状态：2位
    .S_AXI_0_bvalid   (s1_bvalid),          // 写响应有效

    // 读地址通道 (Read Address Channel)
    .S_AXI_0_araddr   (s1_araddr[19:0]),    // 读地址：20位，1MB地址空间（实际BRAM只有128KB）
    .S_AXI_0_arburst  (s1_arburst),         // 突发类型：2位
    .S_AXI_0_arcache  (s1_arcache),         // 缓存属性：4位
    .S_AXI_0_arid     (s1_arid),            // 读地址ID：6位 ✅ 现在支持!
    .S_AXI_0_arlen    (s1_arlen),           // 突发长度：8位
    .S_AXI_0_arlock   (s1_arlock),          // 原子锁：1位
    .S_AXI_0_arprot   (s1_arprot),          // 保护类型：3位
    .S_AXI_0_arready  (s1_arready),         // 读地址就绪
    .S_AXI_0_arsize   (s1_arsize),          // 突发大小：3位
    .S_AXI_0_arvalid  (s1_arvalid),         // 读地址有效

    // 读数据通道 (Read Data Channel)
    .S_AXI_0_rdata    (s1_rdata),           // 读数据：64位
    .S_AXI_0_rid      (s1_rid),             // 读响应ID：6位 ✅ 现在支持!
    .S_AXI_0_rlast    (s1_rlast),           // 读数据最后
    .S_AXI_0_rready   (s1_rready),          // 读数据就绪
    .S_AXI_0_rresp    (s1_rresp),           // 读响应状态：2位
    .S_AXI_0_rvalid   (s1_rvalid),          // 读数据有效

    // 系统信号
    .s_axi_aclk_0     (clk),                // 系统时钟
    .s_axi_aresetn_0  (rst_n)               // 系统复位（高有效）
);

// ==================== ID信号处理 (已修复 - 现在wrapper支持6位ID) ====================
// ✅ axi2bram1mb_wrapper现在都支持6位ID
// ✅ 不再需要手动assign ID信号，wrapper会自动处理
// ✅ 这应该解决DMA卡在RUN状态的问题

// ==================== 128KB BRAM实例化 (S1) ====================
e203_bram_1m u_bram_1m_s1 (
    .bram_addr  (bram_1m_s1_addr[13:0]), // BRAM地址：14位（字对齐，相邻地址+1对应不同64位字）
    .bram_clk   (bram_1m_s1_clk),        // BRAM时钟
    .bram_din   (bram_1m_s1_din),        // BRAM写数据：64位
    .bram_dout  (bram_1m_s1_dout),       // BRAM读数据：64位
    .bram_en    (bram_1m_s1_en),         // BRAM使能
    .bram_rst   (bram_1m_s1_rst),        // BRAM复位
    .bram_we    (bram_1m_s1_we),         // BRAM写使能：8位
    .rst_n      (rst_n)                  // 系统复位
);



  //---------------------------------------------------------------------------
  // new: APB Peripheral (zy)
  // date: 25/06/15
  //---------------------------------------------------------------------------
  
  // 定义端口
  wire  [32-1:0] expl_apb_paddr   ;
  wire           expl_apb_pwrite  ;
  wire           expl_apb_pselx   ;
  wire           expl_apb_penable ;
  wire  [32-1:0] expl_apb_pwdata  ;
  wire  [32-1:0] expl_apb_prdata  ;
  
  // 例化ICB转换APB模块
  sirv_gnrl_icb2apb # (
  .AW   (32),
  .DW   (`E203_XLEN) 
) u_expl_apb_icb2apb(
    .i_icb_cmd_valid (expl_apb_icb_cmd_valid),
    .i_icb_cmd_ready (expl_apb_icb_cmd_ready),
    .i_icb_cmd_addr  (expl_apb_icb_cmd_addr),
    .i_icb_cmd_read  (expl_apb_icb_cmd_read),
    .i_icb_cmd_wdata (expl_apb_icb_cmd_wdata),
    .i_icb_cmd_wmask (expl_apb_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (expl_apb_icb_rsp_valid),
    .i_icb_rsp_ready (expl_apb_icb_rsp_ready),
    .i_icb_rsp_rdata (expl_apb_icb_rsp_rdata),
    .i_icb_rsp_err   (expl_apb_icb_rsp_err),

    .apb_paddr     (expl_apb_paddr),
    .apb_pwrite    (expl_apb_pwrite),
    .apb_pselx     (expl_apb_pselx),
    .apb_penable   (expl_apb_penable), 
    .apb_pwdata    (expl_apb_pwdata),
    .apb_prdata    (expl_apb_prdata),

    .clk           (clk  ),
    .rst_n         (rst_n) 
  );

  //例化APB_MUX模块
  design_apb_mux #(
    .ADDR_WIDTH (32),
    .DATA_WIDTH (32),
    .PORT0_ENABLE (1),
    .PORT1_ENABLE (1),
    .PORT2_ENABLE (1)
  ) u_design_apb_mux(
    .clk           (clk  ),
    .rst_n         (rst_n),
    .paddr         (expl_apb_paddr),
    .pwrite        (expl_apb_pwrite),
    .pselx         (expl_apb_pselx),
    .penable       (expl_apb_penable),
    .pwdata        (expl_apb_pwdata),
    .prdata        (expl_apb_prdata),

    .paddr0        (bram_2_addr),
    .pwrite0       (bram_2_write),
    .pselx0        (bram_2_sel),
    .penable0      (bram_2_enable),
    .pwdata0       (bram_2_wdata),
    .prdata0       (bram_2_rdata),

    // .paddr1        (mac_apb_paddr),
    // .pwrite1       (mac_apb_pwrite),
    // .pselx1        (mac_apb_psel),
    // .penable1      (mac_apb_penable),
    // .pwdata1       (mac_apb_pwdata),
    // .prdata1       (mac_apb_prdata),

    .paddr2        (dma_paddr_full),     // 连接到DMA APB地址
    .pwrite2       (dma_pwrite),         // 连接到DMA APB写使能
    .pselx2        (dma_psel),           // 连接到DMA APB选择
    .penable2      (dma_penable),        // 连接到DMA APB使能
    .pwdata2       (dma_pwdata),         // 连接到DMA APB写数据
    .prdata2       (dma_prdata)          // 连接到DMA APB读数据
  );
/*
// ==================== MacMachine_top APB接口信号 ====================
wire [31:0]  mac_apb_paddr;
wire         mac_apb_pwrite;
wire         mac_apb_psel;
wire         mac_apb_penable;
wire [31:0]  mac_apb_pwdata;
wire [31:0]  mac_apb_prdata;
wire         mac_apb_pready;
wire         mac_apb_pslverr;

// ==================== MacMachine_top中断信号 ====================
wire         macMachineDone_interrupt;
wire         macMachineerror_interrupt;

// ==================== MacMachine_top实例化 ====================
MacMachine_top u_mac_machine_top (
    // APB Slave interface
    .apb_paddr       (mac_apb_paddr),             // APB address
    .apb_pwrite      (mac_apb_pwrite),            // APB write enable
    .apb_psel        (mac_apb_psel),              // APB select
    .apb_penable     (mac_apb_penable),           // APB enable
    .apb_pwdata      (mac_apb_pwdata),            // APB write data
    .apb_prdata      (mac_apb_prdata),            // APB read data

    // Slave 2 Input SRAM 0 interface (connects directly to u_axi2bram_64k.bram1)
    .input_sram0_bram_clk         (bram_64k_clk),               // Clock from axi2bram
    .input_sram0_bram_rst_n       (bram_64k_rst_n),             // Reset from axi2bram
    .input_sram0_bram_w_addr      (bram_64k_w_addr),            // Write address
    .input_sram0_bram_w_din       (bram_64k_w_din),             // Write data
    .input_sram0_bram_w_en        (bram_64k_w_en),              // Write enable
    .input_sram0_bram_w_we        (bram_64k_w_we),              // Write byte enable
    .input_sram0_bram_r_addr      (bram_64k_r_addr),            // Read address
    .input_sram0_bram_r_dout      (bram_64k_r_dout),            // Read data
    .input_sram0_bram_r_en        (bram_64k_r_en),              // Read enable

    // Slave 3 Weight SRAM 0 control interface (connects to slave3 RAM1)
    .weight_sram0_enable          (s3_mac_enable),              // Enable from switch
    .weight_sram0_bram_clk        (s3_mac_bram_clk),            // Clock to external SRAM
    .weight_sram0_bram_rst_n      (s3_mac_bram_rst_n),          // Reset to external SRAM
    .weight_sram0_bram_w_addr     (s3_mac_bram_w_addr),         // Write address
    .weight_sram0_bram_w_din      (s3_mac_bram_w_din),          // Write data
    .weight_sram0_bram_w_en       (s3_mac_bram_w_en),           // Write enable
    .weight_sram0_bram_w_we       (s3_mac_bram_w_we),           // Write byte enable
    .weight_sram0_bram_r_addr     (s3_mac_bram_r_addr),         // Read address
    .weight_sram0_bram_r_dout     (s3_mac_bram_r_dout),         // Read data from external SRAM
    .weight_sram0_bram_r_en       (s3_mac_bram_r_en),           // Read enable

    // Slave 3 Weight SRAM 1 control interface (connects to slave3 RAM2)
    .weight_sram1_enable          (s3_2_mac_enable),            // Enable from switch
    .weight_sram1_bram_clk        (s3_2_mac_bram_clk),          // Clock to external SRAM
    .weight_sram1_bram_rst_n      (s3_2_mac_bram_rst_n),        // Reset to external SRAM
    .weight_sram1_bram_w_addr     (s3_2_mac_bram_w_addr),       // Write address
    .weight_sram1_bram_w_din      (s3_2_mac_bram_w_din),        // Write data
    .weight_sram1_bram_w_en       (s3_2_mac_bram_w_en),         // Write enable
    .weight_sram1_bram_w_we       (s3_2_mac_bram_w_we),         // Write byte enable
    .weight_sram1_bram_r_addr     (s3_2_mac_bram_r_addr),       // Read address
    .weight_sram1_bram_r_dout     (s3_2_mac_bram_r_dout),       // Read data from external SRAM
    .weight_sram1_bram_r_en       (s3_2_mac_bram_r_en),         // Read enable

    // Slave 4 Output SRAM 0 control interface (connects to slave4 RAM1)
    .output_sram0_enable          (s4_mac_enable),              // Enable from switch
    .output_sram0_bram_clk        (s4_mac_bram_clk),            // Clock to external SRAM
    .output_sram0_bram_rst_n      (s4_mac_bram_rst_n),          // Reset to external SRAM
    .output_sram0_bram_w_addr     (s4_mac_bram_w_addr),         // Write address
    .output_sram0_bram_w_din      (s4_mac_bram_w_din),          // Write data
    .output_sram0_bram_w_en       (s4_mac_bram_w_en),           // Write enable
    .output_sram0_bram_w_we       (s4_mac_bram_w_we),           // Write byte enable
    .output_sram0_bram_r_addr     (s4_mac_bram_r_addr),         // Read address
    .output_sram0_bram_r_dout     (s4_mac_bram_r_dout),         // Read data from external SRAM
    .output_sram0_bram_r_en       (s4_mac_bram_r_en),           // Read enable

    // Slave 4 Output SRAM 1 control interface (connects to slave4 RAM2)
    .output_sram1_enable          (s4_2_mac_enable),            // Enable from switch
    .output_sram1_bram_clk        (s4_2_mac_bram_clk),          // Clock to external SRAM
    .output_sram1_bram_rst_n      (s4_2_mac_bram_rst_n),        // Reset to external SRAM
    .output_sram1_bram_w_addr     (s4_2_mac_bram_w_addr),       // Write address
    .output_sram1_bram_w_din      (s4_2_mac_bram_w_din),        // Write data
    .output_sram1_bram_w_en       (s4_2_mac_bram_w_en),         // Write enable
    .output_sram1_bram_w_we       (s4_2_mac_bram_w_we),         // Write byte enable
    .output_sram1_bram_r_addr     (s4_2_mac_bram_r_addr),       // Read address
    .output_sram1_bram_r_dout     (s4_2_mac_bram_r_dout),       // Read data from external SRAM
    .output_sram1_bram_r_en       (s4_2_mac_bram_r_en),         // Read enable

    // Interrupts
    .macMachineDone_interrupt     (macMachineDone_interrupt),   // Done interrupt
    .macMachineerror_interrupt    (macMachineerror_interrupt),  // Error interrupt

    // System signals
    .clk                          (clk),                         // System clock
    .rst_n                        (rst_n)                        // System reset
);

// ==================== 中断信号连接到模块输出 ====================
// MAC中断连接
assign mac_done_irq = macMachineDone_interrupt;    // MAC完成中断
assign mac_err_irq  = macMachineerror_interrupt;   // MAC错误中断
*/
  //例化两个BRAM
  e203_bram_8k u_bram_8k_2 (
    .bram_addr  (bram_2_addr[14:2]),
    .bram_clk   (clk),
    .bram_din   (bram_2_wdata),
    .bram_dout  (bram_2_rdata),
    .bram_en    (bram_2_sel),
    .bram_rst   (!rst_n),
    .bram_we    (bram_2_we),
    .rst_n      (rst_n)
  );

  // BRAM_3实例化已取消，由MacMachine_top替代

    // ==================== DMA控制器实例化 ====================
  dma_top u_dma_top (
    // 系统信号
    .clk              (clk),                    // 主时钟
    .rst_n            (rst_n),                  // 主复位

    // 中断信号
    .intr_dma_done    (dma_intr_done),          // DMA完成中断ID=14
    .intr_dma_err     (dma_intr_err),           // DMA错误中断ID=15

    // APB从设备接口
    .psel             (dma_psel),               // APB选择信号
    .penable          (dma_penable),            // APB使能信号
    .pwrite           (dma_pwrite),             // APB写使能信号
    .paddr            (dma_paddr),              // APB地址信号
    .pwdata           (dma_pwdata),             // APB写数据信号
    .prdata           (dma_prdata),             // APB读数据信号
    .pready           (dma_pready),             // APB就绪信号
    .pslverr          (dma_pslverr),            // APB从设备错误信号

    // AXI主设备接口 - 写地址通道
    .axim_awlock      (dma_axim_awlock),        // AXI写地址锁信号
    .axim_awcache     (dma_axim_awcache),       // AXI写地址缓存信号
    .axim_awprot      (dma_axim_awprot),        // AXI写地址保护信号
    .axim_awqos       (dma_axim_awqos),         // AXI写地址QoS信号
    .axim_awaddr      (dma_axim_awaddr),        // AXI写地址
    .axim_awlen       (dma_axim_awlen),         // AXI写突发长度
    .axim_awsize      (dma_axim_awsize),        // AXI写突发大小
    .axim_awburst     (dma_axim_awburst),       // AXI写突发类型
    .axim_awvalid     (dma_axim_awvalid),       // AXI写地址有效
    .axim_awready     (dma_axim_awready),       // AXI写地址就绪

    // AXI主设备接口 - 写数据通道
    .axim_wdata       (dma_axim_wdata),         // AXI写数据
    .axim_wstrb       (dma_axim_wstrb),         // AXI写数据选通
    .axim_wlast       (dma_axim_wlast),         // AXI写数据最后
    .axim_wvalid      (dma_axim_wvalid),        // AXI写数据有效
    .axim_wready      (dma_axim_wready),        // AXI写数据就绪

    // AXI主设备接口 - 写响应通道
    .axim_bresp       (dma_axim_bresp),         // AXI写响应
    .axim_bvalid      (dma_axim_bvalid),        // AXI写响应有效
    .axim_bready      (dma_axim_bready),        // AXI写响应就绪

    // AXI主设备接口 - 读地址通道
    .axim_arlock      (dma_axim_arlock),        // AXI读地址锁信号
    .axim_arcache     (dma_axim_arcache),       // AXI读地址缓存信号
    .axim_arprot      (dma_axim_arprot),        // AXI读地址保护信号
    .axim_arqos       (dma_axim_arqos),         // AXI读地址QoS信号
    .axim_araddr      (dma_axim_araddr),        // AXI读地址
    .axim_arlen       (dma_axim_arlen),         // AXI读突发长度
    .axim_arsize      (dma_axim_arsize),        // AXI读突发大小
    .axim_arburst     (dma_axim_arburst),       // AXI读突发类型
    .axim_arvalid     (dma_axim_arvalid),       // AXI读地址有效
    .axim_arready     (dma_axim_arready),       // AXI读地址就绪

    // AXI主设备接口 - 读数据通道
    .axim_rdata       (dma_axim_rdata),         // AXI读数据
    .axim_rresp       (dma_axim_rresp),         // AXI读响应
    .axim_rlast       (dma_axim_rlast),         // AXI读数据最后
    .axim_rvalid      (dma_axim_rvalid),        // AXI读数据有效
    .axim_rready      (dma_axim_rready),        // AXI读数据就绪

    // AXI ID信号（可选，本设计中不使用）
    .axim_awid        (dma_axim_awid),          // AXI写ID
    .axim_bid         (dma_axim_bid),           // AXI写响应ID
    .axim_arid        (dma_axim_arid),          // AXI读ID
    .axim_rid         (dma_axim_rid)            // AXI读响应ID
  );
/*
// ==================== RAM Control Switch and MAC Controller for S2 ====================

// Internal BRAM interfaces for S2 - Pseudo dual-port
// Write port
wire [10:0]  s2_switch_bram_w_addr;
wire         s2_switch_bram_clk;
wire         s2_switch_bram_rst_n;
wire [255:0] s2_switch_bram_w_din;
wire         s2_switch_bram_w_en;
wire [31:0]  s2_switch_bram_w_we;
// Read port
wire [10:0]  s2_switch_bram_r_addr;
wire [255:0] s2_switch_bram_r_dout;
wire         s2_switch_bram_r_en;

// MAC controller interfaces for S2 - Pseudo dual-port
// Write port
wire [10:0]  s2_mac_bram_w_addr;
wire         s2_mac_bram_clk;
wire         s2_mac_bram_rst_n;
wire [255:0] s2_mac_bram_w_din;
wire         s2_mac_bram_w_en;
wire [31:0]  s2_mac_bram_w_we;
// Read port
wire [10:0]  s2_mac_bram_r_addr;
wire [255:0] s2_mac_bram_r_dout;
wire         s2_mac_bram_r_en;

// Control interface for S2
wire         s2_ctrl_valid;
wire [31:0]  s2_ctrl_data;
wire         s2_ctrl_ready;
wire         s2_mac_enable;

// BRAM interface signals for S2 RAM2 (axi2bram_64k <-> RamCtrlSwitch) - Pseudo dual-port
// Write port
wire [10:0]  bram_64k_s2_2_w_addr;
wire         bram_64k_s2_2_clk;
wire         bram_64k_s2_2_rst_n;
wire [255:0] bram_64k_s2_2_w_din;
wire         bram_64k_s2_2_w_en;
wire [31:0]  bram_64k_s2_2_w_we;
// Read port
wire [10:0]  bram_64k_s2_2_r_addr;
wire [255:0] bram_64k_s2_2_r_dout;
wire         bram_64k_s2_2_r_en;

// ==================== axi2bram_64k实例化 (64KB BRAM控制器 - 连接到S2) ====================
axi2bram_64k u_axi2bram_64k (
    // AXI Clock and Reset
    .s_axi_aclk      (clk),                    // 系统时钟
    .s_axi_aresetn   (rst_n),                  // 系统复位（高有效）

    // AXI Read Address Channel
    .S_AXI_araddr    (s2_araddr[31:0]),        // 读地址：32位（slave地址空间0x5000_0000~0x500F_FFFF）
    .S_AXI_arburst   (s2_arburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_arcache   (s2_arcache),             // 缓存属性：4位
    .S_AXI_arid      (s2_arid),                // 读地址ID：6位
    .S_AXI_arlen     (s2_arlen),               // 突发长度：8位
    .S_AXI_arlock    (s2_arlock),              // 原子锁：1位
    .S_AXI_arprot    (s2_arprot),              // 保护类型：3位
    .S_AXI_arready   (s2_arready),             // 读地址就绪
    .S_AXI_arsize    (s2_arsize),              // 突发大小：3位
    .S_AXI_arvalid   (s2_arvalid),             // 读地址有效

    // AXI Write Address Channel
    .S_AXI_awaddr    (s2_awaddr[31:0]),        // 写地址：32位（slave地址空间0x5000_0000~0x500F_FFFF）
    .S_AXI_awburst   (s2_awburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_awcache   (s2_awcache),             // 缓存属性：4位
    .S_AXI_awid      (s2_awid),                // 写地址ID：6位
    .S_AXI_awlen     (s2_awlen),               // 突发长度：8位
    .S_AXI_awlock    (s2_awlock),              // 原子锁：1位
    .S_AXI_awprot    (s2_awprot),              // 保护类型：3位
    .S_AXI_awready   (s2_awready),             // 写地址就绪
    .S_AXI_awsize    (s2_awsize),              // 突发大小：3位
    .S_AXI_awvalid   (s2_awvalid),             // 写地址有效

    // AXI Write Data Channel
    .S_AXI_wdata     (s2_wdata),               // 写数据：64位
    .S_AXI_wlast     (s2_wlast),               // 写数据最后
    .S_AXI_wready    (s2_wready),              // 写数据就绪
    .S_AXI_wstrb     (s2_wstrb),               // 写字节选通：8位
    .S_AXI_wvalid    (s2_wvalid),              // 写数据有效

    // AXI Write Response Channel
    .S_AXI_bid       (s2_bid),                 // 写响应ID：6位
    .S_AXI_bready    (s2_bready),              // 写响应就绪
    .S_AXI_bresp     (s2_bresp),               // 写响应状态：2位
    .S_AXI_bvalid    (s2_bvalid),              // 写响应有效

    // AXI Read Data Channel
    .S_AXI_rdata     (s2_rdata),               // 读数据：64位
    .S_AXI_rid       (s2_rid),                 // 读响应ID：6位
    .S_AXI_rlast     (s2_rlast),               // 读数据最后
    .S_AXI_rready    (s2_rready),              // 读数据就绪
    .S_AXI_rresp     (s2_rresp),               // 读响应状态：2位
    .S_AXI_rvalid    (s2_rvalid),              // 读数据有效

    // BRAM1 Interface (Pseudo Dual-Port SRAM) - First RAM (0x0_0000~0x0_FFFF)
    .bram1_clk       (bram_64k_clk),          // Common clock
    .bram1_rst_n     (bram_64k_rst_n),        // Active low reset
    // Write port
    .bram1_w_addr    (bram_64k_w_addr),       // Write address
    .bram1_w_din     (bram_64k_w_din),        // Write data
    .bram1_w_en      (bram_64k_w_en),         // Write enable
    .bram1_w_we      (bram_64k_w_we),         // Write byte enable
    // Read port
    .bram1_r_addr    (bram_64k_r_addr),       // Read address
    .bram1_r_dout    (bram_64k_r_dout),       // Read data
    .bram1_r_en      (bram_64k_r_en),         // Read enable

    // BRAM2 Interface (Pseudo Dual-Port SRAM) - Second RAM (0x1_0000~0x1_FFFF) - DISABLED
    // .bram2_clk       (bram_64k_s2_2_clk),     // Common clock
    // .bram2_rst_n     (bram_64k_s2_2_rst_n),   // Active low reset
    // Write port
    // .bram2_w_addr    (bram_64k_s2_2_w_addr),  // Write address
    // .bram2_w_din     (bram_64k_s2_2_w_din),   // Write data
    // .bram2_w_en      (bram_64k_s2_2_w_en),    // Write enable
    // .bram2_w_we      (bram_64k_s2_2_w_we),    // Write byte enable
    // Read port
    // .bram2_r_addr    (bram_64k_s2_2_r_addr),  // Read address
    // .bram2_r_dout    (bram_64k_s2_2_r_dout),  // Read data
    // .bram2_r_en      (bram_64k_s2_2_r_en),    // Read enable

    // Tie off BRAM2 signals since slave2 doesn't need RAM2
    .bram2_clk       (1'b0),                   // Common clock
    .bram2_rst_n     (1'b1),                   // Active low reset
    .bram2_w_addr    (11'h0),                  // Write address
    .bram2_w_din     (256'h0),                 // Write data
    .bram2_w_en      (1'b0),                   // Write enable
    .bram2_w_we      (32'h0),                  // Write byte enable
    .bram2_r_addr    (11'h0),                  // Read address
    .bram2_r_dout    (),                       // Read data - unconnected
    .bram2_r_en      (1'b0),                   // Read enable

    // Control interface for RamCtrlSwitch RAM1 (address 0x7_F000)
    .ctrl_valid      (s2_ctrl_valid),          // Control write valid for RAM1
    .ctrl_data       (s2_ctrl_data),           // Control data for RAM1
    .ctrl_ready      (s2_ctrl_ready),          // Control ready for RAM1

    // Control interface for RamCtrlSwitch RAM2 (address 0x7_F000) - DISABLED
    // .ctrl2_valid     (s2_2_ctrl_valid),        // Control write valid for RAM2
    // .ctrl2_data      (s2_2_ctrl_data),         // Control data for RAM2
    // .ctrl2_ready     (s2_2_ctrl_ready)         // Control ready for RAM2

    // Tie off BRAM2 control signals
    .ctrl2_valid     (1'b0),                   // Control write valid for RAM2
    .ctrl2_data      (32'h0),                  // Control data for RAM2
    .ctrl2_ready     ()                        // Control ready for RAM2 - unconnected
);

// ==================== RAM Control Switch and MAC Controller for S2 RAM2 ====================
// DISABLED - slave2 doesn't need RAM2

/*
 // Internal BRAM interfaces for S2 RAM2 - Pseudo dual-port
 // Write port
 wire [10:0]  s2_2_switch_bram_w_addr;
 wire         s2_2_switch_bram_clk;
 wire         s2_2_switch_bram_rst_n;
 wire [255:0] s2_2_switch_bram_w_din;
 wire         s2_2_switch_bram_w_en;
 wire [31:0]  s2_2_switch_bram_w_we;
 // Read port
 wire [10:0]  s2_2_switch_bram_r_addr;
 wire [255:0] s2_2_switch_bram_r_dout;
 wire         s2_2_switch_bram_r_en;

 // MAC controller interfaces for S2 RAM2 - Pseudo dual-port
 // Write port
 wire [10:0]  s2_2_mac_bram_w_addr;
 wire         s2_2_mac_bram_clk;
 wire         s2_2_mac_bram_rst_n;
 wire [255:0] s2_2_mac_bram_w_din;
 wire         s2_2_mac_bram_w_en;
 wire [31:0]  s2_2_mac_bram_w_we;
 // Read port
 wire [10:0]  s2_2_mac_bram_r_addr;
 wire [255:0] s2_2_mac_bram_r_dout;
 wire         s2_2_mac_bram_r_en;

 // Control interface for S2 RAM2
 wire         s2_2_ctrl_valid;
 wire [31:0]  s2_2_ctrl_data;
 wire         s2_2_ctrl_ready;
 wire         s2_2_mac_enable;
 */

// ==================== RAM Control Switch for S2 RAM1 ====================
// DISABLED - input_sram now connects directly to u_axi2bram_64k.bram1

// ==================== MAC Machine RAM Controller for S2 RAM1 ====================
// DISABLED - slave2 RAM1 replaced by MacMachine_top

// ==================== RAM Control Switch for S2 RAM2 ====================
// DISABLED - slave2 doesn't need RAM2

/*
 RamCtrlSwitch u_ram_switch_s2_2 (
     .clk             (clk),                     // 系统时钟
     .rst_n           (rst_n),                   // 系统复位

     // Control interface from AXI
     .ctrl_valid      (s2_2_ctrl_valid),        // Control write valid
     .ctrl_data       (s2_2_ctrl_data),         // Control data
     .ctrl_ready      (s2_2_ctrl_ready),        // Control ready

     // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
     .axi_bram_clk    (bram_64k_s2_2_clk),     // AXI BRAM clock
     .axi_bram_rst_n  (bram_64k_s2_2_rst_n),   // AXI BRAM reset
     // AXI Write port
     .axi_bram_w_addr (bram_64k_s2_2_w_addr),  // AXI BRAM write address
     .axi_bram_w_din  (bram_64k_s2_2_w_din),   // AXI BRAM write data
     .axi_bram_w_en   (bram_64k_s2_2_w_en),    // AXI BRAM write enable
     .axi_bram_w_we   (bram_64k_s2_2_w_we),    // AXI BRAM write byte enable
     // AXI Read port
     .axi_bram_r_addr (bram_64k_s2_2_r_addr),  // AXI BRAM read address
     .axi_bram_r_dout (bram_64k_s2_2_r_dout),  // AXI BRAM read data
     .axi_bram_r_en   (bram_64k_s2_2_r_en),    // AXI BRAM read enable

     // BRAM interface from MAC controller - Pseudo dual-port
     .mac_bram_clk    (s2_2_mac_bram_clk),      // MAC BRAM clock
     .mac_bram_rst_n  (s2_2_mac_bram_rst_n),    // MAC BRAM reset
     // MAC Write port
     .mac_bram_w_addr (s2_2_mac_bram_w_addr),   // MAC BRAM write address
     .mac_bram_w_din  (s2_2_mac_bram_w_din),    // MAC BRAM write data
     .mac_bram_w_en   (s2_2_mac_bram_w_en),     // MAC BRAM write enable
     .mac_bram_w_we   (s2_2_mac_bram_w_we),     // MAC BRAM write byte enable
     // MAC Read port
     .mac_bram_r_addr (s2_2_mac_bram_r_addr),   // MAC BRAM read address
     .mac_bram_r_dout (s2_2_mac_bram_r_dout),   // MAC BRAM read data
     .mac_bram_r_en   (s2_2_mac_bram_r_en),     // MAC BRAM read enable

     // BRAM interface to actual BRAM - Pseudo dual-port
     .bram_clk        (s2_2_switch_bram_clk),   // Switch BRAM clock
     .bram_rst_n      (s2_2_switch_bram_rst_n), // Switch BRAM reset
     // Write port
     .bram_w_addr     (s2_2_switch_bram_w_addr), // Switch BRAM write address
     .bram_w_din      (s2_2_switch_bram_w_din),  // Switch BRAM write data
     .bram_w_en       (s2_2_switch_bram_w_en),   // Switch BRAM write enable
     .bram_w_we       (s2_2_switch_bram_w_we),   // Switch BRAM write byte enable
     // Read port
     .bram_r_addr     (s2_2_switch_bram_r_addr), // Switch BRAM read address
     .bram_r_dout     (s2_2_switch_bram_r_dout), // Switch BRAM read data
     .bram_r_en       (s2_2_switch_bram_r_en),   // Switch BRAM read enable

     // Control output to MAC controller
     .mac_enable      (s2_2_mac_enable)         // MAC enable signal
 );
 */

// ==================== MAC Machine RAM Controller for S2 RAM2 ====================
// DISABLED - slave2 doesn't need RAM2, replaced by MacMachine_top

// ==================== 64KB BRAM实例化 (S2 RAM1) ====================
// DISABLED - input_sram now connects directly to u_axi2bram_64k.bram1, no separate BRAM needed

// ==================== 64KB BRAM实例化 (S2 RAM2) - Now connects to switch ====================
// DISABLED - slave2 doesn't need RAM2

/*
 e203_bram_64k u_bram_64k_s2_2 (
     .clk        (s2_2_switch_bram_clk),    // Common clock
     .rst_n      (s2_2_switch_bram_rst_n),  // Active low reset
     // Write port
     .w_addr     (s2_2_switch_bram_w_addr), // Write address
     .w_din      (s2_2_switch_bram_w_din),  // Write data
     .w_en       (s2_2_switch_bram_w_en),   // Write enable
     .w_we       (s2_2_switch_bram_w_we),   // Write byte enable
     // Read port
     .r_addr     (s2_2_switch_bram_r_addr), // Read address
     .r_dout     (s2_2_switch_bram_r_dout), // Read data
     .r_en       (s2_2_switch_bram_r_en)    // Read enable
 );
 */
/*
// ==================== RAM Control Switch and MAC Controller for S3 ====================

// Internal BRAM interfaces for S3 - Pseudo dual-port
// Write port
wire [10:0]  s3_switch_bram_w_addr;
wire         s3_switch_bram_clk;
wire         s3_switch_bram_rst_n;
wire [255:0] s3_switch_bram_w_din;
wire         s3_switch_bram_w_en;
wire [31:0]  s3_switch_bram_w_we;
// Read port
wire [10:0]  s3_switch_bram_r_addr;
wire [255:0] s3_switch_bram_r_dout;
wire         s3_switch_bram_r_en;

// MAC controller interfaces for S3 - Pseudo dual-port
// Write port
wire [10:0]  s3_mac_bram_w_addr;
wire         s3_mac_bram_clk;
wire         s3_mac_bram_rst_n;
wire [255:0] s3_mac_bram_w_din;
wire         s3_mac_bram_w_en;
wire [31:0]  s3_mac_bram_w_we;
// Read port
wire [10:0]  s3_mac_bram_r_addr;
wire [255:0] s3_mac_bram_r_dout;
wire         s3_mac_bram_r_en;

// Control interface for S3
wire         s3_ctrl_valid;
wire [31:0]  s3_ctrl_data;
wire         s3_ctrl_ready;
wire         s3_mac_enable;

// Internal BRAM interfaces for S3 RAM2 - Pseudo dual-port
// Write port
wire [10:0]  s3_2_switch_bram_w_addr;
wire         s3_2_switch_bram_clk;
wire         s3_2_switch_bram_rst_n;
wire [255:0] s3_2_switch_bram_w_din;
wire         s3_2_switch_bram_w_en;
wire [31:0]  s3_2_switch_bram_w_we;
// Read port
wire [10:0]  s3_2_switch_bram_r_addr;
wire [255:0] s3_2_switch_bram_r_dout;
wire         s3_2_switch_bram_r_en;

// MAC controller interfaces for S3 RAM2 - Pseudo dual-port
// Write port
wire [10:0]  s3_2_mac_bram_w_addr;
wire         s3_2_mac_bram_clk;
wire         s3_2_mac_bram_rst_n;
wire [255:0] s3_2_mac_bram_w_din;
wire         s3_2_mac_bram_w_en;
wire [31:0]  s3_2_mac_bram_w_we;
// Read port
wire [10:0]  s3_2_mac_bram_r_addr;
wire [255:0] s3_2_mac_bram_r_dout;
wire         s3_2_mac_bram_r_en;

// Control interface for S3 RAM2
wire         s3_2_ctrl_valid;
wire [31:0]  s3_2_ctrl_data;
wire         s3_2_ctrl_ready;
wire         s3_2_mac_enable;

// BRAM interface signals for S3 RAM2 (axi2bram_64k <-> RamCtrlSwitch) - Pseudo dual-port
// Write port
wire [10:0]  bram_64k_s3_2_w_addr;
wire         bram_64k_s3_2_clk;
wire         bram_64k_s3_2_rst_n;
wire [255:0] bram_64k_s3_2_w_din;
wire         bram_64k_s3_2_w_en;
wire [31:0]  bram_64k_s3_2_w_we;
// Read port
wire [10:0]  bram_64k_s3_2_r_addr;
wire [255:0] bram_64k_s3_2_r_dout;
wire         bram_64k_s3_2_r_en;

// ==================== axi2bram_64k实例化 (64KB BRAM控制器 - 连接到S3) ====================
axi2bram_64k u_axi2bram_64k_s3 (
    // AXI Clock and Reset
    .s_axi_aclk      (clk),                    // 系统时钟
    .s_axi_aresetn   (rst_n),                  // 系统复位（高有效）

    // AXI Read Address Channel
    .S_AXI_araddr    (s3_araddr[31:0]),        // 读地址：32位（slave地址空间0x5010_0000~0x501F_FFFF）
    .S_AXI_arburst   (s3_arburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_arcache   (s3_arcache),             // 缓存属性：4位
    .S_AXI_arid      (s3_arid),                // 读地址ID：6位
    .S_AXI_arlen     (s3_arlen),               // 突发长度：8位
    .S_AXI_arlock    (s3_arlock),              // 原子锁：1位
    .S_AXI_arprot    (s3_arprot),              // 保护类型：3位
    .S_AXI_arready   (s3_arready),             // 读地址就绪
    .S_AXI_arsize    (s3_arsize),              // 突发大小：3位
    .S_AXI_arvalid   (s3_arvalid),             // 读地址有效

    // AXI Write Address Channel
    .S_AXI_awaddr    (s3_awaddr[31:0]),        // 写地址：32位（slave地址空间0x5010_0000~0x501F_FFFF）
    .S_AXI_awburst   (s3_awburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_awcache   (s3_awcache),             // 缓存属性：4位
    .S_AXI_awid      (s3_awid),                // 写地址ID：6位
    .S_AXI_awlen     (s3_awlen),               // 突发长度：8位
    .S_AXI_awlock    (s3_awlock),              // 原子锁：1位
    .S_AXI_awprot    (s3_awprot),              // 保护类型：3位
    .S_AXI_awready   (s3_awready),             // 写地址就绪
    .S_AXI_awsize    (s3_awsize),              // 突发大小：3位
    .S_AXI_awvalid   (s3_awvalid),             // 写地址有效

    // AXI Write Data Channel
    .S_AXI_wdata     (s3_wdata),               // 写数据：64位
    .S_AXI_wlast     (s3_wlast),               // 写数据最后
    .S_AXI_wready    (s3_wready),              // 写数据就绪
    .S_AXI_wstrb     (s3_wstrb),               // 写字节选通：8位
    .S_AXI_wvalid    (s3_wvalid),              // 写数据有效

    // AXI Write Response Channel
    .S_AXI_bid       (s3_bid),                 // 写响应ID：6位
    .S_AXI_bready    (s3_bready),              // 写响应就绪
    .S_AXI_bresp     (s3_bresp),               // 写响应状态：2位
    .S_AXI_bvalid    (s3_bvalid),              // 写响应有效

    // AXI Read Data Channel
    .S_AXI_rdata     (s3_rdata),               // 读数据：64位
    .S_AXI_rid       (s3_rid),                 // 读响应ID：6位
    .S_AXI_rlast     (s3_rlast),               // 读数据最后
    .S_AXI_rready    (s3_rready),              // 读数据就绪
    .S_AXI_rresp     (s3_rresp),               // 读响应状态：2位
    .S_AXI_rvalid    (s3_rvalid),              // 读数据有效

    // BRAM1 Interface (Pseudo Dual-Port SRAM) - First RAM (0x0_0000~0x0_FFFF)
    .bram1_clk       (bram_64k_s3_clk),       // Common clock
    .bram1_rst_n     (bram_64k_s3_rst_n),     // Active low reset
    // Write port
    .bram1_w_addr    (bram_64k_s3_w_addr),    // Write address
    .bram1_w_din     (bram_64k_s3_w_din),     // Write data
    .bram1_w_en      (bram_64k_s3_w_en),      // Write enable
    .bram1_w_we      (bram_64k_s3_w_we),      // Write byte enable
    // Read port
    .bram1_r_addr    (bram_64k_s3_r_addr),    // Read address
    .bram1_r_dout    (bram_64k_s3_r_dout),    // Read data
    .bram1_r_en      (bram_64k_s3_r_en),      // Read enable

    // BRAM2 Interface (Pseudo Dual-Port SRAM) - Second RAM (0x1_0000~0x1_FFFF)
    .bram2_clk       (bram_64k_s3_2_clk),     // Common clock
    .bram2_rst_n     (bram_64k_s3_2_rst_n),   // Active low reset
    // Write port
    .bram2_w_addr    (bram_64k_s3_2_w_addr),  // Write address
    .bram2_w_din     (bram_64k_s3_2_w_din),   // Write data
    .bram2_w_en      (bram_64k_s3_2_w_en),    // Write enable
    .bram2_w_we      (bram_64k_s3_2_w_we),    // Write byte enable
    // Read port
    .bram2_r_addr    (bram_64k_s3_2_r_addr),  // Read address
    .bram2_r_dout    (bram_64k_s3_2_r_dout),  // Read data
    .bram2_r_en      (bram_64k_s3_2_r_en),    // Read enable

    // Control interface for RamCtrlSwitch RAM1 (address 0x7_F000)
    .ctrl_valid      (s3_ctrl_valid),          // Control write valid for RAM1
    .ctrl_data       (s3_ctrl_data),           // Control data for RAM1
    .ctrl_ready      (s3_ctrl_ready),          // Control ready for RAM1

    // Control interface for RamCtrlSwitch RAM2 (address 0x7_F000)
    .ctrl2_valid     (s3_2_ctrl_valid),        // Control write valid for RAM2
    .ctrl2_data      (s3_2_ctrl_data),         // Control data for RAM2
    .ctrl2_ready     (s3_2_ctrl_ready)         // Control ready for RAM2
);

// ==================== RAM Control Switch for S3 ====================
RamCtrlSwitch u_ram_switch_s3 (
    .clk             (clk),                     // 系统时钟
    .rst_n           (rst_n),                   // 系统复位

    // Control interface from AXI
    .ctrl_valid      (s3_ctrl_valid),          // Control write valid
    .ctrl_data       (s3_ctrl_data),           // Control data
    .ctrl_ready      (s3_ctrl_ready),          // Control ready

    // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
    .axi_bram_clk    (bram_64k_s3_clk),       // AXI BRAM clock
    .axi_bram_rst_n  (bram_64k_s3_rst_n),     // AXI BRAM reset
    // AXI Write port
    .axi_bram_w_addr (bram_64k_s3_w_addr),    // AXI BRAM write address
    .axi_bram_w_din  (bram_64k_s3_w_din),     // AXI BRAM write data
    .axi_bram_w_en   (bram_64k_s3_w_en),      // AXI BRAM write enable
    .axi_bram_w_we   (bram_64k_s3_w_we),      // AXI BRAM write byte enable
    // AXI Read port
    .axi_bram_r_addr (bram_64k_s3_r_addr),    // AXI BRAM read address
    .axi_bram_r_dout (bram_64k_s3_r_dout),    // AXI BRAM read data
    .axi_bram_r_en   (bram_64k_s3_r_en),      // AXI BRAM read enable

    // BRAM interface from MAC controller - Pseudo dual-port
    .mac_bram_clk    (s3_mac_bram_clk),        // MAC BRAM clock
    .mac_bram_rst_n  (s3_mac_bram_rst_n),      // MAC BRAM reset
    // MAC Write port
    .mac_bram_w_addr (s3_mac_bram_w_addr),     // MAC BRAM write address
    .mac_bram_w_din  (s3_mac_bram_w_din),      // MAC BRAM write data
    .mac_bram_w_en   (s3_mac_bram_w_en),       // MAC BRAM write enable
    .mac_bram_w_we   (s3_mac_bram_w_we),       // MAC BRAM write byte enable
    // MAC Read port
    .mac_bram_r_addr (s3_mac_bram_r_addr),     // MAC BRAM read address
    .mac_bram_r_dout (s3_mac_bram_r_dout),     // MAC BRAM read data
    .mac_bram_r_en   (s3_mac_bram_r_en),       // MAC BRAM read enable

    // BRAM interface to actual BRAM - Pseudo dual-port
    .bram_clk        (s3_switch_bram_clk),     // Switch BRAM clock
    .bram_rst_n      (s3_switch_bram_rst_n),   // Switch BRAM reset
    // Write port
    .bram_w_addr     (s3_switch_bram_w_addr),  // Switch BRAM write address
    .bram_w_din      (s3_switch_bram_w_din),   // Switch BRAM write data
    .bram_w_en       (s3_switch_bram_w_en),    // Switch BRAM write enable
    .bram_w_we       (s3_switch_bram_w_we),    // Switch BRAM write byte enable
    // Read port
    .bram_r_addr     (s3_switch_bram_r_addr),  // Switch BRAM read address
    .bram_r_dout     (s3_switch_bram_r_dout),  // Switch BRAM read data
    .bram_r_en       (s3_switch_bram_r_en),    // Switch BRAM read enable

    // Control output to MAC controller
    .mac_enable      (s3_mac_enable)           // MAC enable signal
);

// ==================== MAC Machine RAM Controller for S3 ====================
// DISABLED - slave3 RAM1 replaced by MacMachine_top

// ==================== 64KB BRAM实例化 (S3 RAM1) - Now connects to switch ====================
e203_bram_64k u_bram_64k_s3 (
    .clk        (s3_switch_bram_clk),      // Common clock
    .rst_n      (s3_switch_bram_rst_n),    // Active low reset
    // Write port
    .w_addr     (s3_switch_bram_w_addr),   // Write address
    .w_din      (s3_switch_bram_w_din),    // Write data
    .w_en       (s3_switch_bram_w_en),     // Write enable
    .w_we       (s3_switch_bram_w_we),     // Write byte enable
    // Read port
    .r_addr     (s3_switch_bram_r_addr),   // Read address
    .r_dout     (s3_switch_bram_r_dout),   // Read data
    .r_en       (s3_switch_bram_r_en)      // Read enable
);

// ==================== RAM Control Switch for S3 RAM2 ====================
RamCtrlSwitch u_ram_switch_s3_2 (
    .clk             (clk),                     // 系统时钟
    .rst_n           (rst_n),                   // 系统复位

    // Control interface from AXI
    .ctrl_valid      (s3_2_ctrl_valid),        // Control write valid
    .ctrl_data       (s3_2_ctrl_data),         // Control data
    .ctrl_ready      (s3_2_ctrl_ready),        // Control ready

    // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
    .axi_bram_clk    (bram_64k_s3_2_clk),     // AXI BRAM clock
    .axi_bram_rst_n  (bram_64k_s3_2_rst_n),   // AXI BRAM reset
    // AXI Write port
    .axi_bram_w_addr (bram_64k_s3_2_w_addr),  // AXI BRAM write address
    .axi_bram_w_din  (bram_64k_s3_2_w_din),   // AXI BRAM write data
    .axi_bram_w_en   (bram_64k_s3_2_w_en),    // AXI BRAM write enable
    .axi_bram_w_we   (bram_64k_s3_2_w_we),    // AXI BRAM write byte enable
    // AXI Read port
    .axi_bram_r_addr (bram_64k_s3_2_r_addr),  // AXI BRAM read address
    .axi_bram_r_dout (bram_64k_s3_2_r_dout),  // AXI BRAM read data
    .axi_bram_r_en   (bram_64k_s3_2_r_en),    // AXI BRAM read enable

    // BRAM interface from MAC controller - Pseudo dual-port
    .mac_bram_clk    (s3_2_mac_bram_clk),      // MAC BRAM clock
    .mac_bram_rst_n  (s3_2_mac_bram_rst_n),    // MAC BRAM reset
    // MAC Write port
    .mac_bram_w_addr (s3_2_mac_bram_w_addr),   // MAC BRAM write address
    .mac_bram_w_din  (s3_2_mac_bram_w_din),    // MAC BRAM write data
    .mac_bram_w_en   (s3_2_mac_bram_w_en),     // MAC BRAM write enable
    .mac_bram_w_we   (s3_2_mac_bram_w_we),     // MAC BRAM write byte enable
    // MAC Read port
    .mac_bram_r_addr (s3_2_mac_bram_r_addr),   // MAC BRAM read address
    .mac_bram_r_dout (s3_2_mac_bram_r_dout),   // MAC BRAM read data
    .mac_bram_r_en   (s3_2_mac_bram_r_en),     // MAC BRAM read enable

    // BRAM interface to actual BRAM - Pseudo dual-port
    .bram_clk        (s3_2_switch_bram_clk),   // Switch BRAM clock
    .bram_rst_n      (s3_2_switch_bram_rst_n), // Switch BRAM reset
    // Write port
    .bram_w_addr     (s3_2_switch_bram_w_addr), // Switch BRAM write address
    .bram_w_din      (s3_2_switch_bram_w_din),  // Switch BRAM write data
    .bram_w_en       (s3_2_switch_bram_w_en),   // Switch BRAM write enable
    .bram_w_we       (s3_2_switch_bram_w_we),   // Switch BRAM write byte enable
    // Read port
    .bram_r_addr     (s3_2_switch_bram_r_addr), // Switch BRAM read address
    .bram_r_dout     (s3_2_switch_bram_r_dout), // Switch BRAM read data
    .bram_r_en       (s3_2_switch_bram_r_en),   // Switch BRAM read enable

    // Control output to MAC controller
    .mac_enable      (s3_2_mac_enable)         // MAC enable signal
);

// ==================== MAC Machine RAM Controller for S3 RAM2 ====================
// DISABLED - slave3 RAM2 replaced by MacMachine_top

// ==================== 64KB BRAM实例化 (S3 RAM2) - Now connects to switch ====================
e203_bram_64k u_bram_64k_s3_2 (
    .clk        (s3_2_switch_bram_clk),    // Common clock
    .rst_n      (s3_2_switch_bram_rst_n),  // Active low reset
    // Write port
    .w_addr     (s3_2_switch_bram_w_addr), // Write address
    .w_din      (s3_2_switch_bram_w_din),  // Write data
    .w_en       (s3_2_switch_bram_w_en),   // Write enable
    .w_we       (s3_2_switch_bram_w_we),   // Write byte enable
    // Read port
    .r_addr     (s3_2_switch_bram_r_addr), // Read address
    .r_dout     (s3_2_switch_bram_r_dout), // Read data
    .r_en       (s3_2_switch_bram_r_en)    // Read enable
);

// ==================== RAM Control Switch and MAC Controller for S4 ====================

// Internal BRAM interfaces for S4 - Pseudo dual-port
// Write port
wire [10:0]  s4_switch_bram_w_addr;
wire         s4_switch_bram_clk;
wire         s4_switch_bram_rst_n;
wire [255:0] s4_switch_bram_w_din;
wire         s4_switch_bram_w_en;
wire [31:0]  s4_switch_bram_w_we;
// Read port
wire [10:0]  s4_switch_bram_r_addr;
wire [255:0] s4_switch_bram_r_dout;
wire         s4_switch_bram_r_en;

// MAC controller interfaces for S4 - Pseudo dual-port
// Write port
wire [10:0]  s4_mac_bram_w_addr;
wire         s4_mac_bram_clk;
wire         s4_mac_bram_rst_n;
wire [255:0] s4_mac_bram_w_din;
wire         s4_mac_bram_w_en;
wire [31:0]  s4_mac_bram_w_we;
// Read port
wire [10:0]  s4_mac_bram_r_addr;
wire [255:0] s4_mac_bram_r_dout;
wire         s4_mac_bram_r_en;

// Control interface for S4
wire         s4_ctrl_valid;
wire [31:0]  s4_ctrl_data;
wire         s4_ctrl_ready;
wire         s4_mac_enable;

// Internal BRAM interfaces for S4 RAM2 - Pseudo dual-port
// Write port
wire [10:0]  s4_2_switch_bram_w_addr;
wire         s4_2_switch_bram_clk;
wire         s4_2_switch_bram_rst_n;
wire [255:0] s4_2_switch_bram_w_din;
wire         s4_2_switch_bram_w_en;
wire [31:0]  s4_2_switch_bram_w_we;
// Read port
wire [10:0]  s4_2_switch_bram_r_addr;
wire [255:0] s4_2_switch_bram_r_dout;
wire         s4_2_switch_bram_r_en;

// MAC controller interfaces for S4 RAM2 - Pseudo dual-port
// Write port
wire [10:0]  s4_2_mac_bram_w_addr;
wire         s4_2_mac_bram_clk;
wire         s4_2_mac_bram_rst_n;
wire [255:0] s4_2_mac_bram_w_din;
wire         s4_2_mac_bram_w_en;
wire [31:0]  s4_2_mac_bram_w_we;
// Read port
wire [10:0]  s4_2_mac_bram_r_addr;
wire [255:0] s4_2_mac_bram_r_dout;
wire         s4_2_mac_bram_r_en;

// Control interface for S4 RAM2
wire         s4_2_ctrl_valid;
wire [31:0]  s4_2_ctrl_data;
wire         s4_2_ctrl_ready;
wire         s4_2_mac_enable;

// BRAM interface signals for S4 RAM2 (axi2bram_64k <-> RamCtrlSwitch) - Pseudo dual-port
// Write port
wire [10:0]  bram_64k_s4_2_w_addr;
wire         bram_64k_s4_2_clk;
wire         bram_64k_s4_2_rst_n;
wire [255:0] bram_64k_s4_2_w_din;
wire         bram_64k_s4_2_w_en;
wire [31:0]  bram_64k_s4_2_w_we;
// Read port
wire [10:0]  bram_64k_s4_2_r_addr;
wire [255:0] bram_64k_s4_2_r_dout;
wire         bram_64k_s4_2_r_en;

// ==================== axi2bram_64k实例化 (64KB BRAM控制器 - 连接到S4) ====================
axi2bram_64k u_axi2bram_64k_s4 (
    // AXI Clock and Reset
    .s_axi_aclk      (clk),                    // 系统时钟
    .s_axi_aresetn   (rst_n),                  // 系统复位（高有效）

    // AXI Read Address Channel
    .S_AXI_araddr    (s4_araddr[31:0]),        // 读地址：32位（slave地址空间0x5020_0000~0x502F_FFFF）
    .S_AXI_arburst   (s4_arburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_arcache   (s4_arcache),             // 缓存属性：4位
    .S_AXI_arid      (s4_arid),                // 读地址ID：6位
    .S_AXI_arlen     (s4_arlen),               // 突发长度：8位
    .S_AXI_arlock    (s4_arlock),              // 原子锁：1位
    .S_AXI_arprot    (s4_arprot),              // 保护类型：3位
    .S_AXI_arready   (s4_arready),             // 读地址就绪
    .S_AXI_arsize    (s4_arsize),              // 突发大小：3位
    .S_AXI_arvalid   (s4_arvalid),             // 读地址有效

    // AXI Write Address Channel
    .S_AXI_awaddr    (s4_awaddr[31:0]),        // 写地址：32位（slave地址空间0x5020_0000~0x502F_FFFF）
    .S_AXI_awburst   (s4_awburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_awcache   (s4_awcache),             // 缓存属性：4位
    .S_AXI_awid      (s4_awid),                // 写地址ID：6位
    .S_AXI_awlen     (s4_awlen),               // 突发长度：8位
    .S_AXI_awlock    (s4_awlock),              // 原子锁：1位
    .S_AXI_awprot    (s4_awprot),              // 保护类型：3位
    .S_AXI_awready   (s4_awready),             // 写地址就绪
    .S_AXI_awsize    (s4_awsize),              // 突发大小：3位
    .S_AXI_awvalid   (s4_awvalid),             // 写地址有效

    // AXI Write Data Channel
    .S_AXI_wdata     (s4_wdata),               // 写数据：64位
    .S_AXI_wlast     (s4_wlast),               // 写数据最后
    .S_AXI_wready    (s4_wready),              // 写数据就绪
    .S_AXI_wstrb     (s4_wstrb),               // 写字节选通：8位
    .S_AXI_wvalid    (s4_wvalid),              // 写数据有效

    // AXI Write Response Channel
    .S_AXI_bid       (s4_bid),                 // 写响应ID：6位
    .S_AXI_bready    (s4_bready),              // 写响应就绪
    .S_AXI_bresp     (s4_bresp),               // 写响应状态：2位
    .S_AXI_bvalid    (s4_bvalid),              // 写响应有效

    // AXI Read Data Channel
    .S_AXI_rdata     (s4_rdata),               // 读数据：64位
    .S_AXI_rid       (s4_rid),                 // 读响应ID：6位
    .S_AXI_rlast     (s4_rlast),               // 读数据最后
    .S_AXI_rready    (s4_rready),              // 读数据就绪
    .S_AXI_rresp     (s4_rresp),               // 读响应状态：2位
    .S_AXI_rvalid    (s4_rvalid),              // 读数据有效

    // BRAM1 Interface (Pseudo Dual-Port SRAM) - First RAM (0x0_0000~0x0_FFFF)
    .bram1_clk       (bram_64k_s4_clk),       // Common clock
    .bram1_rst_n     (bram_64k_s4_rst_n),     // Active low reset
    // Write port
    .bram1_w_addr    (bram_64k_s4_w_addr),    // Write address
    .bram1_w_din     (bram_64k_s4_w_din),     // Write data
    .bram1_w_en      (bram_64k_s4_w_en),      // Write enable
    .bram1_w_we      (bram_64k_s4_w_we),      // Write byte enable
    // Read port
    .bram1_r_addr    (bram_64k_s4_r_addr),    // Read address
    .bram1_r_dout    (bram_64k_s4_r_dout),    // Read data
    .bram1_r_en      (bram_64k_s4_r_en),      // Read enable

    // BRAM2 Interface (Pseudo Dual-Port SRAM) - Second RAM (0x1_0000~0x1_FFFF)
    .bram2_clk       (bram_64k_s4_2_clk),     // Common clock
    .bram2_rst_n     (bram_64k_s4_2_rst_n),   // Active low reset
    // Write port
    .bram2_w_addr    (bram_64k_s4_2_w_addr),  // Write address
    .bram2_w_din     (bram_64k_s4_2_w_din),   // Write data
    .bram2_w_en      (bram_64k_s4_2_w_en),    // Write enable
    .bram2_w_we      (bram_64k_s4_2_w_we),    // Write byte enable
    // Read port
    .bram2_r_addr    (bram_64k_s4_2_r_addr),  // Read address
    .bram2_r_dout    (bram_64k_s4_2_r_dout),  // Read data
    .bram2_r_en      (bram_64k_s4_2_r_en),    // Read enable

    // Control interface for RamCtrlSwitch RAM1 (address 0x7_F000)
    .ctrl_valid      (s4_ctrl_valid),          // Control write valid for RAM1
    .ctrl_data       (s4_ctrl_data),           // Control data for RAM1
    .ctrl_ready      (s4_ctrl_ready),          // Control ready for RAM1

    // Control interface for RamCtrlSwitch RAM2 (address 0x7_F000)
    .ctrl2_valid     (s4_2_ctrl_valid),        // Control write valid for RAM2
    .ctrl2_data      (s4_2_ctrl_data),         // Control data for RAM2
    .ctrl2_ready     (s4_2_ctrl_ready)         // Control ready for RAM2
);

// ==================== RAM Control Switch for S4 ====================
RamCtrlSwitch u_ram_switch_s4 (
    .clk             (clk),                     // 系统时钟
    .rst_n           (rst_n),                   // 系统复位

    // Control interface from AXI
    .ctrl_valid      (s4_ctrl_valid),          // Control write valid
    .ctrl_data       (s4_ctrl_data),           // Control data
    .ctrl_ready      (s4_ctrl_ready),          // Control ready

    // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
    .axi_bram_clk    (bram_64k_s4_clk),       // AXI BRAM clock
    .axi_bram_rst_n  (bram_64k_s4_rst_n),     // AXI BRAM reset
    // AXI Write port
    .axi_bram_w_addr (bram_64k_s4_w_addr),    // AXI BRAM write address
    .axi_bram_w_din  (bram_64k_s4_w_din),     // AXI BRAM write data
    .axi_bram_w_en   (bram_64k_s4_w_en),      // AXI BRAM write enable
    .axi_bram_w_we   (bram_64k_s4_w_we),      // AXI BRAM write byte enable
    // AXI Read port
    .axi_bram_r_addr (bram_64k_s4_r_addr),    // AXI BRAM read address
    .axi_bram_r_dout (bram_64k_s4_r_dout),    // AXI BRAM read data
    .axi_bram_r_en   (bram_64k_s4_r_en),      // AXI BRAM read enable

    // BRAM interface from MAC controller - Pseudo dual-port
    .mac_bram_clk    (s4_mac_bram_clk),        // MAC BRAM clock
    .mac_bram_rst_n  (s4_mac_bram_rst_n),      // MAC BRAM reset
    // MAC Write port
    .mac_bram_w_addr (s4_mac_bram_w_addr),     // MAC BRAM write address
    .mac_bram_w_din  (s4_mac_bram_w_din),      // MAC BRAM write data
    .mac_bram_w_en   (s4_mac_bram_w_en),       // MAC BRAM write enable
    .mac_bram_w_we   (s4_mac_bram_w_we),       // MAC BRAM write byte enable
    // MAC Read port
    .mac_bram_r_addr (s4_mac_bram_r_addr),     // MAC BRAM read address
    .mac_bram_r_dout (s4_mac_bram_r_dout),     // MAC BRAM read data
    .mac_bram_r_en   (s4_mac_bram_r_en),       // MAC BRAM read enable

    // BRAM interface to actual BRAM - Pseudo dual-port
    .bram_clk        (s4_switch_bram_clk),     // Switch BRAM clock
    .bram_rst_n      (s4_switch_bram_rst_n),   // Switch BRAM reset
    // Write port
    .bram_w_addr     (s4_switch_bram_w_addr),  // Switch BRAM write address
    .bram_w_din      (s4_switch_bram_w_din),   // Switch BRAM write data
    .bram_w_en       (s4_switch_bram_w_en),    // Switch BRAM write enable
    .bram_w_we       (s4_switch_bram_w_we),    // Switch BRAM write byte enable
    // Read port
    .bram_r_addr     (s4_switch_bram_r_addr),  // Switch BRAM read address
    .bram_r_dout     (s4_switch_bram_r_dout),  // Switch BRAM read data
    .bram_r_en       (s4_switch_bram_r_en),    // Switch BRAM read enable

    // Control output to MAC controller
    .mac_enable      (s4_mac_enable)           // MAC enable signal
);

// ==================== MAC Machine RAM Controller for S4 ====================
// DISABLED - slave4 RAM1 replaced by MacMachine_top

// ==================== 64KB BRAM实例化 (S4 RAM1) - Now connects to switch ====================
e203_bram_64k u_bram_64k_s4 (
    .clk        (s4_switch_bram_clk),      // Common clock
    .rst_n      (s4_switch_bram_rst_n),    // Active low reset
    // Write port
    .w_addr     (s4_switch_bram_w_addr),   // Write address
    .w_din      (s4_switch_bram_w_din),    // Write data
    .w_en       (s4_switch_bram_w_en),     // Write enable
    .w_we       (s4_switch_bram_w_we),     // Write byte enable
    // Read port
    .r_addr     (s4_switch_bram_r_addr),   // Read address
    .r_dout     (s4_switch_bram_r_dout),   // Read data
    .r_en       (s4_switch_bram_r_en)      // Read enable
);

// ==================== RAM Control Switch for S4 RAM2 ====================
RamCtrlSwitch u_ram_switch_s4_2 (
    .clk             (clk),                     // 系统时钟
    .rst_n           (rst_n),                   // 系统复位

    // Control interface from AXI
    .ctrl_valid      (s4_2_ctrl_valid),        // Control write valid
    .ctrl_data       (s4_2_ctrl_data),         // Control data
    .ctrl_ready      (s4_2_ctrl_ready),        // Control ready

    // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
    .axi_bram_clk    (bram_64k_s4_2_clk),     // AXI BRAM clock
    .axi_bram_rst_n  (bram_64k_s4_2_rst_n),   // AXI BRAM reset
    // AXI Write port
    .axi_bram_w_addr (bram_64k_s4_2_w_addr),  // AXI BRAM write address
    .axi_bram_w_din  (bram_64k_s4_2_w_din),   // AXI BRAM write data
    .axi_bram_w_en   (bram_64k_s4_2_w_en),    // AXI BRAM write enable
    .axi_bram_w_we   (bram_64k_s4_2_w_we),    // AXI BRAM write byte enable
    // AXI Read port
    .axi_bram_r_addr (bram_64k_s4_2_r_addr),  // AXI BRAM read address
    .axi_bram_r_dout (bram_64k_s4_2_r_dout),  // AXI BRAM read data
    .axi_bram_r_en   (bram_64k_s4_2_r_en),    // AXI BRAM read enable

    // BRAM interface from MAC controller - Pseudo dual-port
    .mac_bram_clk    (s4_2_mac_bram_clk),      // MAC BRAM clock
    .mac_bram_rst_n  (s4_2_mac_bram_rst_n),    // MAC BRAM reset
    // MAC Write port
    .mac_bram_w_addr (s4_2_mac_bram_w_addr),   // MAC BRAM write address
    .mac_bram_w_din  (s4_2_mac_bram_w_din),    // MAC BRAM write data
    .mac_bram_w_en   (s4_2_mac_bram_w_en),     // MAC BRAM write enable
    .mac_bram_w_we   (s4_2_mac_bram_w_we),     // MAC BRAM write byte enable
    // MAC Read port
    .mac_bram_r_addr (s4_2_mac_bram_r_addr),   // MAC BRAM read address
    .mac_bram_r_dout (s4_2_mac_bram_r_dout),   // MAC BRAM read data
    .mac_bram_r_en   (s4_2_mac_bram_r_en),     // MAC BRAM read enable

    // BRAM interface to actual BRAM - Pseudo dual-port
    .bram_clk        (s4_2_switch_bram_clk),   // Switch BRAM clock
    .bram_rst_n      (s4_2_switch_bram_rst_n), // Switch BRAM reset
    // Write port
    .bram_w_addr     (s4_2_switch_bram_w_addr), // Switch BRAM write address
    .bram_w_din      (s4_2_switch_bram_w_din),  // Switch BRAM write data
    .bram_w_en       (s4_2_switch_bram_w_en),   // Switch BRAM write enable
    .bram_w_we       (s4_2_switch_bram_w_we),   // Switch BRAM write byte enable
    // Read port
    .bram_r_addr     (s4_2_switch_bram_r_addr), // Switch BRAM read address
    .bram_r_dout     (s4_2_switch_bram_r_dout), // Switch BRAM read data
    .bram_r_en       (s4_2_switch_bram_r_en),   // Switch BRAM read enable

    // Control output to MAC controller
    .mac_enable      (s4_2_mac_enable)         // MAC enable signal
);

// ==================== MAC Machine RAM Controller for S4 RAM2 ====================
// DISABLED - slave4 RAM2 replaced by MacMachine_top

// ==================== 64KB BRAM实例化 (S4 RAM2) - Now connects to switch ====================
e203_bram_64k u_bram_64k_s4_2 (
    .clk        (s4_2_switch_bram_clk),    // Common clock
    .rst_n      (s4_2_switch_bram_rst_n),  // Active low reset
    // Write port
    .w_addr     (s4_2_switch_bram_w_addr), // Write address
    .w_din      (s4_2_switch_bram_w_din),  // Write data
    .w_en       (s4_2_switch_bram_w_en),   // Write enable
    .w_we       (s4_2_switch_bram_w_we),   // Write byte enable
    // Read port
    .r_addr     (s4_2_switch_bram_r_addr), // Read address
    .r_dout     (s4_2_switch_bram_r_dout), // Read data
    .r_en       (s4_2_switch_bram_r_en)    // Read enable
);
*/

// NEW: initiate axi2ram_asic、design_ram_mux、e203_bram_test
axi2bram_asic u_axi2bram_asic (
  // AXI Clock and Reset
    .s_axi_aclk_0      (clk),                    // 系统时钟
    .s_axi_aresetn_0   (rst_n),                  // 系统复位（高有效）

    // AXI Read Address Channel
    .S_AXI_0_araddr    (s2_araddr[31:0]),        // 读地址：32位（slave地址空间0x5000_0000~0x500F_FFFF）
    .S_AXI_0_arburst   (s2_arburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_0_arcache   (s2_arcache),             // 缓存属性：4位
    .S_AXI_0_arid      (s2_arid),                // 读地址ID：6位
    .S_AXI_0_arlen     (s2_arlen),               // 突发长度：8位
    .S_AXI_0_arlock    (s2_arlock),              // 原子锁：1位
    .S_AXI_0_arprot    (s2_arprot),              // 保护类型：3位
    .S_AXI_0_arready   (s2_arready),             // 读地址就绪
    .S_AXI_0_arsize    (s2_arsize),              // 突发大小：3位
    .S_AXI_0_arvalid   (s2_arvalid),             // 读地址有效

    // AXI Write Address Channel
    .S_AXI_0_awaddr    (s2_awaddr[31:0]),        // 写地址：32位（slave地址空间0x5000_0000~0x500F_FFFF）
    .S_AXI_0_awburst   (s2_awburst),             // 突发类型：2位，FIXED/INCR/WRAP
    .S_AXI_0_awcache   (s2_awcache),             // 缓存属性：4位
    .S_AXI_0_awid      (s2_awid),                // 写地址ID：6位
    .S_AXI_0_awlen     (s2_awlen),               // 突发长度：8位
    .S_AXI_0_awlock    (s2_awlock),              // 原子锁：1位
    .S_AXI_0_awprot    (s2_awprot),              // 保护类型：3位
    .S_AXI_0_awready   (s2_awready),             // 写地址就绪
    .S_AXI_0_awsize    (s2_awsize),              // 突发大小：3位
    .S_AXI_0_awvalid   (s2_awvalid),             // 写地址有效

    // AXI Write Data Channel
    .S_AXI_0_wdata     (s2_wdata),               // 写数据：64位
    .S_AXI_0_wlast     (s2_wlast),               // 写数据最后
    .S_AXI_0_wready    (s2_wready),              // 写数据就绪
    .S_AXI_0_wstrb     (s2_wstrb),               // 写字节选通：8位
    .S_AXI_0_wvalid    (s2_wvalid),              // 写数据有效

    // AXI Write Response Channel
    .S_AXI_0_bid       (s2_bid),                 // 写响应ID：6位
    .S_AXI_0_bready    (s2_bready),              // 写响应就绪
    .S_AXI_0_bresp     (s2_bresp),               // 写响应状态：2位
    .S_AXI_0_bvalid    (s2_bvalid),              // 写响应有效

    // AXI Read Data Channel
    .S_AXI_0_rdata     (s2_rdata),               // 读数据：64位
    .S_AXI_0_rid       (s2_rid),                 // 读响应ID：6位
    .S_AXI_0_rlast     (s2_rlast),               // 读数据最后
    .S_AXI_0_rready    (s2_rready),              // 读数据就绪
    .S_AXI_0_rresp     (s2_rresp),               // 读响应状态：2位
    .S_AXI_0_rvalid    (s2_rvalid),              // 读数据有效

    // BRAM Interface
    .BRAM_PORTA_0_addr   (bram_addr),      // BRAM端口地址：16位
    .BRAM_PORTA_0_clk    (bram_clk),       // BRAM端口时钟
    .BRAM_PORTA_0_dinout (bram_dinout),    // BRAM端口数据：64位
    .BRAM_PORTA_0_en     (bram_en),        // BRAM端口使能
    .BRAM_PORTA_0_rstn   (bram_rstn),      // BRAM端口复位
    .BRAM_PORTA_0_we     (bram_we)         // BRAM端口写使能
);


Mac_ASIC_top_wrapper u_mac_asic_top (
  .clk                        (bram_clk),
  .rst_n                      (bram_rstn),
  .dinout                     (bram_dinout),
  .addr                       (bram_addr),
  .en                         (bram_en),
  .wr_en                      (bram_we),
  // MAC interrupt outputs
  .macMachineDone_interrupt   (mac_done_interrupt),
  .macMachineerror_interrupt  (mac_error_interrupt)
);

endmodule
