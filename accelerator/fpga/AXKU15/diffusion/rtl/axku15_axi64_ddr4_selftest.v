// AXKU15 DDR4 transport self-test wrapper.
//
// The vendor ddr4_core module is supplied externally through the build Tcl.
// This wrapper neither modifies nor vendors the official demo/IP sources.
module axku15_axi64_ddr4_selftest (
    output                  c0_ddr4_act_n,
    output [16:0]           c0_ddr4_adr,
    output [1:0]            c0_ddr4_ba,
    output [0:0]            c0_ddr4_bg,
    output [0:0]            c0_ddr4_cke,
    output [0:0]            c0_ddr4_odt,
    output [0:0]            c0_ddr4_cs_n,
    output [0:0]            c0_ddr4_ck_t,
    output [0:0]            c0_ddr4_ck_c,
    output                  c0_ddr4_reset_n,
    inout  [7:0]            c0_ddr4_dm_dbi_n,
    inout  [63:0]           c0_ddr4_dq,
    inout  [7:0]            c0_ddr4_dqs_t,
    inout  [7:0]            c0_ddr4_dqs_c,
    input                   c0_sys_clk_p,
    input                   c0_sys_clk_n,
    input                   reset_n,
    output                  c0_alert_n,
    output [3:0]            led
);
    wire c0_init_calib_complete;
    wire c0_ddr4_ui_clk;
    wire c0_ddr4_ui_clk_sync_rst;
    wire c0_ddr4_aresetn;
    wire selftest_reset = c0_ddr4_ui_clk_sync_rst | ~c0_ddr4_aresetn;
    wire selftest_active;
    wire selftest_passed;
    wire selftest_failed;

    wire [3:0]  s_axi_awid;
    wire [31:0] s_axi_awaddr;
    wire [7:0]  s_axi_awlen;
    wire [2:0]  s_axi_awsize;
    wire        s_axi_awvalid;
    wire        s_axi_awready;
    wire [63:0] s_axi_wdata;
    wire [7:0]  s_axi_wstrb;
    wire        s_axi_wlast;
    wire        s_axi_wvalid;
    wire        s_axi_wready;
    wire [3:0]  s_axi_bid;
    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    wire        s_axi_bready;
    wire [3:0]  s_axi_arid;
    wire [31:0] s_axi_araddr;
    wire [7:0]  s_axi_arlen;
    wire [2:0]  s_axi_arsize;
    wire        s_axi_arvalid;
    wire        s_axi_arready;
    wire [3:0]  s_axi_rid;
    wire [63:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rlast;
    wire        s_axi_rvalid;
    wire        s_axi_rready;

    assign c0_alert_n = 1'b1;
    assign led[0] = c0_init_calib_complete;
    assign led[1] = selftest_active;
    assign led[2] = selftest_passed;
    assign led[3] = selftest_failed;

    Axi64DdrSelfTest u_selftest (
        .clock                   (c0_ddr4_ui_clk),
        .reset                   (selftest_reset),
        .io_calibrated           (c0_init_calib_complete),
        .io_axi_aw_ready         (s_axi_awready),
        .io_axi_aw_valid         (s_axi_awvalid),
        .io_axi_aw_bits_addr     (s_axi_awaddr),
        .io_axi_aw_bits_id       (s_axi_awid),
        .io_axi_aw_bits_len      (s_axi_awlen),
        .io_axi_aw_bits_size     (s_axi_awsize),
        .io_axi_w_ready          (s_axi_wready),
        .io_axi_w_valid          (s_axi_wvalid),
        .io_axi_w_bits_data      (s_axi_wdata),
        .io_axi_w_bits_strb      (s_axi_wstrb),
        .io_axi_w_bits_last      (s_axi_wlast),
        .io_axi_b_ready          (s_axi_bready),
        .io_axi_b_valid          (s_axi_bvalid),
        .io_axi_b_bits_id        (s_axi_bid),
        .io_axi_b_bits_resp      (s_axi_bresp),
        .io_axi_ar_ready         (s_axi_arready),
        .io_axi_ar_valid         (s_axi_arvalid),
        .io_axi_ar_bits_addr     (s_axi_araddr),
        .io_axi_ar_bits_id       (s_axi_arid),
        .io_axi_ar_bits_len      (s_axi_arlen),
        .io_axi_ar_bits_size     (s_axi_arsize),
        .io_axi_r_ready          (s_axi_rready),
        .io_axi_r_valid          (s_axi_rvalid),
        .io_axi_r_bits_data      (s_axi_rdata),
        .io_axi_r_bits_id        (s_axi_rid),
        .io_axi_r_bits_resp      (s_axi_rresp),
        .io_axi_r_bits_last      (s_axi_rlast),
        .io_active               (selftest_active),
        .io_passed               (selftest_passed),
        .io_failed               (selftest_failed)
    );

    ddr4_core u_ddr4_core (
        .sys_rst                     (~reset_n),
        .c0_sys_clk_p                (c0_sys_clk_p),
        .c0_sys_clk_n                (c0_sys_clk_n),
        .c0_init_calib_complete      (c0_init_calib_complete),
        .c0_ddr4_act_n               (c0_ddr4_act_n),
        .c0_ddr4_adr                 (c0_ddr4_adr),
        .c0_ddr4_ba                  (c0_ddr4_ba),
        .c0_ddr4_bg                  (c0_ddr4_bg),
        .c0_ddr4_cke                 (c0_ddr4_cke),
        .c0_ddr4_odt                 (c0_ddr4_odt),
        .c0_ddr4_cs_n                (c0_ddr4_cs_n),
        .c0_ddr4_ck_t                (c0_ddr4_ck_t),
        .c0_ddr4_ck_c                (c0_ddr4_ck_c),
        .c0_ddr4_reset_n             (c0_ddr4_reset_n),
        .c0_ddr4_dm_dbi_n            (c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq                  (c0_ddr4_dq),
        .c0_ddr4_dqs_c               (c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t               (c0_ddr4_dqs_t),
        .c0_ddr4_ui_clk              (c0_ddr4_ui_clk),
        .c0_ddr4_ui_clk_sync_rst     (c0_ddr4_ui_clk_sync_rst),
        .dbg_clk                     (),
        .c0_ddr4_aresetn             (c0_ddr4_aresetn),
        .c0_ddr4_s_axi_awid          (s_axi_awid),
        .c0_ddr4_s_axi_awaddr        (s_axi_awaddr),
        .c0_ddr4_s_axi_awlen         (s_axi_awlen),
        .c0_ddr4_s_axi_awsize        (s_axi_awsize),
        .c0_ddr4_s_axi_awburst       (2'b01),
        .c0_ddr4_s_axi_awlock        (1'b0),
        .c0_ddr4_s_axi_awcache       (4'b0),
        .c0_ddr4_s_axi_awprot        (3'b0),
        .c0_ddr4_s_axi_awqos         (4'b0),
        .c0_ddr4_s_axi_awvalid       (s_axi_awvalid),
        .c0_ddr4_s_axi_awready       (s_axi_awready),
        .c0_ddr4_s_axi_wdata         (s_axi_wdata),
        .c0_ddr4_s_axi_wstrb         (s_axi_wstrb),
        .c0_ddr4_s_axi_wlast         (s_axi_wlast),
        .c0_ddr4_s_axi_wvalid        (s_axi_wvalid),
        .c0_ddr4_s_axi_wready        (s_axi_wready),
        .c0_ddr4_s_axi_bid           (s_axi_bid),
        .c0_ddr4_s_axi_bresp         (s_axi_bresp),
        .c0_ddr4_s_axi_bvalid        (s_axi_bvalid),
        .c0_ddr4_s_axi_bready        (s_axi_bready),
        .c0_ddr4_s_axi_arid          (s_axi_arid),
        .c0_ddr4_s_axi_araddr        (s_axi_araddr),
        .c0_ddr4_s_axi_arlen         (s_axi_arlen),
        .c0_ddr4_s_axi_arsize        (s_axi_arsize),
        .c0_ddr4_s_axi_arburst       (2'b01),
        .c0_ddr4_s_axi_arlock        (1'b0),
        .c0_ddr4_s_axi_arcache       (4'b0),
        .c0_ddr4_s_axi_arprot        (3'b0),
        .c0_ddr4_s_axi_arqos         (4'b0),
        .c0_ddr4_s_axi_arvalid       (s_axi_arvalid),
        .c0_ddr4_s_axi_arready       (s_axi_arready),
        .c0_ddr4_s_axi_rid           (s_axi_rid),
        .c0_ddr4_s_axi_rdata         (s_axi_rdata),
        .c0_ddr4_s_axi_rresp         (s_axi_rresp),
        .c0_ddr4_s_axi_rlast         (s_axi_rlast),
        .c0_ddr4_s_axi_rvalid        (s_axi_rvalid),
        .c0_ddr4_s_axi_rready        (s_axi_rready),
        .dbg_bus                     ()
    );
endmodule
