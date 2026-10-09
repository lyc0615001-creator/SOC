`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/08 14:43:45
// Design Name: 
// Module Name: mig_transaction_engine
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


module mig_transaction_engine(
        input  wire         ui_clk,
        input  wire         ui_clk_sync_rst,
        input  wire         init_calib_complete,

        // 上层请求
        input  wire         req_valid,
        input  wire         req_write,      // 1=write, 0=read
        input  wire [27:0]  req_addr,
        input  wire [127:0] req_wdata,
        input  wire [15:0]  req_wmask,

        output wire         req_ready,

        // 上层响应
        output reg          rsp_done,
        output reg  [127:0] rsp_rdata,

        // MIG Native UI
        output reg  [27:0]  app_addr,
        output reg  [2:0]   app_cmd,
        output reg          app_en,
        input  wire         app_rdy,

        output reg  [127:0] app_wdf_data,
        output reg          app_wdf_end,
        output reg  [15:0]  app_wdf_mask,
        output reg          app_wdf_wren,
        input  wire         app_wdf_rdy,

        input  wire [127:0] app_rd_data,
        input  wire         app_rd_data_valid,
        input  wire         app_rd_data_end
    );

    localparam [2:0] 
        IDLE       = 3'd0,
        WRITE_DATA = 3'd1,
        WRITE_CMD  = 3'd2,
        READ_CMD   = 3'd3,
        READ_WAIT  = 3'd4,
        DONE       = 3'd5;

    reg [2:0] state;

    reg [27:0]  addr_reg;
    reg [127:0] wdata_reg;
    reg [15:0]  wmask_reg;
    reg         write_reg;

    wire req_fire;

    assign req_ready = (state == IDLE) && init_calib_complete;

    assign req_fire = req_valid && req_ready;

    wire app_cmd_fire;
    wire app_data_fire;

    assign app_cmd_fire = app_en && app_rdy;
    assign app_data_fire = app_wdf_wren && app_wdf_rdy;

    always @(posedge ui_clk) begin
        if (ui_clk_sync_rst) begin
            state <= IDLE;

            rsp_rdata <= 128'd0;
            rsp_done <= 1'b0;

            addr_reg   <= 28'd0;
            wdata_reg  <= 128'd0;
            wmask_reg  <= 16'd0;
            write_reg  <= 1'd0;
        end else begin
            rsp_done <= 1'b0;
            case (state)
                IDLE: begin
                    if (req_fire) begin
                        addr_reg   <= req_addr;
                        wdata_reg  <= req_wdata;
                        wmask_reg  <= req_wmask;
                        write_reg  <= req_write;

                        if (req_write) begin
                            state <= WRITE_DATA;
                        end else begin
                            state <= READ_CMD;
                        end
                    end
                    
                end
                WRITE_DATA: begin
                    if (app_data_fire) begin
                        state <= WRITE_CMD;
                    end
                end
                WRITE_CMD: begin
                    if (app_cmd_fire) begin
                        state <= DONE;
                    end
                end
                READ_CMD: begin
                    if (app_cmd_fire) begin
                        state <= READ_WAIT;
                    end
                end
                READ_WAIT: begin
                    if (app_rd_data_valid) begin
                        rsp_rdata <= app_rd_data;
                        state     <= DONE;
                    end
                end
                DONE: begin
                    rsp_done <= 1'b1;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        app_addr = addr_reg;
        app_cmd = 3'b000;
        app_en = 1'b0;

        app_wdf_data = wdata_reg;
        app_wdf_end = 1'b0;
        app_wdf_mask = 16'h0000;
        app_wdf_wren = 1'b0;
        case (state)
            WRITE_CMD: begin
                app_addr = addr_reg;
                app_cmd = 3'b000;
                app_en = 1'b1;
            end
            WRITE_DATA: begin
                app_wdf_data = wdata_reg;
                app_wdf_end = 1'b1;
                app_wdf_mask = wmask_reg;
                app_wdf_wren = 1'b1;
            end
            READ_CMD: begin
                app_addr = addr_reg;
                app_cmd = 3'b001;
                app_en = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
