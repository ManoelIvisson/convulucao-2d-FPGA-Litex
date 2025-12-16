module image_rom #(
  parameter IMG_W = 640,
  parameter IMG_H = 960
)(
  input  logic        clk,
  input  logic [31:0] addr,
  output logic [7:0]  data
);

  localparam DEPTH = IMG_W*IMG_H;
  logic [7:0] mem [0:DEPTH-1];

  initial begin
    $readmemh("image_in.hex", mem);
  end

  always_ff @(posedge clk) begin
    data <= mem[addr];
  end

endmodule
