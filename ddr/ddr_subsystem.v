`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/08 19:45:12
// Design Name: 
// Module Name: ddr_bus_slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ddr_subsystem(
        input         clk_cpu_50,
        input         clk_mig_160,
        input         clk_ref_200,
        input         sys_rst_n,
        input         cpu_rst_n,
        input         mig_rst_n,

        input         ddr_request,
        input         ddr_re,
        input         ddr_we,

        input       [3:0]   ddr_wstrb,
        input       [31:0]  ddr_addr,  // 可以锁存addr
        input       [31:0]  ddr_wdata,
        output              ddr_ready,
        output      [31:0]  ddr_rdata,

        // ===========
        inout  [15:0] ddr3_dq,
        inout  [1:0]  ddr3_dqs_n,
        inout  [1:0]  ddr3_dqs_p,

        output [13:0] ddr3_addr,
        output [2:0]  ddr3_ba,
        output        ddr3_ras_n,
        output        ddr3_cas_n,
        output        ddr3_we_n,
        output        ddr3_reset_n,
        output [0:0]  ddr3_ck_p,
        output [0:0]  ddr3_ck_n,
        output [0:0]  ddr3_cke,
        output [0:0]  ddr3_cs_n,
        output [1:0]  ddr3_dm,
        output [0:0]  ddr3_odt
    );

    wire [31:0] ddr_offset;
    wire [27:0] mig_addr;

    assign ddr_offset = ddr_addr;

    assign mig_addr = (ddr_offset & 32'hFFFF_FFF0) >> 1;

    wire [127:0] mig_wdata;
    wire [15:0]  mig_wmask;
    wire [127:0] mig_rdata;

    // mig_transaction_engine var
    wire [27:0] app_addr;
    wire [2:0]  app_cmd;
    wire        app_en;

    wire [127:0] app_wdf_data;
    wire         app_wdf_end;
    wire [15:0]  app_wdf_mask;
    wire         app_wdf_wren;

    wire [127:0] app_rd_data;
    wire         app_rd_data_end;
    wire         app_rd_data_valid;
    wire         app_rdy;
    wire         app_wdf_rdy;

    wire         app_sr_active;
    wire         app_ref_ack;
    wire         app_zq_ack;

    wire         ui_clk;
    wire         ui_clk_sync_rst;
    wire         init_calib_complete;

    wire [11:0]  device_temp;

    // ddr_cdc_bridge var
    wire         req_ready;
    wire         rsp_done;
    wire [127:0] rsp_rdata;

    wire         req_valid;
    wire         req_write;
    wire [27:0]  req_addr;
    wire [127:0] req_wdata;
    wire [15:0]  req_wmask;

    wire ddr_req_valid;

    wire ddr_req_write;

    assign ddr_req_valid = ddr_request && (ddr_re || ddr_we);

    assign ddr_req_write = ddr_we;

    // ddr_system_rst
    wire ui_system_rst;

    wire ddr_logic_ui_rst;

    assign ddr_logic_ui_rst = ui_clk_sync_rst || ui_system_rst;

    // ============================================
    // ddr_system_rst instance
    // ============================================

    ddr_system_rst u_ddr_system_rst(
        .ui_clk(ui_clk),
        .rst_n(sys_rst_n),
        .ui_system_rst(ui_system_rst)
    );

    // ============================================
    // ddr_width_adapter instance
    // ============================================

    ddr_width_adapter u_ddr_width_adapter(
        .addr(ddr_addr),
        .wdata(ddr_wdata),
        .wstrb(ddr_wstrb),

        .mig_wdata(mig_wdata),
        .mig_wmask(mig_wmask),

        .mig_rdata(mig_rdata),
        .rdata(ddr_rdata)
    );

    // ============================================
    // ddr_cdc_bridge instance
    // ============================================

    ddr_cdc_bridge u_ddr_cdc_bridge(
        // CPU / simple_bus clock domain
        .cpu_clk(clk_cpu_50),
        .cpu_rstn(cpu_rst_n),

        .cpu_req(ddr_req_valid),
        .cpu_write(ddr_req_write),

        .cpu_addr(mig_addr),
        .cpu_wdata(mig_wdata),
        .cpu_wmask(mig_wmask),

        .bus_ready(ddr_ready),
        .bus_rdata(mig_rdata),

        // MIG ui_clk domain
        .ui_clk(ui_clk),
        .ui_rst(ddr_logic_ui_rst),       // ddr_logic_ui_rst

        .req_valid(req_valid),
        .req_write(req_write),
        .req_addr(req_addr),
        .req_wdata(req_wdata),
        .req_wmask(req_wmask),

        .req_ready(req_ready),

        // Response from mig_transaction_engine
        .rsp_done(rsp_done),
        .rsp_rdata(rsp_rdata)
    );

    // ============================================
    // mig_transaction_engine instance
    // ============================================

    mig_transaction_engine u_mig_transaction_engine(
        .ui_clk(ui_clk),
        .ui_clk_sync_rst(ddr_logic_ui_rst),
        .init_calib_complete(init_calib_complete),

        // 上层请求
        .req_valid(req_valid),
        .req_write(req_write),      // 1=write, 0=read
        .req_addr(req_addr),
        .req_wdata(req_wdata),
        .req_wmask(req_wmask),

        .req_ready(req_ready),

        // 上层响应
        .rsp_done(rsp_done),
        .rsp_rdata(rsp_rdata),

        // MIG Native UI
        .app_addr(app_addr),
        .app_cmd(app_cmd),
        .app_en(app_en),
        .app_rdy(app_rdy),

        .app_wdf_data(app_wdf_data),
        .app_wdf_end(app_wdf_end),
        .app_wdf_mask(app_wdf_mask),
        .app_wdf_wren(app_wdf_wren),
        .app_wdf_rdy(app_wdf_rdy),

        .app_rd_data(app_rd_data),
        .app_rd_data_valid(app_rd_data_valid),
        .app_rd_data_end(app_rd_data_end)
    );


    mig_ddr3 u_mig_ddr3 (
        // DDR3 physical interface
        .ddr3_dq               (ddr3_dq),
        .ddr3_dqs_n            (ddr3_dqs_n),
        .ddr3_dqs_p            (ddr3_dqs_p),

        .ddr3_addr             (ddr3_addr),
        .ddr3_ba               (ddr3_ba),
        .ddr3_ras_n            (ddr3_ras_n),
        .ddr3_cas_n            (ddr3_cas_n),
        .ddr3_we_n             (ddr3_we_n),
        .ddr3_reset_n          (ddr3_reset_n),
        .ddr3_ck_p             (ddr3_ck_p),
        .ddr3_ck_n             (ddr3_ck_n),
        .ddr3_cke              (ddr3_cke),
        .ddr3_cs_n             (ddr3_cs_n),
        .ddr3_dm               (ddr3_dm),
        .ddr3_odt              (ddr3_odt),

        // MIG clocks
        .sys_clk_i             (clk_mig_160),
        .clk_ref_i             (clk_ref_200),

        // Native UI - idle for now
        .app_addr              (app_addr),
        .app_cmd               (app_cmd),
        .app_en                (app_en),

        .app_wdf_data          (app_wdf_data),
        .app_wdf_end           (app_wdf_end),
        .app_wdf_mask          (app_wdf_mask), // 0写入，1屏蔽
        .app_wdf_wren          (app_wdf_wren),

        .app_rd_data           (app_rd_data),
        .app_rd_data_end       (app_rd_data_end),
        .app_rd_data_valid     (app_rd_data_valid),

        .app_rdy               (app_rdy),
        .app_wdf_rdy           (app_wdf_rdy),

        .app_sr_req            (1'b0),
        .app_ref_req           (1'b0),
        .app_zq_req            (1'b0),

        .app_sr_active         (app_sr_active),
        .app_ref_ack           (app_ref_ack),
        .app_zq_ack            (app_zq_ack),

        .ui_clk                (ui_clk),
        .ui_clk_sync_rst       (ui_clk_sync_rst),

        .init_calib_complete   (init_calib_complete),
        .device_temp           (device_temp),

        .sys_rst               (mig_rst_n)
    );
endmodule
