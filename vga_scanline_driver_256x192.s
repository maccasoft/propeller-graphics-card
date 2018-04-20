/*
 * VGA Scanline Driver 320x192
 *
 * 2 scanline buffers
 *
 *      Author: Marko Lukat
 * Modified by: Marco Maccaferri
 *
 * MIT Licensed.
 */

                        .pasm
                        .compress off

                        .section .cog_vga_256x192_video_driver, "ax"

                        .equ    zero, $1F0                  // par (dst only)
                        .equ    vpin, $0FC                  // pin group mask
                        .equ    vgrp, 2                     // pin group
                        .equ    sgrp, 2                     // pin group sync
                        .equ    hv_idle, $01010101 * %11    // h/v sync inactive

                        .equ    res_x, 320                  // |
                        .equ    res_y, 192                  // |
                        .equ    res_m, 1                    // UI support

                        .org     0

driver                  call    #setup                      //  -4   once (replaced by 16 entry table)
                        res     15

                        mov     dira, mask                  // drive outputs

// horizontal timing 320(640)  1(16) 6(96)  3(48)
//   vertical timing 240(480) 10(10) 2(2)  33(33)

vsync                   mov     lcnt, #1                    // |

                        mov     ecnt, #48+10
                        call    #blank wc                   // bottom border + front porch
                        djnz    ecnt, #$-1

                        xor     sync, #$0101                // active
                                                            //
                        call    #blank wc                   // |
                        call    #blank wc                   // vertical sync

                        xor     sync, #$0101                // inactive

                        mov     ecnt, #20+48
                        call    #blank wc                   // back porch + top border
                        djnz    ecnt, #$-1

                        wrword  zero, par                   // reset line counter

                        mov     ecnt, #12
_last                   call    #blank wc                   // back porch
                        djnz    ecnt, #$-1

// The following instruction (performing unsigned borrow) exploits the
// fact that a ret insn has its wr bit cleared and is therefore unsigned
// smaller than a call (wr set).
//
// call #blank   %010111_001i_cccc_ddddddddd_sssssssss
// ret           %010111_000i_cccc_ddddddddd_sssssssss

                        jmpret  blank_ret, _last wc         // last blank line done manually
                                                            // to start pixel loading

// Vertical sync chain done, do visible area.

                        mov     scnt, #res_y
                        mov     ecnt, #15                   // load 15 longs while emitting line

_loop                   mov     outa, idle                  // take over sync lines                  (&&)
                        mov     vcfg, vcfg_norm             // disconnect sync from video h/w        (&&)
                        mov     vscl, hvis                  // visible line 2/8
                        call    #emit wc                    // carry clear

                        mov     outa, idle                  // take over sync lines                  (&&)
                        mov     vcfg, vcfg_norm             // disconnect sync from video h/w        (&&)
                        mov     vscl, hvis                  // visible line 2/8
                        call    #emit wc                    // carry clear

                        djnz    scnt, #_loop                // repeat for all lines

                        jmp     #vsync                      // next frame


blank                   mov     vscl, line                  // 256/640
                        waitvid sync, #0

                        movd    sub7, #one+79               // |
                        movd    sub1, #one+78               // |
                        mov     temp, #320 -1               // |
                        mov     frqb, buf0                  // always use primary
                        shr     frqb, #1                    // added twice #1{/2}

        if_c            call    #load wc                    // load first line

                        mov     vscl, wrap                  // horizontal sync
                        waitvid sync, wrap_value

                        mov     cnt, cnt                    // record sync point
                        add     cnt, #9+360                 // | #9{14}+360
                        waitcnt cnt, #0                     // cover front+sync                      (&&)

blank_ret               ret

// While displaying a line the emitter fetches the next scanline. The visible
// part of the scanline loads 15 longs each, horizontal sync will load the
// remaining 26/24 longs (even/odd). 15-26-15-24

secondary               waitvid vier, #%%3210
                        rdlong  temp, addr
primary                 waitvid one-$01, #%%3210            // in place      E
                        mov     two-$01, temp               //               T
