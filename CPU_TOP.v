module CPU_TOP (
    input clk,
    input rst,
    input [31:0] T_clk,
    output wire dm_write_enM,
    output wire [31:0] display_data
    );

    wire [31:0] instrIM, DM_data_oDM, alu_resultM;
    wire [31:0] data_addr;

    wire [31:0] DM_data_iM, pc_oF, pc_oM;
    wire clk_en, stall;

    assign data_addr = alu_resultM;
    assign display_data = dm_write_enM ? DM_data_iM : pc_oM >> 2;

    MIPS u_mips(
      .clk(clk),
      .rst(rst),
      .clk_en(clk_en),
      .instrIM(instrIM),
      .DM_data_oDM(DM_data_oDM),
      // out
      .dm_write_enM(dm_write_enM),
      .stall(stall),
      .pc_oF(pc_oF),
      .pc_oM(pc_oM),
      .alu_resultM(alu_resultM),
      .DM_data_iM(DM_data_iM)
    );

    // 指令存储
    instr_ram_new u_instr_ram_new (
      .clka(clk),    // input wire clka
      .ena(clk_en && ~stall),      // input wire ena
      .wea(4'b0000),      // input wire [3 : 0] wea
      .addra(pc_oF[9:2]),  // input wire [7 : 0] addra
      .dina(32'b0),    // input wire [31 : 0] dina
      .douta(instrIM)  // output wire [31 : 0] douta
    );

    // 指令存储， 测试单周期
    // instr_ram_pri u_instr_ram_pri(.pc(pc_oF[9:2]), .instr(instrF));

    // 数据存储

    data_ram u_data_ram (
      .clka(clk),    // input wire clka
      .ena(clk_en),      // input wire ena
      .wea({4{dm_write_enM}}),      // input wire [3 : 0] wea
      .addra(data_addr[9:0]),  // input wire [9 : 0] addra
      .dina(DM_data_iM),    // input wire [31 : 0] dina
      .douta(DM_data_oDM)  // output wire [31 : 0] douta
    );

    // 分频器

    cpu_clk_en u_cpu_clk_en(
        .clk(clk),
        .rst(rst),
        .T_clk(T_clk),
        .clk_en(clk_en)
    );

endmodule