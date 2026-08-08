# E203 AXI接口集成指南

## 1. ICB总线接口位置分析

### 1.1 E203 ICB总线架构
E203处理器使用ICB（Internal Chip Bus）作为片内总线，核心的ICB接口位于：

- **CPU核心到BIU**：`rtl/e203/core/e203_biu.v`
- **BIU分路器**：将ICB请求分发到不同目标
- **ICB转换器**：`rtl/e203/general/sirv_gnrl_icbs.v`

### 1.2 现有ICB分路目标
BIU中的ICB分路器当前支持以下目标：
1. `ifuerr_icb` - IFU错误处理
2. `ppi_icb` - 私有外设接口  
3. `clint_icb` - 核心本地中断控制器
4. `plic_icb` - 平台级中断控制器
5. `fio_icb` - 快速I/O（可选）
6. `mem_icb` - 内存接口（可选）

## 2. 添加AXI接口的具体步骤

### 2.1 方案1：在BIU层添加（推荐）

#### 步骤1：修改宏定义
在`rtl/e203/core/config.v`中添加：
```verilog
// 启用AXI接口
`define E203_HAS_AXI_ITF
```

#### 步骤2：修改BIU模块端口
在`rtl/e203/core/e203_biu.v`的模块声明中添加：
```verilog
`ifdef E203_HAS_AXI_ITF //{
//////////////////////////////////////////////////////////////
// AXI Master Interface
input [`E203_ADDR_SIZE-1:0]    axi_region_indic,
input                          axi_icb_enable,

// AXI4 Master接口
output                         m_axi_awvalid,
input                          m_axi_awready,
output [`E203_ADDR_SIZE-1:0]   m_axi_awaddr,
output [3:0]                   m_axi_awcache,
output [2:0]                   m_axi_awprot,
output [1:0]                   m_axi_awlock,
output [1:0]                   m_axi_awburst,
output [3:0]                   m_axi_awlen,
output [2:0]                   m_axi_awsize,

output                         m_axi_wvalid,
input                          m_axi_wready,
output [`E203_XLEN-1:0]        m_axi_wdata,
output [`E203_XLEN/8-1:0]      m_axi_wstrb,
output                         m_axi_wlast,

input                          m_axi_bvalid,
output                         m_axi_bready,
input  [1:0]                   m_axi_bresp,

output                         m_axi_arvalid,
input                          m_axi_arready,
output [`E203_ADDR_SIZE-1:0]   m_axi_araddr,
output [3:0]                   m_axi_arcache,
output [2:0]                   m_axi_arprot,
output [1:0]                   m_axi_arlock,
output [1:0]                   m_axi_arburst,
output [3:0]                   m_axi_arlen,
output [2:0]                   m_axi_arsize,

