
#define H_RES           256
#define V_RES           192
#define VRAM_TILES_H    32
#define VRAM_TILES_V    24
#define SBUF_OFS        32

                        .pasm
                        .compress off

                        .section .cog_scanline_renderer_256x192, "ax"

#include "scanline_renderer.inc"
