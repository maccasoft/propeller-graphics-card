; Propeller Graphics Card for RC2014
; https://github.com/maccasoft/propeller-graphics-card
;
; Raw bitmap mode color bars
;
; Compile:
;
;   z80asm --cpu=z80 -b -r0100h --output=bars.com bars.s
;
; Usage:
;
;   bars [mode]
;
;   Where mode can be 4 (320x240), 5 (256x192) or 6 (256x224).
;   Default is 320x240 if not specified.
;
; Copyright (c) 2018 Marco Maccaferri

                defc    PORTC    = 40h
                defc    PORTD    = 41h
                defc    PORTS    = 43h

                defc    SETMODE  = 00h
                defc    SETPIX   = 01h
                defc    CLRSCR   = 09h
                defc    WRPAL    = 0Bh
                defc    WRBMP    = 0Dh

                defc    M320240  = 03h
                defc    M256192  = 04h
                defc    M256224  = 05h

                defc    WBOOT    = 0000h
                defc    BDOS     = 0005h
                defc    COMBUF   = 0080h

start:
                ; Read command line for mode selection

                ld      a,(COMBUF)
                cp      0
                jp      z,bars_320x240

                ld      b,a
                ld      hl,COMBUF+1

_l006:          ld      a,(hl)
                cp      34h
                jp      z,bars_320x240
                cp      35h
                jp      z,bars_256x192
                cp      36h
                jp      z,bars_256x224
                inc     hl
                djnz    _l006

exit:
                jp      WBOOT

bars_320x240:
                ld      a,SETMODE
                out     (PORTC),a
                ld      a,M320240           ; set video mode 4 (320x240 3bpp)
                out     (PORTD),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ; Draw color bars

                ld      a,WRBMP
                out     (PORTC),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ld      b,240
_l003:          push    bc

                ld      hl,0
                ld      c,8
_l002:          ld      b,8
_l001:          ld      a,l
                out     (PORTD),a
                ld      a,h
                out     (PORTD),a
                djnz    _l001

                ld      de,0001001001001001b    ; index increment
                add     hl,de
                dec     c
                jp      nz,_l002

                pop     bc
                djnz    _l003

                jp      exit

bars_256x192:
                ld      a,SETMODE
                out     (PORTC),a
                ld      a,M256192           ; set video mode 5 (256x192 4bpp)
                out     (PORTD),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ; Draw color bars

                ld      a,WRBMP
                out     (PORTC),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ld      c,192
                jp      _l005

bars_256x224:
                ld      a,SETMODE
                out     (PORTC),a
                ld      a,M256224           ; set video mode 6 (256x224 4bpp)
                out     (PORTD),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ; Draw color bars

                ld      a,WRBMP
                out     (PORTC),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ld      c,224

_l005:          ld      a,0
                ld      b,16

_l004:          out     (PORTD),a
                out     (PORTD),a
                out     (PORTD),a
                out     (PORTD),a
                out     (PORTD),a
                out     (PORTD),a
                out     (PORTD),a
                out     (PORTD),a
                add     a,11H               ; index increment
                djnz    _l004

                dec     c
                jp      nz,_l005

                jp      exit

