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

#include "defines.inc"

                        .org    0

                        mov     offset, PAR                 // Read row offset from PAR
                        shr     offset, #2                  // Note: PAR is 14 bits only! bits 0-1 are 00
                        and     offset, #$7

                        test    vram_expand_h_flag, PAR wz
        if_nz           add     _htiles1, #VRAM_TILES_H
        if_nz           add     _htiles2, #VRAM_TILES_H
        if_nz           add     _htiles3, #VRAM_TILES_H
        if_nz           add     _hmul1, #1
                        test    vram_expand_v_flag, PAR wz
        if_nz           add     _vsub1, #V_RES

vsync
                        rdlong  a, hub_fi wz
        if_nz           jmp     #$-1                        // wait for line counter reset (vsync)

                        mov     sbuf_ptr, #0
                        movd    _rd0, #sprites_table + MAX_SPRITES - 1
                        movd    _rd1, #sprites_table + MAX_SPRITES - 2
                        add     sbuf_ptr, #MAX_SPRITES * 4 -1
                        movi    sbuf_ptr, #MAX_SPRITES - 2
_rd0                    rdlong  0-0, sbuf_ptr
                        sub     _rd0, inc_dest_2
                        sub     sbuf_ptr, i2s7 wc
_rd1                    rdlong  0-0, sbuf_ptr
                        sub     _rd1, inc_dest_2
        if_nc           djnz    sbuf_ptr, #_rd0

                        mov     sbuf_ptr, hub_attributes_ptr
                        rdword  hub_tiles_data, sbuf_ptr
                        add     sbuf_ptr, #2
                        rdword  hub_sprites_data, sbuf_ptr
                        add     sbuf_ptr, #2
                        rdword  xs, sbuf_ptr
                        add     sbuf_ptr, #2
                        rdword  ys, sbuf_ptr

                        mov     scnt, offset

// tiles

loop
                        mov     loffs, scnt
                        add     loffs, ys
_vsub1                  cmpsub  loffs, #V_RES

#if VRAM_TILES_H == 40
                        mov     a, loffs
                        andn    a, #$07
                        mov     video_ptr, a
_hmul1                  shl     video_ptr, #2
                        add     video_ptr, a
#elif VRAM_TILES_H == 32
                        mov     video_ptr, loffs
                        shr     video_ptr, #3
_hmul1                  shl     video_ptr, #5
#endif

                        and     loffs, #7
                        shl     loffs, #3                   // 8-bytes per scanline
                        add     loffs, hub_tiles_data

                        test    xs, #%100 wz
        if_z            movd    str0, #sbuf
        if_nz           movd    str0, #sbuf-1
        if_z            movd    str1, #sbuf+1
        if_nz           movd    str1, #sbuf

                        mov     a, xs
                        shr     a, #3
                        add     video_ptr, a
                        add     video_ptr, hub_video_ram

_htiles1                mov     ccnt, #VRAM_TILES_H
                        sub     ccnt, a

                        mov     ecnt, #VRAM_TILES_H+1

_l1                     rdbyte  tile_ptr, video_ptr         // read tile number to display

                        shl     tile_ptr, #6                // 64 bytes per tile
                        add     tile_ptr, loffs

                        rdlong  colors1, tile_ptr           // pixels, 8 bit per pixel, from msb
                        and     colors1, color_mask
                        add     tile_ptr, #4
                        rdlong  colors2, tile_ptr
                        and     colors2, color_mask

str0                    mov     0-0, colors1
                        add     str0, inc_dest_2
str1                    mov     0-0, colors2
                        add     str1, inc_dest_2

                        add     video_ptr, #1
                        sub     ccnt, #1 wz
_htiles2    if_z        sub     video_ptr, #VRAM_TILES_H
_htiles3    if_z        mov     ccnt, #VRAM_TILES_H
                        djnz    ecnt, #_l1

// fine scroll

                        movs    _src1h,#sbuf
                        movs    _src2h,#sbuf+1
                        movd    _dst1h,#sbuf

                        mov     b, xs
                        and     b, #3 wz
                        shl     b, #3
                        mov     x, #32
                        sub     x, b

                        mov     ecnt, #H_RES/4

_src1h                  mov     colors1, 0-0
_src2h                  mov     colors2, 0-0

            if_nz       shr     colors1, b
            if_nz       shl     colors2, x
            if_nz       or      colors1, colors2

_dst1h                  mov     0-0, colors1

                        add     _src1h, #1
                        add     _src2h, #1
                        add     _dst1h, inc_dest

                        djnz    ecnt, #_src1h

