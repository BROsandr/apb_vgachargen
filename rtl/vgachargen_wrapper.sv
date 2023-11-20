module vgachargen_wrapper (
  input  logic clk_i,
  input  logic rst_ni,

//  input  logic [7:0]                 char_i,
//  input  logic [$clog2(80 * 30)-1:0] addr_i,
//  input  logic                       wen_i,

  output wire [3:0]R_o,
  output wire [3:0]G_o,
  output wire [3:0]B_o,

  output wire hSYNC_o,
  output wire vSYNC_o
);

  logic clk_125m;
  logic locked;
  logic clk_25m;

  clk_wiz_0 clk_wiz_0 (
    // Clock out ports
    .clk_out1(clk_125m),     // output clk_out1
    .clk_out2(clk_25m),
    // Status and control signals
    .resetn(rst_ni), // input resetn
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_i)
  );      // input clk_in1
  
  logic rst;

  assign rst = ~rst_ni | ~locked;

  VGA_TextMode_topModule top (
    .clk   (clk_125m),
    .clk_25m (clk_25m),
    .rst,

    .ch_map_data_i  ('0),
    .col_map_data_i ('0),
    .col_map_data_o (),
    .ch_map_addr_i  ('0),
    .col_map_addr_i ('0),
    .ch_map_wen_i   ('0),
    .col_map_wen_i  ('0),

    .R     (R_o),
    .G     (G_o),
    .B     (B_o),

    .hSYNC (hSYNC_o),
    .vSYNC (vSYNC_o)
  );
endmodule
