module index_generator
  import vgachargen_pkg::*;
(
  input  logic [VGA_MAX_V_WIDTH  -1:0] vcount_i,
  input  logic [VGA_MAX_H_WIDTH  -1:0] hcount_i,

  output logic [CH_MAP_ADDR_WIDTH-1:0] ch_map_addr_o,
  output logic [BITMAP_ADDR_WIDTH-1:0] bitmap_addr_o
);

  logic [CH_H_WIDTH-1:0] haddr_chars;
  logic [CH_V_WIDTH-1:0] vaddr_chars;

  assign haddr_chars = CH_H_WIDTH'(hcount_i >> BITMAP_H_WIDTH);
  assign vaddr_chars = CH_V_WIDTH'(vcount_i >> BITMAP_V_WIDTH);

  `define _MULT_BY_80(_x) ((_x << 6) + (_x << 4))
  assign ch_map_addr_o = `_MULT_BY_80(vaddr_chars) + haddr_chars;
  `undef _MULT_BY_80

  logic [BITMAP_H_WIDTH-1:0] haddr_pixels;
  logic [BITMAP_V_WIDTH-1:0] vaddr_pixels;

  assign haddr_pixels = hcount_i[BITMAP_H_WIDTH-1:0];
  assign vaddr_pixels = vcount_i[BITMAP_V_WIDTH-1:0];

  `define _MULT_BY_8(_x) (_x << 3)
  assign bitmap_addr_o = `_MULT_BY_8(vaddr_pixels) + haddr_pixels;
  `undef _MULT_BY_8


endmodule
