`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/18 13:11:01
// Design Name: 
// Module Name: LED_display
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

module LED_display(
        input clk,
        input rst,
        input display_status, // 1 写 0 正常 
        input [31:0] T_clk,
        input [31:0] display_data,
        output [7:0] seg,
        output [1:0] sel,
        output [3:0] led
    );

    wire  [3:0] seg10, seg1;
    reg [6:0] reg_display_data;

    wire led_clk_en;
    reg [1:0] display_type; // 00 normal 01 加载 10 空白

    cpu_clk_en u_cpu_clk_en(
        .clk(clk),
        .rst(rst),
        .T_clk(T_clk >> 3),
        .clk_en(led_clk_en)
    );

    reg [2:0] sw_phase;

    assign led = display_status ? 4'b0001 : 4'b0000;

    // 判断sw下 展示load还是data
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sw_phase <= 3'b0;
            display_type <= 2'b0; // 默认data
        end else begin
            if(led_clk_en) begin
                if (display_status == 1'b0 | display_status === 1'bx) begin
                    sw_phase <= 3'b0;
                    display_type <= 2'b0;
                end else if (sw_phase < 3'd6) begin
                    sw_phase <= sw_phase + 1'b1;
                    display_type <= sw_phase % 2 ? 2'b10 : 2'b01; // 偶数次为load
                end else begin
                    display_type <= 1'b0;
                    sw_phase <= sw_phase == 3'd7 ? 3'b0 : sw_phase;
                end
            end 
        end
    end

    // 展示数据
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_display_data <= 32'b0;
        end
        else begin
            if (led_clk_en) begin
                reg_display_data <= display_data[6:0];
            end
        end
    end
    assign seg10 = (reg_display_data / 10) % 10;
    assign seg1  = reg_display_data % 10;

    LED u_LED (.clk(clk), .rst(rst), .display_type(display_type), .seg10(seg10), .seg1(seg1), .seg(seg), .sel(sel));

endmodule

module LED (
        input clk,
        input rst,
        input [1:0] display_type,
        input [3:0] seg10,
        input [3:0] seg1,
        output reg [7:0] seg,
        output reg [1:0] sel
    );
    parameter T = 50000;
    // parameter T = 2;

    parameter load = 2'b01;
    parameter blank = 2'b10;

    reg [31:0] cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 32'd0;
            sel <= 2'b01;
            seg <= 8'd0;
        end else begin
            if (cnt == T - 1) begin
                cnt <= 32'd0;
                sel <= ~sel;
                if (display_type == load) begin
                    seg <= 8'b00010000;
                end else if (display_type == blank) begin
                    seg <= 8'b00000000;
                end else begin
                    case (sel == 2'b01 ? seg10 : seg1)
                        4'd0: seg <= 8'b11111100;
                        4'd1: seg <= 8'b01100000;
                        4'd2: seg <= 8'b11011010;
                        4'd3: seg <= 8'b11110010;
                        4'd4: seg <= 8'b01100110;
                        4'd5: seg <= 8'b10110110;
                        4'd6: seg <= 8'b10111110;
                        4'd7: seg <= 8'b11100000;
                        4'd8: seg <= 8'b11111110;
                        4'd9: seg <= 8'b11110110;
                        default: seg <= 8'b00000000;
                    endcase
                end
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
    
endmodule