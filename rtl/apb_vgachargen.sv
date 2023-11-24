module apb_vgachargen
#(
  parameter APB_ADDR_WIDTH = 14,  // extended APB slaves
  parameter APB_DATA_WIDTH = 32
)
(
  input  logic                      clk_i,
  input  logic                      rstn_i,
  input  logic [APB_ADDR_WIDTH-1:0] apb_paddr_i,
  input  logic [APB_DATA_WIDTH-1:0] apb_pwdata_i,
  input  logic                      apb_pwrite_i,
  input  logic                      apb_psel_i,
  input  logic                      apb_penable_i,
  output logic [APB_DATA_WIDTH-1:0] apb_prdata_o,
  output logic                      apb_pready_o,
  output logic                      apb_pslverr_o,
  output logic [3:0]                R_o,
  output logic [3:0]                G_o,
  output logic [3:0]                B_o,
  output logic                      hSYNC_o,
  output logic                      vSYNC_o
);

  //////////////////////////
  // APB decoding         //
  //////////////////////////

  logic apb_write;
  logic apb_read;

  assign apb_write = apb_psel_i & apb_pwrite_i;
  assign apb_read  = apb_psel_i & ~apb_pwrite_i;

  logic  apb_sel_ch_map;
  logic  apb_sel_col_map;

  assign apb_sel_ch_map  = apb_paddr_i[13:12] == 2'b00;
  assign apb_sel_col_map = apb_paddr_i[13:12] == 2'b01;
  // assign apb_sel_ch_t_rw = apb_paddr_i >= 2400 / 4;

  logic [31:0]                 col_map_data2apb;
  logic [31:0]                 ch_map_data2apb;
  // logic [127:0]               ch_t_rw_data2apb;

  // //////////////////////////
  // // addr_in registers    //
  // //////////////////////////

  logic [9:0] ch_map_addr_ff;
  logic [9:0] ch_map_addr_next;

  assign ch_map_addr_next = apb_paddr_i[$left(apb_paddr_i):2];

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) ch_map_addr_ff <= '0;
    else              ch_map_addr_ff <= ch_map_addr_next;
  end

  logic [9:0] col_map_addr_ff;
  logic [9:0] col_map_addr_next;

  assign col_map_addr_next = apb_paddr_i[$left(apb_paddr_i):2];

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) col_map_addr_ff <= '0;
    else              col_map_addr_ff <= col_map_addr_next;
  end
  
  import vgachargen_pkg::*;

  // logic [CH_T_ADDR_WIDTH-1:0] ch_t_rw_addr_ff;
  // logic [CH_T_ADDR_WIDTH-1:0] ch_t_rw_addr_next;

  // assign ch_t_rw_addr_next = apb_paddr_i[$left(apb_paddr_i):2];

  // always_ff @(posedge clk_i or negedge rstn_i) begin
  //   if      (~rstn_i) ch_t_rw_addr_ff <= '0;
  //   else              ch_t_rw_addr_ff <= ch_t_rw_addr_next;
  // end

  // //////////////////////////
  // // data_in registers    //
  // //////////////////////////

  logic [31:0] ch_map_data2vga_ff;
  logic [31:0] ch_map_data2vga_next;
  logic        ch_map_data2vga_en;

  assign ch_map_data2vga_en   = apb_write && apb_sel_ch_map;
  assign ch_map_data2vga_next = apb_pwdata_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)            ch_map_data2vga_ff <= '0;
    else if (ch_map_data2vga_en) ch_map_data2vga_ff <= ch_map_data2vga_next;
  end

  logic [3:0] ch_map_data2vga_en_ff;
  logic [3:0] ch_map_data2vga_en_next;

  assign      ch_map_data2vga_en_next = {4{ch_map_data2vga_en}};

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)            ch_map_data2vga_en_ff <= '0;
    else                         ch_map_data2vga_en_ff <= ch_map_data2vga_en_next;
  end

  logic [31:0] col_map_data2vga_ff;
  logic [31:0] col_map_data2vga_next;
  logic        col_map_data2vga_en;

  assign col_map_data2vga_en   = apb_write && apb_sel_col_map;
  assign col_map_data2vga_next = apb_pwdata_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)             col_map_data2vga_ff <= '0;
    else if (col_map_data2vga_en) col_map_data2vga_ff <= col_map_data2vga_next;
  end

  logic [3:0] col_map_data2vga_en_ff;
  logic [3:0] col_map_data2vga_en_next;

  assign col_map_data2vga_en_next = {4{col_map_data2vga_en}};

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)             col_map_data2vga_en_ff <= '0;
    else                          col_map_data2vga_en_ff <= col_map_data2vga_en_next;
  end

  // logic [127:0] ch_t_rw_data2vga_ff;
  // logic [127:0] ch_t_rw_data2vga_next;
  // logic         ch_t_rw_data2vga_en;

  // assign ch_t_rw_data2vga_en   = apb_write && apb_sel_ch_t_rw;
  // assign ch_t_rw_data2vga_next =  (ch_t_rw_addr_ff[3:2] == 0) ? {ch_t_rw_data2apb[127:33], apb_pwdata_i} :
  //                                 (ch_t_rw_addr_ff[3:2] == 1) ? {ch_t_rw_data2apb[127:64], apb_pwdata_i, ch_t_rw_data2apb[31:0]} :
  //                                 (ch_t_rw_addr_ff[3:2] == 2) ? {ch_t_rw_data2apb[127:96], apb_pwdata_i, ch_t_rw_data2apb[63:0]}
  //                                                             : {apb_pwdata_i, ch_t_rw_data2apb[95:0]};

  // always_ff @(posedge clk_i or negedge rstn_i) begin
  //   if      (~rstn_i)             ch_t_rw_data2vga_ff <= '0;
  //   else if (ch_t_rw_data2vga_en) ch_t_rw_data2vga_ff <= ch_t_rw_data2vga_next;
  // end

  // logic         ch_t_rw_data2vga_en_ff;
  // always_ff @(posedge clk_i or negedge rstn_i) begin
  //   if      (~rstn_i)             ch_t_rw_data2vga_en_ff <= '0;
  //   else                          ch_t_rw_data2vga_en_ff <= ch_t_rw_data2vga_en;
  // end


  //////////////////////////
  // APB data out         //
  //////////////////////////

  always_comb begin
    apb_prdata_o = '0;

    case ({apb_sel_col_map, apb_sel_ch_map})
      2'b01  : apb_prdata_o = ch_map_data2apb;
      2'b10  : apb_prdata_o = col_map_data2apb;
      default: apb_prdata_o = 32'hfa11_1eaf;
    endcase
  end

  //////////////////////////
  // APB ready            //
  //////////////////////////

  logic       apb_ready_next;
  logic       apb_ready_en;
  logic [1:0] apb_ready_ff;

  assign apb_ready_next = ( apb_psel_i & apb_penable_i ) & ~apb_ready_ff[0] & ~apb_ready_ff[1];

  assign apb_ready_en = (apb_psel_i & apb_penable_i)
                      | apb_ready_ff[0] | apb_ready_ff[1];

  always_ff @(posedge clk_i or negedge rstn_i)
  if (~rstn_i)
    apb_ready_ff[0] <= '0;
  else if (apb_ready_en)
    apb_ready_ff[0] <= apb_ready_next;

  always_ff @(posedge clk_i or negedge rstn_i)
  if (~rstn_i)
    apb_ready_ff[1] <= '0;
  else
    apb_ready_ff[1] <= apb_ready_ff[0];

  assign apb_pready_o  = apb_ready_ff[1];


  //////////////////////////
  // APB error            //
  //////////////////////////

  // Writes to status are forbidden
  // Writes to data_out registers are forbidden

  logic apb_err_next;
  logic apb_err_en;
  logic apb_err_ff;

  assign apb_err_next = 1'b0;

  assign apb_err_en = apb_ready_ff[0];

  always_ff @(posedge clk_i or negedge rstn_i)
  if (~rstn_i)
    apb_err_ff <= '0;
  else if (apb_err_en)
    apb_err_ff <= apb_err_next;

  assign apb_pslverr_o = apb_err_ff;


  //////////////////////////
  // Cipher instantiation //
  //////////////////////////


  // Instantiation
  vgachargen #(
    .CLK_FACTOR_25M  (50 / 25)
  ) vgachargen (
    .sys_clk_i (clk_i),
    .sys_arstn_i  (rstn_i),
    .factor_clk_i (clk_i),
    .factor_arstn_i  (rstn_i),
    .col_map_data_i (col_map_data2vga_ff),
    .col_map_data_o (col_map_data2apb),
    .col_map_addr_i (col_map_addr_ff),
    .col_map_wen_i (col_map_data2vga_en_ff),
    .ch_map_data_i (ch_map_data2vga_ff),
    .ch_map_data_o (ch_map_data2apb),
    .ch_map_addr_i (ch_map_addr_ff),
    .ch_map_wen_i (ch_map_data2vga_en_ff),
    .ch_t_rw_data_i ('0),
    .ch_t_rw_data_o (),
    .ch_t_rw_wen_i ('0),
    .ch_t_rw_addr_i ('0),
    .vga_r_o (R_o),
    .vga_g_o (G_o),
    .vga_b_o (B_o),
    .vga_vs_o(vSYNC_o),
    .vga_hs_o(hSYNC_o)
  );


endmodule
