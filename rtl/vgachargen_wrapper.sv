module vgachargen_wrapper (
  input  logic clk_i,
  input  logic rst_ni,

//  input  logic [7:0]                 char_i,
//  input  logic [$clog2(80 * 30)-1:0] addr_i,
//  input  logic                       wen_i,

  output wire [3:0]R_o,
  output wire [3:0]G_o,
  output wire [3:0]B_o,

  input  wire [7:0]                 col_map_data_i,
  output wire [7:0]                 col_map_data_o,
  input  wire [$clog2(80 * 30)-1:0] col_map_addr_i,
  input  wire                       col_map_wen_i,
  input  wire [7:0]                 ch_map_data_i,
  output wire [7:0]                 ch_map_data_o,
  input  wire [$clog2(80 * 30)-1:0] ch_map_addr_i,
  input  wire                       ch_map_wen_i,
  input  wire [127:0]               ch_t_rw_data_i,
  output wire [127:0]               ch_t_rw_data_o,
  input  wire                       ch_t_rw_wen_i,
  input  wire [$clog2(128)-1:0]     ch_t_rw_addr_i,

  output wire hSYNC_o,
  output wire vSYNC_o
);

  logic clk_25m;
  assign clk_25m = clk_i;

  logic clk_125m;
  logic locked;
  logic clk_25m;

  logic clk_divider_strb;

  clk_divider # (
    .DIVISOR (4)
  ) clk_divider (
    .clk_i,
    .arst_ni (rst_ni),
    .strb_o  (clk_divider_strb)
  );
  
  logic rst;

  assign rst = ~rst_ni;

  VGA_TextMode_topModule top (
    .clk   (clk_125m),
    .clk_25m (clk_25m),
    .en_i    (clk_divider_strb),
    .rst,

    .col_map_data_i,
    .col_map_data_o,
    .col_map_addr_i,
    .col_map_wen_i,
    .ch_map_data_i,
    .ch_map_data_o,
    .ch_map_addr_i,
    .ch_map_wen_i,
    .ch_t_rw_data_i,
    .ch_t_rw_data_o,
    .ch_t_rw_wen_i,
    .ch_t_rw_addr_i,

    .R     (R_o),
    .G     (G_o),
    .B     (B_o),

    .hSYNC (hSYNC_o),
    .vSYNC (vSYNC_o)
  );
endmodule
