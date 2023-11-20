`timescale 1ns / 1ps


module VGA_TextMode_topModule
                (
                    input wire clk,
                    input wire rst,

                    input  wire [7:0]                 char_i,
                    input  wire [$clog2(80 * 30)-1:0] addr_i,
                    input  wire                       wen_i,

                    output wire [3:0]R, 
                    output wire [3:0]G, 
                    output wire [3:0]B,

                    output wire hSYNC,
                    output wire vSYNC
                );
                
                
                
localparam CHARACTER_SET_COUNT = 256;
localparam CHARACTER_ROM_MEMLOC = "CharacterROM_ASCII.mem";
localparam CHARACTER_BUFFER_MEMLOC = "characterBuffer80x60.mem";

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
                    .write_enable(wen_i),
                    .inputData(char_i),
                    .waddr_i (addr_i),

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

wire   currentPixel;
assign currentPixel = (pixelDrawing == 1) ? ~currentCharacter[characterXY] : 0;

assign R = (currentPixel) ? 4'hf: 4'b0;
assign B = (currentPixel) ? 4'hf: 4'b0;
assign G = (currentPixel) ? 4'hf: 4'b0;

endmodule
