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
  logic [9:0] col_map_addr_i;
  logic [3:0]                         col_map_wen_i;
  logic [3:0][7:0]  ch_map_data_i;
  logic [9:0]  ch_map_addr_i;
  logic [3:0]                        ch_map_wen_i;
  logic [31:0]    ch_t_rw_data_i;
  logic                          ch_t_rw_wen_i;
  logic [11:0]    ch_t_rw_addr_i;
  logic [31:0]  ch_map_data_o;
  logic [31:0]    ch_t_rw_data_o;
  logic [31:0]                    col_map_data_o;

  vgachargen vgachargen(
    .clk_i     (sys_clk),             // системный синхроимпульс
    .vga_clk_i (factor_clk),         // клок с частотой 100МГц
    .rst_i     (arst_n),             // сигнал сброса

    .char_map_addr_i  (ch_map_addr_i),   // адрес позиции выводимого символа
    .char_map_we_i    (|ch_map_wen_i),     // сигнал разрешения записи кода
    .char_map_be_i   (ch_map_wen_i),  // сигнал выбора байтов для записи
    .char_map_wdata_i (ch_map_data_i),  // ascii-код выводимого символа
    .char_map_rdata_o (ch_map_data_o),  // сигнал чтения кода символа
    .col_map_addr_i   (col_map_addr_i),    // адрес позиции устанавливаемой схемы
    .col_map_we_i     (|col_map_wen_i),      // сигнал разрешения записи схемы
    .col_map_be_i     (col_map_wen_i),      // сигнал выбора байтов для записи
    .col_map_wdata_i  (col_map_data_i),   // код устанавливаемой цветовой схемы
    .col_map_rdata_o  (col_map_data_o),   // сигнал чтения кода схемы

   .char_tiff_addr_i (ch_t_rw_addr_i),  // адрес позиции устанавливаемого шрифта
   .char_tiff_we_i   (ch_t_rw_wen_i),    // сигнал разрешения записи шрифта
//    .char_tiff_be_i   (),    // сигнал выбора байтов для записи
   .char_tiff_wdata_i(ch_t_rw_data_i), // отображаемые пиксели в текущей позиции шрифта
   .char_tiff_rdata_o(ch_t_rw_data_o), // сигнал чтения пикселей шрифта

    .vga_r_o (),           // красный канал vga
    .vga_g_o (),           // зеленый канал vga
    .vga_b_o (),           // синий канал vga
    .vga_hs_o (),          // линия горизонтальной синхронизации vga
    .vga_vs_o ()           // линия вертикальной синхронизации vga
  );

  task write_col_map();
    byte counter = 0;

    @(posedge sys_clk);
    col_map_addr_i <= -10'h1;
    col_map_data_i <= '1;


    for (int i = 0; i < 2400 / 4; ++i) begin
      @(posedge sys_clk);
      col_map_data_i <= {4{counter}};
      col_map_wen_i  <= 4'b1111;
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
      if (col_map_data !== {4{counter}}) begin
        fail = 1;
        $error("col_map_data mismatch. Expected %x, actual %x", counter, col_map_data);
        $stop;
      end
      ++counter;
    end
    col_map_addr_i <= 10'h0;

    if (!fail) $display("OK    :read_col_map");
    else       $display("ERROR :read_col_map");
  endtask

  task write_ch_map();
    bit [31:0] counter = CH_MAP_DATA_WIDTH'(0);

    @(posedge sys_clk);
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(-1);
    ch_map_data_i <= '1;


    for (int i = 0; i < 600; ++i) begin
      @(posedge sys_clk);
      ch_map_data_i <= counter;
      ch_map_wen_i  <= 4'b1111;
      ch_map_addr_i <= ch_map_addr_i + CH_MAP_ADDR_WIDTH'(1);
      ++counter;
    end
    ch_map_wen_i  <= 1'b0;
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(0);
  endtask

  task read_ch_map();
    bit fail = 0;
    bit [31:0] counter = 32'h0;

    @(posedge sys_clk);
    ch_map_addr_i <= CH_MAP_ADDR_WIDTH'(0);
    @(posedge sys_clk);
    @(posedge sys_clk);

    for (int i = 0; i < 599; ++i) begin
      logic [31:0] ch_map_data;
      ch_map_addr_i <= ch_map_addr_i + 32'h1;
      @(posedge sys_clk);
      ch_map_data   = ch_map_data_o;
      if (ch_map_data !== counter) begin
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
    bit [31:0] counter = '0;

    @(posedge sys_clk);
    ch_t_rw_addr_i <= -12'd4;
    ch_t_rw_data_i <= '1;


    for (int i = 0; i < 256 * 4; ++i) begin
      @(posedge sys_clk);
      ch_t_rw_data_i <= counter;
      ch_t_rw_wen_i  <= 1'b1;
      ch_t_rw_addr_i <= ch_t_rw_addr_i + 12'd4;
      ++counter;
    end
    ch_t_rw_wen_i  <= 1'b0;
    ch_t_rw_addr_i <= '0;
  endtask

  task read_ch_t_rw();
    bit fail = 0;
    bit [31:0] counter = '0;

    @(posedge sys_clk);
    ch_t_rw_addr_i <= '0;
    @(posedge sys_clk);
    @(posedge sys_clk);

    for (int i = 0; i < 256 * 4 - 1; ++i) begin
      logic [31:0] ch_t_rw_data;
      ch_t_rw_addr_i <= ch_t_rw_addr_i + 12'd4;
      @(posedge sys_clk);
      ch_t_rw_data   = ch_t_rw_data_o;
      if (ch_t_rw_data !== counter) begin
        fail = 1;
        $error("ch_t mismatch. Expected %x, actual %x", counter, ch_t_rw_data);
        $stop;
      end
      ++counter;
    end
    ch_t_rw_addr_i <= '0;

    if (!fail) $display("OK    :read_ch_t");
    else       $display("ERROR :read_ch_t");
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
