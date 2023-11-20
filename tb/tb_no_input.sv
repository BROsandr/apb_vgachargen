module tb_no_input ();

  timeprecision 1ps;
  timeunit      1ns;

  logic clk;
  logic arst_n;

  localparam int unsigned CLK_PERIOD = 8;

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

  VGA_TextMode_topModule VGA_TextMode_topModule (
      .clk,
      .rst (~arst_n),
      .clk_25m (clk_25m),

//      .char_i (),
//      .addr_i (),
//      .wen_i  (),

      .R (),
      .G (),
      .B (),

      .hSYNC (),
      .vSYNC ()
  );

  initial begin
    reset();

    #1us;

    $finish();
  end
endmodule
