/*
 * Propeller Graphics Card for RC2014 Computer
 * TMS9918 Emulation Firmware
 *
 * Copyright (c) 2018 Marco Maccaferri
 * MIT Licensed.
 */

#include "../defines.inc"

                        .pasm
                        .compress off

                        .section .cog_scanline_renderer, "ax"

                                                            // register 0 control bits
                        .equ    TMSMODE3,   %00000010       //       mode bit 3
                        .equ    TMSEXTVID,  %00000001       //       external video

                                                            // register 1 control bits
                        .equ    TMS4K16K,   %10000000       //       4/16K RAM
                        .equ    TMSBLANK,   %01000000       //       screen blank
                        .equ    TMSINTEN,   %00100000       //       interrupt enable
                        .equ    TMSMODE1,   %00010000       //       mode bit 1
                        .equ    TMSMODE2,   %00001000       //       mode bit 2
                        .equ    TMSSPRSIZE, %00000010       //       sprite size
                        .equ    TMSSPRMAG,  %00000001       //       sprite magnification

                        .equ    TMSSPRITES, 32


                        .org    0

vsync
                        rdlong  a, hub_fi wz
            if_nz       jmp     #$-1                        // wait for line counter reset (vsync)

                        mov     scnt, PAR                   // Read row offset from PAR
                        shr     scnt, #2                    // Note: PAR is 14 bits only! bits 0-1 are 00
                        and     scnt, #$7

loop
                        mov     sbuf_ptr, hub_registers
                        rdbyte  register0, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register1, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register2, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register3, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register4, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register5, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register6, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  register7, sbuf_ptr

                        shl     register2, #10              // name table base address * $400
                        shl     register3, #6               // color table base address * $40
                        shl     register4, #11              // pattern generator base address * $800
                        shl     register5, #7               // sprite attribute table base address * $80
                        shl     register6, #11              // sprite pattern generator base address * $800

                        mov     a, register7
                        and     a, #$0F
                        add     a, #palette
                        movs    bd, a

                        test    register1, #TMSBLANK wz     // blank screen flag
bd                      mov     backdrop, 0-0
        if_z            mov     backdrop, #0
        if_z            jmp     #border

                        // top and bottom borders

                        cmp     scnt, #24 wc
        if_c            jmp     #border
                        cmp     scnt, #24+192 wc
        if_c            jmp     #visible

border                  movd    _dst1, #sbuf
                        mov     ecnt, #64
_dst1                   mov     0-0, backdrop
                        add     _dst1, inc_dest
                        djnz    ecnt, #$-2
                        jmp     #emit

                        // visible part

visible
                        mov     lcnt, scnt
                        sub     lcnt, #24                   // subtract top border offset

                        test    register1, #TMSMODE2 wz     // multicolor mode
        if_nz           jmp     #multicolor_mode

                        mov     a, lcnt                     // row offset into pattern generator
                        and     a, #7

                        test    register0, #TMSMODE3 wz     // graphics mode II
        if_nz           andn    register3, vdp_8k_mask      // limit color table to 8k boundaries
        if_nz           andn    register4, vdp_8k_mask      // limit pattern table to 8k boundaries

        if_nz           mov     b, lcnt
        if_nz           shr     b, #6                       // divide by 64 (8 rows by 8 pixels)
        if_nz           shl     b, #11                      // multiply by 2048
        if_nz           add     a, b

        if_nz           add     register3, a                // row offset into color table
                        add     register4, a

                        test    register1, #TMSMODE1 wz     // text mode

                        andn    lcnt, #$07                  // divide and multiply by 8
                        mov     a, lcnt
                        shl     a, #2                       // multiply by 32
        if_nz           add     a, lcnt                     // multiply by 40
                        add     register2, a

        if_z            jmp     #graphics_mode

// 40 patterns per row

text_mode
                        mov     sbuf, backdrop
                        mov     sbuf+1, backdrop
                        mov     sbuf+62, backdrop
                        mov     sbuf+63, backdrop

                        mov     ecnt, #20
                        movd    _dst5, #sbuf+2
                        movd    _dst6, #sbuf+2+1
                        movd    _dst7, #sbuf+2+2

                        mov     a, register7
                        and     a, #$0F
                        add     a, #palette
                        movs    _c0t, a

                        shr     register7, #4
                        and     register7, #$0F
                        add     register7, #palette
                        movs    _c1t, register7