// sprites

                        movs    _tile, #sprites_table       // Initialize sprite rendering
                        mov     pcnt, #MAX_SPRITES

_tile                   mov     tile, 0-0 wz
            if_z        jmp     #_next

                        test    tile, y_sign_mask wc        // check 9th bit
                        mov     y, tile
                        shl     y, #16
                        rcr     y, #24                      // sign-extend y
                        cmps    y, neg_clip wz,wc
            if_c        and     y, #$1FF                    // max -32

                        mov     h, tile                     // calculate height
                        shr     h, #25
                        and     h, #$18
                        add     h, #8

                        mov     a, scnt                     // check sprite scanline visibility
                        subs    a, y  wc,wz
            if_c        jmp     #_next
                        cmp     a, h wc,wz
            if_nc       jmp     #_next

                        test    tile, flip_mask wz          // adjust y if sprite is flipped
            if_nz       mov     y, h
            if_nz       sub     y, #1
            if_nz       sub     y, a
            if_nz       mov     a, y
                        shl     a, #3                       // 8-bits per pixel
                        shl     h, #3

                        mov     ecnt, tile                  // calculate width
                        shr     ecnt, #27
                        and     ecnt, #$18
                        add     ecnt, #8

                        mov     tile_ptr, tile
                        and     tile_ptr, tile_mask
                        shr     tile_ptr, #10
                        add     tile_ptr, hub_sprites_data

                        add     tile_ptr, a
                        test    tile, mirror_mask wz
                        cmp     ecnt, #16 wc
     if_nz_and_nc       add     tile_ptr, h
            if_nc       cmp     ecnt, #24 wc
     if_nz_and_nc       add     tile_ptr, h
            if_nc       cmp     ecnt, #32 wc
     if_nz_and_nc       add     tile_ptr, h
                        sumz    h, #4

                        test    tile, x_sign_mask wc        // check 9th bit
                        mov     x, tile
                        shl     x, #24
                        rcr     x, #24                      // sign-extend x
                        cmps    x, neg_clip wz,wc
            if_c        and     x, #$1FF                    // max -32

                        movd    _src0, #sbuf                // sets source and destination buffer pointers
                        movd    _src1, #sbuf+1
                        movd    _dst0, #sbuf
                        movd    _dst1, #sbuf+1

                        mov     a, x                        // adjust scanline buffer pointer to x location
                        sar     a, #2
                        shl     a, #9
                        add     _src0, a
                        add     _src1, a
                        add     _dst0, a
                        add     _dst1, a

                        and     x, #3
                        mov     ccnt, #8
                        sub     ccnt, x
                        shl     x, #3                       // 8-bits per pixel
                        mov     b, #32
                        sub     b, x

                        mov     pixels2, #0

_l2                     rdlong  data1, tile_ptr
                        xor     data1, transparency_mask
                        add     tile_ptr, #4
                        rdlong  data2, tile_ptr
                        xor     data2, transparency_mask

_l2b                    test    tile, mirror_mask wc
                        sumc    tile_ptr, h

            if_c        ror     data1, #24
            if_c        mov     a, data1
            if_c        and     a, swap_mask
            if_c        ror     data1, #16
            if_c        andn    data1, swap_mask
            if_c        or      a, data1

            if_c        ror     data2, #24
            if_c        mov     data1, data2
            if_c        and     data1, swap_mask
            if_c        ror     data2, #16
            if_c        andn    data2, swap_mask
            if_c        or      data1, data2

            if_c        mov     data2, a

                        mov     pixels1, data1
                        shl     pixels1, x
                        or      pixels1, pixels2
                        cmp     x, #0 wz
            if_nz       mov     pixels2, data1
                        shr     pixels2, b

                        mov     colors1, #0
                        test    pixels1, t_mask_0 wz
        if_z            or      colors1, mask_0
                        test    pixels1, t_mask_1 wz
        if_z            or      colors1, mask_1
                        test    pixels1, t_mask_2 wz
        if_z            or      colors1, mask_2
                        test    pixels1, t_mask_3 wz
        if_z            or      colors1, mask_3
_src0                   and     0-0, colors1
                        andn    pixels1, colors1
_dst0                   or      0-0, pixels1

                        mov     pixels1, data2
                        shl     pixels1, x
                        or      pixels1, pixels2
                        cmp     x, #0 wz
            if_nz       mov     pixels2, data2
                        shr     pixels2, b

                        mov     colors1, #0
                        test    pixels1, t_mask_0 wz
        if_z            or      colors1, mask_0
                        test    pixels1, t_mask_1 wz
        if_z            or      colors1, mask_1
                        test    pixels1, t_mask_2 wz
        if_z            or      colors1, mask_2
                        test    pixels1, t_mask_3 wz
        if_z            or      colors1, mask_3
