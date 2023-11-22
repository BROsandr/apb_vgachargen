module single_port_ro_bram #(
  parameter               INIT_FILE_LOC    = "",
  parameter               INIT_FILE_IS_BIN = 0,
  parameter  int unsigned DATA_WIDTH       = 2,
  parameter  int unsigned ADDR_WIDTH       = 4,
  localparam int unsigned DEPTH_WORDS      = 2 ** ADDR_WIDTH
) (
  input  logic                  clk_i,
  input  logic [ADDR_WIDTH-1:0] addr_i,
  output logic [DATA_WIDTH-1:0] dout_o
);
  logic [DATA_WIDTH-1:0] mem[DEPTH_WORDS];

  if   (INIT_FILE_IS_BIN) initial  $readmemb(INIT_FILE_LOC, mem, 0, DEPTH_WORDS-1);
  else                    initial  $readmemh(INIT_FILE_LOC, mem, 0, DEPTH_WORDS-1);

  always_ff @(posedge clk_i) begin
    dout_o <= mem[addr_i];
  end

endmodule
