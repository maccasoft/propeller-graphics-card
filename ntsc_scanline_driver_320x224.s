/*
 * P8X Game System
 * NTSC RGB Scanline Driver 320x224
 *
 * Connections:
 *
 *        VGA     SCART
 * RED      1 ... 15   RED
 * GREEN    2 --- 11   GREEN
 * BLUE     3 ---  7   BLUE
 * HSYNC   13 --- 19   COMPOSITE OUT (F)
 *                        - or -
 *                20   COMPOSITE IN (TV)
 * VCC        --- 16   RGB SWITCH
 * GND        --- 5, 9, 13, 18
 *
 * Copyright (c) 2015-2018 Marco Maccaferri
 * MIT Licensed
 */

                        .pasm
                        .compress off

                        .section .cog_ntsc_320x240_video_driver, "ax"

                        .equ    vpin, $0FF                  // pin group mask
                        .equ    vgrp, 2                     // pin group
                        .equ    hv_idle, $03030303          // h/v sync inactive
                        .equ    vsync_pin, 24

                        .equ    res_x, 320                  // |
                        .equ    res_y, 224                  // UI support

                        .org     0

// Upset video h/w and relatives.

                        movi    ctra, #%0_00001_110         // PLL, VCO/2
                        mov     frqa, frqx

                        mov     vscl, #64                   // 1/64

                        movd    vcfg, #vgrp                 // pin group
                        movs    vcfg, #vpin                 // pins
                        movi    vcfg, #%0_01_1_00_000       // VGA, 4 colour mode

                        mov     cnt, clk_freq
                        shr     cnt, #10                    // ~1ms
                        add     cnt, cnt
                        waitcnt cnt, #0                     // PLL needs to settle

                        mov     dira, mask                  // drive outputs

// Setup complete, enter display loop.

vsync
                        mov     ecnt, #6
_l1                     mov     vscl, vscleqlo              // 6 equalizing pulses
                        waitvid sync, #0
                        mov     vscl, vscleqhi
                        waitvid sync, idle
                        djnz    ecnt, #_l1

                        mov     ecnt, #6
_l2                     mov     vscl, vsclserr              // 6 synchronization pulses
                        waitvid sync, #0
                        mov     vscl, vsclsync
                        waitvid sync, idle
                        djnz    ecnt, #_l2

                        mov     ecnt, #6
_l3                     mov     vscl, vscleqlo              // 6 equalizing pulses
                        waitvid sync, #0
                        mov     vscl, vscleqhi
                        waitvid sync, idle
                        djnz    ecnt, #_l3

// Vertical sync chain done, do visible area.

                        mov     ecnt, #6
                        call    #blank
                        djnz    ecnt, #$-1

                        mov     lcnt, #0                    // Reset scanline counter
                        wrlong  lcnt, PAR

                        mov     ecnt, #6
                        call    #blank
                        djnz    ecnt, #$-1

                        mov     ecnt, #8                    // top border
                        call    #border
                        djnz    ecnt, #$-1

                        mov     scnt, #res_y

