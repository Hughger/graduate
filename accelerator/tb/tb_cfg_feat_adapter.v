// `timescale 1ns/1ps  // 注释掉，让主模块控制timescale

// Testbench adapter bridging high-level cfg/feature/output accesses
// to the unified 64-bit bus of Mac_ASIC_top.
// Addressing rule per requirement:
// - Build 19-bit byte-address = BIAS + OFFSET
// - bus_addr = byte-address >> 3 (16-bit, 64-bit aligned)
// - For 256-bit accesses, split into 4x64-bit beats (low -> high)

module tb_cfg_feat_adapter(
  input  wire        clock,
  input  wire        reset,
  output reg  [15:0] bus_addr,
  output reg         bus_en,
  output reg         bus_wr_en,
  inout  wire [63:0] bus_dinout,
  // status
  output wire         busy,

  // config bus (32-bit data, 32-bit address in register-space)
  input  wire [31:0] io_configBus_data,
  input  wire [31:0] io_configBus_addr,
  input  wire        io_configBus_en,

  // feature map write (256-bit data per addr)
  input  wire        io_featureMapBus_en,
  input  wire [12:0] io_featureMapBus_addr,
  input  wire [255:0] io_featureMapBus_data,

  // weight write ports (from testbench)
  input  wire        io_weightSramWritePing_en,
  input  wire [12:0] io_weightSramWritePing_addr,
  input  wire [255:0] io_weightSramWritePing_data,
  input  wire        io_weightSramWritePong_en,
  input  wire [12:0] io_weightSramWritePong_addr,
  input  wire [255:0] io_weightSramWritePong_data,
  // weight read ports (unused in this adapter – pass-through zeros)
  input  wire        io_weightSramReadPing_readEnable,
  input  wire [24:0] io_weightSramReadPing_readAddress,
  output wire [255:0] io_weightSramReadPing_readData,
  input  wire        io_weightSramReadPong_readEnable,
  input  wire [24:0] io_weightSramReadPong_readAddress,
  output wire [255:0] io_weightSramReadPong_readData,

  // output SRAM ping
  output reg         io_outputSramPing_writeEnable,
  output reg  [12:0] io_outputSramPing_writeAddress,
  output reg  [255:0] io_outputSramPing_writeData,
  input  wire        io_outputSramPing_readEnable,
  input  wire [12:0] io_outputSramPing_readAddress,
  output reg  [255:0] io_outputSramPing_readData,
  output reg         io_outputSramPing_readValid,

  // output SRAM pong
  output reg         io_outputSramPong_writeEnable,
  output reg  [12:0] io_outputSramPong_writeAddress,
  output reg  [255:0] io_outputSramPong_writeData,
  input  wire        io_outputSramPong_readEnable,
  input  wire [12:0] io_outputSramPong_readAddress,
  output reg  [255:0] io_outputSramPong_readData,
  output reg         io_outputSramPong_readValid,

  // outputJoint (not used here, tie-offs)
  output reg         io_outputJointSram_writeEnable,
  output reg  [12:0] io_outputJointSram_writeAddress,
  output reg  [255:0] io_outputJointSram_writeData,
  input  wire        io_outputJointSram_readEnable,
  input  wire [12:0] io_outputJointSram_readAddress,
  output reg  [255:0] io_outputJointSram_readData,

  // joint (not used here, tie-offs)
  output reg         io_jointSram_writeEnable,
  output reg  [17:0] io_jointSram_writeAddress,
  output reg  [255:0] io_jointSram_writeData,
  input  wire        io_jointSram_readEnable,
  input  wire [17:0] io_jointSram_readAddress,
  output reg  [255:0] io_jointSram_readData
);

  // Address biases (19-bit byte address space per requirement)
  localparam [18:0] BIAS_CFG   = 19'h00000; // RAM0
  localparam [18:0] BIAS_FEAT  = 19'h10000; // RAM1
  localparam [18:0] BIAS_WPING = 19'h20000; // RAM2
  localparam [18:0] BIAS_WPONG = 19'h30000; // RAM3
  localparam [18:0] BIAS_OPING = 19'h40000; // RAM4
  localparam [18:0] BIAS_OPONG = 19'h50000; // RAM5
  localparam [18:0] BIAS_CTRL  = 19'h60000; // CTRL (SRAM控制寄存器)

  // Simple shared bus master FSM
  localparam ST_IDLE     = 5'd0;
  localparam ST_CFG_W    = 5'd1;
  localparam ST_CTRL_W   = 5'd2;  // SRAM控制寄存器写入
  localparam ST_WPING_W0 = 5'd3;  // 权重ping写入
  localparam ST_WPING_W1 = 5'd4;
  localparam ST_WPING_W2 = 5'd5;
  localparam ST_WPING_W3 = 5'd6;
  localparam ST_WPONG_W0 = 5'd7;  // 权重pong写入
  localparam ST_WPONG_W1 = 5'd8;
  localparam ST_WPONG_W2 = 5'd9;
  localparam ST_WPONG_W3 = 5'd10;
  localparam ST_FEAT_W0  = 5'd11;
  localparam ST_FEAT_W1  = 5'd12;
  localparam ST_FEAT_W2  = 5'd13;
  localparam ST_FEAT_W3  = 5'd14;
  localparam ST_OPING_R0 = 5'd15;
  localparam ST_OPING_R1 = 5'd16;
  localparam ST_OPING_R2 = 5'd17;
  localparam ST_OPING_R3 = 5'd18;
  localparam ST_OPONG_R0 = 5'd19;
  localparam ST_OPONG_R1 = 5'd20;
  localparam ST_OPONG_R2 = 5'd21;
  localparam ST_OPONG_R3 = 5'd22;
  // 2-CLK read latency wait states
  localparam ST_OPING_W0 = 5'd23;
  localparam ST_OPING_W1 = 5'd24;
  localparam ST_OPING_W2 = 5'd25;
  localparam ST_OPING_W3 = 5'd26;
  localparam ST_OPONG_W0 = 5'd27;
  localparam ST_OPONG_W1 = 5'd28;
  localparam ST_OPONG_W2 = 5'd29;
  localparam ST_OPONG_W3 = 5'd30;

  reg [4:0] state;
  reg [1:0] read_wait; // counts down the 2-cycle latency

  // 64-bit bus data direction control
  reg        drive_bus;
  reg [63:0] bus_wdata_q;
  assign bus_dinout = drive_bus ? bus_wdata_q : 64'bz;

  // Latches for pending operations
  reg [31:0] cfg_data_q;
  reg [31:0] cfg_addr_q;

  reg [12:0] feat_addr_q;
  reg [255:0] feat_data_q;

  reg [12:0] wping_addr_q;
  reg [255:0] wping_data_q;
  reg [12:0] wpong_addr_q;
  reg [255:0] wpong_data_q;

  reg [12:0] oping_raddr_q;
  reg [12:0] opong_raddr_q;

  // Read data assembly
  reg [255:0] read_assemble;

  // Helpers: build bus_addr from 19-bit byte-address
  function [15:0] to_bus_addr_from19;
    input [18:0] byte_addr19;
    begin
      to_bus_addr_from19 = byte_addr19[18:3];
    end
  endfunction

  // Byte address calculators
  function [18:0] cfg_byte_addr;
    input [31:0] reg_addr; // 32-bit register index
    begin
      // place each 32-bit register on its own 64-bit slot (8-byte aligned)
      cfg_byte_addr = BIAS_CFG + {reg_addr, 3'b000};
      $display("[ADDR] cfg_byte_addr: reg_addr=0x%08x, byte_addr=0x%05x, bus_addr=0x%04x", 
               reg_addr, cfg_byte_addr, to_bus_addr_from19(cfg_byte_addr));
    end
  endfunction

  function [18:0] feat_byte_addr_base;
    input [12:0] a13;
    begin
      // 256-bit line => 32 bytes per address
      feat_byte_addr_base = BIAS_FEAT + {a13, 5'b0};
      $display("[ADDR] feat_byte_addr_base: a13=0x%04x, byte_addr=0x%05x, bus_addr=0x%04x", 
               a13, feat_byte_addr_base, to_bus_addr_from19(feat_byte_addr_base));
    end
  endfunction

  function [18:0] oping_byte_addr_base;
    input [12:0] a13;
    begin
      oping_byte_addr_base = BIAS_OPING + {a13, 5'b0};
      $display("[ADDR] oping_byte_addr_base: a13=0x%04x, byte_addr=0x%05x, bus_addr=0x%04x", 
               a13, oping_byte_addr_base, to_bus_addr_from19(oping_byte_addr_base));
    end
  endfunction

  function [18:0] opong_byte_addr_base;
    input [12:0] a13;
    begin
      opong_byte_addr_base = BIAS_OPONG + {a13, 5'b0};
      $display("[ADDR] opong_byte_addr_base: a13=0x%04x, byte_addr=0x%05x, bus_addr=0x%04x", 
               a13, opong_byte_addr_base, to_bus_addr_from19(opong_byte_addr_base));
    end
  endfunction

  function [18:0] wping_byte_addr_base;
    input [12:0] a13;
    begin
      wping_byte_addr_base = BIAS_WPING + {a13, 5'b0};
      $display("[ADDR] wping_byte_addr_base: a13=0x%04x, byte_addr=0x%05x, bus_addr=0x%04x", 
               a13, wping_byte_addr_base, to_bus_addr_from19(wping_byte_addr_base));
    end
  endfunction

  function [18:0] wpong_byte_addr_base;
    input [12:0] a13;
    begin
      wpong_byte_addr_base = BIAS_WPONG + {a13, 5'b0};
      $display("[ADDR] wpong_byte_addr_base: a13=0x%04x, byte_addr=0x%05x, bus_addr=0x%04x", 
               a13, wpong_byte_addr_base, to_bus_addr_from19(wpong_byte_addr_base));
    end
  endfunction

  // Default/tie-offs for unused channels
  assign io_weightSramReadPing_readData = {256{1'b0}};
  assign io_weightSramReadPong_readData = {256{1'b0}};

  // Control
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= ST_IDLE;
      read_wait <= 2'd0;
      bus_addr   <= 16'b0;
      bus_en     <= 1'b0;
      bus_wr_en  <= 1'b0;
      drive_bus  <= 1'b0;
      bus_wdata_q<= 64'b0;
      cfg_data_q <= 32'b0;
      cfg_addr_q <= 32'b0;
      feat_addr_q<= 13'b0;
      feat_data_q<= 256'b0;
      wping_addr_q <= 13'b0;
      wping_data_q <= 256'b0;
      wpong_addr_q <= 13'b0;
      wpong_data_q <= 256'b0;
      oping_raddr_q <= 13'b0;
      opong_raddr_q <= 13'b0;

      io_outputSramPing_writeEnable <= 1'b0;
      io_outputSramPing_writeAddress<= 13'b0;
      io_outputSramPing_writeData   <= 256'b0;
      io_outputSramPing_readData    <= 256'b0;
      io_outputSramPing_readValid   <= 1'b0;

      io_outputSramPong_writeEnable <= 1'b0;
      io_outputSramPong_writeAddress<= 13'b0;
      io_outputSramPong_writeData   <= 256'b0;
      io_outputSramPong_readData    <= 256'b0;
      io_outputSramPong_readValid   <= 1'b0;

      io_outputJointSram_writeEnable <= 1'b0;
      io_outputJointSram_writeAddress<= 13'b0;
      io_outputJointSram_writeData   <= 256'b0;
      io_outputJointSram_readData    <= 256'b0;

      io_jointSram_writeEnable <= 1'b0;
      io_jointSram_writeAddress<= 18'b0;
      io_jointSram_writeData   <= 256'b0;
      io_jointSram_readData    <= 256'b0;

      read_assemble <= 256'b0;
    end else begin
      // Defaults each cycle
      bus_en    <= 1'b0;
      bus_wr_en <= 1'b0;
      drive_bus <= 1'b0;
      io_outputSramPing_readValid <= 1'b0;
      io_outputSramPong_readValid <= 1'b0;
      // default wait stays unless set
      if (read_wait != 2'd0) begin
        read_wait <= read_wait - 2'd1;
      end

      // Clear write flags for unused outputs
      io_outputSramPing_writeEnable <= 1'b0;
      io_outputSramPong_writeEnable <= 1'b0;
      io_outputJointSram_writeEnable<= 1'b0;
      io_jointSram_writeEnable      <= 1'b0;

      case (state)
        ST_IDLE: begin
          // Priority: cfg write -> weight write -> feature write -> output reads (ping then pong)
          if (io_configBus_en) begin
            cfg_addr_q <= io_configBus_addr;
            cfg_data_q <= io_configBus_data;
            // Check if this is SRAM control register (0x5006_0000)
            if (io_configBus_addr == 32'h50060000) begin
              // SRAM control register write: {zero, data[31:0]}
              bus_wdata_q <= {32'b0, io_configBus_data};
              bus_addr    <= to_bus_addr_from19(BIAS_CTRL);
              bus_en      <= 1'b1;
              bus_wr_en   <= 1'b1;
              drive_bus   <= 1'b1;
              state       <= ST_CTRL_W;
            end else begin
              // Normal config write: {zero, data[31:0]}
              bus_wdata_q <= {32'b0, io_configBus_data};
              bus_addr    <= to_bus_addr_from19(cfg_byte_addr(io_configBus_addr));
              bus_en      <= 1'b1;
              bus_wr_en   <= 1'b1;
              drive_bus   <= 1'b1;
              state       <= ST_CFG_W;
            end
          end else if (io_weightSramWritePing_en) begin
            wping_addr_q <= io_weightSramWritePing_addr;
            wping_data_q <= io_weightSramWritePing_data;
            // beat 0 (lowest 64-bit)
            bus_wdata_q <= io_weightSramWritePing_data[63:0];
            bus_addr    <= to_bus_addr_from19(wping_byte_addr_base(io_weightSramWritePing_addr) + 19'd0);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b1;
            drive_bus   <= 1'b1;
            state       <= ST_WPING_W0;
          end else if (io_weightSramWritePong_en) begin
            wpong_addr_q <= io_weightSramWritePong_addr;
            wpong_data_q <= io_weightSramWritePong_data;
            // beat 0 (lowest 64-bit)
            bus_wdata_q <= io_weightSramWritePong_data[63:0];
            bus_addr    <= to_bus_addr_from19(wpong_byte_addr_base(io_weightSramWritePong_addr) + 19'd0);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b1;
            drive_bus   <= 1'b1;
            state       <= ST_WPONG_W0;
          end else if (io_featureMapBus_en) begin
            feat_addr_q <= io_featureMapBus_addr;
            feat_data_q <= io_featureMapBus_data;
            // beat 0 (lowest 64-bit)
            bus_wdata_q <= io_featureMapBus_data[63:0];
            bus_addr    <= to_bus_addr_from19(feat_byte_addr_base(io_featureMapBus_addr) + 19'd0);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b1;
            drive_bus   <= 1'b1;
            state       <= ST_FEAT_W0;
          end else if (io_outputSramPing_readEnable) begin
            oping_raddr_q <= io_outputSramPing_readAddress;
            // issue first read beat
            bus_addr    <= to_bus_addr_from19(oping_byte_addr_base(io_outputSramPing_readAddress) + 19'd0);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            state       <= ST_OPING_R0;
          end else if (io_outputSramPong_readEnable) begin
            opong_raddr_q <= io_outputSramPong_readAddress;
            bus_addr    <= to_bus_addr_from19(opong_byte_addr_base(io_outputSramPong_readAddress) + 19'd0);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            state       <= ST_OPONG_R0;
          end
        end

        ST_CFG_W: begin
          // single-cycle write done
          state <= ST_IDLE;
        end

        ST_CTRL_W: begin
          // SRAM control register single-cycle write done
          state <= ST_IDLE;
        end

        // Weight ping 4-beat write: low -> high
        ST_WPING_W0: begin
          bus_wdata_q <= wping_data_q[127:64];
          bus_addr    <= to_bus_addr_from19(wping_byte_addr_base(wping_addr_q) + 19'd8);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_WPING_W1;
        end
        ST_WPING_W1: begin
          bus_wdata_q <= wping_data_q[191:128];
          bus_addr    <= to_bus_addr_from19(wping_byte_addr_base(wping_addr_q) + 19'd16);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_WPING_W2;
        end
        ST_WPING_W2: begin
          bus_wdata_q <= wping_data_q[255:192];
          bus_addr    <= to_bus_addr_from19(wping_byte_addr_base(wping_addr_q) + 19'd24);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_WPING_W3;
        end
        ST_WPING_W3: begin
          // done
          state <= ST_IDLE;
        end

        // Weight pong 4-beat write: low -> high
        ST_WPONG_W0: begin
          bus_wdata_q <= wpong_data_q[127:64];
          bus_addr    <= to_bus_addr_from19(wpong_byte_addr_base(wpong_addr_q) + 19'd8);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_WPONG_W1;
        end
        ST_WPONG_W1: begin
          bus_wdata_q <= wpong_data_q[191:128];
          bus_addr    <= to_bus_addr_from19(wpong_byte_addr_base(wpong_addr_q) + 19'd16);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_WPONG_W2;
        end
        ST_WPONG_W2: begin
          bus_wdata_q <= wpong_data_q[255:192];
          bus_addr    <= to_bus_addr_from19(wpong_byte_addr_base(wpong_addr_q) + 19'd24);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_WPONG_W3;
        end
        ST_WPONG_W3: begin
          // done
          state <= ST_IDLE;
        end

        // Feature 4-beat write: low -> high
        ST_FEAT_W0: begin
          bus_wdata_q <= feat_data_q[127:64];
          bus_addr    <= to_bus_addr_from19(feat_byte_addr_base(feat_addr_q) + 19'd8);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_FEAT_W1;
        end
        ST_FEAT_W1: begin
          bus_wdata_q <= feat_data_q[191:128];
          bus_addr    <= to_bus_addr_from19(feat_byte_addr_base(feat_addr_q) + 19'd16);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_FEAT_W2;
        end
        ST_FEAT_W2: begin
          bus_wdata_q <= feat_data_q[255:192];
          bus_addr    <= to_bus_addr_from19(feat_byte_addr_base(feat_addr_q) + 19'd24);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b1;
          drive_bus   <= 1'b1;
          state       <= ST_FEAT_W3;
        end
        ST_FEAT_W3: begin
          // done
          state <= ST_IDLE;
        end

        // Output ping read with 2-CLK latency per beat
        ST_OPING_R0: begin
          // issue beat0
          bus_addr    <= to_bus_addr_from19(oping_byte_addr_base(oping_raddr_q) + 19'd0);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b0;
          drive_bus   <= 1'b0;
          read_wait   <= 2'd2;
          state       <= ST_OPING_W0;
        end
        ST_OPING_W0: begin
          if (read_wait == 2'd0) begin
            read_assemble[63:0] <= bus_dinout;
            // issue beat1
            bus_addr    <= to_bus_addr_from19(oping_byte_addr_base(oping_raddr_q) + 19'd8);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            read_wait   <= 2'd2;
            state       <= ST_OPING_R1;
          end
        end
        ST_OPING_R1: begin
          if (read_wait == 2'd0) begin
            read_assemble[127:64] <= bus_dinout;
            // issue beat2
            bus_addr    <= to_bus_addr_from19(oping_byte_addr_base(oping_raddr_q) + 19'd16);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            read_wait   <= 2'd2;
            state       <= ST_OPING_W2;
          end
        end
        ST_OPING_W2: begin
          if (read_wait == 2'd0) begin
            read_assemble[191:128] <= bus_dinout;
            // issue beat3
            bus_addr    <= to_bus_addr_from19(oping_byte_addr_base(oping_raddr_q) + 19'd24);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            read_wait   <= 2'd2;
            state       <= ST_OPING_R3;
          end
        end
        ST_OPING_R3: begin
          if (read_wait == 2'd0) begin
            read_assemble[255:192] <= bus_dinout;
            io_outputSramPing_readData <= read_assemble;
            io_outputSramPing_readValid <= 1'b1;
            state <= ST_IDLE;
          end
        end

        // Output pong read with 2-CLK latency per beat
        ST_OPONG_R0: begin
          // issue beat0
          bus_addr    <= to_bus_addr_from19(opong_byte_addr_base(opong_raddr_q) + 19'd0);
          bus_en      <= 1'b1;
          bus_wr_en   <= 1'b0;
          drive_bus   <= 1'b0;
          read_wait   <= 2'd2;
          state       <= ST_OPONG_W0;
        end
        ST_OPONG_W0: begin
          if (read_wait == 2'd0) begin
            read_assemble[63:0] <= bus_dinout;
            // issue beat1
            bus_addr    <= to_bus_addr_from19(opong_byte_addr_base(opong_raddr_q) + 19'd8);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            read_wait   <= 2'd2;
            state       <= ST_OPONG_R1;
          end
        end
        ST_OPONG_R1: begin
          if (read_wait == 2'd0) begin
            read_assemble[127:64] <= bus_dinout;
            // issue beat2
            bus_addr    <= to_bus_addr_from19(opong_byte_addr_base(opong_raddr_q) + 19'd16);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            read_wait   <= 2'd2;
            state       <= ST_OPONG_W2;
          end
        end
        ST_OPONG_W2: begin
          if (read_wait == 2'd0) begin
            read_assemble[191:128] <= bus_dinout;
            // issue beat3
            bus_addr    <= to_bus_addr_from19(opong_byte_addr_base(opong_raddr_q) + 19'd24);
            bus_en      <= 1'b1;
            bus_wr_en   <= 1'b0;
            drive_bus   <= 1'b0;
            read_wait   <= 2'd2;
            state       <= ST_OPONG_R3;
          end
        end
        ST_OPONG_R3: begin
          if (read_wait == 2'd0) begin
            read_assemble[255:192] <= bus_dinout;
            io_outputSramPong_readData <= read_assemble;
            io_outputSramPong_readValid <= 1'b1;
            state <= ST_IDLE;
          end
        end

        default: begin
          state <= ST_IDLE;
        end
      endcase
    end
  end

  assign busy = (state != ST_IDLE);
endmodule


