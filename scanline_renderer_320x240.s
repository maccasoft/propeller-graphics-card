
#define H_RES           320
#define V_RES           240
#define VRAM_TILES_H    40
#define VRAM_TILES_V    30
#define SBUF_OFS        0

                        .pasm
                        .compress off

                        .section .cog_scanline_renderer_320x240, "ax"

#include "scanline_renderer.inc"
