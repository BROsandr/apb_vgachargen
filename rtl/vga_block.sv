module vga_block
  import vgachargen_pkg::*;
#(
  parameter int unsigned             CLK_FACTOR_25M = 4
) (
  input  logic                       clk_i,
  input  logic                       arstn_i,
  output logic [VGA_MAX_H_WIDTH-1:0] hcount_o,
  output logic [VGA_MAX_V_WIDTH-1:0] vcount_o,
  output logic                       pixel_enable_o,
  output logic                       vga_hs_o,
  output logic                       vga_vs_o
);
  logic clk_divider_strb;

  clk_divider # (
    .DIVISOR (CLK_FACTOR_25M)
  ) clk_divider (
    .clk_i,
    .arstn_i,
    .strb_o  (clk_divider_strb)
  );

  // timing_generator timing_generator (
  //   .clk_i,
  //   .arstn_i,
  //   .en_i     (clk_divider_strb),
  //   .vga_hs_o,
  //   .vga_vs_o,
  //   .hcount_o,
  //   .vcount_o,
  //   .pixel_enable_o

  // );

  timing_generator #(
    .CLK_MHZ (100)
  ) timing_generator (
    .clk  (clk_i),
    .rst  (~arstn_i),
    .hsync(vga_hs_o),
    .vsync(vga_vs_o),
    .display_on (pixel_enable_o),
    .hpos  (hcount_o),
    .vpos  (vcount_o)
  );
endmodule
