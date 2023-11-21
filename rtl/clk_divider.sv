module clk_divider # (
  parameter int unsigned DIVISOR = 2
) (
  input  logic                       clk_i,
  input  logic                       arst_ni,
  output logic                       strb_o
);
  localparam int unsigned COUNTER_WIDTH = $clog2(DIVISOR);

  logic [COUNTER_WIDTH-1:0] counter_ff;
  logic                     strb_ff;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if   (~arst_ni) counter_ff <= '0;
    else            counter_ff <= counter_ff + COUNTER_WIDTH'(1);
  end

  assign strb_o = &counter_ff;

endmodule
