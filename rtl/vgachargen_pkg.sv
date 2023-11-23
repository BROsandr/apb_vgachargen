package vgachargen_pkg;

  parameter int unsigned HD = 640; // Display area
  parameter int unsigned HF = 16;  // Front porch
  parameter int unsigned HR = 96;  // Retrace/Sync
  parameter int unsigned HB = 48;  // Back Porch
  parameter int unsigned VD = 480;
  parameter int unsigned VF = 10;
  parameter int unsigned VR = 2;
  parameter int unsigned VB = 33;

  parameter int unsigned HTOTAL = HD + HF + HR + HB;
  parameter int unsigned VTOTAL = VD + VF + VR + VB;

  parameter int unsigned VGA_MAX_H_WIDTH = $clog2(HTOTAL);
  parameter int unsigned VGA_MAX_V_WIDTH = $clog2(VTOTAL);

  parameter int unsigned BITMAP_H_PIXELS   = 8;
  parameter int unsigned BITMAP_V_PIXELS   = 16;
  parameter int unsigned BITMAP_H_WIDTH    = $clog2(BITMAP_H_PIXELS);
  parameter int unsigned BITMAP_V_WIDTH    = $clog2(BITMAP_V_PIXELS);
  parameter int unsigned CH_T_DATA_WIDTH   = BITMAP_H_PIXELS * BITMAP_V_PIXELS;
  parameter int unsigned BITMAP_ADDR_WIDTH = $clog2(CH_T_DATA_WIDTH);
  parameter int unsigned CHARSET_COUNT     = 256;
  parameter int unsigned CH_T_ADDR_WIDTH   = $clog2(CHARSET_COUNT/2);

  parameter int unsigned CH_H_PIXELS        = HD / BITMAP_H_PIXELS;
  parameter int unsigned CH_V_PIXELS        = VD / BITMAP_V_PIXELS;
  parameter int unsigned CH_V_WIDTH         = $clog2(CH_V_PIXELS);
  parameter int unsigned CH_H_WIDTH         = $clog2(CH_H_PIXELS);
  parameter int unsigned CH_MAP_ADDR_WIDTH  = CH_V_WIDTH + CH_H_WIDTH;
  parameter int unsigned CH_MAP_DATA_WIDTH  = CH_T_ADDR_WIDTH + 1;
  parameter int unsigned COL_MAP_ADDR_WIDTH = CH_MAP_ADDR_WIDTH;

  typedef enum bit [11:0] {
    BLACK = '0,
    WHITE = '1,
    BLUE  = 12'h00f,
    RED   = 12'hf00,
    GREEN = 12'h0f0
  } color_t;

  function color_t color_decode(logic [3:0] color_encoded);
    case (color_encoded)
      4'h0   : return BLACK;
      4'ha   : return BLUE;
      4'hb   : return RED;
      4'h1   : return GREEN;
      4'hf   : return WHITE;
      default: return BLACK;
    endcase
  endfunction
endpackage
