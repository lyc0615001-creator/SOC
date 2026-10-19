`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 14:56:47
// Design Name: 
// Module Name: tmds_serializer
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


module tmds_serializer(
        input  pixel_clk,
        input  clk_5x,
        input  rst,

        input  [9:0] tmds_data,

        output       serial_out
    );

    wire slave_shift1;
    wire slave_shift2;

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),   // DDR, SDR
        .DATA_RATE_TQ("BUF"),   // DDR, BUF, SDR
        .DATA_WIDTH(10),         // Parallel data width (2-8,10,14)
        .SERDES_MODE("MASTER"), // MASTER, SLAVE
        .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
    )
    u_master (
        .OFB(),             // 1-bit output: Feedback path for data
        .OQ(serial_out),               // 1-bit output: Data path output
        // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .TBYTEOUT(),   // 1-bit output: Byte group tristate
        .TFB(),             // 1-bit output: 3-state control
        .TQ(),               // 1-bit output: 3-state control
        .CLK(clk_5x),             // 1-bit input: High speed clock
        .CLKDIV(pixel_clk),       // 1-bit input: Divided clock
        // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
        .D1(tmds_data[0]),
        .D2(tmds_data[1]),
        .D3(tmds_data[2]),
        .D4(tmds_data[3]),
        .D5(tmds_data[4]),
        .D6(tmds_data[5]),
        .D7(tmds_data[6]),
        .D8(tmds_data[7]),
        .OCE(1'b1),             // 1-bit input: Output data clock enable
        .RST(rst),             // 1-bit input: Reset
        // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
        .SHIFTIN1(slave_shift1),
        .SHIFTIN2(slave_shift2),
        // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .TBYTEIN(1'b0),     // 1-bit input: Byte group tristate
        .TCE(1'b0)              // 1-bit input: 3-state clock enable
    );

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),   // DDR, SDR
        .DATA_RATE_TQ("BUF"),   // DDR, BUF, SDR
        .DATA_WIDTH(10),         // Parallel data width (2-8,10,14)
        .SERDES_MODE("SLAVE"), // MASTER, SLAVE
        .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
    )
    u_slave (
        .OFB(),             // 1-bit output: Feedback path for data
        .OQ(),               // 1-bit output: Data path output
        // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
        .SHIFTOUT1(slave_shift1),
        .SHIFTOUT2(slave_shift2),
        .TBYTEOUT(),   // 1-bit output: Byte group tristate
        .TFB(),             // 1-bit output: 3-state control
        .TQ(),               // 1-bit output: 3-state control
        .CLK(clk_5x),             // 1-bit input: High speed clock
        .CLKDIV(pixel_clk),       // 1-bit input: Divided clock
        // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
        .D1(),
        .D2(),
        .D3(tmds_data[8]),
        .D4(tmds_data[9]),
        .D5(),
        .D6(),
        .D7(),
        .D8(),
        .OCE(1'b1),             // 1-bit input: Output data clock enable
        .RST(rst),             // 1-bit input: Reset
        // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
        .SHIFTIN1(),
        .SHIFTIN2(),
        // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .TBYTEIN(1'b0),     // 1-bit input: Byte group tristate
        .TCE(1'b0)              // 1-bit input: 3-state clock enable
    );
endmodule
