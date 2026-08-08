module MacMachine_top (
    // Config Bus interface (directly from MacMachineWrapper)
    input wire [31:0]  io_configBus_data,   // Config data input
    input wire [31:0]  io_configBus_addr,   // Config address input
    input wire         io_configBus_en,     // Config enable input

    // Slave 2 Input SRAM 0 interface (SRAM inside MacMachine, connect to internal BRAM)
    // BRAM Interface - Pseudo dual-port (connect to internal RAM)
    // Write port
    input  wire [10:0]  input_sram0_bram_w_addr,   // Write address (11-bit for 64KB)
    input  wire [255:0] input_sram0_bram_w_din,    // Write data
    input  wire         input_sram0_bram_w_en,     // Write enable
    input  wire [31:0]  input_sram0_bram_w_we,     // Write byte enable
    // Read port
    input  wire [10:0]  input_sram0_bram_r_addr,   // Read address (11-bit for 64KB)
    output wire [255:0] input_sram0_bram_r_dout,   // Read data
    input  wire         input_sram0_bram_r_en,     // Read enable


    // Slave 3 Weight SRAM 0 control interface (to external SRAM)
    input  wire         weight_sram0_enable,        // Enable signal from switch
    // BRAM Interface - Pseudo dual-port
    // Write port
    output wire [10:0]  weight_sram0_bram_w_addr,   // Write address (11-bit for 64KB)
    output wire [255:0] weight_sram0_bram_w_din,    // Write data
    output wire         weight_sram0_bram_w_en,     // Write enable
    output wire [31:0]  weight_sram0_bram_w_we,     // Write byte enable
    // Read port
    output wire [10:0]  weight_sram0_bram_r_addr,   // Read address (11-bit for 64KB)
    input  wire [255:0] weight_sram0_bram_r_dout,   // Read data
    output wire         weight_sram0_bram_r_en,     // Read enable

    // Slave 3 Weight SRAM 1 control interface (to external SRAM)
    input  wire         weight_sram1_enable,        // Enable signal from switch
    // BRAM Interface - Pseudo dual-port
    // Write port
    output wire [10:0]  weight_sram1_bram_w_addr,   // Write address (11-bit for 64KB)
    output wire [255:0] weight_sram1_bram_w_din,    // Write data
    output wire         weight_sram1_bram_w_en,     // Write enable
    output wire [31:0]  weight_sram1_bram_w_we,     // Write byte enable
    // Read port
    output wire [10:0]  weight_sram1_bram_r_addr,   // Read address (11-bit for 64KB)
    input  wire [255:0] weight_sram1_bram_r_dout,   // Read data
    output wire         weight_sram1_bram_r_en,     // Read enable

    // Slave 4 Output SRAM 0 control interface (to external SRAM)
    input  wire         output_sram0_enable,        // Enable signal from switch
    // BRAM Interface - Pseudo dual-port
    // Write port
    output wire [10:0]  output_sram0_bram_w_addr,   // Write address (11-bit for 64KB)
    output wire [511:0] output_sram0_bram_w_din,    // Write data (512-bit)
    output wire         output_sram0_bram_w_en,     // Write enable
    output wire [63:0]  output_sram0_bram_w_we,     // Write byte enable (64-bit)
    // Read port
    output wire [10:0]  output_sram0_bram_r_addr,   // Read address (11-bit for 64KB)
    input  wire [511:0] output_sram0_bram_r_dout,   // Read data (512-bit)
    output wire         output_sram0_bram_r_en,     // Read enable


    // Slave 4 Output SRAM 1 control interface (to external SRAM)
    input  wire         output_sram1_enable,        // Enable signal from switch
    // BRAM Interface - Pseudo dual-port
    // Write port
    output wire [10:0]  output_sram1_bram_w_addr,   // Write address (11-bit for 64KB)
    output wire [511:0] output_sram1_bram_w_din,    // Write data (512-bit)
    output wire         output_sram1_bram_w_en,     // Write enable
    output wire [63:0]  output_sram1_bram_w_we,     // Write byte enable (64-bit)
    // Read port
    output wire [10:0]  output_sram1_bram_r_addr,   // Read address (11-bit for 64KB)
    input  wire [511:0] output_sram1_bram_r_dout,   // Read data (512-bit)
    output wire         output_sram1_bram_r_en,     // Read enable

    output wire         macMachineDone_interrupt, //接到中断去
    output wire         macMachineerror_interrupt, //接到中断

    // System signals
    input  wire         clk,             // System clock
    input  wire         rst_n            // System reset (active low)
);
// Note: All BRAM interfaces use the system clk and rst_n


