`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/23 15:36:46
// Design Name: 
// Module Name: bram_ram
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


module bram_ram #(parameter ADDR_WIDTH = 10)(
        input             clk,
        input             rst,
        input             ram_request,
        input             ram_re,
        input             ram_we,
        input     [3:0]   ram_wstrb,
        input     [31:0]  ram_addr,
        input     [31:0]  ram_wdata,
        output            ram_ready,
        output    [31:0]  ram_rdata
    );

    reg [31:0] ram [0: ((1 << ADDR_WIDTH) - 1)];

    localparam IDLE = 1'b0;
    localparam RESP = 1'b1;

    reg state;
    reg [31:0] ram_rdata_reg;
      
    wire re_ram;    
    wire we_ram;


    assign re_ram = ram_request && ram_re;
    assign we_ram = ram_request && ram_we;

    wire ram_re_fire;

    wire ram_we_fire;  

    assign ram_re_fire = re_ram && state == IDLE;

    assign ram_we_fire = we_ram && ram_ready;

    assign ram_ready = (state == RESP);

    assign ram_rdata = ram_rdata_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (ram_request) begin
                        state <= RESP;
                    end
                end            
                RESP: begin
                    if (ram_request) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (ram_re_fire) begin
            ram_rdata_reg <= ram[ram_addr];
        end else if (ram_we_fire) begin
            if (ram_wstrb[0]) begin
                ram[ram_addr][7:0] <= ram_wdata[7:0];
            end
            if (ram_wstrb[1]) begin
                ram[ram_addr][15:8] <= ram_wdata[15:8];
            end
            if (ram_wstrb[2]) begin
                ram[ram_addr][23:16] <= ram_wdata[23:16];
            end
            if (ram_wstrb[3]) begin
                ram[ram_addr][31:24] <= ram_wdata[31:24];
            end
        end
    end

    // initial begin
    //     ram[0] = 32'h11223344;
    //     ram[1] = 32'h55667788;
    // end
endmodule
