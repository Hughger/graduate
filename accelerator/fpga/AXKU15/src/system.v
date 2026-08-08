`timescale 1ns/1ps

module system
(
  input wire sys_clk_p,    // 差分时钟正端
  input wire sys_clk_n,    // 差分时钟负端
//RTC_CLK-Y18

  input wire fpga_rst,//FPGA_RESET-T6
  input wire mcu_rst,//MCU_RESET-P20


  // Dedicated QSPI interface
  output wire qspi0_cs,
  // qspi0_sck通过STARTUP原语内部连接到配置引脚，不需要外部端口
  // output wire qspi0_sck,
  inout wire [3:0] qspi0_dq,
                           
  /*                         
  //gpioA
  inout wire [31:0] gpioA,//GPIOA00~GPIOA31

  //gpioB
  inout wire [31:0] gpioB,//GPIOB00~GPIOB31
  */

  // 调试串口接口 - 使用开发板专用串口引脚_cy
  output wire uart_tx,    // D2引脚 - 发送
  input  wire uart_rx,    // D1引脚 - 接收

  
  // JD (used for JTAG connection)
  inout wire mcu_TDO,//MCU_TDO-N17
  inout wire mcu_TCK,//MCU_TCK-P15 
  inout wire mcu_TDI,//MCU_TDI-T18
  inout wire mcu_TMS,//MCU_TMS-P17

  //pmu_wakeup

  inout wire pmu_paden,  //PMU_VDDPADEN-U15
  inout wire pmu_padrst, //PMU_VADDPARST_V15
  inout wire mcu_wakeup  //MCU_WAKE-N15
);

  wire clk_out1;
  wire mmcm_locked;

  wire reset_periph;

  wire ck_rst;

  // All wires connected to the chip top
  wire dut_clock;
  wire dut_reset;

  
  wire dut_io_pads_jtag_TCK_i_ival;
  wire dut_io_pads_jtag_TMS_i_ival;
  wire dut_io_pads_jtag_TMS_o_oval;
  wire dut_io_pads_jtag_TMS_o_oe;
  wire dut_io_pads_jtag_TMS_o_ie;
  wire dut_io_pads_jtag_TMS_o_pue;
  wire dut_io_pads_jtag_TMS_o_ds;
  wire dut_io_pads_jtag_TDI_i_ival;
  wire dut_io_pads_jtag_TDO_o_oval;
  wire dut_io_pads_jtag_TDO_o_oe;
  

  // GPIO线路定义 - 用于UART功能
  wire [32-1:0] dut_io_pads_gpioA_i_ival;
  wire [32-1:0] dut_io_pads_gpioA_o_oval;
  wire [32-1:0] dut_io_pads_gpioA_o_oe;

  /*
  wire [32-1:0] dut_io_pads_gpioB_i_ival;
  wire [32-1:0] dut_io_pads_gpioB_o_oval;
  wire [32-1:0] dut_io_pads_gpioB_o_oe;
  */

  wire dut_io_pads_qspi0_sck_o_oval;
  wire dut_io_pads_qspi0_cs_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_i_ival;
  wire dut_io_pads_qspi0_dq_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_o_oe;
  wire dut_io_pads_qspi0_dq_1_i_ival;
  wire dut_io_pads_qspi0_dq_1_o_oval;
  wire dut_io_pads_qspi0_dq_1_o_oe;
  wire dut_io_pads_qspi0_dq_2_i_ival;
  wire dut_io_pads_qspi0_dq_2_o_oval;
  wire dut_io_pads_qspi0_dq_2_o_oe;
  wire dut_io_pads_qspi0_dq_3_i_ival;
  wire dut_io_pads_qspi0_dq_3_o_oval;
  wire dut_io_pads_qspi0_dq_3_o_oe;


  wire dut_io_pads_aon_erst_n_i_ival;
  wire dut_io_pads_aon_pmu_dwakeup_n_i_ival;
  wire dut_io_pads_aon_pmu_vddpaden_o_oval;
  wire dut_io_pads_aon_pmu_padrst_o_oval ;
  wire dut_io_pads_bootrom_n_i_ival;
  wire dut_io_pads_dbgmode0_n_i_ival;
  wire dut_io_pads_dbgmode1_n_i_ival;
  wire dut_io_pads_dbgmode2_n_i_ival;

  //=================================================
  // Clock & Reset
  wire sys_clk;           // 差分时钟转换后的单端时钟
  wire clk_8388;
  wire clk_16M;
  
  // 差分时钟输入缓冲器
  IBUFGDS u_ibufg_sys_clk   //专用原语，差分信号输入
  (
    .I  (sys_clk_p),            
    .IB (sys_clk_n),          
    .O  (sys_clk)        
  );
  
  wire CLK32768KHZ;

  mmcm ip_mmcm
  (
    .resetn(ck_rst),
    .clk_in1(sys_clk),      // 使用转换后的差分时钟
    
    .clk_out1(clk_16M), // 16 MHz, this clock we set to 16MHz 
    .locked(mmcm_locked)
  );

  assign ck_rst = fpga_rst & mcu_rst;
  
  divclk U0_divclk(
        .clk(clk_16M),
        .rstn(ck_rst),
        .clk_out(CLK32768KHZ));

  reset_sys ip_reset_sys
  (
    .slowest_sync_clk(clk_16M),
    .ext_reset_in(ck_rst), // Active-low
    .aux_reset_in(1'b1),
    .mb_debug_sys_rst(1'b0),
    .dcm_locked(mmcm_locked),
    .mb_reset(),
    .bus_struct_reset(),
    .peripheral_reset(reset_periph),
    .interconnect_aresetn(),
    .peripheral_aresetn()
  );

  //=================================================
  // SPI0 Interface

  wire [3:0] qspi0_ui_dq_o; 
  wire [3:0] qspi0_ui_dq_oe;
  wire [3:0] qspi0_ui_dq_i;

  PULLUP qspi0_pullup[3:0]
  (
    .O(qspi0_dq)
  );

  IOBUF qspi0_iobuf[3:0]
  (
    .IO(qspi0_dq),
    .O(qspi0_ui_dq_i),
    .I(qspi0_ui_dq_o),
    .T(~qspi0_ui_dq_oe)
  );


  //=================================================
  // IOBUF instantiation for GPIOs

  /*
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioA_iobuf[31:0]
  (
    .O(dut_io_pads_gpioA_i_ival),
    .IO(gpioA),
    .I(dut_io_pads_gpioA_o_oval),
    .T(~dut_io_pads_gpioA_o_oe)
  );

  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  gpioB_iobuf[31:0]
  (
    .O(dut_io_pads_gpioB_i_ival),
    .IO(gpioB),
    .I(dut_io_pads_gpioB_o_oval),
    .T(~dut_io_pads_gpioB_o_oe)
  );
  */
  //=================================================
  // JTAG IOBUFs

  
  wire iobuf_jtag_TCK_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TCK
  (
    .O(iobuf_jtag_TCK_o),
    .IO(mcu_TCK),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TCK_i_ival = iobuf_jtag_TCK_o ;
  PULLUP pullup_TCK (.O(mcu_TCK));

  wire iobuf_jtag_TMS_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TMS
  (
    .O(iobuf_jtag_TMS_o),
    .IO(mcu_TMS),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TMS_i_ival = iobuf_jtag_TMS_o;
  PULLUP pullup_TMS (.O(mcu_TMS));

  wire iobuf_jtag_TDI_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDI
  (
    .O(iobuf_jtag_TDI_o),
    .IO(mcu_TDI),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TDI_i_ival = iobuf_jtag_TDI_o;
  PULLUP pullup_TDI (.O(mcu_TDI));

  wire iobuf_jtag_TDO_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDO
  (
    .O(iobuf_jtag_TDO_o),
    .IO(mcu_TDO),
    .I(dut_io_pads_jtag_TDO_o_oval),
    .T(~dut_io_pads_jtag_TDO_o_oe)
  );

  //wire iobuf_jtag_TRST_n_o;
  //IOBUF
  //#(
  //  .DRIVE(12),
  //  .IBUF_LOW_PWR("TRUE"),
  //  .IOSTANDARD("DEFAULT"),
  //  .SLEW("SLOW")
  //)
  

  //=================================================
  // Assignment of IOBUF "IO" pins to package pins

  // Pins IO0-IO13
  // Shield header row 0: PD0-PD7

  // Use the LEDs for some more useful debugging things.
  // assign pmu_paden  = dut_io_pads_aon_pmu_vddpaden_o_oval;  
  /*
  将板载 LED1 (D8) 作为 GPIOA[17]，便于软件控制闪烁验证 CPU 运行情况_cy
  软件侧请在启动后：
    1. 清除 IOF 使 GPIO17 成为普通 GPIO
    2. 设置 PADDIR 17 为输出
    3. 周期性翻转 PADOUT 17
  这样即可在不依赖 UART 的情况下观察 CPU 是否在运行
  */
  assign pmu_paden  = dut_io_pads_gpioA_o_oval[17];  //cy_led1
  assign pmu_padrst = dut_io_pads_aon_pmu_padrst_o_oval;		

  // model select
  assign dut_io_pads_bootrom_n_i_ival  = 1'b0;   // 0：从BootROM启动(0x1000)，1：FLASH启动(0x20000000)
  assign dut_io_pads_dbgmode0_n_i_ival = 1'b1;
  assign dut_io_pads_dbgmode1_n_i_ival = 1'b1;
  assign dut_io_pads_dbgmode2_n_i_ival = 1'b1;
  //

  e203_soc_top dut
  (
    .hfextclk(clk_16M),
    .hfxoscen(),

    .lfextclk(CLK32768KHZ), 
    .lfxoscen(),

    
       // Note: this is the real SoC top AON domain slow clock
    .io_pads_jtag_TCK_i_ival(dut_io_pads_jtag_TCK_i_ival),
    .io_pads_jtag_TMS_i_ival(dut_io_pads_jtag_TMS_i_ival),
    .io_pads_jtag_TDI_i_ival(dut_io_pads_jtag_TDI_i_ival),
    .io_pads_jtag_TDO_o_oval(dut_io_pads_jtag_TDO_o_oval),
    .io_pads_jtag_TDO_o_oe  (dut_io_pads_jtag_TDO_o_oe),
    

         // 连接GPIO A - 用于UART功能_cy
    .io_pads_gpioA_i_ival(dut_io_pads_gpioA_i_ival),
    .io_pads_gpioA_o_oval(dut_io_pads_gpioA_o_oval),
    .io_pads_gpioA_o_oe  (dut_io_pads_gpioA_o_oe),

     // GPIO B暂时不使用
     .io_pads_gpioB_i_ival(32'h0),
     .io_pads_gpioB_o_oval(),
     .io_pads_gpioB_o_oe  (),

    .io_pads_qspi0_sck_o_oval (dut_io_pads_qspi0_sck_o_oval),
    .io_pads_qspi0_cs_0_o_oval(dut_io_pads_qspi0_cs_0_o_oval),

    .io_pads_qspi0_dq_0_i_ival(dut_io_pads_qspi0_dq_0_i_ival),
    .io_pads_qspi0_dq_0_o_oval(dut_io_pads_qspi0_dq_0_o_oval),
    .io_pads_qspi0_dq_0_o_oe  (dut_io_pads_qspi0_dq_0_o_oe),
    .io_pads_qspi0_dq_1_i_ival(dut_io_pads_qspi0_dq_1_i_ival),
    .io_pads_qspi0_dq_1_o_oval(dut_io_pads_qspi0_dq_1_o_oval),
    .io_pads_qspi0_dq_1_o_oe  (dut_io_pads_qspi0_dq_1_o_oe),
    .io_pads_qspi0_dq_2_i_ival(dut_io_pads_qspi0_dq_2_i_ival),
    .io_pads_qspi0_dq_2_o_oval(dut_io_pads_qspi0_dq_2_o_oval),
    .io_pads_qspi0_dq_2_o_oe  (dut_io_pads_qspi0_dq_2_o_oe),
    .io_pads_qspi0_dq_3_i_ival(dut_io_pads_qspi0_dq_3_i_ival),
    .io_pads_qspi0_dq_3_o_oval(dut_io_pads_qspi0_dq_3_o_oval),
    .io_pads_qspi0_dq_3_o_oe  (dut_io_pads_qspi0_dq_3_o_oe),


       // Note: this is the real SoC top level reset signal
    .io_pads_aon_erst_n_i_ival(ck_rst),
    .io_pads_aon_pmu_dwakeup_n_i_ival(dut_io_pads_aon_pmu_dwakeup_n_i_ival),
    .io_pads_aon_pmu_vddpaden_o_oval(dut_io_pads_aon_pmu_vddpaden_o_oval),

    .io_pads_aon_pmu_padrst_o_oval    (dut_io_pads_aon_pmu_padrst_o_oval ),

    .io_pads_bootrom_n_i_ival       (dut_io_pads_bootrom_n_i_ival),

    .io_pads_dbgmode0_n_i_ival       (dut_io_pads_dbgmode0_n_i_ival),
    .io_pads_dbgmode1_n_i_ival       (dut_io_pads_dbgmode1_n_i_ival),
    .io_pads_dbgmode2_n_i_ival       (dut_io_pads_dbgmode2_n_i_ival) 
  );

  // Assign reasonable values to otherwise unconnected inputs to chip top

  wire iobuf_dwakeup_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_dwakeup_n
  (
    .O(iobuf_dwakeup_o),
    .IO(mcu_wakeup),
    .I(1'b1),
    .T(1'b1)
  );
  assign dut_io_pads_aon_pmu_dwakeup_n_i_ival = (~iobuf_dwakeup_o);

  

  assign dut_io_pads_aon_pmu_vddpaden_i_ival = 1'b1;

  // QSPI时钟使用STARTUP原语连接配置时钟
  // 因为QSPI时钟连接到配置引脚，必须使用STARTUP原语来访问
  STARTUPE3 #(
    .PROG_USR("FALSE"),          // 激活程序时钟输入，"FALSE"表示不使用
    .SIM_CCLK_FREQ(0.0)          // 仿真时的CCLK频率，单位MHz，0.0表示不指定
  ) STARTUPE3_inst (
    .CFGCLK(),                   // 配置时钟输出，未使用
    .CFGMCLK(),                  // 配置主时钟输出，未使用  
    .DI(4'h0),                   // 配置数据输入，未使用
    .EOS(),                      // 配置完成信号，未使用
    .PREQ(),                     // 请求信号，未使用
    .DO(),                       // 配置数据输出，未使用
    .DTS(4'hF),                  // 数据三态控制，全部设为高阻
    .FCSBO(dut_io_pads_qspi0_cs_0_o_oval),  // Flash片选输出
    .FCSBTS(~1'b1),              // Flash片选三态控制，使能输出
    .GSR(1'b0),                  // 全局复位，不使用
    .GTS(1'b0),                  // 全局三态，不使用
    .KEYCLEARB(1'b1),            // 密钥清除，不使用
    .PACK(1'b0),                 // 包模式，不使用
    .USRCCLKO(dut_io_pads_qspi0_sck_o_oval), // 用户时钟输出到CCLK引脚
    .USRCCLKTS(1'b0),            // 用户时钟三态控制，使能输出
    .USRDONEO(1'b1),             // 用户完成信号，设为高
    .USRDONETS(1'b1)             // 用户完成三态控制，设为高阻
  );

  // qspi0_sck现在通过STARTUP原语连接，不需要直接赋值
  // assign qspi0_sck = dut_io_pads_qspi0_sck_o_oval;  // 删除这行
  assign qspi0_cs  = dut_io_pads_qspi0_cs_0_o_oval;
  assign qspi0_ui_dq_o = {
    dut_io_pads_qspi0_dq_3_o_oval,
    dut_io_pads_qspi0_dq_2_o_oval,
    dut_io_pads_qspi0_dq_1_o_oval,
    dut_io_pads_qspi0_dq_0_o_oval
  };
  assign qspi0_ui_dq_oe = {
    dut_io_pads_qspi0_dq_3_o_oe,
    dut_io_pads_qspi0_dq_2_o_oe,
    dut_io_pads_qspi0_dq_1_o_oe,
    dut_io_pads_qspi0_dq_0_o_oe
  };
  assign dut_io_pads_qspi0_dq_0_i_ival = qspi0_ui_dq_i[0];
  assign dut_io_pads_qspi0_dq_1_i_ival = qspi0_ui_dq_i[1];
  assign dut_io_pads_qspi0_dq_2_i_ival = qspi0_ui_dq_i[2];
  assign dut_io_pads_qspi0_dq_3_i_ival = qspi0_ui_dq_i[3];

  //=================================================
  // UART连接 - 使用GPIO复用到专用串口引脚_cy
  
  // 直接连接UART到GPIO复用输出
  // 根据e203设计：gpioA[16]=UART0_RXD, gpioA[17]=UART0_TXD
  assign uart_tx = dut_io_pads_gpioA_o_oval[17];  // UART0 发送
  
  // 正确连接GPIO输入信号，避免覆盖UART RX
  assign dut_io_pads_gpioA_i_ival[31:17] = 15'h0;     // GPIO31-17设为0
  assign dut_io_pads_gpioA_i_ival[16] = uart_rx;      // GPIO16 = UART0 接收
  assign dut_io_pads_gpioA_i_ival[15:0] = 16'h0;      // GPIO15-0设为0
  
endmodule


