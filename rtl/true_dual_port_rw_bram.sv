module true_dual_port_rw_bram #(
  parameter               INIT_FILE_NAME   = "",
  parameter               INIT_FILE_IS_BIN = 0,
  parameter  int unsigned COL_WIDTH        = 8,
  parameter  int unsigned NUM_COLS         = 4,
  parameter  int unsigned ADDR_WIDTH       = 4,
  localparam int unsigned DATA_WIDTH       = NUM_COLS * COL_WIDTH,
  localparam int unsigned DEPTH_WORDS      = 2 ** ADDR_WIDTH
) (
  input  logic                  clka_i,
  input  logic                  clkb_i,
  input  logic [ADDR_WIDTH-1:0] addra_i,
  input  logic [ADDR_WIDTH-1:0] addrb_i,
  input  logic [NUM_COLS  -1:0] wea_i,
  input  logic [DATA_WIDTH-1:0] dina_i,
  output logic [DATA_WIDTH-1:0] douta_o,
  output logic [DATA_WIDTH-1:0] doutb_o
);
  logic [DATA_WIDTH-1:0] mem[DEPTH_WORDS];

  if (INIT_FILE_NAME != "") begin                                                     : use_init_file
    if   (INIT_FILE_IS_BIN) initial  $readmemb(INIT_FILE_NAME, mem, 0, DEPTH_WORDS-1);
    else                    initial  $readmemh(INIT_FILE_NAME, mem, 0, DEPTH_WORDS-1);
  end else begin                                                                      : init_bram_to_zero
    initial begin
      for (int unsigned i = 0; i < DEPTH_WORDS; ++i) mem[i] = '0;
    end
  end

  always_ff @(posedge clka_i) begin
    for (int i = 0; i < NUM_COLS; ++i) begin
      if (wea_i[i]) mem[addra_i][i*COL_WIDTH+:COL_WIDTH] <= dina_i[i*COL_WIDTH+:COL_WIDTH];
    end
  end

  always_ff @(posedge clka_i) begin
    douta_o <= mem[addra_i];
  end

  always_ff @(posedge clkb_i) begin
    doutb_o <= mem[addrb_i];
  end

endmodule