// ==================== 内部Joint SRAM信号定义 ====================
wire         joint_sram0_w_en, joint_sram0_r_en;
wire [9:0]   joint_sram0_w_addr, joint_sram0_r_addr;
wire [511:0] joint_sram0_w_din, joint_sram0_r_dout;
wire         joint_sram1_w_en, joint_sram1_r_en;
wire [9:0]   joint_sram1_w_addr, joint_sram1_r_addr;
wire [511:0] joint_sram1_w_din, joint_sram1_r_dout;
// Internal 21-bit addresses from MacMachineWrapper to weight SRAMs
wire [20:0]  weight_sram0_read_addr_21;
wire [20:0]  weight_sram1_read_addr_21;

// Internal 11-bit addresses and 512-bit data for output SRAMs
wire [10:0]  output_sram0_write_addr_11, output_sram0_read_addr_11;
wire [10:0]  output_sram1_write_addr_11, output_sram1_read_addr_11;
wire [511:0] output_sram0_write_data_512, output_sram0_read_data_512;
wire [511:0] output_sram1_write_data_512, output_sram1_read_data_512;

// Internal 11-bit addresses and 512-bit data for joint SRAMs
wire [10:0]  joint_sram0_write_addr_11, joint_sram0_read_addr_11;
wire [10:0]  joint_sram1_write_addr_11, joint_sram1_read_addr_11;
wire [511:0] joint_sram0_write_data_512, joint_sram0_read_data_512;
wire [511:0] joint_sram1_write_data_512, joint_sram1_read_data_512;

// ==================== BRAM Write Enable assignments ====================
// Output SRAMs use 512-bit, Weight SRAMs use 256-bit
assign output_sram0_bram_w_we = output_sram0_bram_w_en ? 64'hFFFFFFFFFFFFFFFF : 64'h0; // 512-bit write
assign output_sram1_bram_w_we = output_sram1_bram_w_en ? 64'hFFFFFFFFFFFFFFFF : 64'h0; // 512-bit write
assign weight_sram0_bram_w_we = weight_sram0_bram_w_en ? 32'hFFFFFFFF : 32'h0; // 256-bit write
assign weight_sram1_bram_w_we = weight_sram1_bram_w_en ? 32'hFFFFFFFF : 32'h0; // 256-bit write

// ==================== Address and Data Conversion ====================
// Direct 11-bit address connection (no conversion needed)
assign output_sram0_bram_w_addr = output_sram0_write_addr_11;  // 11-bit direct
assign output_sram0_bram_r_addr = output_sram0_read_addr_11;   // 11-bit direct
assign output_sram1_bram_w_addr = output_sram1_write_addr_11;  // 11-bit direct
assign output_sram1_bram_r_addr = output_sram1_read_addr_11;   // 11-bit direct

// Convert 21-bit weight addresses to 11-bit BRAM addresses (divide by 1K)
assign weight_sram0_bram_r_addr = weight_sram0_read_addr_21;  // 21-bit to 11-bit
assign weight_sram1_bram_r_addr = weight_sram1_read_addr_21;  // 21-bit to 11-bit

// Convert 11-bit joint addresses to 10-bit BRAM addresses (divide by 2) for 512-bit BRAM
assign joint_sram0_w_addr = joint_sram0_write_addr_11;  // 11-bit to 10-bit
assign joint_sram0_r_addr = joint_sram0_read_addr_11;   // 11-bit to 10-bit
assign joint_sram1_w_addr = joint_sram1_write_addr_11;  // 11-bit to 10-bit
assign joint_sram1_r_addr = joint_sram1_read_addr_11;   // 11-bit to 10-bit

