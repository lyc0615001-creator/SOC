`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/19 15:20:46
// Design Name: 
// Module Name: Hazard
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


module Hazard(
        input [4:0] rsD, rtD,
        input used_rsD, used_rtD,
        input [4:0] RF_address3E, RF_address3M, RF_address3DM,
        input reg_write_enE, reg_write_enM, reg_write_enDM,
        input reg_data_muxE, reg_data_muxM,
        input branch_selD, jump_selD,
        input validD, validE, validM, validDM,
        output [1:0] forwardAD, forwardBD,
        output stall, redirectD
    );

    wire hazardE, hazardM;

    // F IM D E M DM W

    // R 数据冒险
    // 原因：当前指令写入地址为下一指令读取地址 需要数据前递
    // 前递D阶段架构 E/M/DM/W + normal -> D 共五种情况

    // 判断条件，以E阶段前递为例 ： RF_address3E !=0 && RF_address3E == rsD/rtD && w_enE && !lw
    // 定义 forwardAD 000-normal  001-E  010-M  011-DM  100-W 
    // ** v2.2 删除W阶段前递，使用同周期读写判断

    assign forwardAD = !validD ? 2'b00 :
                       ((validE && reg_write_enE && !reg_data_muxE && (RF_address3E != 5'b0) && (RF_address3E == rsD)) ? 2'b01 :
                       (validM && reg_write_enM && !reg_data_muxM && (RF_address3M != 5'b0) && (RF_address3M == rsD)) ? 2'b10 :
                       (validDM && reg_write_enDM && (RF_address3DM != 5'b0) && (RF_address3DM == rsD)) ? 2'b11 :
                       2'b00);
    
    assign forwardBD = !validD ? 2'b00 :
                       ((validE && reg_write_enE && !reg_data_muxE && (RF_address3E != 5'b0) && (RF_address3E == rtD)) ? 2'b01 :
                       (validM && reg_write_enM && !reg_data_muxM && (RF_address3M != 5'b0) && (RF_address3M == rtD))  ? 2'b10 :
                       (validDM && reg_write_enDM && (RF_address3DM != 5'b0) && (RF_address3DM == rtD)) ? 2'b11 :
                       2'b00);

    // lw 数据冒险
    // 原因： 如果当前指令所需数据来自上一条指令lw，那么普通的数据前递无法解决问题，因为lw指令在E/M阶段只有地址 
    // 解决措施： 流水线暂停，将当前指令及之后的指令暂停，并invalid一条E阶段指令

    // D阶段判别架构
    // 判断条件： (reg_write_enE &&  RF_adress3E == rsD || RF_adress3E == rtD) or (reg_write_enM &&  RF_adress3M == rsD || RF_adress3M == rtD)

    assign hazardE = validD && validE && reg_write_enE && reg_data_muxE && (RF_address3E != 5'b0) && ((used_rsD && RF_address3E == rsD) || (used_rtD && RF_address3E == rtD));
    assign hazardM = validD && validM && reg_write_enM && reg_data_muxM && (RF_address3M != 5'b0) && ((used_rsD && RF_address3M == rsD) || (used_rtD && RF_address3M == rtD));

    assign stall = hazardE || hazardM;

    // beq jump 控制冒险
    // 原因：当前执行beq或jump，需要生成一个redirectD信号，无效之后的两条指令
    // 解决措施：进行redirectD操作使得下一周期的validIM、validD为0

    // D阶段判别架构
    // 判断条件：branch_selD || jump_selD

    assign redirectD = (jump_selD || branch_selD);



endmodule
