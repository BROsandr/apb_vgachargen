module vgachargen_synth (
  input  logic            clk_i,             // системный синхроимпульс
  input  logic            clk100m_i,         // клок с частотой 100МГц
  input  logic            arstn_i,           // сигнал сброса

  output logic [3:0]      vga_r_o,           // красный канал vga
  output logic [3:0]      vga_g_o,           // зеленый канал vga
  output logic [3:0]      vga_b_o,           // синий канал vga
  output logic            vga_hs_o,          // линия горизонтальной синхронизации vga
  output logic            vga_vs_o           // линия вертикальной синхронизации vga
);
  logic  clk25m175;
  logic  locked;

  clk_wiz_0 clk_wiz_0 (
    // Clock out ports
    .clk25m175(clk25m175),     // output clk_out1
    // Status and control signals
    .resetn  (arstn_i), // input resetn
    .locked,       // output locked
    // Clock in ports
    .clk_in1 (clk_i)
  );      // input clk_in1

  logic  arstn;
  assign arstn = arstn_i & locked;

  vgachargen #(
    .CLK_FACTOR_25M (1)
  ) vgachargen (
      .clk_i            (clk_i),     // системный синхроимпульс
      .vga_clk_i        (clk25m175), // клок с частотой 25m175МГц
      .rst_i            (~arstn),    // сигнал сброса

      /*
          Интерфейс записи выводимого символа
      */
      .char_map_addr_i  ('0), // адрес позиции выводимого символа
      .char_map_ce_i    ('0),
      .char_map_we_i    ('0), // сигнал разрешения записи кода
      .char_map_be_i    ('0), // сигнал выбора байтов для записи
      .char_map_wdata_i ('0), // ascii-код выводимого символа
      .char_map_rdata_o (), // сигнал чтения кода символа

      /*
          Интерфейс установки цветовой схемы
      */
      .col_map_addr_i  ('0),   // адрес позиции устанавливаемой схемы
      .col_map_ce_i    ('0),
      .col_map_we_i    ('0),   // сигнал разрешения записи схемы
      .col_map_be_i    ('0),   // сигнал выбора байтов для записи
      .col_map_wdata_i ('0),   // код устанавливаемой цветовой схемы
      .col_map_rdata_o (),   // сигнал чтения кода схемы

      /*
          Интерфейс установки шрифта.
      */
      .char_tiff_addr_i  ('0), // адрес позиции устанавливаемого шрифта
      .char_tiff_ce_i    ('0),
      .char_tiff_we_i    ('0), // сигнал разрешения записи шрифта
      .char_tiff_wdata_i ('0), // отображаемые пиксели в текущей позиции шрифта
      .char_tiff_rdata_o (), // сигнал чтения пикселей шрифта

      .vga_r_o,           // красный канал vga
      .vga_g_o,           // зеленый канал vga
      .vga_b_o,           // синий канал vga
      .vga_hs_o,          // линия горизонтальной синхронизации vga
      .vga_vs_o           // линия вертикальной синхронизации vga
  );

endmodule
