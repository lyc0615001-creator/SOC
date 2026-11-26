`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/08 14:28:00
// Design Name: 
// Module Name: ddr_width_adapter
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


module ddr_width_adapter (
    input  wire [31:0]  addr,
    input  wire [31:0]  wdata,
    input  wire [3:0]   wstrb,

    output reg  [127:0] buf_wdata,
    output      [15:0]  buf_wmask,

    input  wire [127:0] buf_rdata,
    output reg  [31:0]  rdata
);

    reg [15:0] expanded_wstrb;

    always @(*) begin
        buf_wdata = 128'd0;
        expanded_wstrb = 16'd0;

        case (addr[3:2])
            2'b00: begin
                buf_wdata[31:0]   = wdata;

                expanded_wstrb[3:0] = wstrb; 
            end 
            2'b01: begin
                buf_wdata[63:32]  = wdata;

                expanded_wstrb[7:4] = wstrb; 
            end 
            2'b10: begin
                buf_wdata[95:64]  = wdata;

                expanded_wstrb[11:8] = wstrb; 
            end 
            2'b11: begin
                buf_wdata[127:96] = wdata;

                expanded_wstrb[15:12] = wstrb; 
            end 
            default: begin
                buf_wdata = 128'd0;
                expanded_wstrb = 16'd0;
            end 
        endcase
    end
    always @(*) begin
        rdata = 32'd0;

        case (addr[3:2])
            2'b00: begin
                rdata = buf_rdata[31:0];
            end 
            2'b01: begin
                rdata = buf_rdata[63:32];
            end 
            2'b10: begin
                rdata = buf_rdata[95:64];
            end 
            2'b11: begin
                rdata = buf_rdata[127:96];
            end 
            default: begin
                rdata = 32'd0;
            end 
        endcase
    end

    assign buf_wmask = ~expanded_wstrb;

endmodule