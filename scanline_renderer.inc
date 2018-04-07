/*
 * P8X Game System
 * Video Scanline Renderer
 *
 * 256 or 320 horizontal pixels lines
 * 6-bits per pixels (direct palette)
 * 8x8 pixels tiles
 * 8x8 up to 32x32 pixels sprites
 *
 * Copyright (c) 2015-2018 Marco Maccaferri
 * MIT Licensed.
 */

                        .org    0

                        mov     offset, PAR                 // Read row offset from PAR
                        shr     offset, #2                  // Note: PAR is 14 bits only! bits 0-1 are 00
                        and     offset, #$7

vsync
                        rdlong  a, hub_fi wz
            if_nz       jmp     #$-1                        // wait for line counter reset (vsync)

                        mov     sbuf_ptr, hub_sprite_ram
                        movd    _rd0, #sprites_table + MAX_SPRITES - 1
                        movd    _rd1, #sprites_table + MAX_SPRITES - 2
                        add     sbuf_ptr, #MAX_SPRITES * 4 -1
                        movi    sbuf_ptr, #MAX_SPRITES - 2
_rd0                    rdlong  0-0, sbuf_ptr
                        sub     _rd0, inc_dest_2
                        sub     sbuf_ptr, i2s7 wc
_rd1                    rdlong  0-0, sbuf_ptr
                        sub     _rd1, inc_dest_2
            if_nc       djnz    sbuf_ptr, #_rd0

                        rdword  hub_tiles_data, hub_tiles_ptr
                        rdword  hub_sprites_data, hub_sprites_ptr

                        mov     roffs, #0
                        mov     loffs, offset
                        shl     loffs, #3                   // 8 bytes per scanline
                        mov     scnt, offset

loop
                        mov     video_ptr, hub_video_ram
                        add     video_ptr, roffs

                        add     loffs, hub_tiles_data

                        movd    str0, #sbuf
                        movd    str1, #sbuf+1
                        mov     ecnt, #VRAM_TILES_H

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
                        djnz    ecnt, #_l1

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

            if_z        sub     h, #4
            if_nz       add     h, #4

                        test    tile, x_sign_mask wc        // check 9th bit
                        mov     x, tile
                        shl     x, #24
                        rcr     x, #24                      // sign-extend x
                        cmps    x, neg_clip wz,wc
            if_c        and     x, #$1FF                    // max -32

                        movs    _src0, #sbuf                // sets source and destination buffer pointers
                        movs    _src1, #sbuf+1
                        movd    _dst0, #sbuf
                        movd    _dst1, #sbuf+1

                        mov     a, x                        // adjust scanline buffer pointer to x location
                        sar     a, #2
                        add     _src0, a
                        add     _src1, a
                        shl     a, #9
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

_src0                   mov     colors1, 0-0
_src1                   mov     colors2, 0-0

            if_nc       add     tile_ptr, h
            if_c        sub     tile_ptr, h

            if_nc       mov     pixels1, data1
            if_nc       shl     pixels1, x
            if_c        mov     pixels1, data2
            if_c        shr     pixels1, x
                        or      pixels1, pixels2
                        cmp     x, #0 wz
     if_nz_and_nc       mov     pixels2, data1
            if_nc       shr     pixels2, b
     if_nz_and_c        mov     pixels2, data2
            if_c        shl     pixels2, b

            if_c        ror     colors1, #24
                        mov     a, pixels1
                        and     a, mask_0 wz
            if_nz       andn    colors1, mask_0
            if_nz       or      colors1, a
                        mov     a, pixels1
                        and     a, mask_2 wz
            if_nz       andn    colors1, mask_2
            if_nz       or      colors1, a
            if_c        ror     colors1, #16
                        mov     a, pixels1
                        and     a, mask_1 wz
            if_nz       andn    colors1, mask_1
            if_nz       or      colors1, a
                        and     pixels1, mask_3 wz
            if_nz       andn    colors1, mask_3
            if_nz       or      colors1, pixels1
            if_c        rol     colors1, #8

            if_nc       mov     pixels1, data2
            if_nc       shl     pixels1, x
            if_c        mov     pixels1, data1
            if_c        shr     pixels1, x
                        or      pixels1, pixels2
                        cmp     x, #0 wz
     if_nz_and_nc       mov     pixels2, data2
            if_nc       shr     pixels2, b
     if_nz_and_c        mov     pixels2, data1
            if_c        shl     pixels2, b

            if_c        ror     colors2, #24
                        mov     a, pixels1
                        and     a, mask_0 wz
            if_nz       andn    colors2, mask_0
            if_nz       or      colors2, a
                        mov     a, pixels1
                        and     a, mask_2 wz
            if_nz       andn    colors2, mask_2
            if_nz       or      colors2, a
            if_c        ror     colors2, #16
                        mov     a, pixels1
                        and     a, mask_1 wz
            if_nz       andn    colors2, mask_1
            if_nz       or      colors2, a
                        and     pixels1, mask_3 wz
            if_nz       andn    colors2, mask_3
            if_nz       or      colors2, pixels1
            if_c        rol     colors2, #8

                        and     colors1, color_mask
                        and     colors2, color_mask
_dst0                   mov     0-0, colors1
_dst1                   mov     0-0, colors2

                        sub     ecnt, ccnt  wc,wz
        if_z_or_c       jmp     #_next

                        add     _src0, #2
                        add     _src1, #2
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

emit
                        rdlong  a, hub_fi
                        cmp     a, scnt wz,wc
            if_ne       jmp     #$-2                        // wait for line fetch start

                        mov     sbuf_ptr, hub_sbuf
#if H_RES == 320
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
#else
                        movd    _wr0, #sbuf +(H_RES/4) -1
                        movd    _wr1, #sbuf +(H_RES/4) -2
                        add     sbuf_ptr, #H_RES -1
                        movi    sbuf_ptr, #(H_RES/4) -2
#endif
_wr0                    wrlong  0-0, sbuf_ptr
                        sub     _wr0, inc_dest_2
                        sub     sbuf_ptr, i2s7 wc
_wr1                    wrlong  0-0, sbuf_ptr
                        sub     _wr1, inc_dest_2
            if_nc       djnz    sbuf_ptr, #_wr0

                        sub     loffs, hub_tiles_data
                        add     loffs, #COGS<<3             // next line offset
                        cmpsub  loffs, #8<<3 wc
            if_c        add     roffs, #VRAM_TILES_H

                        add     scnt, #COGS                 // next line to render
                        cmp     scnt, #V_RES wc,wz
            if_b        jmp     #loop

                        jmp     #vsync

// driver parameters

hub_sprite_ram          long    $0000
hub_video_ram           long    $0000 + (MAX_SPRITES * 4)
hub_tiles_data          long    $0000 + (MAX_SPRITES * 4) + (40 * 30)
hub_sprites_data        long    $0000 + (MAX_SPRITES * 4) + (40 * 30)
hub_tiles_ptr           long    $7EB0
hub_sprites_ptr         long    $7EB2
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
roffs                   res     1
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
