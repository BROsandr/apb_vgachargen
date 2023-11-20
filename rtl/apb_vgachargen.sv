module apb_vgachargen
#(
  parameter APB_ADDR_WIDTH = 13,  // extended APB slaves
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

  assign apb_sel_ch_map  = apb_paddr_i  < 2400;
  assign apb_sel_col_map  = apb_sel_ch_map;
  assign apb_sel_ch_t_rw = apb_paddr_i >= 2400;

  // //////////////////////////
  // // data_in registers    //
  // //////////////////////////

  logic [7:0] ch_map_data2vga_ff;
  logic [7:0] ch_map_data2vga_next;
  logic       ch_map_data2vga_en;

  assign ch_map_data2vga_en   = apb_write && apb_sel_ch_map;
  assign ch_map_data2vga_next = apb_pwdata_i[7:0];

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)            ch_map_data2vga_ff <= '0;
    else if (ch_map_data2vga_en) ch_map_data2vga_ff <= ch_map_data2vga_next;
  end

  logic [7:0] col_map_data2vga_ff;
  logic [7:0] col_map_data2vga_next;
  logic       col_map_data2vga_en;

  assign col_map_data2vga_en   = ch_map_data_in_en;
  assign col_map_data2vga_next = apb_pwdata_i[15:8];

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)             col_map_data2vga_ff <= '0;
    else if (col_map_data2vga_en) col_map_data2vga_ff <= col_map_data_next;
  end

  logic [127:0] ch_t_rw_data_in_ff;
  logic [127:0] ch_t_rw_data_in_next;
  logic         ch_t_rw_data_in_en;

  assign ch_t_rw_data_in_en   = apb_write && apb_sel_ch_map;
  assign ch_t_rw_data_in_next =  (ch_map_addr_ff[6:5] == 0) ? {ch_map_data2apb[127:33], apb_pwdata_i} :
                                 (ch_map_addr_ff[6:5] == 1) ? {ch_map_data2apb[127:64], apb_pwdata_i, ch_map_data2apb[31:0]} :
                                 (ch_map_addr_ff[6:5] == 2) ? {ch_map_data2apb[127:96], apb_pwdata_i, ch_map_data2apb[63:0]}
                                                            : {apb_pwdata_i, ch_map_data2apb[95:0]};

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)            ch_t_rw_data_in_ff <= '0;
    else if (ch_t_rw_data_in_en) ch_t_rw_data_in_ff <= ch_t_rw_data_in_next;
  end

  // //////////////////////////
  // // addr_in registers    //
  // //////////////////////////

  logic [$clog2(80 * 30)-1:0] ch_map_addr_ff;
  logic [$clog2(80 * 30)-1:0] ch_map_addr_next;

  assign ch_map_addr_next = apb_paddr_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) ch_map_addr_ff <= '0;
    else              ch_map_addr_ff <= ch_map_addr_next;
  end

  logic [$clog2(80 * 30)-1:0] col_map_addr_ff;
  logic [$clog2(80 * 30)-1:0] col_map_addr_next;

  assign col_map_addr_next = apb_paddr_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) col_map_addr_ff <= '0;
    else              col_map_addr_ff <= col_map_addr_next;
  end

  logic [$clog2(80 * 30)-1:0] ch_t_rw_addr_ff;
  logic [$clog2(80 * 30)-1:0] ch_t_rw_addr_next;

  assign ch_t_rw_addr_next = apb_paddr_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) ch_t_rw_addr_ff <= '0;
    else              ch_t_rw_addr_ff <= ch_t_rw_addr_next;
  end

  //////////////////////////
  // APB data out         //
  //////////////////////////

  assign apb_prdata_o  = !apb_write && (apb_sel_ch_t_rw ? ch_t_rw_addr_ff :
                                        apb_sel_col_map ? col_map_addr_ff :
                                        apb_sel_ch_map  ? ch_map_addr_ff
                                                        : '0);


  //////////////////////////
  // APB ready            //
  //////////////////////////

  logic apb_ready_next;
  logic apb_ready_en;
  logic apb_ready_ff;

  assign apb_ready_next = ( apb_psel_i & apb_penable_i ) & ~apb_ready_ff;

  assign apb_ready_en = (apb_psel_i & apb_penable_i)
                      | apb_ready_ff;

  always_ff @(posedge clk_i or negedge rstn_i)
  if (~rstn_i)
    apb_ready_ff <= '0;
  else if (apb_ready_en)
    apb_ready_ff <= apb_ready_next;

  assign apb_pready_o  = apb_ready_ff;


  //////////////////////////
  // APB error            //
  //////////////////////////

  // Writes to status are forbidden
  // Writes to data_out registers are forbidden

  logic apb_err_next;
  logic apb_err_en;
  logic apb_err_ff;

  assign apb_err_next = apb_read;


  assign apb_err_en = (apb_psel_i & apb_penable_i);

  always_ff @(posedge clk_i or negedge rstn_i)
  if (~rstn_i)
    apb_err_ff <= '0;
  else if (apb_err_en)
    apb_err_ff <= apb_err_next;

  assign apb_pslverr_o = apb_err_ff;


  //////////////////////////
  // Cipher instantiation //
  //////////////////////////

  logic [7:0]                 col_map_data2apb;
  logic [7:0]                 ch_map_data2apb;
  logic [127:0]               ch_t_rw_data2apb;

  // Instantiation
  vgachargen_wrapper vgachargen_wrapper (
    .clk_i,
    .rst_ni  (rstn_i),
    .col_map_data_i (col_map_data2vga_ff),
    .col_map_data_o (col_map_data2apb),
    .col_map_addr_i (col_map_addr_ff),
    .col_map_wen_i (col_map_data2vga_en),
    .ch_map_data_i (ch_map_data2vga_ff),
    .ch_map_data_o (ch_map_data2apb),
    .ch_map_addr_i (ch_map_addr_ff),
    .ch_map_wen_i (ch_map_data2vga_en),
    .ch_t_rw_data_i (ch_t_rw_data2vga_ff),
    .ch_t_rw_data_o (ch_t_rw_data2apb),
    .ch_t_rw_wen_i (ch_t_rw_data2vga_en),
    .ch_t_rw_addr_i (ch_t_rw_addr_ff),
    .R_o,
    .G_o,
    .B_o,
    .hSYNC_o,
    .vSYNC_o
  );


endmodule
