module vgachargen
  import vgachargen_pkg::*;
#(
  parameter int unsigned CLK_FACTOR_25M           = 100 / 25,
  parameter              CH_T_RO_INIT_FILE_NAME   = "ch_t_ro.mem",
  parameter bit          CH_T_RO_INIT_FILE_IS_BIN = 1,
  parameter              CH_T_RW_INIT_FILE_NAME   = "ch_t_rw.mem",
  parameter bit          CH_T_RW_INIT_FILE_IS_BIN = 1,
  parameter              CH_MAP_INIT_FILE_NAME    = "ch_map.mem",
  parameter bit          CH_MAP_INIT_FILE_IS_BIN  = 0,
  parameter              COL_MAP_INIT_FILE_NAME   = "col_map.mem",
  parameter bit          COL_MAP_INIT_FILE_IS_BIN = 0
) (
  input  logic                          sys_clk_i,
  input  logic                          factor_clk_i,
  input  logic                          sys_arstn_i,
  input  logic                          factor_arstn_i,

  input  logic [7:0]                    col_map_data_i,
  input  logic [COL_MAP_ADDR_WIDTH-1:0] col_map_addr_i,
  input  logic                          col_map_wen_i,

  input  logic [CH_MAP_DATA_WIDTH-1:0]  ch_map_data_i,
  input  logic [CH_MAP_ADDR_WIDTH-1:0]  ch_map_addr_i,
  input  logic                          ch_map_wen_i,

  input  logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_i,
  input  logic                          ch_t_rw_wen_i,
  input  logic [CH_T_ADDR_WIDTH-1:0]    ch_t_rw_addr_i,

  output logic [CH_MAP_DATA_WIDTH-1:0]  ch_map_data_o,
  output logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_o,
  output logic [7:0]                    col_map_data_o,

  output logic [3:0]                    vga_r_o,
  output logic [3:0]                    vga_g_o,
  output logic [3:0]                    vga_b_o,
  output logic                          vga_hs_o,
  output logic                          vga_vs_o
);

  logic [VGA_MAX_H_WIDTH-1:0] hcount_pixels;
  logic [VGA_MAX_V_WIDTH-1:0] vcount_pixels;

  logic       pixel_enable;
  logic       pixel_enable_delayed;

  delay #(
    .DATA_WIDTH (1),
    .DELAY_BY   (2)
  ) pixel_enable_delay (
    .clk_i   (factor_clk_i),
    .arstn_i (factor_arstn_i),
    .data_i  (pixel_enable),
    .data_o  (pixel_enable_delayed)
  );

  logic vga_vs_delayed;
  logic vga_vs;

  delay #(
    .DATA_WIDTH (1),
    .DELAY_BY   (2)
  ) vga_vs_delay (
    .clk_i   (factor_clk_i),
    .arstn_i (factor_arstn_i),
    .data_i  (vga_vs),
    .data_o  (vga_vs_delayed)
  );

  logic vga_hs_delayed;
  logic vga_hs;

  delay #(
    .DATA_WIDTH (1),
    .DELAY_BY   (2)
  ) vga_hs_delay (
    .clk_i   (factor_clk_i),
    .arstn_i (factor_arstn_i),
    .data_i  (vga_hs),
    .data_o  (vga_hs_delayed)
  );


  vga_block #(
    .CLK_FACTOR_25M (CLK_FACTOR_25M)
  ) vga_block (
    .clk_i          (factor_clk_i),
    .arstn_i        (factor_arstn_i),
    .hcount_o       (hcount_pixels),
    .vcount_o       (vcount_pixels),
    .pixel_enable_o (pixel_enable),
    .vga_hs_o       (vga_hs),
    .vga_vs_o       (vga_vs)
  );

  logic [CH_MAP_ADDR_WIDTH-1:0] ch_map_addr_internal;

  logic [BITMAP_ADDR_WIDTH-1:0] bitmap_addr;
  logic [BITMAP_ADDR_WIDTH-1:0] bitmap_addr_delayed;

  delay #(
    .DATA_WIDTH (BITMAP_ADDR_WIDTH),
    .DELAY_BY   (2)
  ) bitmap_delay (
    .clk_i   (factor_clk_i),
    .arstn_i (factor_arstn_i),
    .data_i  (bitmap_addr),
    .data_o  (bitmap_addr_delayed)
  );

  index_generator index_generator (
    .vcount_i      (vcount_pixels),
    .hcount_i      (hcount_pixels),
    .ch_map_addr_o (ch_map_addr_internal),
    .bitmap_addr_o (bitmap_addr)
  );


  logic [CH_T_ADDR_WIDTH:0] ch_t_addr_internal;

  true_dual_port_rw_bram #(
    .INIT_FILE_NAME   (CH_MAP_INIT_FILE_NAME),
    .INIT_FILE_IS_BIN (CH_MAP_INIT_FILE_IS_BIN),
    .DATA_WIDTH       (CH_T_ADDR_WIDTH+1),
    .ADDR_WIDTH       (CH_MAP_ADDR_WIDTH)
  ) ch_map (
    .clka_i  (sys_clk_i),
    .clkb_i  (factor_clk_i),
    .addra_i (ch_map_addr_i),
    .addrb_i (ch_map_addr_internal),
    .wea_i   (ch_map_wen_i),
    .dina_i  (ch_map_data_i),
    .douta_o (ch_map_data_o),
    .doutb_o (ch_t_addr_internal)
  );

  logic [CH_T_ADDR_WIDTH-1:0] ch_t_ro_addr_internal;
  assign                      ch_t_ro_addr_internal = ch_t_addr_internal[CH_T_ADDR_WIDTH-1:0];
  logic [CH_T_DATA_WIDTH-1:0] ch_t_ro_data_internal;

  single_port_ro_bram #(
    .INIT_FILE_NAME   (CH_T_RO_INIT_FILE_NAME),
    .INIT_FILE_IS_BIN (CH_T_RO_INIT_FILE_IS_BIN),
    .DATA_WIDTH       (CH_T_DATA_WIDTH),
    .ADDR_WIDTH       (CH_T_ADDR_WIDTH)
  ) ch_t_ro (
    .clk_i (factor_clk_i),
    .addr_i(ch_t_ro_addr_internal),
    .dout_o(ch_t_ro_data_internal)
  );

  logic [CH_T_ADDR_WIDTH-1:0] ch_t_rw_addr_internal;
  assign                      ch_t_rw_addr_internal = ch_t_ro_addr_internal;
  logic [CH_T_DATA_WIDTH-1:0] ch_t_rw_data_internal;

  true_dual_port_rw_bram #(
    .INIT_FILE_NAME   (CH_T_RW_INIT_FILE_NAME),
    .INIT_FILE_IS_BIN (CH_T_RW_INIT_FILE_IS_BIN),
    .DATA_WIDTH       (CH_T_DATA_WIDTH),
    .ADDR_WIDTH       (CH_T_ADDR_WIDTH)
  ) ch_t_rw (
    .clka_i  (sys_clk_i),
    .clkb_i  (factor_clk_i),
    .addra_i (ch_t_rw_addr_i),
    .addrb_i (ch_t_rw_addr_internal),
    .wea_i   (ch_t_rw_wen_i),
    .dina_i  (ch_t_rw_data_i),
    .douta_o (ch_t_rw_data_o),
    .doutb_o (ch_t_rw_data_internal)
  );

  logic [CH_T_DATA_WIDTH-1:0] ch_t_data_internal;
  assign                      ch_t_data_internal = ch_t_addr_internal[CH_T_ADDR_WIDTH]  ? ch_t_rw_data_internal
                                                                                        : ch_t_ro_data_internal;

  logic [7:0] col_map_data_internal;
  logic [7:0] col_map_data_internal_delayed;

  delay #(
    .DATA_WIDTH (8),
    .DELAY_BY   (1)
  ) col_map_data_delay (
    .clk_i   (factor_clk_i),
    .arstn_i (factor_arstn_i),
    .data_i  (col_map_data_internal),
    .data_o  (col_map_data_internal_delayed)
  );

  logic [3:0] fg_col_map_data;
  logic [3:0] bg_col_map_data;

  assign fg_col_map_data = col_map_data_internal_delayed[7:4];
  assign bg_col_map_data = col_map_data_internal_delayed[3:0];

  true_dual_port_rw_bram #(
    .INIT_FILE_NAME   (COL_MAP_INIT_FILE_NAME),
    .INIT_FILE_IS_BIN (COL_MAP_INIT_FILE_IS_BIN),
    .DATA_WIDTH       (8),
    .ADDR_WIDTH       (COL_MAP_ADDR_WIDTH)
  ) col_map (
    .clka_i  (sys_clk_i),
    .clkb_i  (factor_clk_i),
    .addra_i (col_map_addr_i),
    .addrb_i (ch_map_addr_internal),
    .wea_i   (col_map_wen_i),
    .dina_i  (col_map_data_i),
    .douta_o (col_map_data_o),
    .doutb_o (col_map_data_internal)
  );

  logic   currentPixel;
  assign  currentPixel = ch_t_data_internal[bitmap_addr_delayed];

  color_t fg_color;
  assign  fg_color = color_decode(fg_col_map_data);

  color_t bg_color;
  assign  bg_color = color_decode(bg_col_map_data);

  // register outputs
  logic [3:0] vga_r_ff;
  logic [3:0] vga_r_next;
  logic [3:0] vga_g_ff;
  logic [3:0] vga_g_next;
  logic [3:0] vga_b_ff;
  logic [3:0] vga_b_next;
  logic       vga_vs_ff;
  logic       vga_vs_next;
  logic       vga_hs_ff;
  logic       vga_hs_next;

  assign vga_r_next = pixel_enable_delayed ? (currentPixel ? fg_color[11:8]: bg_color[11:8]) : '0;
  assign vga_g_next = pixel_enable_delayed ? (currentPixel ? fg_color[7:4] : bg_color[7:4])  : '0;
  assign vga_b_next = pixel_enable_delayed ? (currentPixel ? fg_color[3:0] : bg_color[3:0])  : '0;

  assign vga_vs_next = vga_vs_delayed;
  assign vga_hs_next = vga_hs_delayed;

  always_ff @(posedge factor_clk_i or negedge factor_arstn_i) begin
    if (!factor_arstn_i) begin
      vga_r_ff  <= '0;
      vga_g_ff  <= '0;
      vga_b_ff  <= '0;
      vga_hs_ff <= '0;
      vga_vs_ff <= '0;
    end else begin
      vga_r_ff  <= vga_r_next;
      vga_g_ff  <= vga_g_next;
      vga_b_ff  <= vga_b_next;
      vga_hs_ff <= vga_hs_next;
      vga_vs_ff <= vga_vs_next;
    end
  end

  assign vga_r_o = vga_r_ff;
  assign vga_g_o = vga_g_ff;
  assign vga_b_o = vga_b_ff;

  assign vga_hs_o = vga_hs_ff;
  assign vga_vs_o = vga_vs_ff;

endmodule
