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

                        .equ    H_RES, 320
                        .equ    V_RES, 240
                        .equ    SBUF_OFS, 0

                        .section .cog_bitmap_scanline_renderer_320x240, "ax"

                        .org    0

                        mov     offset, PAR
                        shr     offset, #2
                        and     offset, #$7

vsync
                        rdlong  a, hub_fi wz
        if_nz           jmp     #$-1                        // wait for line counter reset (vsync)

                        mov     sbuf_ptr, hub_palette
                        rdbyte  palette, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+1, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+2, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+3, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+4, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+5, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+6, sbuf_ptr
                        add     sbuf_ptr, #1
                        rdbyte  palette+7, sbuf_ptr

                        mov     scnt, offset

// bitmap

loop
                        mov     loffs, scnt

                        mov     video_ptr, loffs
                        shl     video_ptr, #7

                        mov     ecnt, #32

                        movd    str0, #sbuf
                        movd    str1, #sbuf+1
                        movd    str2, #sbuf+2
                        movd    str3, #sbuf+3
                        movd    str4, #sbuf+4

_l1                     rdword  pixels1, video_ptr
                        add     video_ptr, #2

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv4, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv3, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv2, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv1, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv8, a

                        rdword  pixels1, video_ptr
                        add     video_ptr, #2

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv7, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv6, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv5, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv12, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv11, a

                        rdword  pixels1, video_ptr
                        add     video_ptr, #2

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv10, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv9, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv16, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv15, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv14, a

                        rdword  pixels1, video_ptr
                        add     video_ptr, #2

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv13, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv20, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv19, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv18, a

                        shr     pixels1, #3

                        mov     a, pixels1
                        and     a, #$07
                        add     a, #palette
                        movs    _mv17, a

_mv1                    mov     colors1, 0-0
                        shl     colors1, #8
_mv2                    or     colors1, 0-0
                        shl     colors1, #8
_mv3                    or     colors1, 0-0
                        shl     colors1, #8
_mv4                    or     colors1, 0-0

str0                    mov     0-0, colors1
                        add     str0, inc_dest_5

_mv5                    mov     colors1, 0-0
                        shl     colors1, #8
_mv6                    or     colors1, 0-0
                        shl     colors1, #8
_mv7                    or     colors1, 0-0
                        shl     colors1, #8
_mv8                    or     colors1, 0-0

str1                    mov     0-0, colors1
                        add     str1, inc_dest_5

_mv9                    mov     colors1, 0-0
                        shl     colors1, #8
_mv10                   or     colors1, 0-0
                        shl     colors1, #8
_mv11                   or     colors1, 0-0
                        shl     colors1, #8
_mv12                   or     colors1, 0-0

str2                    mov     0-0, colors1
                        add     str2, inc_dest_5

_mv13                   mov     colors1, 0-0
                        shl     colors1, #8
_mv14                   or     colors1, 0-0
                        shl     colors1, #8
_mv15                   or     colors1, 0-0
                        shl     colors1, #8
_mv16                   or     colors1, 0-0

str3                    mov     0-0, colors1
                        add     str3, inc_dest_5

_mv17                   mov     colors1, 0-0
                        shl     colors1, #8
_mv18                   or     colors1, 0-0
                        shl     colors1, #8
_mv19                   or     colors1, 0-0
                        shl     colors1, #8
_mv20                   or     colors1, 0-0

str4                    mov     0-0, colors1
                        add     str4, inc_dest_5

                        djnz    ecnt, #_l1

// scanline buffer output

emit
                        rdlong  a, hub_fi
                        cmp     a, scnt wz,wc
        if_ne           jmp     #$-2                        // wait for line fetch start

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
        if_nc           djnz    sbuf_ptr, #_wr0

                        add     scnt, #COGS                 // next line to render
                        cmp     scnt, #V_RES wc,wz
        if_b            jmp     #loop

                        jmp     #vsync

// driver parameters

hub_video_ram           long    $0000
hub_palette             long    $7800

hub_fi                  long    $7EBC
hub_sbuf                long    $7EC0 + SBUF_OFS

// initialised data and/or presets

inc_dest                long    1 << 9
inc_dest_2              long    2 << 9
inc_dest_5              long    5 << 9
i2s7                    long    2 << 23 | 7

pixels1                 long    0
colors1                 long    0

palette                 long    $00, $C0, $30, $F0, $0C, $CC, $3C, $FC

// uninitialised data and/or temporaries

a                       res     1
data1                   res     1
data2                   res     1

offset                  res     1
loffs                   res     1

ecnt                    res     1
scnt                    res     1

video_ptr               res     1

// code and/or data repurposed for scanline buffer

sbuf_ptr                res     1
sbuf

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
