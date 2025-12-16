module conv_csr (
    input  logic        clk,
    input  logic        rst,

    // FIFO interface
    input  logic [7:0]  fifo_dout,
    input  logic        fifo_empty,
    output logic        fifo_rd_en,

    // CSR interface
    input  logic        csr_pixel_re,
    output logic [7:0]  csr_pixel_r,
    output logic        csr_valid_r,

    output logic [31:0] pixel_count
);

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_rd_en   <= 1'b0;
            csr_pixel_r  <= 8'd0;
            pixel_count  <= 32'd0;
        end else begin
            fifo_rd_en <= 1'b0;

            if (csr_pixel_re && !fifo_empty) begin
                fifo_rd_en  <= 1'b1;
                csr_pixel_r <= fifo_dout;
                pixel_count <= pixel_count + 1;
            end
        end
    end

    assign csr_valid_r = ~fifo_empty;

endmodule
