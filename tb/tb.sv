module tb ();

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

  import vgachargen_pkg::*;

  logic [7:0]                    col_map_data_i;
  logic [COL_MAP_ADDR_WIDTH-1:0] col_map_addr_i;
  logic                          col_map_wen_i;
  logic [CH_MAP_DATA_WIDTH-1:0]  ch_map_data_i;
  logic [CH_MAP_ADDR_WIDTH-1:0]  ch_map_addr_i;
  logic                          ch_map_wen_i;
  logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_i;
  logic                          ch_t_rw_wen_i;
  logic [CH_T_ADDR_WIDTH-1:0]    ch_t_rw_addr_i;
  logic [CH_MAP_DATA_WIDTH-1:0]  ch_map_data_o;
  logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_o;
  logic [7:0]                    col_map_data_o;

  vgachargen vgachargen(
    .clk_i   (clk),
    .arstn_i (arst_n),

    .vga_r_o (),
    .vga_b_o (),
    .vga_g_o (),

    .col_map_data_i(col_map_data_i),
    .col_map_data_o(col_map_data_o),
    .col_map_addr_i(col_map_addr_i),
    .col_map_wen_i (col_map_wen_i),
    .ch_map_data_i (ch_map_data_i),
    .ch_map_data_o (ch_map_data_o),
    .ch_map_addr_i (ch_map_addr_i),
    .ch_map_wen_i  (ch_map_wen_i),
    .ch_t_rw_data_i(ch_t_rw_data_i),
    .ch_t_rw_data_o(ch_t_rw_data_o),
    .ch_t_rw_wen_i (ch_t_rw_wen_i),
    .ch_t_rw_addr_i(ch_t_rw_addr_i),

    .vga_hs_o      (),
    .vga_vs_o      ()
  );

  task write_col_map();
    byte counter = 0;

    @(posedge clk);
    col_map_addr_i <= COL_MAP_ADDR_WIDTH'(-1);
    col_map_data_i <= '1;


    for (int i = 0; i < 30; ++i) begin
      for (int j = 0; j < 80; ++j) begin
        @(posedge clk);
        col_map_data_i <= counter;
        col_map_wen_i  <= 1'b1;
        col_map_addr_i <= col_map_addr_i + COL_MAP_ADDR_WIDTH'(1);
        ++counter;
      end
    end
    col_map_wen_i  <= 1'b0;
    col_map_addr_i <= COL_MAP_ADDR_WIDTH'(0);
  endtask

  task read_col_map();
    bit fail = 0;
    byte counter = 0;

    @(posedge clk);
    col_map_addr_i <= COL_MAP_ADDR_WIDTH'(0);
    @(posedge clk);
    @(posedge clk);

    for (int i = 0; i < 2399; ++i) begin
      logic [7:0] col_map_data;
      col_map_addr_i <= col_map_addr_i + COL_MAP_ADDR_WIDTH'(1);
      @(posedge clk);
      col_map_data   = col_map_data_o;
      if (col_map_data != counter) begin
        fail = 1;
        $error("col_map_data mismatch. Expected %x, actual %x", counter, col_map_data);
        $stop;
      end
      ++counter;
    end
    col_map_addr_i <= COL_MAP_ADDR_WIDTH'(0);

    if (!fail) $display("OK    :read_col_map");
    else       $display("ERROR :read_col_map");
  endtask

  task write_ch_map();
    bit [CH_MAP_DATA_WIDTH-1:0] counter = CH_MAP_DATA_WIDTH'(0);

    @(posedge clk);
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(-1);
    ch_map_data_i <= '1;


    for (int i = 0; i < 30; ++i) begin
      for (int j = 0; j < 80; ++j) begin
        @(posedge clk);
        ch_map_data_i <= counter;
        ch_map_wen_i  <= 1'b1;
        ch_map_addr_i <= ch_map_addr_i + CH_MAP_ADDR_WIDTH'(1);
        ++counter;
      end
    end
    ch_map_wen_i  <= 1'b0;
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(0);
  endtask

  task read_ch_map();
    bit fail = 0;
    bit [CH_MAP_DATA_WIDTH-1:0] counter = CH_MAP_DATA_WIDTH'(0);

    @(posedge clk);
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(0);
    @(posedge clk);
    @(posedge clk);

    for (int i = 0; i < 2399; ++i) begin
      logic [CH_MAP_DATA_WIDTH-1:0] ch_map_data;
      ch_map_addr_i <= ch_map_addr_i + CH_MAP_ADDR_WIDTH'(1);
      @(posedge clk);
      ch_map_data   = ch_map_data_o;
      if (ch_map_data != counter) begin
        fail = 1;
        $error("ch_map_data mismatch. Expected %x, actual %x", counter, ch_map_data);
        $stop;
      end
      ++counter;
    end
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(0);

    if (!fail) $display("OK    :read_ch_map");
    else       $display("ERROR :read_ch_map");
  endtask

  task write_ch_t_rw();
    bit [CH_T_DATA_WIDTH-1:0] counter = CH_T_DATA_WIDTH'(0);

    @(posedge clk);
    ch_t_rw_addr_i <= CH_T_ADDR_WIDTH'(-1);
    ch_t_rw_data_i <= '1;


    for (int i = 0; i < 128; ++i) begin
      @(posedge clk);
      ch_t_rw_data_i <= counter;
      ch_t_rw_wen_i  <= 1'b1;
      ch_t_rw_addr_i <= ch_t_rw_addr_i + CH_T_ADDR_WIDTH'(1);
      ++counter;
    end
    ch_t_rw_wen_i  <= 1'b0;
    ch_t_rw_addr_i <= CH_T_ADDR_WIDTH'(0);
  endtask

  task read_ch_t_rw();
    bit fail = 0;
    bit [CH_T_DATA_WIDTH-1:0] counter = CH_T_DATA_WIDTH'(0);

    @(posedge clk);
    ch_t_rw_addr_i <= CH_T_ADDR_WIDTH'(0);
    @(posedge clk);
    @(posedge clk);

    for (int i = 0; i < 128; ++i) begin
      logic [CH_T_DATA_WIDTH-1:0] ch_t_rw_data;
      ch_t_rw_addr_i <= ch_t_rw_addr_i + CH_T_ADDR_WIDTH'(1);
      @(posedge clk);
      ch_t_rw_data   = ch_t_rw_data_o;
      if (ch_t_rw_data != counter) begin
        fail = 1;
        $error("ch_map_data mismatch. Expected %x, actual %x", counter, ch_t_rw_data);
        $stop;
      end
      ++counter;
    end
    ch_t_rw_addr_i <= CH_T_ADDR_WIDTH'(0);

    if (!fail) $display("OK    :read_ch_t_rw");
    else       $display("ERROR :read_ch_t_rw");
  endtask

  initial begin
    reset();

    write_col_map();
    read_col_map();
    write_ch_map();
    read_ch_map();
    write_ch_t_rw();
    read_ch_t_rw();

    #1us;

    $finish();
  end
endmodule
