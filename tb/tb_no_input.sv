module tb_no_input ();

  timeprecision 1ps;
  timeunit      1ns;

  logic clk;
  logic arst_n;

  localparam int unsigned CLK_PERIOD = 10;

  initial begin
    clk <= 0;
    forever #(CLK_PERIOD/2) clk <= ~clk;
  end

  task reset();
    arst_n <= 1'b0;
    #100;
    arst_n <= 1'b1;
  endtask

  logic clk_25m;
  
  initial begin
    clk_25m <= 1'b0;
    forever begin
      #40ns clk_25m <= ~clk_25m;
    end
  end

vgachargen_wrapper vgachargen_wrapper (
  .clk_i (clk),
  .rst_ni (arst_n),

//  input  logic [7:0]                 char_i,
//  input  logic [$clog2(80 * 30)-1:0] addr_i,
//  input  logic                       wen_i,

  .R_o (),
  .G_o (),
  .B_o (),

  // input  wire [7:0]                 col_map_data_i,
  // output wire [7:0]                 col_map_data_o,
  // input  wire [$clog2(80 * 30)-1:0] col_map_addr_i,
  // input  wire                       col_map_wen_i,
  // input  wire [7:0]                 ch_map_data_i,
  // output wire [7:0]                 ch_map_data_o,
  // input  wire [$clog2(80 * 30)-1:0] ch_map_addr_i,
  // input  wire                       ch_map_wen_i,
  // input  wire [127:0]               ch_t_rw_data_i,
  // output wire [127:0]               ch_t_rw_data_o,
  // input  wire                       ch_t_rw_wen_i,
  // input  wire [$clog2(128)-1:0]     ch_t_rw_addr_i,

  .hSYNC_o(),
  .vSYNC_o ()
);

  initial begin
    reset();

    #1us;

    $finish();
  end
endmodule
