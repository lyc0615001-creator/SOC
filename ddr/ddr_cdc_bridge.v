// `default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/08 15:50:31
// Design Name: 
// Module Name: ddr_cdc_bridge
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


module ddr_cdc_bridge(

        // ============================================================
        // CPU / simple_bus clock domain
        // ============================================================
        input          cpu_clk,
        input          cpu_rstn,

        input          cpu_req,
        input          cpu_write,

        input  [27:0]  cpu_addr,
        input  [127:0] cpu_wdata,
        input  [15:0]  cpu_wmask,

        output             bus_ready,
        output reg [127:0] bus_rdata,

        // ============================================================
        // MIG ui_clk domain
        // ============================================================

        input              ui_clk,
        input              ui_rst,       // ui_clk_sync_rst

        output reg         req_valid,
        output reg         req_write,
        output reg [27:0]  req_addr,
        output reg [127:0] req_wdata,
        output reg [15:0]  req_wmask,

        input          req_ready,

        // Response from mig_transaction_engine
        input          rsp_done,
        input [127:0]  rsp_rdata
    );

    localparam [1:0] 
        BUS_IDLE       = 2'd0,
        BUS_WAIT       = 2'd1,
        BUS_RESP       = 2'd2;
    
    localparam 
        MIG_IDLE       = 1'd0,
        MIG_WAIT       = 1'd1;

    reg [1:0] bus_state;
    reg       mig_state;

    wire bus_fire;
    wire mig_fire;

    wire bus_busy;

    assign bus_fire = cpu_req && !bus_busy;

    assign mig_fire = rsp_done;

    // assign reg

    reg [27:0]  bus_addr;
    reg [127:0] bus_wdata;
    reg [15:0]  bus_wmask;
    reg         bus_write;
    
    reg         req_toggle;
    

    reg [127:0] rsp_data_hold;

    reg         rsp_toggle;

    // ============================================================
    // Synchronizers
    // ============================================================

    (* ASYNC_REG = "TRUE" *) reg req_sync1;
    (* ASYNC_REG = "TRUE" *) reg req_sync2;

    (* ASYNC_REG = "TRUE" *) reg rsp_sync1;
    (* ASYNC_REG = "TRUE" *) reg rsp_sync2;

    reg req_seen;
    reg rsp_seen;

    wire cpu_accept_fire;
    wire mig_recept_fire;

    assign cpu_accept_fire = rsp_sync2 != rsp_seen;

    assign mig_recept_fire = req_sync2 != req_seen && !req_valid;
    
    assign bus_busy = bus_state != BUS_IDLE; 

    assign bus_ready = bus_state == BUS_RESP;

    // cpu domain
    always @(posedge cpu_clk) begin
        if (!cpu_rstn) begin
            // IDLE½×¶Î
            bus_addr  <= 28'd0;
            bus_wdata <= 128'd0;
            bus_wmask <= 16'hffff;
            bus_write <= 1'b0;

            req_toggle <= 1'b0;

            bus_state <= BUS_IDLE;

            // WAIT½×¶Î
            rsp_sync1 <= 1'b0;
            rsp_sync2 <= 1'b0;

            rsp_seen <= 1'b0;

            bus_rdata <= 128'd0;
        end else begin
            rsp_sync1 <= rsp_toggle;
            rsp_sync2 <= rsp_sync1;
            case (bus_state)
                BUS_IDLE: begin
                    if (bus_fire) begin
                        // ÇÐ»»×´Ì¬+Ëø´æÊý¾Ý
                        bus_state <= BUS_WAIT;

                        bus_addr  <= cpu_addr;
                        bus_wdata <= cpu_wdata;
                        bus_wmask <= cpu_wmask;
                        bus_write <= cpu_write;
                        
                        req_toggle <= ~req_toggle;
                    end
                end
                BUS_WAIT: begin
                    if (cpu_accept_fire) begin
                        rsp_seen <= rsp_sync2;

                        bus_rdata <= rsp_data_hold;

                        bus_state <= BUS_RESP;
                    end
                end
                BUS_RESP: begin
                    if (cpu_req && bus_ready) begin
                        bus_state <= BUS_IDLE;
                    end
                end
                default: begin
                    bus_state <= BUS_IDLE;
                end
            endcase
        end
    end

    // ***********************************

    always @(posedge ui_clk) begin
        if (ui_rst) begin
            rsp_data_hold <= 128'd0;
            rsp_toggle <= 1'b0;

            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;

            req_seen <= 1'b0;
            req_valid <= 1'b0;

            req_write <= 1'b1;
            req_addr  <= 28'd0;
            req_wdata <= 128'd0;
            req_wmask <= 16'd0;

            mig_state <= MIG_IDLE;
        end else begin

            if (req_valid && req_ready) begin
                req_valid <= 1'b0;
            end

            req_sync1 <= req_toggle;
            req_sync2 <= req_sync1;

            case (mig_state)
                MIG_IDLE: begin
                    if (mig_recept_fire) begin
                        req_seen <= req_sync2;
                        
                        req_write <= bus_write;
                        req_addr  <= bus_addr;
                        req_wdata <= bus_wdata;
                        req_wmask <= bus_wmask;

                        req_valid <= 1'b1;

                        mig_state <= MIG_WAIT;
                    end
                end 
                MIG_WAIT: begin
                    if (mig_fire) begin
                        rsp_data_hold <= rsp_rdata;
                        
                        rsp_toggle <= ~rsp_toggle;

                        mig_state <= MIG_IDLE;
                    end
                end 
                default: begin
                    mig_state <= MIG_IDLE;
                end
            endcase
        end
    end

endmodule
