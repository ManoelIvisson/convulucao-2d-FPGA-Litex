// mac9.sv
module mac9 #(
  parameter PIX_W  = 8,
  parameter COEF_W = 16,
  parameter ACC_W  = 32
)(
  input  logic                clk,
  input  logic                rstn,
  input  logic [PIX_W-1:0]    px0, px1, px2,
  input  logic [PIX_W-1:0]    px3, px4, px5,
  input  logic [PIX_W-1:0]    px6, px7, px8,
  input  logic signed [COEF_W-1:0] k0,k1,k2,k3,k4,k5,k6,k7,k8,
  output logic signed [ACC_W-1:0] acc_out
);

  // register inputs (optional pipeline stage)
  logic signed [COEF_W+PIX_W-1:0] p0,p1,p2,p3,p4,p5,p6,p7,p8;

  always_ff @(posedge clk) begin
    if (!rstn) begin
      p0 <= '0; p1 <= '0; p2 <= '0;
      p3 <= '0; p4 <= '0; p5 <= '0;
      p6 <= '0; p7 <= '0; p8 <= '0;
      acc_out <= '0;
    end else begin
      p0 <= $signed({{(COEF_W){1'b0}}, px0}) * k0;
      p1 <= $signed({{(COEF_W){1'b0}}, px1}) * k1;
      p2 <= $signed({{(COEF_W){1'b0}}, px2}) * k2;
      p3 <= $signed({{(COEF_W){1'b0}}, px3}) * k3;
      p4 <= $signed({{(COEF_W){1'b0}}, px4}) * k4;
      p5 <= $signed({{(COEF_W){1'b0}}, px5}) * k5;
      p6 <= $signed({{(COEF_W){1'b0}}, px6}) * k6;
      p7 <= $signed({{(COEF_W){1'b0}}, px7}) * k7;
      p8 <= $signed({{(COEF_W){1'b0}}, px8}) * k8;

      // adder tree (you could pipeline deeper if needed)
      acc_out <= p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8;
    end
  end

endmodule
