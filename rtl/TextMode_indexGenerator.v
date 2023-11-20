`timescale 1ns / 1ps

module TextMode_indexGenerator
                (
                    input wire [$clog2(640)-1:0]xPixel,
                    input wire [$clog2(480)-1:0]yPixel,

                    output wire [$clog2(80*30)-1:0]currentCharacterPixelIndex,
                    output wire [$clog2(128)-1:0]characterXY
                );

wire [$clog2(80)-1:0]currentCharacterPixelIndex_x;
wire [$clog2(60)-1:0]currentCharacterPixelIndex_y;


assign currentCharacterPixelIndex_x = xPixel>>3;
assign currentCharacterPixelIndex_y = yPixel>>4;

assign currentCharacterPixelIndex = (currentCharacterPixelIndex_y<<6) + (currentCharacterPixelIndex_y<<4) + currentCharacterPixelIndex_x;


wire [$clog2(8) -1:0]characterX;
wire [$clog2(16)-1:0]characterY;

assign characterX = xPixel;

assign characterY = yPixel;

assign characterXY = (characterY<<3) + characterX;


endmodule