// Direct 512-bit data connection for output SRAMs
assign output_sram0_bram_w_din = output_sram0_write_data_512; // 512-bit direct
assign output_sram1_bram_w_din = output_sram1_write_data_512; // 512-bit direct
assign output_sram0_read_data_512 = output_sram0_bram_r_dout; // 512-bit direct
assign output_sram1_read_data_512 = output_sram1_bram_r_dout; // 512-bit direct

// Direct 512-bit data connection for joint SRAMs
assign joint_sram0_w_din = joint_sram0_write_data_512; // 512-bit direct
assign joint_sram1_w_din = joint_sram1_write_data_512; // 512-bit direct
assign joint_sram0_read_data_512 = joint_sram0_r_dout; // 512-bit direct
assign joint_sram1_read_data_512 = joint_sram1_r_dout; // 512-bit direct

// ==================== BRAM Default Value assignments ====================
// Set default values for unused output ports to avoid high-Z state
assign weight_sram0_bram_w_addr = 11'h0;      // Default write address (11-bit)
assign weight_sram0_bram_w_din = 256'h0;      // Default write data (256-bit)
assign weight_sram0_bram_w_en = 1'b0;         // Default write enable (disabled)

assign weight_sram1_bram_w_addr = 11'h0;      // Default write address (11-bit)
assign weight_sram1_bram_w_din = 256'h0;      // Default write data (256-bit)
assign weight_sram1_bram_w_en = 1'b0;         // Default write enable (disabled)


// // Config Bus signals directly from MacMachineWrapper
// wire [31:0] config_data_out;   // Data from MacMachineWrapper to config bus
// wire [31:0] config_addr_out;   // Address from MacMachineWrapper to config bus
// wire        config_en_out;     // Enable from MacMachineWrapper to config bus

// // Connect Config Bus signals to module outputs
// assign io_configBus_data = config_data_out;
// assign io_configBus_addr = config_addr_out;
// assign io_configBus_en = config_en_out;


// ==================== MacMachineWrapper实例化 ====================

