module pixel_feeder_uart #(
    parameter PIX_W = 8
)(
    input  logic clk,
    input  logic rstn,

    // CPU → HW
    input  logic        px_valid,
    input  logic [7:0]  px_in,

    // HW → conv
    output logic        valid_out,
    output logic [7:0]  px_out
);

    always_ff @(posedge clk) begin
        if (!rstn) begin
            valid_out <= 0;
        end else begin
            valid_out <= px_valid;
            px_out    <= px_in;
        end
    end

endmodule
