// conv_top.sv
// Top-level for 3x3 convolution (grayscale, 8-bit pixels).
// Params: PIX_W bits pixel, COEF_W bits coefficient, IMG_W width (pixels per line)
module conv_top #(
  parameter PIX_W   = 8,    // input pixel width (unsigned 0..255)
  parameter COEF_W  = 16,   // coefficient width (signed)
  parameter ACC_W   = 32,   // accumulator width
  parameter IMG_W   = 128   // image width (pixels per row)
)(
  input  logic                 clk,
  input  logic                 rstn,

  // streaming pixel input (1 pixel per clk when valid_in)
  input  logic                 valid_in,
  input  logic [PIX_W-1:0]     px_in,

  // kernel write interface (simple synchronous write)
  input  logic                 kernel_wr,
  input  logic [3:0]           kernel_addr, // 0..8
  input  logic signed [COEF_W-1:0] kernel_data,

  // streaming pixel output (1 per clk when valid_out)
  output logic                 valid_out,
  output logic [PIX_W-1:0]     px_out
);

  // kernel storage
  logic signed [COEF_W-1:0] kernel [0:8];
  integer i;
  always_ff @(posedge clk) begin
    if (!rstn) begin
      for (i=0;i<9;i=i+1) kernel[i] <= '0;
    end else begin
      if (kernel_wr) kernel[kernel_addr] <= kernel_data;
    end
  end

  // 3x3 window wires
  logic [PIX_W-1:0] w00, w01, w02;
  logic [PIX_W-1:0] w10, w11, w12;
  logic [PIX_W-1:0] w20, w21, w22;
  logic window_valid;

  // instantiate linebuffer
  linebuffer_3x3 #(.PIX_W(PIX_W), .IMG_W(IMG_W)) lb (
    .clk(clk), .rstn(rstn),
    .valid_in(valid_in), .px_in(px_in),
    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22),
    .valid_out(window_valid)
  );

  // mac9: multiply and accumulate 9 pixels with 9 kernel coeffs
  logic signed [ACC_W-1:0] acc_out;
  mac9 #(.PIX_W(PIX_W), .COEF_W(COEF_W), .ACC_W(ACC_W)) mac (
    .clk(clk), .rstn(rstn),
    .px0(w00), .px1(w01), .px2(w02),
    .px3(w10), .px4(w11), .px5(w12),
    .px6(w20), .px7(w21), .px8(w22),
    .k0(kernel[0]), .k1(kernel[1]), .k2(kernel[2]),
    .k3(kernel[3]), .k4(kernel[4]), .k5(kernel[5]),
    .k6(kernel[6]), .k7(kernel[7]), .k8(kernel[8]),
    .acc_out(acc_out)
  );

  // normalization/clamp: choose a shift (you can parameterize)
  // For now, use a fixed right shift of 8 (i.e., divide by 256) as an example.
  localparam int SHIFT = 8;

  logic signed [ACC_W-1:0] acc_shifted;
  always_ff @(posedge clk) begin
    if (!rstn) begin
      px_out <= '0;
      valid_out <= 1'b0;
    end else begin
      if (window_valid) begin
        // arithmetic shift or logical depending on sign; here treat negative to clamp to 0
        acc_shifted = acc_out >>> SHIFT;
        // clamp to 0..(2^PIX_W-1)
        if (acc_shifted <= 0)
          px_out <= '0;
        else if (acc_shifted >= (1<<PIX_W)-1)
          px_out <= {(PIX_W){1'b1}};
        else
          px_out <= acc_shifted[PIX_W-1:0];
        valid_out <= 1'b1;
      end else begin
        valid_out <= 1'b0;
      end
    end
  end

endmodule
