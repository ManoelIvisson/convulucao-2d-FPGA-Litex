module pixel_feeder #(
  parameter IMG_W = 640,
  parameter IMG_H = 960
)(
  input  logic clk,
  input  logic rstn,

  output logic        valid_out,
  output logic [7:0]  px_out,
  output logic        done
);

  logic [31:0] addr;
  logic [7:0]  rom_data;

  image_rom #(.IMG_W(IMG_W), .IMG_H(IMG_H)) rom (
    .clk(clk),
    .addr(addr),
    .data(rom_data)
  );

  always_ff @(posedge clk) begin
    if (!rstn) begin
      addr      <= 0;
      valid_out <= 0;
      done      <= 0;
    end else if (!done) begin
      px_out    <= rom_data;
      valid_out <= 1;
      addr      <= addr + 1;
      if (addr == IMG_W*IMG_H-1)
        done <= 1;
    end
  end

endmodule
