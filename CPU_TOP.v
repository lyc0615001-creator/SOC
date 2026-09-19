module CPU_TOP (
    input clk,
    input rst,
    input [31:0] T_clk,
    output wire dm_write_en,
    output wire [31:0] display_data
    );

    // wire [31:0] pc_o;
    wire [31:0] instr, DM_data_o, alu_result;
    wire [31:0] data_addr;

    wire [31:0] DM_data_i, pc_o;

    assign data_addr = alu_result;
    assign display_data = dm_write_en ? DM_data_i : pc_o >> 2;

    MIPS u_mips(
      .clk(clk),
      .rst(rst),
      .clk_en(clk_en),
      .instr(instr),
      .DM_data_o(DM_data_o),
      // out
      .dm_write_en(dm_write_en),
      .pc_o(pc_o),
      .alu_result(alu_result),
      .DM_data_i(DM_data_i)
    );

    // 指令存储
    // instr_ram u_instr_ram (
    //   .clka(clk),    // input wire clka
    //   .ena(1'b1),      // input wire ena
    //   .wea(4'b0000),      // input wire [3 : 0] wea
    //   .addra(pc_o[9:2]),  // input wire [7 : 0] addra
    //   .dina(32'b0),    // input wire [31 : 0] dina
    //   .douta(instr)  // output wire [31 : 0] douta
    // );

    // 指令存储， 测试单周期
    instr_ram_pri u_instr_ram_pri(.pc(pc_o[9:2]), .instr(instr));

    // 数据存储

    data_ram u_data_ram (
      .clka(clk),    // input wire clka
      .ena(clk_en),      // input wire ena
      .wea(dm_write_en),      // input wire [3 : 0] wea
      .addra(data_addr),  // input wire [9 : 0] addra
      .dina(DM_data_i),    // input wire [31 : 0] dina
      .douta(DM_data_o)  // output wire [31 : 0] douta
    );

    // 分频器

    cpu_clk_en u_cpu_clk_en(
        .clk(clk),
        .rst(rst),
        .T_clk(T_clk),
        .clk_en(clk_en)
    );

endmodule