module vgachargen
  import vgachargen_pkg::*;
#(
  parameter int unsigned CLK_FACTOR_25M         = 100 / 25,
  parameter              CH_T_RO_INIT_FILE_NAME = "ch_t_ro.mem",
  parameter              CH_T_RW_INIT_FILE_NAME = "ch_t_rw.mem",
  parameter              CH_MAP_INIT_FILE_NAME  = "ch_map.mem",
  parameter              COL_MAP_INIT_FILE_NAME = "col_map.mem"
) (
  input logic clk_i,
  input logic arstn_i,

  // input  logic [COL_MAP_DATA_WIDTH-1:0] col_map_data_i,
  // input  logic [COL_MAP_ADDR_WIDTH-1:0] col_map_addr_i,
  // input  logic                          col_map_wen_i,
  // input  logic [CH_MAP_DATA_WIDTH-1:0]  ch_map_data_i,
  // input  logic [CH_MAP_ADDR_WIDTH-1:0]  ch_map_addr_i,
  // input  logic                          ch_map_wen_i,
  // input  logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_i,
  // input  logic                          ch_t_rw_wen_i,
  // input  logic [CH_T_ADDR_WIDTH-1:0]    ch_t_rw_addr_i,

  // output logic [CH_MAP_DATA_WIDTH-1:0]  ch_map_data_o,
  // output logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_o,
  // output logic [COL_MAP_DATA_WIDTH-1:0] col_map_data_o,
  output logic [3:0]     vga_r_o,
  output logic [3:0]     vga_g_o,
  output logic [3:0]     vga_b_o,
  output logic                          vga_hs_o,
  output logic                          vga_vs_o
);

  logic [VGA_MAX_H_WIDTH-1:0] hcount_pixels;
  logic [VGA_MAX_V_WIDTH-1:0] vcount_pixels;

  logic [1:0] pixel_enable_delay_ff;
  logic [1:0] pixel_enable_delay_next;
  logic       pixel_enable;

  assign pixel_enable_delay_next = {pixel_enable_delay_ff[0], pixel_enable};

  always @(posedge clk_i or negedge arstn_i) begin
    if   (!arstn_i) pixel_enable_delay_ff <= '0;
    else            pixel_enable_delay_ff <= pixel_enable_delay_next;
  end

  logic [1:0] vga_hs_delay_ff;
  logic [1:0] vga_hs_delay_next;
  logic       vga_hs;

  logic [1:0] vga_vs_delay_ff;
  logic [1:0] vga_vs_delay_next;
  logic       vga_vs;

  vga_block #(
    .CLK_FACTOR_25M (CLK_FACTOR_25M)
  ) vga_block (
    .clk_i          (clk_i),
    .arstn_i        (arstn_i),
    .hcount_o       (hcount_pixels),
    .vcount_o       (vcount_pixels),
    .pixel_enable_o (pixel_enable),
    .vga_hs_o       (vga_hs),
    .vga_vs_o       (vga_vs)
  );


  logic [CH_MAP_ADDR_WIDTH-1:0] ch_map_addr_internal;

  logic [BITMAP_ADDR_WIDTH-1:0] bitmap_addr_delay_ff  [2];
  logic [BITMAP_ADDR_WIDTH-1:0] bitmap_addr_delay_next[2];
  logic [BITMAP_ADDR_WIDTH-1:0] bitmap_addr;

  assign vga_hs_delay_next = {vga_hs_delay_ff[0], vga_hs};
  always_ff @(posedge clk_i or negedge arstn_i) begin
    if   (!arstn_i) vga_hs_delay_ff <= '0;
    else            vga_hs_delay_ff <= vga_hs_delay_next;
  end

  assign vga_vs_delay_next = {vga_vs_delay_ff[0], vga_vs};
  always_ff @(posedge clk_i or negedge arstn_i) begin
    if   (!arstn_i) vga_vs_delay_ff <= '0;
    else            vga_vs_delay_ff <= vga_vs_delay_next;
  end

  assign bitmap_addr_delay_next = {bitmap_addr_delay_ff[0], bitmap_addr};
  always @(posedge clk_i) begin
    if   (!arstn_i) bitmap_addr_delay_ff <= {'0, '0};
    else            bitmap_addr_delay_ff <= bitmap_addr_delay_next;
  end

  index_generator index_generator (
    .vcount_i      (vcount_pixels),
    .hcount_i      (hcount_pixels),
    .ch_map_addr_o (ch_map_addr_internal),
    .bitmap_addr_o (bitmap_addr)
  );


