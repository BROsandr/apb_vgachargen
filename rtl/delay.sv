module delay #(
  parameter int unsigned DATA_WIDTH = 8,
  parameter int unsigned DELAY_BY   = 2
) (
  input  logic                  clk_i,
  input  logic                  arstn_i,
  input  logic [DATA_WIDTH-1:0] data_i,
  output logic [DATA_WIDTH-1:0] data_o
);
  logic [DELAY_BY-1:0][DATA_WIDTH-1:0] data_ff  ;
  logic [DELAY_BY-1:0][DATA_WIDTH-1:0] data_next;

  assign data_next = {data_ff[0:DELAY_BY-2], data_i};

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (!arstn_i) data_ff <= '0;
    else          data_ff <= data_next;
  end
endmodule