_src1                   and     0-0, colors1
                        andn    pixels1, colors1
_dst1                   or      0-0, pixels1

                        sub     ecnt, ccnt  wc,wz
        if_z_or_c       jmp     #_next

                        add     _src0, inc_dest_2
                        add     _src1, inc_dest_2
                        add     _dst0, inc_dest_2
                        add     _dst1, inc_dest_2

                        mov     ccnt, #8
                        cmp     ecnt, #8  wc,wz
            if_nc       jmp     #_l2

                        mov     data1, #0
                        mov     data2, #0
                        jmp     #_l2b

_next                   add     _tile, #1
                        djnz    pcnt, #_tile


// scanline buffer output

emit
                        rdlong  a, hub_fi
                        cmp     a, scnt wz,wc
            if_ne       jmp     #$-2                        // wait for line fetch start

                        mov     sbuf_ptr, hub_sbuf
                        wrlong  sbuf, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 1, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 2, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 3, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 4, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 5, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 6, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 7, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 8, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 9, sbuf_ptr
                        add     sbuf_ptr, #4

                        movd    _wr0, #sbuf +(H_RES/4) -1
                        movd    _wr1, #sbuf +(H_RES/4) -2
                        add     sbuf_ptr, #(H_RES-40) -1
                        movi    sbuf_ptr, #((H_RES/4)-10) -2
_wr0                    wrlong  0-0, sbuf_ptr
                        sub     _wr0, inc_dest_2
                        sub     sbuf_ptr, i2s7 wc
_wr1                    wrlong  0-0, sbuf_ptr
                        sub     _wr1, inc_dest_2
            if_nc       djnz    sbuf_ptr, #_wr0

                        add     scnt, #COGS                 // next line to render
                        cmp     scnt, #V_RES wc,wz
            if_b        jmp     #loop

                        jmp     #vsync

// driver parameters

hub_video_ram           long    $0000 + (MAX_SPRITES * 4)
hub_tiles_data          long    $0000 + (MAX_SPRITES * 4)
hub_sprites_data        long    $0000 + (MAX_SPRITES * 4)

hub_attributes_ptr      long    $7EB0

hub_fi                  long    $7EBC
hub_sbuf                long    $7EC0 + SBUF_OFS

// initialised data and/or presets

inc_dest                long    1 << 9
inc_dest_2              long    2 << 9
i2s7                    long    2 << 23 | 7
mask_0                  long    $00_00_00_FF
mask_1                  long    $00_00_FF_00
mask_2                  long    $00_FF_00_00
mask_3                  long    $FF_00_00_00

swap_mask               long    $00_FF_00_FF

t_mask_0                long    %00000000_00000000_00000000_00000001
t_mask_1                long    %00000000_00000000_00000001_00000000
t_mask_2                long    %00000000_00000001_00000000_00000000
t_mask_3                long    %00000001_00000000_00000000_00000000

color_mask              long    %11111100_11111100_11111100_11111100
transparency_mask       long    %00000001_00000001_00000001_00000001

x_sign_mask             long    %00000001_00000000_00000000_00000000
y_sign_mask             long    %00000010_00000000_00000000_00000000
mirror_mask             long    %00000100_00000000_00000000_00000000
flip_mask               long    %00001000_00000000_00000000_00000000
tile_mask               long    %00000000_11111111_00000000_00000000

neg_clip                long    -32

pixels1                 long    0
pixels2                 long    0
colors1                 long    0
colors2                 long    0

vram_expand_h_flag      long    VRAM_EXPAND_H << 5
vram_expand_v_flag      long    VRAM_EXPAND_V << 5

// uninitialised data and/or temporaries

a                       res     1
b                       res     1
h                       res     1
x                       res     1
y                       res     1
data1                   res     1
data2                   res     1
tile                    res     1

offset                  res     1
loffs                   res     1
xs                      res     1
ys                      res     1

ecnt                    res     1
scnt                    res     1
ccnt                    res     1
pcnt                    res     1

tile_ptr                res     1
video_ptr               res     1

sprites_table           res     MAX_SPRITES

sbuf_ptr                res     8                           // Reserve some space for off-screen sprites
sbuf                    res     H_RES/4                     // All locations from here are reserved for the scanline buffer
                        res     8

                        fit     $1F0

/*
 * TERMS OF USE: MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
