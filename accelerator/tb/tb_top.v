`include "e203_defines.v"

module tb_top();

  reg  clk;
  reg  lfextclk;
  reg  rst_n;

  wire hfclk = clk;

  `define CPU_TOP u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_cpu_top
  `define EXU `CPU_TOP.u_e203_cpu.u_e203_core.u_e203_exu
  `define ITCM `CPU_TOP.u_e203_srams.u_e203_itcm_ram
  `define IFU `CPU_TOP.u_e203_cpu.u_e203_core.u_e203_ifu
  `define BPU `IFU.u_e203_ifu_ift2icb.u_e203_ifu_litebpu

  `define PC_WRITE_TOHOST       `E203_PC_SIZE'h80000086
  `define PC_EXT_IRQ_BEFOR_MRET `E203_PC_SIZE'h800000a6
  `define PC_SFT_IRQ_BEFOR_MRET `E203_PC_SIZE'h800000be
  `define PC_TMR_IRQ_BEFOR_MRET `E203_PC_SIZE'h800000d6
  `define PC_AFTER_SETMTVEC     `E203_PC_SIZE'h8000015C

  wire [`E203_XLEN-1:0] x3 = `EXU.u_e203_exu_regfile.rf_r[3];
  wire [`E203_XLEN-1:0] t0 = `EXU.u_e203_exu_regfile.rf_r[5]; // t0寄存器(x5)，用于MROM跳转
  wire [`E203_PC_SIZE-1:0] pc = `EXU.u_e203_exu_commit.alu_cmt_i_pc;
  wire [`E203_PC_SIZE-1:0] pc_vld = `EXU.u_e203_exu_commit.alu_cmt_i_valid;

  reg [31:0] pc_write_to_host_cnt;
  reg [31:0] pc_write_to_host_cycle;
  reg [31:0] valid_ir_cycle;
  reg [31:0] cycle_count;
  reg pc_write_to_host_flag;

  // 监控current_stage变量（假设它在DTCM中的某个位置）
  // current_stage变量的地址需要从编译结果中获取
  // 作为简化，我们监控一些关键地址的访问
  wire axi_access_detected;
  assign axi_access_detected = 1'b0; // 这里可以添加AXI访问检测逻辑

  // 监控APB总线访问
  wire apb_access_detected;
  wire [31:0] apb_addr;
  wire [31:0] apb_data;
  wire apb_write;
  
  assign apb_access_detected = u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems.expl_apb_icb_cmd_valid;
  assign apb_addr = u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems.expl_apb_icb_cmd_addr;
  assign apb_data = u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems.expl_apb_icb_cmd_wdata;
  assign apb_write = ~u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems.expl_apb_icb_cmd_read;

  // 监控地址映射
  wire [31:0] mem_addr = u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems.mem_icb_cmd_addr;
  wire mem_valid = u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems.mem_icb_cmd_valid;
  
  always @(posedge hfclk) begin
    if (mem_valid) begin
      if ((mem_addr >= 32'h50000000) && (mem_addr < 32'h60000000)) begin
        $display("Access to APB region: addr=0x%08h", mem_addr);
      end else if ((mem_addr >= 32'h80000000) && (mem_addr < 32'hF0000000)) begin
        $display("Access to SysMem region: addr=0x%08h", mem_addr);
      end
    end
  end

  always @(posedge hfclk or negedge rst_n)
  begin 
    if(rst_n == 1'b0) begin
        pc_write_to_host_cnt <= 32'b0;
        pc_write_to_host_flag <= 1'b0;
        pc_write_to_host_cycle <= 32'b0;
    end
    else if (pc_vld) begin
        // 根据PC地址范围选择正确的内存显示
        if ((pc >= 32'h80000000) && (pc < 32'h80010000)) begin
            // ITCM地址范围：0x80000000 - 0x8000FFFF
            $display("Debug: cycle %d, PC = 0x%08h, Instruction = 0x%016h (ITCM)", 
                     cycle_count, pc, `ITCM.mem_r[(pc - 32'h80000000) >> 3]);
        end
        else if (pc < 32'h00002000) begin
            // MROM地址范围：0x00000000 - 0x00001FFF
            $display("Debug: cycle %d, PC = 0x%08h (MROM)", cycle_count, pc);
        end
        else begin
            // 其他地址范围
            $display("Debug: cycle %d, PC = 0x%08h (Other)", cycle_count, pc);
        end
        
        // 当PC在0x8000006c-0x80000070之间时，显示更多信息
        if ((pc >= 32'h8000006c) && (pc <= 32'h80000070)) begin
            $display("Warning: PC in potential dead loop at 0x%08h", pc);
            // 显示相关寄存器的值
            $display("x3 = 0x%08h, x4 = 0x%08h, x5 = 0x%08h", 
                     `EXU.u_e203_exu_regfile.rf_r[3],
                     `EXU.u_e203_exu_regfile.rf_r[4],
                     `EXU.u_e203_exu_regfile.rf_r[5]);
        end
    end
  end

  // MROM执行监控和寄存器监控
  reg [31:0] last_pc;
  always @(posedge hfclk or negedge rst_n)
  begin 
    if(rst_n == 1'b0) begin
        last_pc <= 32'hFFFFFFFF;
        $display("=== CPU复位 ===");
    end
    else if (pc_vld) begin
        // 监控复位后第一个PC
        if (last_pc == 32'hFFFFFFFF) begin
            $display("=== 复位后第一个PC: 0x%08h ===", pc);
        end
        
        // 监控MROM执行
        if (pc == 32'h00001000) begin
            $display(">>> 执行MROM[0] (PC=0x00001000): auipc t0, 0x7ffff");
            $display("    期望: t0 = PC + (0x7ffff << 12) = 0x80000000");
        end
        if (pc == 32'h00001004) begin
            $display(">>> 执行MROM[1] (PC=0x00001004): jr t0");
            $display("    当前 t0 = 0x%08h (期望: 0x80000000)", t0);
            if (t0 == 32'h80000000) begin
                $display("    ✓ t0值正确，应该跳转到0x80000000");
            end else begin
                $display("    ✗ t0值错误！期望0x80000000，实际0x%08h", t0);
            end
            // 检查JALR指令的执行状态
            $display("    检查JALR执行状态:");
            $display("      - 跳转目标地址应该是: t0 + 0 = 0x%08h", t0);
            $display("      - 地址对齐检查: 0x%08h[1:0] = %b (应该为00)", t0, t0[1:0]);
            if (t0[1:0] != 2'b00) begin
                $display("      ✗ 警告: 跳转目标地址未对齐！JALR要求地址最低位必须为0");
            end
        end
        
        // 监控PC卡在0x00001004的情况（JALR执行后）
        if (pc == 32'h00001004 && last_pc == 32'h00001004) begin
            if (cycle_count % 50 == 0) begin // 每50个周期显示一次
                $display("警告: PC卡在0x00001004 (JALR指令后)");
                $display("      t0 = 0x%08h", t0);
                $display("      跳转目标 = 0x%08h", t0);
                $display("      已持续 %d 个周期", cycle_count);
            end
        end
        
        // 监控跳转到ITCM
        if ((last_pc < 32'h00002000) && (pc >= 32'h80000000) && (pc < 32'h80010000)) begin
            $display(">>> ✓ 成功跳转到ITCM: PC从0x%08h跳转到0x%08h", last_pc, pc);
            $display("    ITCM[0] = 0x%016h", `ITCM.mem_r[0]);
        end
        
        // 监控PC卡在MROM的情况
        if ((pc >= 32'h00001000) && (pc < 32'h00002000) && (last_pc == pc)) begin
            if (cycle_count % 100 == 0) begin // 每100个周期显示一次，避免输出过多
                $display("警告: PC卡在MROM地址 0x%08h (已持续%d个周期)", pc, cycle_count);
                $display("      t0 = 0x%08h", t0);
            end
        end
        
        last_pc <= pc;
    end
  end

  always @(posedge hfclk or negedge rst_n)
  begin 
    if(rst_n == 1'b0) begin
        cycle_count <= 32'b0;
    end
    else begin
        cycle_count <= cycle_count + 1'b1;
    end
  end

  wire i_valid = `EXU.i_valid;
  wire i_ready = `EXU.i_ready;

  always @(posedge hfclk or negedge rst_n)
  begin 
    if(rst_n == 1'b0) begin
        valid_ir_cycle <= 32'b0;
    end
    else if(i_valid & i_ready & (pc_write_to_host_flag == 1'b0)) begin
        valid_ir_cycle <= valid_ir_cycle + 1'b1;
    end
  end


  // Randomly force the external interrupt
  `define EXT_IRQ u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.plic_ext_irq
  `define SFT_IRQ u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.clint_sft_irq
  `define TMR_IRQ u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.clint_tmr_irq

  `define U_CPU u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_cpu_top.u_e203_cpu
  `define ITCM_BUS_ERR `U_CPU.u_e203_itcm_ctrl.sram_icb_rsp_err
  `define ITCM_BUS_READ `U_CPU.u_e203_itcm_ctrl.sram_icb_rsp_read
  `define STATUS_MIE   `U_CPU.u_e203_core.u_e203_exu.u_e203_exu_commit.u_e203_exu_excp.status_mie_r

  wire stop_assert_irq = (pc_write_to_host_cnt > 32);

  reg tb_itcm_bus_err;

  reg tb_ext_irq;
  reg tb_tmr_irq;
  reg tb_sft_irq;
  initial begin
    tb_ext_irq = 1'b0;
    tb_tmr_irq = 1'b0;
    tb_sft_irq = 1'b0;
  end

`ifdef ENABLE_TB_FORCE
  initial begin
    tb_itcm_bus_err = 1'b0;
    #100
    @(pc == `PC_AFTER_SETMTVEC ) // Wait the program goes out the reset_vector program
    forever begin
      repeat ($urandom_range(1, 20)) @(posedge clk) tb_itcm_bus_err = 1'b0; // Wait random times
      repeat ($urandom_range(1, 200)) @(posedge clk) tb_itcm_bus_err = 1'b1; // Wait random times
      if(stop_assert_irq) begin
          break;
      end
    end
  end


  initial begin
    force `EXT_IRQ = tb_ext_irq;
    force `SFT_IRQ = tb_sft_irq;
    force `TMR_IRQ = tb_tmr_irq;
       // We force the bus-error only when:
       //   It is in common code, not in exception code, by checking MIE bit
       //   It is in read operation, not write, otherwise the test cannot recover
    force `ITCM_BUS_ERR = tb_itcm_bus_err
                        & `STATUS_MIE 
                        & `ITCM_BUS_READ
                        ;
  end


  initial begin
    #100
    @(pc == `PC_AFTER_SETMTVEC ) // Wait the program goes out the reset_vector program
    forever begin
      repeat ($urandom_range(1, 1000)) @(posedge clk) tb_ext_irq = 1'b0; // Wait random times
      tb_ext_irq = 1'b1; // assert the irq
      @((pc == `PC_EXT_IRQ_BEFOR_MRET)) // Wait the program run into the IRQ handler by check PC values
      tb_ext_irq = 1'b0;
      if(stop_assert_irq) begin
          break;
      end
    end
  end

  initial begin
    #100
    @(pc == `PC_AFTER_SETMTVEC ) // Wait the program goes out the reset_vector program
    forever begin
      repeat ($urandom_range(1, 1000)) @(posedge clk) tb_sft_irq = 1'b0; // Wait random times
      tb_sft_irq = 1'b1; // assert the irq
      @((pc == `PC_SFT_IRQ_BEFOR_MRET)) // Wait the program run into the IRQ handler by check PC values
      tb_sft_irq = 1'b0;
      if(stop_assert_irq) begin
          break;
      end
    end
  end

  initial begin
    #100
    @(pc == `PC_AFTER_SETMTVEC ) // Wait the program goes out the reset_vector program
    forever begin
      repeat ($urandom_range(1, 1000)) @(posedge clk) tb_tmr_irq = 1'b0; // Wait random times
      tb_tmr_irq = 1'b1; // assert the irq
      @((pc == `PC_TMR_IRQ_BEFOR_MRET)) // Wait the program run into the IRQ handler by check PC values
      tb_tmr_irq = 1'b0;
      if(stop_assert_irq) begin
          break;
      end
    end
  end
`endif

  reg[8*300:1] testcase;
  integer dumpwave;

  initial begin
    $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");  
    if($value$plusargs("TESTCASE=%s",testcase))begin
      $display("TESTCASE=%s",testcase);
    end

    pc_write_to_host_flag <=0;
    clk   <=0;
    lfextclk   <=0;
    rst_n <=0;
    #120 rst_n <=1;

    //@(pc_write_to_host_cnt == 32'd1) #10 rst_n <=1;
    wait (x3 == 32'd290);
`ifdef ENABLE_TB_FORCE
    @((~tb_tmr_irq) & (~tb_sft_irq) & (~tb_ext_irq)) #10 rst_n <=1;// Wait the interrupt to complete
`endif

        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~ Test Result Summary ~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~TESTCASE: %s ~~~~~~~~~~~~~", testcase);
        $display("~~~~~~~~~~~~~~Total cycle_count value: %d ~~~~~~~~~~~~~", cycle_count);
        $display("~~~~~~~~~~The valid Instruction Count: %d ~~~~~~~~~~~~~", valid_ir_cycle);
        $display("~~~~~The test ending reached at cycle: %d ~~~~~~~~~~~~~", pc_write_to_host_cycle);
        $display("~~~~~~~~~~~~~~~The final x3 Reg value: %d ~~~~~~~~~~~~~", x3);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    if (x3 == 32'h122) begin
        $display("~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    end
    else begin
        $display("~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~~~~~~~");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    end
    #10
     $finish;
  end

  // 修改超时检测
  initial begin
    #1000000
    $display("Time Out !!!");
    $display("Last PC = 0x%08h", pc);
    $display("Last x3 = 0x%08h", x3);
    $finish;
  end

  always
  begin 
     #2 clk <= ~clk;
  end

  always
  begin 
     #33 lfextclk <= ~lfextclk;
  end



  
  
  initial begin
    if($value$plusargs("DUMPWAVE=%d",dumpwave)) begin
      if(dumpwave != 0) begin
        `ifdef vcs
          $display("VCS used");
          $fsdbDumpfile("tb_top.fsdb");
          $fsdbDumpvars(0, tb_top, "+mda");
          // 添加更多关键信号的波形记录
          $fsdbDumpvars(0, `ITCM);
          $fsdbDumpvars(0, u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems);
          $fsdbDumpvars(0, `EXU.u_e203_exu_regfile);
        `endif

        `ifdef iverilog
          $display("iverilog used");
          $dumpfile("tb_top.vcd");
          $dumpvars(0, tb_top);
          // 添加更多关键信号的波形记录
          $dumpvars(0, `ITCM);
          $dumpvars(0, u_e203_soc_top.u_e203_subsys_top.u_e203_subsys_main.u_e203_subsys_mems);
          $dumpvars(0, `EXU.u_e203_exu_regfile);
        `endif
      end
    end
  end




  integer i;
  reg [7:0] itcm_mem [0:(`E203_ITCM_RAM_DP*8)-1];
  
  initial begin
    // ===== 仿真时使用标准的testcase加载方式 =====
    // 注意：FPGA综合时程序已在e203_itcm_ram.v中预加载
    // 仿真时使用命令行参数指定的testcase文件
    
    //wait(rst_n == 1'b1);

    if(testcase != "") begin
      $display("=== 加载仿真测试用例 ===");
      $display("加载testcase: %s", testcase);
      
      $readmemh({testcase,".verilog"}, itcm_mem);

      for (i=0;i<(`E203_ITCM_RAM_DP);i=i+1) begin
          `ITCM.mem_r[i][00+7:00] = itcm_mem[i*8+0];
          `ITCM.mem_r[i][08+7:08] = itcm_mem[i*8+1];
          `ITCM.mem_r[i][16+7:16] = itcm_mem[i*8+2];
          `ITCM.mem_r[i][24+7:24] = itcm_mem[i*8+3];
          `ITCM.mem_r[i][32+7:32] = itcm_mem[i*8+4];
          `ITCM.mem_r[i][40+7:40] = itcm_mem[i*8+5];
          `ITCM.mem_r[i][48+7:48] = itcm_mem[i*8+6];
          `ITCM.mem_r[i][56+7:56] = itcm_mem[i*8+7];
      end

      $display("ITCM 0x00: %h", `ITCM.mem_r[8'h00]);
      $display("ITCM 0x01: %h", `ITCM.mem_r[8'h01]);
      $display("ITCM 0x02: %h", `ITCM.mem_r[8'h02]);
      $display("ITCM 0x03: %h", `ITCM.mem_r[8'h03]);
      $display("ITCM 0x04: %h", `ITCM.mem_r[8'h04]);
      $display("ITCM 0x05: %h", `ITCM.mem_r[8'h05]);
      $display("ITCM 0x06: %h", `ITCM.mem_r[8'h06]);
      $display("ITCM 0x07: %h", `ITCM.mem_r[8'h07]);
      $display("ITCM 0x16: %h", `ITCM.mem_r[8'h16]);
      $display("ITCM 0x20: %h", `ITCM.mem_r[8'h20]);
      $display("=== testcase加载完成 ===");
    end
    else begin
      $display("=== 使用ITCM预加载程序 ===");
      $display("未指定testcase，使用e203_itcm_ram.v中预加载的程序");
      $display("ITCM 前8个地址内容:");
      for (i=0;i<8;i=i+1) begin
        $display("  [0x%08h] = 0x%016h", (32'h80000000 + i*8), `ITCM.mem_r[i]);
      end
      $display("=========================");
    end
  end



  wire jtag_TDI = 1'b0;
  wire jtag_TDO;
  wire jtag_TCK = 1'b0;
  wire jtag_TMS = 1'b0;
  wire jtag_TRST = 1'b0;

  wire jtag_DRV_TDO = 1'b0;


e203_soc_top u_e203_soc_top(
   
   .hfextclk(hfclk),
   .hfxoscen(),

   .lfextclk(lfextclk),
   .lfxoscen(),

   .io_pads_jtag_TCK_i_ival (jtag_TCK),
   .io_pads_jtag_TMS_i_ival (jtag_TMS),
   .io_pads_jtag_TDI_i_ival (jtag_TDI),
   .io_pads_jtag_TDO_o_oval (jtag_TDO),
   .io_pads_jtag_TDO_o_oe (),

   .io_pads_gpioA_i_ival(32'b0),
   .io_pads_gpioA_o_oval(),
   .io_pads_gpioA_o_oe  (),

   .io_pads_gpioB_i_ival(32'b0),
   .io_pads_gpioB_o_oval(),
   .io_pads_gpioB_o_oe  (),

   .io_pads_qspi0_sck_o_oval (),
   .io_pads_qspi0_cs_0_o_oval(),
   .io_pads_qspi0_dq_0_i_ival(1'b1),
   .io_pads_qspi0_dq_0_o_oval(),
   .io_pads_qspi0_dq_0_o_oe  (),
   .io_pads_qspi0_dq_1_i_ival(1'b1),
   .io_pads_qspi0_dq_1_o_oval(),
   .io_pads_qspi0_dq_1_o_oe  (),
   .io_pads_qspi0_dq_2_i_ival(1'b1),
   .io_pads_qspi0_dq_2_o_oval(),
   .io_pads_qspi0_dq_2_o_oe  (),
   .io_pads_qspi0_dq_3_i_ival(1'b1),
   .io_pads_qspi0_dq_3_o_oval(),
   .io_pads_qspi0_dq_3_o_oe  (),

   .io_pads_aon_erst_n_i_ival (rst_n),//This is the real reset, active low
   .io_pads_aon_pmu_dwakeup_n_i_ival (1'b1),

   .io_pads_aon_pmu_vddpaden_o_oval (),
    .io_pads_aon_pmu_padrst_o_oval    (),

    .io_pads_bootrom_n_i_ival       (1'b0),// In Simulation we boot from ROM
    .io_pads_dbgmode0_n_i_ival       (1'b1),
    .io_pads_dbgmode1_n_i_ival       (1'b1),
    .io_pads_dbgmode2_n_i_ival       (1'b1) 
);

initial begin
    $value$plusargs("DUMPWAVE=%d",dumpwave);
    if(dumpwave != 0)begin
         // To add your waveform generation function
	 $fsdbDumpfile("dump.fsdb");
	 $fsdbDumpvars("+all");
    end
  end


endmodule