_c0t                    mov     colors0, 0-0
                        and     colors0, #$FF
_c1t                    mov     colors1, 0-0
                        and     colors1, #$FF

rloop40                 rdbyte  tile_ptr, register2         // read tile number to display
                        shl     tile_ptr, #3                // 8 bytes per tile
                        add     tile_ptr, register4
                        rdbyte  tile, tile_ptr              // pixels, 1 bit per pixel, from msb

                        add     register2, #1
                        rdbyte  tile_ptr, register2         // read tile number to display
                        shl     tile_ptr, #3                // 8 bytes per tile
                        add     tile_ptr, register4
                        rdbyte  data, tile_ptr              // pixels, 1 bit per pixel, from msb

                        shl     tile, #6
                        or      tile, data
                        shr     tile, #2

                        mov     pixels1, #0
                        mov     pixels2, #0
                        mov     pixels3, #0
                        mov     ccnt, #4
                        test    tile, #%1_0000_0000 wz
        if_z            or      pixels1, colors0
        if_nz           or      pixels1, colors1
                        test    tile, #%0_0001_0000 wz
        if_z            or      pixels2, colors0
        if_nz           or      pixels2, colors1
                        test    tile, #%0_0000_0001 wz
        if_z            or      pixels3, colors0
        if_nz           or      pixels3, colors1
                        shr     tile, #1
                        ror     pixels1, #8
                        ror     pixels2, #8
                        ror     pixels3, #8
                        djnz    ccnt, #$-13

_dst5                   mov     0-0, pixels1
                        add     _dst5, inc_dest_3
_dst6                   mov     0-0, pixels2
                        add     _dst6, inc_dest_3
_dst7                   mov     0-0, pixels3
                        add     _dst7, inc_dest_3

                        add     register2, #1
                        djnz    ecnt, #rloop40
                        jmp     #emit

// 32 patterns per row

multicolor_mode
                        mov     a, lcnt
                        shr     a, #2
                        and     a, #$07
                        add     register4, a

                        andn    lcnt, #$07                  // divide and multiply by 8
                        shl     lcnt, #2                    // multiply by 32
                        add     register2, lcnt

                        mov     ecnt, #32
                        movd    _dst10, #sbuf
                        movd    _dst11, #sbuf+1

rloop64                 rdbyte  tile_ptr, register2         // read tile number to display
                        shl     tile_ptr, #3
                        add     tile_ptr, register4         // points to color table

                        rdbyte  a, tile_ptr                 // colors

                        mov     colors0, a
                        shr     colors0, #4
                        test    colors0, #$0F wz
        if_z            mov     colors0, register7
                        and     colors0, #$0F
                        add     colors0, #palette
                        movs    _dst10, colors0

                        mov     colors1, a
                        test    colors1, #$0F wz
        if_z            mov     colors1, register7
                        and     colors1, #$0F
                        add     colors1, #palette
                        movs    _dst11, colors1

_dst10                  mov     0-0, 1-1
                        add     _dst10, inc_dest_2

_dst11                  mov     0-0, 1-1
                        add     _dst11, inc_dest_2

                        add     register2, #1
                        djnz    ecnt, #rloop64

                        jmp     #sprites

// 32 patterns per row

graphics_mode
                        mov     ecnt, #32
                        movd    _dst8, #sbuf
                        movd    _dst9, #sbuf+1

rloop32                 rdbyte  tile_ptr, register2         // read tile number to display

                        mov     ptr, tile_ptr
                        test    register0, #TMSMODE3 wz     // graphics mode II
        if_nz           shl     ptr, #3
        if_z            shr     ptr, #3
                        add     ptr, register3              // points to color table
                        rdbyte  a, ptr                      // colors

                        mov     b, a
                        test    b, #$0F wz
        if_z            mov     b, register7
                        and     b, #$0F
                        add     b, #palette
                        movs    _c0g, b

                        shr     a, #4
                        test    a, #$0F wz
        if_z            mov     a, register7
                        and     a, #$0F
                        add     a, #palette
                        movs    _c1g, a

_c0g                    mov     colors0, 0-0
                        and     colors0, #$FF
