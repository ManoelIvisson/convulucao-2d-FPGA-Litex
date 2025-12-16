module output_fifo #(
    parameter W = 8,
    parameter DEPTH = 1024
)(
    input  logic clk,
    input  logic rstn,

    input  logic [W-1:0] wr_data,
    input  logic         wr_en,

    output logic [W-1:0] rd_data,
    input  logic         rd_en,

    output logic         valid
);

    logic [W-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] wptr, rptr;
    logic [$clog2(DEPTH):0] count;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            wptr  <= 0;
            rptr  <= 0;
            count <= 0;
        end else begin
            if (wr_en && count < DEPTH) begin
                mem[wptr] <= wr_data;
                wptr <= wptr + 1;
                count <= count + 1;
            end
            if (rd_en && count > 0) begin
                rd_data <= mem[rptr];
                rptr <= rptr + 1;
                count <= count - 1;
            end
        end
    end

    assign valid = (count != 0);

endmodule
