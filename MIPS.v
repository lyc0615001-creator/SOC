module MIPS (
    input clk, rst,
    input clk_en,
    input [31:0] instr,
    input [31:0] DM_data_o,
    output dm_write_en,
    output [31:0] pc_o, 
    output [31:0] alu_result,
    output [31:0] DM_data_i
);

    wire reg_write_en, alu_src_mux, reg_data_mux, reg_dst_mux;
    wire branch, jump;
    wire [2:0] alu_control;

    Datapath u_Datapath(
    .clk(clk), 
    .rst(rst),
    .clk_en(clk_en),
    .instr(instr),
    .DM_data_o(DM_data_o),
    .reg_write_en(reg_write_en),
    .alu_src_mux(alu_src_mux),
    .reg_data_mux(reg_data_mux),
    .reg_dst_mux(reg_dst_mux),
    .branch(branch),
    .jump(jump),
    .alu_control(alu_control),
    // out
    .pc_o(pc_o),
    .alu_result(alu_result),
    .DM_data_i(DM_data_i)
);

    Controller u_Controller(
        .clk(clk),
        .op_code(instr[31:26]),
        .funct(instr[5:0]),
        // out
        .reg_write_en(reg_write_en), 
        .alu_src_mux(alu_src_mux),  
        .reg_dst_mux(reg_dst_mux), 
        .reg_data_mux(reg_data_mux), 
        .dm_write_en(dm_write_en),
        .branch(branch), 
        .jump(jump),
        .alu_control(alu_control)
    );
    
endmodule