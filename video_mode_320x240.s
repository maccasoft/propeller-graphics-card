
#define VRAM_TILES_H    40
#define VRAM_TILES_V    30

                        .pasm
                        .compress off

                        .section .cog_320x240_video_mode, "ax"

                        .org    0

                        jmp     #start

                        long    (239 << 16) | (VRAM_TILES_H * VRAM_TILES_V)

video_drivers           long    @__load_start_cog_ntsc_320x240_video_driver
                        long    @__load_start_cog_pal_320x240_video_driver
                        long    @__load_start_cog_vga_320x240_video_driver
                        long    @__load_start_cog_vga_320x240_video_driver

scanline_renderer       long    @__load_start_cog_scanline_renderer_320x240

#include "video_mode.inc"