_c1g                    mov     colors1, 0-0
                        and     colors1, #$FF

                        shl     tile_ptr, #3                // 8 bytes per tile
                        add     tile_ptr, register4
                        rdbyte  tile, tile_ptr              // pixels, 1 bit per pixel, from msb

                        mov     pixels1, #0
                        mov     pixels2, #0
                        mov     ccnt, #4
                        test    tile, #%0001_0000 wz
        if_z            or      pixels1, colors0
        if_nz           or      pixels1, colors1
                        test    tile, #%0000_0001 wz
        if_z            or      pixels2, colors0
        if_nz           or      pixels2, colors1
                        shr     tile, #1
                        ror     pixels1, #8
                        ror     pixels2, #8
                        djnz    ccnt, #$-9

_dst8                   mov     0-0, pixels1
                        add     _dst8, inc_dest_2
_dst9                   mov     0-0, pixels2
                        add     _dst9, inc_dest_2

                        add     register2, #1
                        djnz    ecnt, #rloop32

                        // fall through

sprites
                        mov     lcnt, #4
                        mov     pcnt, #32

                        mov     b, #8
                        test    register1, #TMSSPRSIZE wz
        if_nz           shl     b, #1
                        test    register1, #TMSSPRMAG wz
        if_nz           shl     b, #1

_sprite_loop            rdlong  tile, register5

                        mov     y, tile
                        shl     y, #24
                        sar     y, #24                      // sign-extend y
                        cmps    y, neg_clip wz,wc
        if_c            and     y, #$FF                     // max -32
                        cmp     y, #$D0 wz                  // end of sprites processing
        if_z            jmp     #emit

                        mov     a, scnt                     // check sprite scanline visibility
                        sub     a, #24
                        subs    a, y wc,wz
        if_c            jmp     #_next
                        cmp     a, b wc,wz
        if_nc           jmp     #_next

                        mov     tile_ptr, tile
                        shr     tile_ptr, #16
                        and     tile_ptr, #$FF
                        shl     tile_ptr, #3
                        add     tile_ptr, register6
                        test    register1, #TMSSPRMAG wz
        if_nz           shr     a, #1
                        add     tile_ptr, a

                        mov     a, tile                     // set pixel color
                        shr     a, #24
                        test    a, #$0F wz
        if_z            mov     a, register7
                        and     a, #$0F
                        add     a, #palette
                        movs    _st1, a

                        mov     x, tile
                        shr     x, #8
                        and     x, #$FF
                        test    tile, TMSEARLYCLK wz
        if_nz           sub     x, #32

                        mov     a, x                        // adjust scanline buffer pointer to x location
                        shr     a, #2
                        add     a, #sbuf
                        movs    _ssrc, a
                        movd    _sdst, a

                        and     x, #3

                        test    register1, #TMSSPRSIZE wz
                        test    register1, #TMSSPRMAG wc

                        rdbyte  pixels1, tile_ptr
                        shl     pixels1, #8
        if_nz           add     tile_ptr, #16
        if_nz           rdbyte  pixels2, tile_ptr
        if_nz           or      pixels1, pixels2
                        shl     pixels1, #16
                        mov     pixels2, #0

        if_z_and_nc     movs    _pixcnt, #2+1
        if_nz_and_nc    movs    _pixcnt, #4+1
        if_z_and_c      movs    _pixcnt, #4+1
        if_nz_and_c     movs    _pixcnt, #8+1
        if_nc           jmp     #_st1

                        mov     ecnt, #16
_xl1                    shl     pixels1, #1 wc
                        shl     pixels2, #2
                        muxc    pixels2, #%11
                        djnz    ecnt, #_xl1
                        mov     pixels1, pixels2

_st1                    mov     colors1, 0-0
                        and     colors1, #$FF

                        shr     pixels1, x
                        cmp     x, #0 wz
        if_nz           mov     a, #32
        if_nz           sub     a, x
        if_nz           shl     pixels2, a
        if_z            mov     pixels2, #0

_pixcnt                 mov     ccnt, #0-0
_ssrc                   mov     colors0, 0-0
                        mov     ecnt, #4
_l3a                    shl     pixels1, #1 wc
                        rol     colors0, #8
        if_c            andn    colors0, #$FF
        if_c            or      colors0, colors1
                        shl     pixels2, #1 wc
                        muxc    pixels1, #%1
                        djnz    ecnt, #_l3a
