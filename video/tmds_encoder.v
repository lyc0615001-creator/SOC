`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 13:20:04
// Design Name: 
// Module Name: tmds_encoder
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


module tmds_encoder(
        input  wire        pixel_clk,
        input  wire        rst_n,

        input  wire        de,

        input  wire [7:0]  data,
        input  wire [1:0]  ctrl,

        output reg [9:0]   tmds
    );

    // 第一阶段：生成[8:0] q_m
    reg [3:0] count_one;
    integer i;

    always @(*) begin
        count_one = 4'd0;

        for (i = 0; i < 8; i = i + 1) begin
            count_one = count_one + data[i];
        end
    end

    wire choose_xnor;
    assign choose_xnor = (count_one > 4) || (count_one == 4 && data[0] == 0); // xnor
    
    reg [8:0] q_m;
    integer j;
    always @(*) begin
        q_m[0] = data[0];
        for (j = 1; j < 8; j = j + 1) begin
            q_m[j] = choose_xnor ? (q_m[j - 1] ~^ data[j]) : (q_m[j - 1] ^ data[j]);
        end
        q_m[8] = ~choose_xnor; // 1-xor 0-xnor
    end

    // 第二阶段：DC balance 生成[9:0] tmds
    reg [3:0] qm_count_one;
    integer k;

    always @(*) begin
        qm_count_one = 4'd0;

        for (k = 0; k < 8; k = k + 1) begin
            qm_count_one = qm_count_one + q_m[k];
        end
    end

    reg  signed [4:0] running_disparity; // 历史
    wire signed [4:0] balance; // 当前
    assign balance = 2 * qm_count_one - 8;
    // 状态判断
    wire normal;
    wire flip;
    
    
    assign normal = running_disparity == 0 || balance == 0;
    assign flip = (running_disparity > 0 && balance > 0) || (running_disparity < 0 && balance < 0);
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            running_disparity <= 0;
            tmds <= 0;
        end else begin
            if (!de) begin
                running_disparity <= 0;
                case (ctrl)
                    2'b00:  tmds <= 10'b1101010100;
                    2'b01:  tmds <= 10'b0010101011;
                    2'b10:  tmds <= 10'b0101010100;
                    2'b11:  tmds <= 10'b1010101011;
                    default: tmds <= 10'd0;
                endcase
            end else begin
                if (normal) begin
                    tmds[9:8] <= {~q_m[8], q_m[8]};
                    tmds[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];

                    running_disparity <= q_m[8] ? (running_disparity + balance) :  (running_disparity - balance);
                end else if (flip) begin
                    tmds[9]   <= 1'b1;
                    tmds[8]   <= q_m[8];
                    tmds[7:0] <= ~q_m[7:0];

                    running_disparity <= running_disparity - balance + (q_m[8] ? 2 : 0);
                end else begin
                    tmds[9]   <= 1'b0;
                    tmds[8:0] <= q_m[8:0];

                    running_disparity <= running_disparity + balance - (q_m[8] ? 0 : 2);
                end
            end
            
        end
    end


endmodule
