module mux2 #(parameter WIDTH = 32) (
    input [WIDTH-1:0] data_i1,
    input [WIDTH-1:0] data_i2,
    input sel,
    output [WIDTH-1:0] data_o
);
    assign data_o = sel ? data_i1 : data_i2;
    
endmodule