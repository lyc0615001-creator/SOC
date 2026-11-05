`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/05 13:35:35
// Design Name: 
// Module Name: slow_slave
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


module slow_slave(
        input            clk,
        input            rst,
        input            req,
        input            read,
        input            write,
        input    [3:0]   wstrb,
        input    [7:0]   addr,
        input    [31:0]  wdata,


        output reg [31:0] rdata,
        output reg        ready
    );

    // 0x1000_5000 ~ 0x1000_50FF

    localparam ADDR_DATA = 8'h00;

    reg        busy;
    reg [1:0]  wait_cnt;

    reg        req_read;
    reg        req_write;
    reg [7:0]  req_addr;
    reg [31:0] req_wdata;
    reg [3:0]  req_wstrb;

    reg [31:0] data_reg;

    wire re_data;
    wire we_data;

    assign re_data = req_read && req_addr == ADDR_DATA;
    assign we_data = req_write && req_addr == ADDR_DATA;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            req_read  <= 1'b0;
            req_write <= 1'b0;
            req_addr  <= 8'd0;
            req_wdata <= 32'd0;
            req_wstrb <= 4'd0;
            data_reg  <= 32'd0;
            busy      <= 1'b0;
        end else begin
            ready <= 1'b0;
            if (!busy) begin
                if (req) begin
                    busy      <= 1'b1;
                    wait_cnt  <= 2'b00;

                    req_read  <= read;
                    req_write <= write;
                    req_addr  <= addr;
                    req_wdata <= wdata;
                    req_wstrb <= wstrb;
                end
            end else if (!ready) begin
                if (wait_cnt == 2'b10) begin
                    wait_cnt <= 1'b0;

                    ready <= 1'b1;
                    if (re_data) begin
                        rdata <= data_reg;
                    end 
                    if (we_data) begin
                        if (req_wstrb[0]) begin
                            data_reg[7:0] <= req_wdata[7:0];
                        end
                        if (req_wstrb[1]) begin
                            data_reg[15:8] <= req_wdata[15:8];
                        end
                        if (req_wstrb[2]) begin
                            data_reg[23:16] <= req_wdata[23:16];
                        end
                        if (req_wstrb[3]) begin
                            data_reg[31:24] <= req_wdata[31:24];
                        end
                    end
                end else begin
                    wait_cnt <= wait_cnt + 1'b1;
                end
            end else if (req) begin
                busy <= 1'b0;
            end
        end
    end
endmodule
