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
wire pixelDrawing;

VGA_Block
                #
                (
                    .MODES(0) // finixing to 640 x 480 for 80 x60 text buffer
                )
                VGABLOCKIns
                (
                    .systemClk_125MHz(clk),
                    .rst(rst),

                    .xPixel(xPixel),
                    .yPixel(yPixel),
                    .pixelDrawing(pixelDrawing),

                    .hSYNC(hSYNC),
                    .vSYNC(vSYNC)
                );


wire [$clog2(80*30)-1:0]currentCharacterPixelIndex;
wire [$clog2(8 * 16)-1:0]characterXY;

TextMode_indexGenerator TMindexGenIns
                (
                    .xPixel(xPixel),
                    .yPixel(yPixel),

                    .currentCharacterPixelIndex(currentCharacterPixelIndex),
                    .characterXY(characterXY)
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
                    .clk(clk),
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
                    .clk(clk),
                    .enable(1),

                    .chracterIndex_addressIn(currentCharacterIndex),
                    .currentCharacter_dataOut(currentCharacter)
                );

  logic [7:0] color;
  logic [3:0] fg_color;
  logic [3:0] bg_color;

  assign fg_color = color[7:4];
  assign bg_color = color[3:0];

  true_dual_port_bram #(
    .INIT_FILE   (COL_MEMLOC),
    .DATA_WIDTH  (8),
    .DEPTH_WORDS (80 * 30)
  ) true_dual_port_bram (
    .clk_i   (clk),
    .addra_i (col_map_addr_i),
    .addrb_i (currentCharacterPixelIndex),
    .wea_i   (col_map_wen_i),
    .dina_i  (col_map_data_i),
    .douta_o (col_map_data_o),
    .doutb_o (color)
  );

wire   currentPixel;
assign currentPixel = (pixelDrawing == 1) ? ~currentCharacter[characterXY] : 0;

assign R = ~((currentPixel) ? fg_color: bg_color);
assign B = ~((currentPixel) ? fg_color: bg_color);
assign G = ~((currentPixel) ? fg_color: bg_color);

endmodule