emit                    mov     zwei, one+$01               //               B
                        mov     drei, one+$02               //               C
                        mov     vier, one+$03               //               D
                        waitvid one+$00, #%%3210            // in place      A
                        movs    $+3, cnt
                        andn    $+2, #%111110000
                        add     addr, #4                    // advance address for next load
                        jmp     0-0                         // select target

_1st                    waitvid zwei, #%%3210
                        rdlong  temp, addr
                        waitvid drei, #%%3210
                        add     primary+5, dst5             // A++
                        add     primary+2, #5               // B++
                        add     primary+3, #5               // C++
                        add     primary+4, #5               // D++
                        waitvid vier, #%%3210
                        add     primary+0, dst5             // E++
                        add     primary+1, dst1             // T++
                        djnz    ecnt, #primary
_1st_tail               waitvid one+$4A, #%%3210            // emit one/two[74]
                        jmp     splice

_2nd                    waitvid zwei, #%%3210
                        add     primary+5, dst5             // A++
                        add     primary+2, #5               // B++
                        add     primary+3, #5               // C++
                        add     primary+4, #5               // D++
                        waitvid drei, #%%3210
                        rdlong  temp, addr
                        waitvid vier, #%%3210
                        add     primary+0, dst5             // E++
                        add     primary+1, dst1             // T++
                        djnz    ecnt, #primary
_2nd_tail               waitvid one+$4A, #%%3210            // emit one/two[74]
                        jmp     splice

_3rd                    waitvid zwei, #%%3210
                        add     primary+5, dst5             // A++
                        add     primary+2, #5               // B++
                        add     primary+3, #5               // C++
                        add     primary+4, #5               // D++
                        waitvid drei, #%%3210
                        add     primary+0, dst5             // E++
                        add     primary+1, dst1             // T++
                        djnz    ecnt, #secondary
                        waitvid vier, #%%3210               // emit one/two[73]
                        rdlong  temp, addr
_3rd_tail               waitvid one+$4A, #%%3210            // emit one/two[74]
                        jmp     splice

splice                  hubop   $, com0

com0                    mov     two+$0E, temp               // last write
                        movs    splice, #com1
                        movd    primary+1, #two+$28         // T==
                        waitvid one+$4B, #%%3210            // emit one[75]
                        movd    primary+5, #one+$00         // A==
                        movs    primary+2, #one+$01         // B==
                        movs    primary+3, #one+$02         // C==
                        movs    primary+4, #one+$03         // D==
                        waitvid one+$4C, #%%3210            // emit one[76]
                        movd    primary+0, #one-$01         // E==
//                        nop
//                        nop
//                        nop
                        waitvid one+$4D, #%%3210            // emit one[77]
                        movd    sub7, #two+40
                        movd    sub1, #two+39
                        mov     temp, #104 -1               // 26 longs
                        add     addr, #4
                        waitvid one+$4E, #%%3210            // emit one[78]
                        mov     frqb, addr
                        shr     frqb, #1                    // added twice #1{/2}
                        add     addr, #104 -4               // counter early advance
                        add     lcnt, #1                    // next line index
                        waitvid one+$4F, #%%3210            // emit one[79]
                        jmpret  zero, #emit_tail wc,nr      // carry set

com1                    mov     two+$37, temp               // last write
                        movs    splice, #com2
                        movd    primary+1, #one-$01         // T==
                        waitvid one+$4B, #%%3210            // emit one[75]
                        movd    primary+5, #two+$00         // A==
                        movs    primary+2, #two+$01         // B==
                        movs    primary+3, #two+$02         // C==
                        movs    primary+4, #two+$03         // D==
                        waitvid one+$4C, #%%3210            // emit one[76]
                        movd    primary+0, #two-$01         // E==
                        movd    _1st_tail, #two+$4A
                        movd    _2nd_tail, #two+$4A
                        movd    _3rd_tail, #two+$4A
                        waitvid one+$4D, #%%3210            // emit one[77]
                        movd    sub7, #two+79
                        movd    sub1, #two+78
                        mov     temp, #96 -1                // 24 longs
                        add     addr, #4
                        waitvid one+$4E, #%%3210            // emit one[78]
                        mov     frqb, addr
                        shr     frqb, #1                    // added twice #1{/2}
                        mov     addr, buf0                  // fill primary buffer next
                        sub     addr, #4                    // counter early advance
                        waitvid one+$4F, #%%3210            // emit one[79]
                        jmp     #emit_skip

