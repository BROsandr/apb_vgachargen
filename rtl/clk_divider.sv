module clk_divider # (
  parameter int unsigned DIVISOR = 2
) (
  input  logic                       clk_i,
  input  logic                       arst_ni,
  output logic                       strb_o
);
  localparam int unsigned COUNTER_WIDTH = $clog2(DIVISOR);

  logic [COUNTER_WIDTH-1:0] counter_next;
  logic [COUNTER_WIDTH-1:0] counter_ff;

  assign counter_next = (counter_ff < DIVISOR) ? (counter_ff + COUNTER_WIDTH'(1)) : '0;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if   (~arst_ni) counter_ff <= '0;
    else            counter_ff <= counter_next;
  end

  logic strb_ff;
  logic strb_next;

  assign strb_next = ~|counter_ff;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if   (~arst_ni) strb_ff <= '0;
    else            strb_ff <= strb_next;
  end

  assign strb_o = strb_ff;

endmodule
