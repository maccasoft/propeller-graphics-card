/*
 * P8X Game System
 * Video Scanline Renderer
 *
 * 256 or 320 horizontal pixels lines
 * 6-bits per pixels (direct palette)
 * 8x8 pixels tiles
 * 8x8 up to 32x32 pixels sprites
 * Full-screen scrolling
 *
 * Copyright (c) 2015-2018 Marco Maccaferri
 * MIT Licensed.
 */

                        .pasm
                        .compress off

                        .equ    H_RES, 256
                        .equ    V_RES, 224
                        .equ    SBUF_OFS, 32

                        .section .cog_bitmap_scanline_renderer_256x224, "ax"

#include "bitmap_scanline_renderer.inc"