com2                    mov     one+$0E, temp               // last write
                        movs    splice, #com3
                        movd    primary+1, #one+$28         // T==
                        waitvid two+$4B, #%%3210            // emit two[75]
                        movd    primary+5, #two+$00         // A==
                        movs    primary+2, #two+$01         // B==
                        movs    primary+3, #two+$02         // C==
                        movs    primary+4, #two+$03         // D==
                        waitvid two+$4C, #%%3210            // emit two[76]
                        movd    primary+0, #two-$01         // E==
//                        nop
//                        nop
//                        nop
                        waitvid two+$4D, #%%3210            // emit two[77]
                        movd    sub7, #one+40
                        movd    sub1, #one+39
                        mov     temp, #104 -1               // 26 longs
                        add     addr, #4
                        waitvid two+$4E, #%%3210            // emit two[78]
                        mov     frqb, addr
                        shr     frqb, #1                    // added twice #1{/2}
                        add     addr, #104 -4               // counter early advance
                        add     lcnt, #1                    // next line index
                        waitvid two+$4F, #%%3210            // emit two[79]
                        jmpret  zero, #emit_tail wc,nr      // carry set

com3                    mov     one+$37, temp               // last write
                        movs    splice, #com0
                        movd    primary+1, #two-$01         // T==
                        waitvid two+$4B, #%%3210            // emit two[75]
                        movd    primary+5, #one+$00         // A==
                        movs    primary+2, #one+$01         // B==
                        movs    primary+3, #one+$02         // C==
                        movs    primary+4, #one+$03         // D==
                        waitvid two+$4C, #%%3210            // emit two[76]
                        movd    primary+0, #one-$01         // E==
                        movd    _1st_tail, #one+$4A
                        movd    _2nd_tail, #one+$4A
                        movd    _3rd_tail, #one+$4A
                        waitvid two+$4D, #%%3210            // emit two[77]
                        movd    sub7, #one+79
                        movd    sub1, #one+78
                        mov     temp, #96 -1                // 24 longs
                        add     addr, #4
                        waitvid two+$4E, #%%3210            // emit two[78]
                        mov     frqb, addr
                        shr     frqb, #1                    // added twice #1{/2}
                        mov     addr, buf1                  // fill secondary buffer next
                        sub     addr, #4                    // counter early advance
                        waitvid two+$4F, #%%3210            // emit two[79]
//                        jmp     #emit_skip

emit_skip               cmp     scnt, #2 wc                 // last line -> no 3rd party override
emit_tail               mov     ecnt, #15                   // restore load counter
                        mov     vscl, wrap                  // |
                        waitvid sync, wrap_value            // chain horizontal sync

                        mov     vcfg, vcfg_sync             // drive/change sync lines               (&&)
                        mov     outa, #0                    // stop interfering                      (&&)

// Loader is embedded here for speed reasons, also used during last blank line.

load                    mov     phsb, temp                  // 8n + 7

sub7                    rdlong  0-0, phsb                   // |
                        sub     sub7, dst2                  // |
                        sub     phsb, #7 wz                 // |
sub1                    rdlong  0-0, phsb                   // |
                        sub     sub1, dst2                  // |
            if_nz       djnz    phsb, #sub7                 // sub #7/djnz (Thanks Phil!)

{extn}      if_nc       rdword  temp, extn wz               // fetch optional 3rd party buffer
{extn}      if_a        mov     addr, temp                  // a = nc & nz
{extn}      if_a        sub     addr, #4                    // |
{extn}      if_nc       wrlong  lcnt, extn                  // line has been fetched
load_ret
emit_ret                ret

//{odd lines}    djnz    scnt, #:loop            // repeat for all lines
//
//       :loop   mov     outa, idle              // take over sync lines                  (&&)
//               mov     vcfg, vcfg_norm         // disconnect sync from video h/w        (&&)
//               mov     vscl, hvis              // visible line 2/8
//
//               call    #emit
//
//       emit    mov     zwei, one+$01           //               B
//               mov     drei, one+$02           //               C
//               mov     vier, one+$03           //               D
//               waitvid one+$00, #%%3210        // in place      A