MacMachineWrapper u_mac_machine_wrapper(
    .clock(clk),
    .reset(~rst_n),

    // Config Bus interface (direct output)
    .io_configBus_data(io_configBus_data),          // Output: Config data to external
    .io_configBus_addr(io_configBus_addr),          // Output: Config address to external
    .io_configBus_en(io_configBus_en),               // Output: Config enable to external

    // Feature Map Bus (connect to internal input SRAM write port) - 256-bit
    .io_featureMapBus_data(input_sram0_bram_w_din),    // Write data to internal input SRAM (256-bit)
    .io_featureMapBus_addr({2'b0, input_sram0_bram_w_addr}), // Write address (13-bit, extend 11-bit to 13-bit)
    .io_featureMapBus_en(input_sram0_bram_w_en),        // Write enable to internal input SRAM

    // Weight SRAM Read Ping (connect to weight_sram0) - 256-bit
    .io_weightSramReadPing_readEnable(weight_sram0_bram_r_en),        // Read enable
    .io_weightSramReadPing_readAddress(weight_sram0_read_addr_21), // 21-bit address from wrapper
    .io_weightSramReadPing_readData(weight_sram0_bram_r_dout),        // Read data (256-bit)

    // Weight SRAM Read Pong (connect to weight_sram1) - 256-bit
    .io_weightSramReadPong_readEnable(weight_sram1_bram_r_en),        // Read enable
    .io_weightSramReadPong_readAddress(weight_sram1_read_addr_21), // 21-bit address from wrapper
    .io_weightSramReadPong_readData(weight_sram1_bram_r_dout),        // Read data (256-bit)

    // Output SRAM Ping (connect to output_sram0) - 512-bit
    .io_outputSramPing_writeEnable(output_sram0_bram_w_en),           // Write enable
    .io_outputSramPing_writeAddress(output_sram0_write_addr_11),      // Write address (11-bit)
    .io_outputSramPing_writeData(output_sram0_write_data_512),        // Write data (512-bit)
    .io_outputSramPing_readEnable(output_sram0_bram_r_en),            // Read enable
    .io_outputSramPing_readAddress(output_sram0_read_addr_11),        // Read address (11-bit)
    .io_outputSramPing_readData(output_sram0_read_data_512),          // Read data (512-bit)

    // Output SRAM Pong (connect to output_sram1) - 512-bit
    .io_outputSramPong_writeEnable(output_sram1_bram_w_en),           // Write enable
    .io_outputSramPong_writeAddress(output_sram1_write_addr_11),      // Write address (11-bit)
    .io_outputSramPong_writeData(output_sram1_write_data_512),        // Write data (512-bit)
    .io_outputSramPong_readEnable(output_sram1_bram_r_en),            // Read enable
    .io_outputSramPong_readAddress(output_sram1_read_addr_11),        // Read address (11-bit)
    .io_outputSramPong_readData(output_sram1_read_data_512),          // Read data (512-bit)

    // Output Joint SRAM (connect to internal joint_sram0) - 512-bit
    .io_outputJointSram_writeEnable(joint_sram0_w_en),                // Write enable
    .io_outputJointSram_writeAddress(joint_sram0_write_addr_11),      // Write address (11-bit)
    .io_outputJointSram_writeData(joint_sram0_write_data_512),        // Write data (512-bit)
    .io_outputJointSram_readEnable(joint_sram0_r_en),                 // Read enable
    .io_outputJointSram_readAddress(joint_sram0_read_addr_11),        // Read address (11-bit)
    .io_outputJointSram_readData(joint_sram0_read_data_512),          // Read data (512-bit)

    // Joint SRAM (connect to internal joint_sram1) - 512-bit
    .io_jointSram_writeEnable(joint_sram1_w_en),                      // Write enable
    .io_jointSram_writeAddress(joint_sram1_write_addr_11),            // Write address (11-bit)
    .io_jointSram_writeData(joint_sram1_write_data_512),              // Write data (512-bit)
    .io_jointSram_readEnable(joint_sram1_r_en),                       // Read enable
    .io_jointSram_readAddress(joint_sram1_read_addr_11),              // Read address (11-bit)
    .io_jointSram_readData(joint_sram1_read_data_512),                // Read data (512-bit)

    // Interrupts
    .io_interrupts_doneInterrupt(macMachineDone_interrupt),
    .io_interrupts_errorInterrupt(macMachineerror_interrupt)
);

// Address conversion is now handled above in the conversion section

// ==================== 内部Joint SRAM实例化 ====================
// Joint SRAM 0 (for Output Joint operations)
e203_bram_64k_512b u_joint_sram0 (
    .clk        (clk),                          // System clock
    .rst_n      (rst_n),                        // System reset
    // Write port
    .w_addr     (joint_sram0_w_addr),           // Write address (10-bit)
    .w_din      (joint_sram0_w_din),            // Write data (512-bit)
    .w_en       (joint_sram0_w_en),             // Write enable
    .w_we       (joint_sram0_w_en ? 64'hFFFFFFFFFFFFFFFF : 64'h0), // Write byte enable (full 512-bit write)
    // Read port
    .r_addr     (joint_sram0_r_addr),           // Read address (10-bit)
    .r_dout     (joint_sram0_r_dout),           // Read data (512-bit)
    .r_en       (joint_sram0_r_en)              // Read enable
);

// Joint SRAM 1 (for Joint operations)
e203_bram_64k_512b u_joint_sram1 (
    .clk        (clk),                          // System clock
    .rst_n      (rst_n),                        // System reset
    // Write port
    .w_addr     (joint_sram1_w_addr),           // Write address (10-bit)
    .w_din      (joint_sram1_w_din),            // Write data (512-bit)
    .w_en       (joint_sram1_w_en),             // Write enable
    .w_we       (joint_sram1_w_en ? 64'hFFFFFFFFFFFFFFFF : 64'h0), // Write byte enable (full 512-bit write)
    // Read port
    .r_addr     (joint_sram1_r_addr),           // Read address (10-bit)
    .r_dout     (joint_sram1_r_dout),           // Read data (512-bit)
    .r_en       (joint_sram1_r_en)              // Read enable
);

// Note: MacMachineWrapper is an external module definition
// The actual MacMachine_top module ends here

endmodule
