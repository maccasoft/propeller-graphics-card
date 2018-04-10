
#define VRAM_TILES_H    32
#define VRAM_TILES_V    24

                        .pasm
                        .compress off

                        .section .cog_256x192_video_mode, "ax"

                        .org    0

                        jmp     #start

                        long    (191 << 16) | (VRAM_TILES_H * VRAM_TILES_V)

video_drivers           long    @__load_start_cog_ntsc_256x192_video_driver
                        long    @__load_start_cog_pal_256x192_video_driver
                        long    @__load_start_cog_vga_256x192_video_driver
                        long    @__load_start_cog_vga_256x192_video_driver

scanline_renderer       long    @__load_start_cog_scanline_renderer_256x192

#include "video_mode.inc"
