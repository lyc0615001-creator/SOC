module repair_flopenrc (
    input  wire         clk,
    input  wire         rst,
    input  wire         cpu_en,
    input  wire         en,
    input  wire         clear,

    input  wire         bus_wait,
    input  wire [1:0]   forwardAE,
    input  wire [1:0]   forwardBE,
    input  wire [31:0]  RF_data_o1_mux4D,
    input  wire [31:0]  RF_data_o2_mux4D,
    input  wire [31:0]  RF_data_iW,

    output reg  [31:0]  RF_data_o1_mux4E,
    output reg  [31:0]  RF_data_o2_mux4E
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            RF_data_o1_mux4E <= 32'b0;
            RF_data_o2_mux4E <= 32'b0;
        end else if (cpu_en) begin
            if (clear) begin
                RF_data_o1_mux4E <= 32'b0;
                RF_data_o2_mux4E <= 32'b0;
            end else if (en) begin
                RF_data_o1_mux4E <= RF_data_o1_mux4D;
                RF_data_o2_mux4E <= RF_data_o2_mux4D;
            end else if (bus_wait) begin
                if (forwardAE == 2'b10) begin
                    RF_data_o1_mux4E <= RF_data_iW;
                end
                if (forwardBE == 2'b10) begin
                    RF_data_o2_mux4E <= RF_data_iW;
                end
            end
        end   
    end
    
endmodule