wire [CH_T_ADDR_WIDTH:0]currentCharacterIndex;

true_dual_port_rw_bram
                #
                (
                  .INIT_FILE_NAME ("ch_map.mem"),
                  .DATA_WIDTH     (CH_T_ADDR_WIDTH+1),
                  .ADDR_WIDTH     (CH_MAP_ADDR_WIDTH)
                )
                ch_map
                (
                    .clk_i  (clk_i),
                    .addra_i (ch_map_addr_i),
                    .addrb_i (ch_map_addr_internal),
                    .wea_i   (ch_map_wen_i),
                    .dina_i  (ch_map_data_i),
                    .douta_o (ch_map_data_o),
                    .doutb_o (currentCharacterIndex)
                );

  logic [CH_T_DATA_WIDTH-1:0] currentCharacter_ch_t_ro;
  logic [CH_T_DATA_WIDTH-1:0] currentCharacter_ch_t_rw;
  logic [CH_T_DATA_WIDTH-1:0] currentCharacter;

  single_port_ro_bram #(
    .INIT_FILE_NAME   ("ch_t_ro.mem"),
    .INIT_FILE_IS_BIN (1),
    .DATA_WIDTH       (CH_T_DATA_WIDTH),
    .ADDR_WIDTH       (CH_T_ADDR_WIDTH)
  ) ch_t_ro (
    .clk_i(clk_i),

    .addr_i(currentCharacterIndex[$left(currentCharacterIndex)-1:0]),
    .dout_o(currentCharacter_ch_t_ro)
  );

  true_dual_port_rw_bram #(
    .INIT_FILE_NAME   ("ch_t_rw.mem"),
    .INIT_FILE_IS_BIN (1),
    .DATA_WIDTH       (CH_T_DATA_WIDTH),
    .ADDR_WIDTH       (CH_T_ADDR_WIDTH)
  ) ch_t_rw (
    .clk_i   (clk_i),
    .addra_i (ch_t_rw_addr_i),
    .addrb_i (currentCharacterIndex[$left(currentCharacterIndex)-1:0]),
    .wea_i   (ch_t_rw_wen_i),
    .dina_i  (ch_t_rw_data_i),
    .douta_o (ch_t_rw_data_o),
    .doutb_o (currentCharacter_ch_t_rw)
  );

  assign currentCharacter = currentCharacterIndex[$left(currentCharacterIndex)] ? currentCharacter_ch_t_rw : currentCharacter_ch_t_ro;

  logic [7:0] col_map_data_delay_next;
  logic [7:0] col_map_data_delay_ff;
  logic [7:0] col_map_data_internal;
  logic [3:0] fg_col_map_data;
  logic [3:0] bg_col_map_data;

  assign fg_col_map_data = col_map_data_delay_ff[7:4];
  assign bg_col_map_data = col_map_data_delay_ff[3:0];

  true_dual_port_rw_bram #(
    .INIT_FILE_NAME ("col_map.mem"),
    .DATA_WIDTH     (8),
    .ADDR_WIDTH     (COL_MAP_ADDR_WIDTH)
  ) col_map (
    .clk_i   (clk_i),
    .addra_i (col_map_addr_i),
    .addrb_i (ch_map_addr_internal),
    .wea_i   (col_map_wen_i),
    .dina_i  (col_map_data_i),
    .douta_o (col_map_data_o),
    .doutb_o (col_map_data_internal)
  );

  assign col_map_data_delay_next = col_map_data_internal;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if   (!arstn_i) col_map_data_delay_ff <= '0;
    else            col_map_data_delay_ff <= col_map_data_delay_next;
  end

  logic   currentPixel;
  assign  currentPixel = currentCharacter[bitmap_addr_delay_ff[1]];

  color_t fg_color;
  assign  fg_color = color_decode(fg_col_map_data);

  color_t bg_color;
  assign  bg_color = color_decode(bg_col_map_data);

  assign vga_r_o = pixel_enable_delay_ff[1] ? (currentPixel ? fg_color[11:8]: bg_color[11:8]) : '0;
  assign vga_g_o = pixel_enable_delay_ff[1] ? (currentPixel ? fg_color[7:4] : bg_color[7:4])  : '0;
  assign vga_b_o = pixel_enable_delay_ff[1] ? (currentPixel ? fg_color[3:0] : bg_color[3:0])  : '0;

  assign vga_vs_o = vga_vs_delay_ff[1];
  assign vga_hs_o = vga_hs_delay_ff[1];

endmodule
