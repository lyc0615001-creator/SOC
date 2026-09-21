module MIPS (
    input clk, rst,
    input clk_en,
    input [31:0] instrIM,
    input [31:0] DM_data_oDM,
    output dm_write_enM,
    output stall,
    output [31:0] pc_oF, pc_oM,
    output [31:0] alu_resultM,
    output [31:0] DM_data_iM
);
    wire reg_write_enE, reg_write_enM, reg_write_enDM;
    wire reg_write_enW, alu_src_muxE, reg_data_muxDM, reg_dst_muxD;
    wire reg_data_muxE, reg_data_muxM;
    wire branchD, jumpD;
    wire used_rsD, used_rtD;
    wire flush;
    wire [2:0] alu_controlE;
    wire [31:0] instrD;

    Datapath u_Datapath(
    .clk(clk), 
    .rst(rst),
    .clk_en(clk_en),
    .instrIM(instrIM),
    .DM_data_oDM(DM_data_oDM),
    .reg_write_enE(reg_write_enE), 
    .reg_write_enM(reg_write_enM), 
    .reg_write_enDM(reg_write_enDM), 
    .reg_write_enW(reg_write_enW),
    .alu_src_muxE(alu_src_muxE),
    .reg_data_muxE(reg_data_muxE),
    .reg_data_muxM(reg_data_muxM),
    .reg_data_muxDM(reg_data_muxDM),
    .reg_dst_muxD(reg_dst_muxD),
    .branchD(branchD),
    .jumpD(jumpD),
    .used_rsD(used_rsD),
    .used_rtD(used_rtD),
    .alu_controlE(alu_controlE),
    // out
    .pc_oF(pc_oF),
    .pc_oM(pc_oM),
    .alu_resultM(alu_resultM),
    .DM_data_iM(DM_data_iM),
    .instrD(instrD),
    .stall(stall), 
    .flush(flush)
);

    Controller u_Controller(
        .clk(clk),
        .rst(rst),
        .clk_en(clk_en),
        .stall(stall), 
        .flush(flush),
        .op_code(instrD[31:26]),
        .funct(instrD[5:0]),
        // out
        .reg_write_enE(reg_write_enE), 
        .reg_write_enM(reg_write_enM), 
        .reg_write_enDM(reg_write_enDM), 
        .reg_write_enW(reg_write_enW), 
        .alu_src_muxE(alu_src_muxE),  
        .reg_dst_muxD(reg_dst_muxD), 
        .reg_data_muxE(reg_data_muxE), 
        .reg_data_muxM(reg_data_muxM), 
        .reg_data_muxDM(reg_data_muxDM), 
        .dm_write_enM(dm_write_enM),
        .branchD(branchD), 
        .jumpD(jumpD),
        .used_rsD(used_rsD),
        .used_rtD(used_rtD),
        .alu_controlE(alu_controlE)
    );
    
endmodule