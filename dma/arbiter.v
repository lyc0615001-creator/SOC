`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 19:35:46
// Design Name: 
// Module Name: arbiter
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


module arbiter(
        input              clk,
        input              rst_n,

        input              cpu_request,
        input              cpu_read,
        input              cpu_write,
        input      [3:0]   cpu_wstrb,
        input      [31:0]  cpu_addr,
        input      [31:0]  cpu_wdata,

        output reg         cpu_ready,
        output reg [31:0]  cpu_rdata,
        output reg [1:0]   cpu_resp,

        input  wire        dma_request,
        input  wire        dma_re,
        input  wire        dma_we,
        input  wire [3:0]  dma_wstrb,
        input  wire [31:0] dma_addr,
        input  wire [31:0] dma_wdata,

        output reg         dma_ready,
        output reg  [31:0] dma_rdata,
        output reg  [1:0]  dma_resp,

        output reg         arbiter_request,
        output reg         arbiter_read,
        output reg         arbiter_write,
        output reg [3:0]   arbiter_wstrb,
        output reg [31:0]  arbiter_addr,
        output reg [31:0]  arbiter_wdata,

        input              arbiter_ready,
        input     [31:0]   arbiter_rdata,
        input     [1:0]    arbiter_resp,

        // fault monitor
        output reg         arbiter_source  // 0 CPU 1 DMA
    );

    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;

    reg state;
    reg [3:0] owner;

    // 定义变量
    wire [3:0] req;
    wire [3:0] grant;

    assign req = {2'd0, dma_request, cpu_request};

    // 定义事务
    wire start_affair;
    wire grant_en;

    assign start_affair = |req;

    assign grant_en = (state == IDLE) && start_affair;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            owner <= 4'd0; 
        end else begin
            case (state)
                IDLE: begin
                    if (start_affair) begin
                        owner <= grant;
   
                        state <= BUSY;
                    end
                end
                BUSY: begin
                    if (arbiter_ready) begin
                        state <= IDLE;

                        owner <= 4'd0; 
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    always @(*) begin
        arbiter_request = 1'b0;
        arbiter_read    = 1'b0;
        arbiter_write   = 1'b0;
        arbiter_wstrb   = 4'b0;
        arbiter_addr    = 32'd0;
        arbiter_wdata   = 32'd0;

        cpu_ready = 1'b0;
        cpu_rdata = 32'd0;
        cpu_resp  = 2'd0;

        dma_ready = 1'b0;
        dma_rdata = 32'd0;
        dma_resp  = 2'd0;

        arbiter_source = 1'b0;

        case (state)
            IDLE: begin
                if (start_affair) begin
                    case (grant)
                        4'b0001: begin
                            arbiter_request = cpu_request;
                            arbiter_read    = cpu_read;
                            arbiter_write   = cpu_write;
                            arbiter_wstrb   = cpu_wstrb;
                            arbiter_addr    = cpu_addr;
                            arbiter_wdata   = cpu_wdata;

                            cpu_ready       = arbiter_ready;
                            cpu_rdata       = arbiter_rdata;
                            cpu_resp        = arbiter_resp;

                            arbiter_source  = 1'b0;
                        end
                        4'b0010: begin
                            arbiter_request = dma_request;
                            arbiter_read    = dma_re;
                            arbiter_write   = dma_we;
                            arbiter_wstrb   = dma_wstrb;
                            arbiter_addr    = dma_addr;
                            arbiter_wdata   = dma_wdata;

                            dma_ready       = arbiter_ready;
                            dma_rdata       = arbiter_rdata; 
                            dma_resp        = arbiter_resp;

                            arbiter_source  = 1'b1;
                        end
                        default: ;
                    endcase
                end
            end
            BUSY: begin
                case (owner)
                    4'b0001: begin
                        arbiter_request = cpu_request;
                        arbiter_read    = cpu_read;
                        arbiter_write   = cpu_write;
                        arbiter_wstrb   = cpu_wstrb;
                        arbiter_addr    = cpu_addr;
                        arbiter_wdata   = cpu_wdata;

                        cpu_ready       = arbiter_ready;
                        cpu_rdata       = arbiter_rdata;
                        cpu_resp        = arbiter_resp;

                        arbiter_source  = 1'b0;
                    end
                    4'b0010: begin
                        arbiter_request = dma_request;
                        arbiter_read    = dma_re;
                        arbiter_write   = dma_we;
                        arbiter_wstrb   = dma_wstrb;
                        arbiter_addr    = dma_addr;
                        arbiter_wdata   = dma_wdata;

                        dma_ready       = arbiter_ready;
                        dma_rdata       = arbiter_rdata;
                        dma_resp        = arbiter_resp; 

                        arbiter_source  = 1'b1;
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end
    
    ROUND_ROBIN_ARBITER U_ROUND_ROBIN_ARBITER(
        .clk(clk),
        .rst_n(rst_n),
        .grant_en(grant_en),
        .req(req),
        .grant(grant)
    );
endmodule
