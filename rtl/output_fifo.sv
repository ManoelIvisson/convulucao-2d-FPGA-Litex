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

    output logic         empty
);

    logic [W-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] wptr, rptr;
    logic [$clog2(DEPTH):0] count;

    assign empty = (count == 0);

    always_ff @(posedge clk) begin
        if (!rstn) begin
            wptr <= 0;
            rptr <= 0;
            count <= 0;
        end else begin
            case ({wr_en && count < DEPTH, rd_en && count > 0})
            2'b10: begin
                mem[wptr] <= wr_data;
                wptr <= wptr + 1;
                count <= count + 1;
            end
            2'b01: begin
                rd_data <= mem[rptr];
                rptr <= rptr + 1;
                count <= count - 1;
            end
            endcase
        end
    end

endmodule
