module Regfile (
    input clk, rst,
    input w_en, clk_en,
    input [4:0] RF_address1, RF_address2, RF_address3,
    input [31:0] RF_data_i,
    output [31:0] RF_data_o1, RF_data_o2
);
    reg [31:0] regfile [31:0];
    always @(posedge clk) begin
        if (clk_en) begin
            if (w_en && RF_address3 != 5'd0) begin
                regfile[RF_address3] <= RF_data_i;
            end
        end
        
    end

    assign RF_data_o1 = (RF_address1 == 5'd0) ? 32'd0 : ((RF_address1 == RF_address3) ? RF_data_i : regfile[RF_address1]); 
    assign RF_data_o2 = (RF_address2 == 5'd0) ? 32'd0 : ((RF_address2 == RF_address3) ? RF_data_i : regfile[RF_address2]); 
    
    // assign RF_data_o1 = (RF_address1 == 5'd0) ? 32'd0 : regfile[RF_address1]; 
    // assign RF_data_o2 = (RF_address2 == 5'd0) ? 32'd0 : regfile[RF_address2]; 

endmodule