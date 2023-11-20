`timescale 1ns / 1ps


module VGA_TextMode_topModule
                (
                    input wire clk,
                    input wire rst,

                    input  wire [7:0]                 ch_map_data_i,
                    input  wire [7:0]                 col_map_data_i,
                    input  wire [7:0]                 col_map_data_o,
                    input  wire [$clog2(80 * 30)-1:0] ch_map_addr_i,
                    input  wire [$clog2(80 * 30)-1:0] col_map_addr_i,
                    input  wire                       ch_map_wen_i,
                    input  wire                       col_map_wen_i,
                    input  wire                       clk_25m,

                    output wire [3:0]R, 
                    output wire [3:0]G, 
                    output wire [3:0]B,

                    output wire hSYNC,
                    output wire vSYNC
                );
                
                
                
localparam CHARACTER_SET_COUNT = 256;
localparam CHARACTER_ROM_MEMLOC = "CharacterROM_ASCII.mem";
localparam CHARACTER_BUFFER_MEMLOC = "characterBuffer80x60.mem";
localparam COL_MEMLOC = "cols.mem";

wire [$clog2(640)-1:0]xPixel;
wire [$clog2(480)-1:0]yPixel;

reg [1:0] pixelDrawing_ff;
reg       pixelDrawing_next;

always @(posedge clk_25m) begin
  if (rst) pixelDrawing_ff <= '0;
  else     pixelDrawing_ff <= {pixelDrawing_ff[0], pixelDrawing_next};
end

  logic [1:0] hSYNC_ff;
  logic       hSYNC_next;
  logic [1:0] vSYNC_ff;
  logic       vSYNC_next;

VGA_Block
                #
                (
                    .MODES(0) // finixing to 640 x 480 for 80 x60 text buffer
                )
                VGABLOCKIns
                (
                    .systemClk_125MHz(clk),
                    .rst(rst),
                    .clk_25m(clk_25m),

                    .xPixel(xPixel),
                    .yPixel(yPixel),
                    .pixelDrawing(pixelDrawing_next),

                    .hSYNC(hSYNC_next),
                    .vSYNC(vSYNC_next)
                );


wire [$clog2(80*30)-1:0]currentCharacterPixelIndex;

reg [$clog2(8 * 16)-1:0] characterXY_ff1;
reg [$clog2(8 * 16)-1:0] characterXY_ff2;
reg [$clog2(8 * 16)-1:0] characterXY_next;

  always_ff @(clk_25m) begin
    if (rst) hSYNC_ff <= '0;
    else     hSYNC_ff <= {hSYNC_ff[0], hSYNC_next};
  end

  always_ff @(clk_25m) begin
    if (rst) vSYNC_ff <= '0;
    else     vSYNC_ff <= {vSYNC_ff[0], vSYNC_next};
  end

always @(posedge clk_25m) begin
  if (rst) {characterXY_ff2, characterXY_ff1} <= '0;
  else     {characterXY_ff2, characterXY_ff1} <= {characterXY_ff1, characterXY_next};
end

TextMode_indexGenerator TMindexGenIns
                (
                    .xPixel(xPixel),
                    .yPixel(yPixel),

                    .currentCharacterPixelIndex(currentCharacterPixelIndex),
                    .characterXY(characterXY_next)
                );



wire [$clog2(CHARACTER_SET_COUNT)-1:0]currentCharacterIndex;

TextMode_textBuffer80x60
                #
                (
                    .CHARACTER_SET_COUNT(CHARACTER_SET_COUNT),
                    .MEMFILELOC(CHARACTER_BUFFER_MEMLOC)
                )
                TMtextBuffIns
                (
                    .clk(clk_25m),
                    .enable(1),
                    .write_enable(ch_map_wen_i),
                    .inputData(ch_map_data_i),
                    .waddr_i (ch_map_addr_i),
                    .currentCharacterPixelIndex_addressIn(currentCharacterPixelIndex),

                    .currentCharacterIndex_dataOut(currentCharacterIndex)
                );

wire [16 * 8-1:0]currentCharacter;

TextMode_characterROM
                #
                (
                    .CHARACTER_SET_COUNT(CHARACTER_SET_COUNT),
                    .MEMFILELOC(CHARACTER_ROM_MEMLOC)
                )
                TMcharacterROMIns
                (
                    .clk(clk_25m),
                    .enable(1),

                    .chracterIndex_addressIn(currentCharacterIndex),
                    .currentCharacter_dataOut(currentCharacter)
                );

  logic [7:0]      color_next;
  logic [7:0] color_ff1;
  logic [7:0] color_ff2;
  logic [3:0] fg_color;
  logic [3:0] bg_color;

  assign fg_color = color_ff1[7:4];
  assign bg_color = color_ff1[3:0];

  true_dual_port_bram #(
    .INIT_FILE   (COL_MEMLOC),
    .DATA_WIDTH  (8),
    .DEPTH_WORDS (80 * 30)
  ) true_dual_port_bram (
    .clk_i   (clk_25m),
    .addra_i (col_map_addr_i),
    .addrb_i (currentCharacterPixelIndex),
    .wea_i   (col_map_wen_i),
    .dina_i  (col_map_data_i),
    .douta_o (col_map_data_o),
    .doutb_o (color_next)
  );

  always_ff @(clk_25m) begin
    if (rst) {color_ff2, color_ff1} <= '0;
    else     {color_ff2, color_ff1} <= {color_ff1, color_next};
  end

wire   currentPixel;
assign currentPixel = (pixelDrawing_ff[1] == 1) ? ~currentCharacter[characterXY_ff2] : 0;

assign R = pixelDrawing_ff[1] ? (~((currentPixel) ? fg_color: bg_color)) : '0;
assign B = pixelDrawing_ff[1] ? (~((currentPixel) ? fg_color: bg_color)) : '0;
assign G = pixelDrawing_ff[1] ? (~((currentPixel) ? fg_color: bg_color)) : '0;

  assign vSYNC = vSYNC_ff[1];
  assign hSYNC = hSYNC_ff[1];

endmodule
