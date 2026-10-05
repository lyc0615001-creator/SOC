`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/30 13:27:32
// Design Name: 
// Module Name: cp0
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


module cp0(
        input              clk,
        input              rst,
        input              cpu_en,

        input              interrupt_accept,
        input              eret,
        input      [31:0]  epc_i,
        output     [31:0]  epc_o,
        output     [31:0]  cp0_status,

        input              cp0_we,
        input      [4:0]   cp0_addr,
        input      [31:0]  cp0_wdata,

        output     [31:0]  cp0_rdata
    );

    reg [31:0] count;
    reg [31:0] compare;
    reg [31:0] status;
    reg [31:0] cause;
    reg [31:0] epc;

    // status[0] = IE
    // status[1] = EXL

    assign epc_o = epc;
    assign cp0_status = status;
    assign cp0_rdata = (cp0_addr == 5'd9) ? count : 
                       (cp0_addr == 5'd11) ? compare : 
                       (cp0_addr == 5'd12) ? status : 
                       (cp0_addr == 5'd13) ? cause : 
                       (cp0_addr == 5'd14) ? epc : 
                       32'd0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cause <= 32'd0;
            epc <= 32'd0;
            status <= 32'd1;
        end else begin
            if (cpu_en) begin
                if (interrupt_accept) begin
                    status[1] <= 1'b1;
                    epc <= epc_i;
                    cause[3:0] <= 4'b0001;
                end else if (eret) begin
                    status[1] <= 1'b0;
                end else if (cp0_we) begin
                    case (cp0_addr)
                        5'd9: count<= cp0_wdata;
                        5'd11: compare<= cp0_wdata;
                        5'd12: status<= cp0_wdata;
                        5'd13: cause<= cp0_wdata;
                        5'd14: epc<= cp0_wdata;
                        default: ;
                    endcase
                end
            end
        end 
    end
endmodule
