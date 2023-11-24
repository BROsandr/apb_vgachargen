module tb ();

  timeprecision 1ps;
  timeunit      1ns;

  logic factor_clk;
  logic sys_clk;
  logic arst_n;

  localparam int unsigned FACTOR_CLK_PERIOD = 40;
  localparam int unsigned SYS_CLK_PERIOD    = 100;

  initial begin
    factor_clk <= 0;
    forever #(FACTOR_CLK_PERIOD/2) factor_clk <= ~factor_clk;
  end

  initial begin
    sys_clk <= 0;
    forever #(SYS_CLK_PERIOD/2) sys_clk <= ~sys_clk;
  end

  task reset();
    arst_n <= 1'b0;
    #100;
    arst_n <= 1'b1;
  endtask

  import vgachargen_pkg::*;

  logic [3:0][7:0]                    col_map_data_i;
  logic [$clog2(2400/4)-1:0] col_map_addr_i;
  logic [3:0]                         col_map_wen_i;
  logic [3:0][7:0]  ch_map_data_i;
  logic [$clog2(2400/4)-1:0]  ch_map_addr_i;
  logic [3:0]                        ch_map_wen_i;
  logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_i;
  logic                          ch_t_rw_wen_i;
  logic [CH_T_ADDR_WIDTH-1:0]    ch_t_rw_addr_i;
  logic [31:0]  ch_map_data_o;
  logic [CH_T_DATA_WIDTH-1:0]    ch_t_rw_data_o;
  logic [31:0]                    col_map_data_o;

  vgachargen vgachargen(
    .factor_clk_i   (factor_clk),
    .sys_clk_i      (sys_clk),
    .factor_arstn_i (arst_n),
    .sys_arstn_i    (arst_n),

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

    @(posedge sys_clk);
    col_map_addr_i <= -10'h1;
    col_map_data_i <= '1;


    for (int i = 0; i < 2400 / 4; ++i) begin
      @(posedge sys_clk);
      col_map_data_i <= {4{counter}};
      col_map_wen_i  <= 4'b0010;
      col_map_addr_i <= col_map_addr_i + 10'h1;
      ++counter;
    end
    col_map_wen_i  <= 1'b0;
    col_map_addr_i <= 10'h0;
  endtask

  task read_col_map();
    bit fail = 0;
    byte counter = 0;

    @(posedge sys_clk);
    col_map_addr_i <= 10'h0;
    @(posedge sys_clk);
    @(posedge sys_clk);

    for (int i = 0; i < 2400/4-1; ++i) begin
      logic [31:0] col_map_data;
      col_map_addr_i <= col_map_addr_i + 10'h1;
      @(posedge sys_clk);
      col_map_data   = col_map_data_o;
      if ({col_map_data[31:8], 8'b0} != {counter, 8'b0}) begin
        fail = 1;
        $error("col_map_data mismatch. Expected %x, actual %x", {counter, 8'b0}, col_map_data);
        $stop;
      end
      ++counter;
    end
    col_map_addr_i <= 10'h0;

    if (!fail) $display("OK    :read_col_map");
    else       $display("ERROR :read_col_map");
  endtask

  task write_ch_map();
    bit [CH_MAP_DATA_WIDTH-1:0] counter = CH_MAP_DATA_WIDTH'(0);

    @(posedge sys_clk);
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(-1);
    ch_map_data_i <= '1;


    for (int i = 0; i < 30; ++i) begin
      for (int j = 0; j < 80; ++j) begin
        @(posedge sys_clk);
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

    @(posedge sys_clk);
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(0);
    @(posedge sys_clk);
    @(posedge sys_clk);

    for (int i = 0; i < 2399; ++i) begin
      logic [CH_MAP_DATA_WIDTH-1:0] ch_map_data;
      ch_map_addr_i <= ch_map_addr_i + CH_MAP_ADDR_WIDTH'(1);
      @(posedge sys_clk);
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

    @(posedge sys_clk);
    ch_t_rw_addr_i <= CH_T_ADDR_WIDTH'(-1);
    ch_t_rw_data_i <= '1;


    for (int i = 0; i < 128; ++i) begin
      @(posedge sys_clk);
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

    @(posedge sys_clk);
    ch_t_rw_addr_i <= CH_T_ADDR_WIDTH'(0);
    @(posedge sys_clk);
    @(posedge sys_clk);

    for (int i = 0; i < 128; ++i) begin
      logic [CH_T_DATA_WIDTH-1:0] ch_t_rw_data;
      ch_t_rw_addr_i <= ch_t_rw_addr_i + CH_T_ADDR_WIDTH'(1);
      @(posedge sys_clk);
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
