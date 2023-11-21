module true_dual_port_bram #(
  parameter               INIT_FILE   = "",
  parameter               BINARY_FILE = 0,
  parameter  int unsigned DATA_WIDTH  = 2,
  parameter  int unsigned DEPTH_WORDS = 2,
  localparam int unsigned ADDR_WIDTH  = $clog2(DEPTH_WORDS)
) (
  input  logic                  clka_i,
  input  logic                  clkb_i,
  input  logic [ADDR_WIDTH-1:0] addra_i,
  input  logic [ADDR_WIDTH-1:0] addrb_i,
  input  logic                  wea_i,
  input  logic [DATA_WIDTH-1:0] dina_i,
  output logic [DATA_WIDTH-1:0] douta_o,
  output logic [DATA_WIDTH-1:0] doutb_o
);
  logic [DATA_WIDTH-1:0] mem[DEPTH_WORDS];

  if (INIT_FILE != "") begin                             : use_init_file
    if (BINARY_FILE) initial  $readmemb(INIT_FILE, mem, 0, DEPTH_WORDS-1);
    else             initial  $readmemh(INIT_FILE, mem, 0, DEPTH_WORDS-1);
  end else begin                                         : init_bram_to_zero
    initial begin
      for (int unsigned i = 0; i < DEPTH_WORDS; ++i) mem[i] = '0;
    end
  end

  always_ff @(posedge clka_i) begin
    if (wea_i) mem[addra_i] <= dina_i;
  end

  always_ff @(posedge clka_i) begin
    douta_o <= mem[addra_i];
  end

  always_ff @(posedge clkb_i) begin
    doutb_o <= mem[addrb_i];
  end

endmodule
