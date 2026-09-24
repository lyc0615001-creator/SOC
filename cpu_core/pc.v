module pc (
    input clk,
    input rst,
    input en,
    input cpu_en,
    input [31:0] pc_i,
    output reg [31:0] pc_o
);
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            pc_o <= 32'd0;
        end else if (cpu_en && en) begin
            pc_o <= pc_i;
        end
    end
    
endmodule