input                          m_axi_rvalid,
output                         m_axi_rready,
input  [`E203_XLEN-1:0]        m_axi_rdata,
input  [1:0]                   m_axi_rresp,
input                          m_axi_rlast,
`endif//}
```

#### 步骤3：修改分路器数量
在BIU中找到分路器数量定义（大约第230行）：
```verilog
`ifdef E203_HAS_AXI_ITF //{
    localparam BIU_SPLT_I_NUM_3 = (BIU_SPLT_I_NUM_2 + 1);
`else//}{
    localparam BIU_SPLT_I_NUM_3 = BIU_SPLT_I_NUM_2;
`endif//}

localparam BIU_SPLT_I_NUM = BIU_SPLT_I_NUM_3;
```

#### 步骤4：添加AXI ICB信号
```verilog
`ifdef E203_HAS_AXI_ITF //{
wire                         axi_icb_cmd_valid;
wire                         axi_icb_cmd_ready;
wire [`E203_ADDR_SIZE-1:0]   axi_icb_cmd_addr; 
wire                         axi_icb_cmd_read; 
wire [`E203_XLEN-1:0]        axi_icb_cmd_wdata;
wire [`E203_XLEN/8-1:0]      axi_icb_cmd_wmask;
wire [1:0]                   axi_icb_cmd_burst;
wire [1:0]                   axi_icb_cmd_beat;
wire                         axi_icb_cmd_lock;
wire                         axi_icb_cmd_excl;
wire [1:0]                   axi_icb_cmd_size;

wire                         axi_icb_rsp_valid;
wire                         axi_icb_rsp_ready;
wire                         axi_icb_rsp_err  ;
wire                         axi_icb_rsp_excl_ok;
wire [`E203_XLEN-1:0]        axi_icb_rsp_rdata;
`endif//}
```

#### 步骤5：修改分路器信号分配
找到分路器信号分配（大约第610行），在每个assign语句中添加AXI接口：
```verilog
assign {
         ifuerr_icb_cmd_valid
       , ppi_icb_cmd_valid
       , clint_icb_cmd_valid
       , plic_icb_cmd_valid
       `ifdef E203_HAS_FIO //{
       , fio_icb_cmd_valid
       `endif//}
       `ifdef E203_HAS_MEM_ITF //{
       , mem_icb_cmd_valid
       `endif//}
       `ifdef E203_HAS_AXI_ITF //{
       , axi_icb_cmd_valid
       `endif//}
       } = splt_bus_icb_cmd_valid;
```

#### 步骤6：修改地址译码逻辑
找到地址译码逻辑（大约第856行）：
```verilog
wire [BIU_SPLT_I_NUM-1:0] buf_icb_splt_indic =
{
   `ifdef E203_HAS_AXI_ITF //{
   (arbt_icb_cmd_addr[`E203_ADDR_SIZE-1:`E203_ADDR_SIZE-8] == axi_region_indic[`E203_ADDR_SIZE-1:`E203_ADDR_SIZE-8]) & axi_icb_enable,
   `endif//}
   // ... 其他接口的地址译码 ...
};
```

#### 步骤7：实例化ICB到AXI转换器
在BIU中添加转换器实例：
```verilog
`ifdef E203_HAS_AXI_ITF //{
sirv_gnrl_icb2axi # (
  .AXI_FIFO_DP         (2),
  .AXI_FIFO_CUT_READY  (1),
  .AW                  (`E203_ADDR_SIZE),
  .FIFO_OUTS_NUM       (8),
  .FIFO_CUT_READY      (0),
  .DW                  (`E203_XLEN)
) u_axi_icb2axi (
  .i_icb_cmd_valid     (axi_icb_cmd_valid),
  .i_icb_cmd_ready     (axi_icb_cmd_ready),
  .i_icb_cmd_read      (axi_icb_cmd_read ),
  .i_icb_cmd_addr      (axi_icb_cmd_addr ),
  .i_icb_cmd_wdata     (axi_icb_cmd_wdata),
  .i_icb_cmd_wmask     (axi_icb_cmd_wmask),
  .i_icb_cmd_size      (axi_icb_cmd_size ),

  .i_icb_rsp_valid     (axi_icb_rsp_valid),
  .i_icb_rsp_ready     (axi_icb_rsp_ready),
  .i_icb_rsp_err       (axi_icb_rsp_err  ),
  .i_icb_rsp_rdata     (axi_icb_rsp_rdata),

  .o_axi_arvalid       (m_axi_arvalid),
  .o_axi_arready       (m_axi_arready),
  .o_axi_araddr        (m_axi_araddr ),
  .o_axi_arcache       (m_axi_arcache),
  .o_axi_arprot        (m_axi_arprot ),
  .o_axi_arlock        (m_axi_arlock ),
  .o_axi_arburst       (m_axi_arburst),
  .o_axi_arlen         (m_axi_arlen  ),
  .o_axi_arsize        (m_axi_arsize ),

  .o_axi_awvalid       (m_axi_awvalid),
  .o_axi_awready       (m_axi_awready),
  .o_axi_awaddr        (m_axi_awaddr ),
  .o_axi_awcache       (m_axi_awcache),
  .o_axi_awprot        (m_axi_awprot ),
  .o_axi_awlock        (m_axi_awlock ),
  .o_axi_awburst       (m_axi_awburst),
  .o_axi_awlen         (m_axi_awlen  ),
  .o_axi_awsize        (m_axi_awsize ),

  .o_axi_rvalid        (m_axi_rvalid ),
  .o_axi_rready        (m_axi_rready ),
  .o_axi_rdata         (m_axi_rdata  ),
  .o_axi_rresp         (m_axi_rresp  ),
  .o_axi_rlast         (m_axi_rlast  ),

  .o_axi_wvalid        (m_axi_wvalid ),
  .o_axi_wready        (m_axi_wready ),
  .o_axi_wdata         (m_axi_wdata  ),
  .o_axi_wstrb         (m_axi_wstrb  ),
  .o_axi_wlast         (m_axi_wlast  ),

  .o_axi_bvalid        (m_axi_bvalid ),
  .o_axi_bready        (m_axi_bready ),
  .o_axi_bresp         (m_axi_bresp  ),

  .clk                 (clk),
  .rst_n               (rst_n)
);
`endif//}
```

### 2.2 修改上层模块

#### 修改CPU模块
在`rtl/e203/core/e203_cpu.v`中添加AXI接口端口并连接到BIU。

#### 修改子系统模块
在`rtl/e203/subsys/e203_subsys_main.v`中添加AXI接口端口。

#### 修改顶层模块
在`rtl/e203/soc/e203_soc_top.v`或您的顶层模块中暴露AXI接口。

## 3. 地址空间配置

根据您之前的需求，配置AXI地址空间为`0x4000_0000 ~ 0x4FFF_FFFF`：

```verilog
// 在CPU实例化时配置
.axi_region_indic (32'h4000_0000),
.axi_icb_enable   (1'b1),
```

## 4. 验证和调试

### 4.1 添加调试信号
```verilog
// 在BIU中添加调试信号
wire axi_access = (arbt_icb_cmd_addr[31:28] == 4'h4) & arbt_icb_cmd_valid & arbt_icb_cmd_ready;
```

### 4.2 仿真验证
1. 创建测试用例访问AXI地址空间
2. 验证ICB到AXI的转换正确性
3. 检查时序和握手信号

## 5. 参数配置建议

### 5.1 ICB2AXI转换器参数
```verilog
.AXI_FIFO_DP         (2),        // AXI管线深度
.AXI_FIFO_CUT_READY  (1),        // 切断ready信号
.FIFO_OUTS_NUM       (8),        // Outstanding事务数
.FIFO_CUT_READY      (0),        // ICB FIFO ready信号
.DW                  (32)        // 数据宽度（32位）
```

### 5.2 地址译码位宽
使用高8位进行地址译码（[31:24]），支持256MB地址空间粒度。

## 6. 注意事项

1. **时钟域**：确保AXI接口与CPU核心同时钟
2. **复位同步**：AXI接口需要同步复位
3. **Outstanding事务**：根据外部AXI从设备能力配置
4. **数据宽度**：E203为32位，确保AXI接口匹配
5. **地址对齐**：注意AXI访问的地址对齐要求

通过以上步骤，您就可以成功将AXI接口集成到E203处理器中，并将其连接到外部AXI总线系统。 