// The horizontal sync part takes 160 pixel clocks (508.4 clock cycles @80MHz).
// We spend 7 + 11/12*4 in normal insns plus an additional 26/24 hub windows for
// final pixel loading. Which gives us a worst case timing of
// - 51 + 26*16 + 0..15 = 482
// - 55 + 24*16 + 0..15 = 454
// with 1/3 remaining hub window(s) for even/odd lines respectively {extn}.

// initialised data and/or presets

idle                    long    (hv_idle & $00FF) << (sgrp * 8)
sync                    long    (hv_idle ^ $0200)  & $FFFF

wrap_value              long    $1554                       // horizontal sync pulse %%0001111110
wrap                    long    16 << 12 | 160              //  16/160
hvis                    long     2 << 12 | 8                //   2/8
line                    long     0 << 12 | 640              // 256/640

vcfg_norm               long    %0_01_1_00_000 << 23 | vgrp << 9 | vpin
vcfg_sync               long    %0_01_1_00_000 << 23 | sgrp << 9 | %11

mask                    long    vpin << (vgrp * 8) | %11 << (sgrp * 8)

dst1                    long    1 << 9                      // dst     +/-= 1
dst2                    long    2 << 9                      // dst     +/-= 2
dst5                    long    5 << 9                      // dst     +/-= 5

buf0                    long    $7EC0                       // |
buf1                    long    $7EC0                       // double buffer reference

extn                    long    +2

// Stuff below is re-purposed for temporary storage.

setup                   rdlong  temp, par                   //  +0 =
                        neg     href, cnt                   //  +8   hub window reference            (%%)
                        shr     temp, #16                   //  -4   secondary ...
                        rdword  temp, par                   //  +0 = primary buffer

                        add     href, #3 + 15               //  -4   |
                        and     href, #%1111                //  +0 = (15 - (H - 3)) & 15

                        add     copy, href                  // apply offset
                        mov     ecnt, #16                   // all possible hub offsets

copy                    mov     $000, dist                  // |
                        add     copy, d1s1                  // |
                        djnz    ecnt, #copy                 // transfer [shifted] table

                        mov     addr, buf1                  // address starts as secondary buffer
                        sub     addr, #4                    // counter early advance

                        add     extn, par                   // 3rd party buffer reference
                        wrlong  zero, par                   // acknowledge buffers

// Upset video h/w and relatives.

                        movi    ctrb, #%0_11111_000         // LOGIC always (loader support)
                        movi    ctra, #%0_00001_101         // PLL, VCO/4
                        mov     frqa, frqx                  // 25.175MHz

                        mov     vscl, hvis                  // 2/8
                        mov     vcfg, vcfg_sync             // VGA, 4 colour mode

// Setup complete, do the heavy lifting upstairs ...

setup_ret               ret

//                       hub access distribution table valid for
//                       25/26 cycles between WHOPs, 80MHz
dist                    long    _2nd, _2nd, _2nd ,_2nd ,_2nd ,_2nd, _3rd, _3rd
                        long    _1st, _1st, _1st, _1st, _1st, _1st, _1st, _1st
                        long    _2nd, _2nd, _2nd ,_2nd ,_2nd ,_2nd, _3rd, _3rd
                        long    _1st, _1st, _1st, _1st, _1st, _1st, _1st
frqx                    long    $1423D70A
d1s1                    long    1 << 9 | 1                  // dst/src +/-= 1

// uninitialised data and/or temporaries

ecnt                    res     1                           // element count
href                    res     1                           // hub window reference  < setup +1      (%%)

addr                    res     1                           // colour buffer reference
lcnt                    res     1                           // line counter
scnt                    res     1                           // scanlines

temp                    res     1
zwei                    res     1
drei                    res     1
vier                    res     1

one                     res     80
two                                                         // all locations from here are reserved
                                                            // for the second scanline buffer

                        fit

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