_sdst                   mov     0-0, colors0
                        add     _ssrc, #1
                        add     _sdst, inc_dest
                        djnz    ccnt, #_ssrc

                        sub     lcnt, #1 wz
        if_z            jmp     #emit

_next                   add     register5, #4
                        djnz    pcnt, #_sprite_loop

emit
                        rdlong  a, hub_fi
                        cmp     a, scnt wz,wc
        if_ne           jmp     #$-2                        // wait for line fetch start

                        mov     sbuf_ptr, hub_sbuf

                        mov     ecnt, #8
                        wrlong  backdrop, sbuf_ptr
                        add     sbuf_ptr, #4
                        djnz    ecnt, #$-2

                        wrlong  sbuf, sbuf_ptr
                        add     sbuf_ptr, #4
                        wrlong  sbuf + 1, sbuf_ptr
                        add     sbuf_ptr, #4

                        movd    _wr0, #sbuf +(256/4) -1
                        movd    _wr1, #sbuf +(256/4) -2
                        add     sbuf_ptr, #256-8 -1
                        movi    sbuf_ptr, #(256/4)-2 -2
_wr0                    wrlong  0-0, sbuf_ptr
                        sub     _wr0, inc_dest_2
                        sub     sbuf_ptr, i2s7 wc
_wr1                    wrlong  0-0, sbuf_ptr
                        sub     _wr1, inc_dest_2
        if_nc           djnz    sbuf_ptr, #_wr0

                        mov     sbuf_ptr, hub_sbuf
                        add     sbuf_ptr, #32+256

                        mov     ecnt, #8
                        wrlong  backdrop, sbuf_ptr
                        add     sbuf_ptr, #4
                        djnz    ecnt, #$-2

                        add     scnt, #COGS                 // next line to render
                        cmp     scnt, #240 wc,wz
        if_b            jmp     #loop

                        jmp     #vsync

// driver parameters

hub_registers           long    $4000

hub_fi                  long    $7EBC
hub_sbuf                long    $7EC0

// initialised data and/or presets

inc_dest                long    1 << 9
inc_dest_2              long    2 << 9
inc_dest_3              long    3 << 9
i2s7                    long    2 << 23 | 7

vdp_8k_mask             long    $1FFF
neg_clip                long    -32
TMSEARLYCLK             long    %10000000_00000000_00000000_00000000

register0               long    $00
register1               long    $00
register2               long    $00
register3               long    $00
register4               long    $00
register5               long    $00
register6               long    $00
register7               long    $00

palette                 long    %%000_0_000_0_000_0_000_0   // 0 - Transparent
                        long    %%000_0_000_0_000_0_000_0   // 1 - Black
                        long    %%131_0_131_0_131_0_131_0   // 2 - M. Green
                        long    %%232_0_232_0_232_0_232_0   // 3 - L. Green
                        long    %%013_0_013_0_013_0_013_0   // 4 - D. Blue
                        long    %%123_0_123_0_123_0_123_0   // 5 - L. Blue
                        long    %%300_0_300_0_300_0_300_0   // 6 - D. Red
                        long    %%033_0_033_0_033_0_033_0   // 7 - Cyan
                        long    %%311_0_311_0_311_0_311_0   // 8 - M. Red
                        long    %%322_0_322_0_322_0_322_0   // 9 - L. Red
                        long    %%331_0_331_0_331_0_331_0   // 10 - D. Yellow
                        long    %%332_0_332_0_332_0_332_0   // 11 - L. Yellow
                        long    %%020_0_020_0_020_0_020_0   // 12 - D. Green
                        long    %%213_0_213_0_213_0_213_0   // 13 - Magenta
                        long    %%222_0_222_0_222_0_222_0   // 14 - Grey
                        long    %%333_0_333_0_333_0_333_0   // 15 - White

// uninitialised data and/or temporaries

a                       res     1
b                       res     1
x                       res     1
y                       res     1
data                    res     1
tile                    res     1
ptr                     res     1

ecnt                    res     1
scnt                    res     1
ccnt                    res     1
pcnt                    res     1
lcnt                    res     1

tile_ptr                res     1

pixels1                 res     1
pixels2                 res     1
pixels3                 res     1
colors0                 res     1
colors1                 res     1

backdrop                res     1

sbuf_ptr                res     8                           // space for left-side off-screen sprites
sbuf                    res     64                          // scanline buffer
                        res     8                           // space for right-side off-screen sprites

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
