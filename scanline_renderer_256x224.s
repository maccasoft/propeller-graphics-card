
#define H_RES           256
#define V_RES           224
#define VRAM_TILES_H    32
#define VRAM_TILES_V    28
#define SBUF_OFS        32

                        .pasm
                        .compress off

                        .section .cog_scanline_renderer_256x224, "ax"

#include "scanline_renderer.inc"
