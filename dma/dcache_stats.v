module dcache_stats (
    input wire clk,
    input wire rst_n,

    input wire cache_read_event,
    input wire hit_event,
    input wire miss_event,
    input wire fill_word_event,
    input wire fill_done_event,
    input wire fill_fail_event,

    output reg [31:0] cache_read_count,
    output reg [31:0] hit_count,
    output reg [31:0] miss_count,
    output reg [31:0] fill_word_count,
    output reg [31:0] fill_done_count,
    output reg [31:0] fill_fail_count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cache_read_count <= 32'b0;
            hit_count        <= 32'b0;
            miss_count       <= 32'b0;
            fill_word_count  <= 32'b0;
            fill_done_count  <= 32'b0;
            fill_fail_count  <= 32'b0;
        end else begin
            if (cache_read_event) begin
                cache_read_count <= cache_read_count + 32'b1;
            end
            if (hit_event) begin
                hit_count <= hit_count + 32'b1;
            end
            if (miss_event) begin
                miss_count <= miss_count + 32'b1;
            end
            if (fill_word_event) begin
                fill_word_count <= fill_word_count + 32'b1;
            end
            if (fill_done_event) begin
                fill_done_count <= fill_done_count + 32'b1;
            end
            if (fill_fail_event) begin
                fill_fail_count <= fill_fail_count + 32'b1;
            end
        end
    end

endmodule