_loop                                                       // 240 active lines
                        mov     sbuf_ptr, sbuf

                        rdlong  pal +0, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +1, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +2, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +3, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +4, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +5, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +6, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +7, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +8, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +9, sbuf_ptr

                        mov     vscl, vsclsync
                        waitvid sync, #0

                        add     sbuf_ptr, #4
                        rdlong  pal +10, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +11, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +12, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +13, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +14, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +15, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +16, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +17, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +18, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +19, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +20, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +21, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +22, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +23, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +24, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +25, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +26, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +27, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +28, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +29, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +30, sbuf_ptr

                        mov     vscl, vsclbrst
                        waitvid sync, idle

                        mov     outa, idle_sync             // take over sync lines
                        andn    vcfg, #%11                  // disconnect from video h/w

                        add     sbuf_ptr, #4
                        rdlong  pal +31, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +32, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +33, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +34, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +35, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +36, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +37, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +38, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +39, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +40, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +41, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +42, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +43, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +44, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +45, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +46, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +47, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +48, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +49, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +50, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +51, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +52, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +53, sbuf_ptr
                        add     sbuf_ptr, #4
                        rdlong  pal +54, sbuf_ptr
                        add     sbuf_ptr, #4

                        mov     vscl, vsclactv
                        movd    _vid, #pal+25

                        waitvid pal +0, #%%3210
                        rdlong  pal +55, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +1, #%%3210
                        rdlong  pal +56, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +2, #%%3210
                        rdlong  pal +57, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +3, #%%3210
                        rdlong  pal +58, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +4, #%%3210
                        rdlong  pal +59, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +5, #%%3210
                        rdlong  pal +60, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +6, #%%3210
                        rdlong  pal +61, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +7, #%%3210
                        rdlong  pal +62, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +8, #%%3210
                        rdlong  pal +63, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +9, #%%3210
                        rdlong  pal +64, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +10, #%%3210
                        rdlong  pal +65, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +11, #%%3210
                        rdlong  pal +66, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +12, #%%3210
                        rdlong  pal +67, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +13, #%%3210
                        rdlong  pal +68, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +14, #%%3210
                        rdlong  pal +69, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +15, #%%3210
                        rdlong  pal +70, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +16, #%%3210
                        rdlong  pal +71, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +17, #%%3210
                        rdlong  pal +72, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +18, #%%3210
                        rdlong  pal +73, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +19, #%%3210
                        rdlong  pal +74, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +20, #%%3210
                        rdlong  pal +75, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +21, #%%3210
                        rdlong  pal +76, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +22, #%%3210
                        rdlong  pal +77, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +23, #%%3210
                        rdlong  pal +78, sbuf_ptr
                        add     sbuf_ptr, #4
                        waitvid pal +24, #%%3210
                        rdlong  pal +79, sbuf_ptr

                        add     lcnt, #1
                        wrlong  lcnt, PAR

                        mov     ecnt, #(res_x / 4) - 25
_vid                    waitvid 0-0, #%%3210
                        add     _vid, inc_dst
                        djnz    ecnt, #_vid

                        mov     vscl, vsclfp
                        waitvid sync, idle

                        or      vcfg, #%11                  // drive sync lines
                        mov     outa, #0                    // stop interfering

                        djnz    scnt, #_loop                // repeat for all lines

                        mov     ecnt, #8                    // bottom border
                        call    #border
                        djnz    ecnt, #$-1

                        call    #blank

                        jmp     #vsync                      // next frame

blank
                        mov     vscl, vsclsync
                        waitvid sync, #0
                        mov     vscl, vsclserr
                        waitvid sync, idle
                        mov     vscl, vsclhalf
                        waitvid sync, idle
blank_ret               ret

border
                        mov     vscl, vsclsync
                        waitvid sync, #0
                        mov     vscl, vsclbrst
                        waitvid sync, idle

                        mov     vscl, vsclactv
                        movd    _vid, #pal+25

                        mov     ccnt, #25
                        waitvid sync, idle
                        djnz    ccnt, #$-1

                        add     lcnt, #1
                        wrlong  lcnt, PAR

                        mov     ccnt, #(res_x / 4) - 25
                        waitvid sync, idle
                        djnz    ccnt, #$-1

                        mov     vscl, vsclfp
                        waitvid sync, idle
border_ret              ret

// driver parameters

sbuf                    long    $7EC0

// initialised data and/or presets

sync                    long    $03030301                   // %%0 = -40 IRE, %%1 = 0 IRE, %%2 = even burst, %%3 = odd burst
idle                    long    $55555555                   // 16 pixels color 1
idle_sync               long    $03 << (vgrp * 8)

vsclhalf                long    (0 << 12) |  1822               // H/2
vsclsync                long    (0 << 12) |  270                // sync = 4.7us
vsclserr                long    (0 << 12) | (1822 - 270)        // serration = H/2 - sync
vscleqlo                long    (0 << 12) |  135                // equalizing = 2.3us
vscleqhi                long    (0 << 12) | (1822 - 135)        // H/2 - equalizing
vsclbrst                long    (0 << 12) | (527 - 270 + 75)    // sync + blanking
vsclfp                  long    (0 << 12) | (86 + 76)           // front porch + overscan
vsclactv                long    (9 << 12) | (9 * 4)             // 9 PLLA per pixel, 4 pixels per frame

clk_freq                long    80000000
frqx                    long    $16E8BA00                   // 3,579,545 Hz

mask                    long    vpin << (vgrp * 8) | (1 << vsync_pin)
vsync_mask              long    1 << vsync_pin

inc_dst                 long    1 << 9

// uninitialised data and/or temporaries

ecnt                    res     1                           // element count
lcnt                    res     1                           // line counter
scnt                    res     1                           // scanlines
ccnt                    res     1

// colour buffer

sbuf_ptr                res     1
pal                                                         // all locations from here are reserved for the scanline buffer

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
