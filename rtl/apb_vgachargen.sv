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

  //////////////////////////
  // Control register     //
  //////////////////////////


  // WEN bit
  logic wen_en;
  logic wen_ff;
  logic wen_next;

  assign wen_en = apb_write | wen_ff;

  assign wen_next = apb_write ? apb_pwdata_i[0]
                  :                         '0;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) wen_ff <= '0;
    else if (wen_en)  wen_ff <= wen_next;
  end


  // //////////////////////////
  // // Char_in registers    //
  // //////////////////////////

  logic [7:0] char_in_ff;
  logic [7:0] char_in_next;
  logic       char_in_en;

  assign char_in_en   = apb_write;

  assign char_in_next = apb_pwdata_i[7:0];

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)    char_in_ff <= '0;
    else if (char_in_en) char_in_ff <= char_in_next;
  end

  // //////////////////////////
  // // addr_in registers    //
  // //////////////////////////

  logic [APB_ADDR_WIDTH-1:0] addr_in_ff;
  logic [APB_ADDR_WIDTH-1:0] addr_in_next;
  logic                      addr_in_en;

  assign addr_in_en   = apb_write;

  assign addr_in_next = apb_paddr_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i)    addr_in_ff <= '0;
    else if (addr_in_en) addr_in_ff <= addr_in_next;
  end

  //////////////////////////
  // APB data out         //
  //////////////////////////

  assign apb_prdata_o  = '0;


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

  // Instantiation
  vgachargen_wrapper vgachargen_wrapper (
    .clk_i,
    .rst_ni  (rstn_i),
    .char_i  (char_in_ff),
    .addr_i  (addr_in_ff),
    .wen_i   (wen_ff),
    .R_o,
    .G_o,
    .B_o,
    .hSYNC_o,
    .vSYNC_o
  );


endmodule
