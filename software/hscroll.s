; Propeller Graphics Card for RC2014
; https://github.com/maccasoft/propeller-graphics-card
;
; Horizontal scroll demo.
;
; Compile:
;
;   z80asm --cpu=z80 -b -r0100h --output=hscroll.com hscroll.s music.s
;
; Copyright (c) 2018 Marco Maccaferri

                defc    PORTC    = 40h
                defc    PORTD    = 41h
                defc    PORTS    = 43h

                defc    SETMODE  = 00h
                defc    SETXS    = 03h
                defc    SETYS    = 04h
                defc    SETTILBK = 06h
                defc    SETSPRBK = 07h
                defc    WRSPR    = 0Ch
                defc    WRMAP    = 0Dh
                defc    WRBMP    = 0Eh
                defc    WRMEM    = 0Fh

                defc    M320240  = 00h
                defc    M256192  = 01h
                defc    M256224  = 02h
                defc    EXPANDH  = 80h
                defc    EXPANDV  = 40h

                defc    MIRROR   = 04h
                defc    FLIP     = 08h

                defc    WBOOT    = 0000h
                defc    BDOS     = 0005h

                xref    ay_init
                xref    ay_play_music
                xref    ay_reset

init:
                ld      a,SETMODE
                out     (PORTC),a
                ld      a,M320240+EXPANDH   ; set video mode 1 (320x240) with horizontal tilemap expand
                out     (PORTD),a
                ld      a,24h               ; add 4 overlay rows starting from row 2
                out     (PORTD),a
                ld      a,00h
                out     (PORTD),a

                call    ay_init

                ; Upload tiles

                ld      a,WRBMP
                out     (PORTC),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ld      e,16h               ; number of tiles
                ld      hl,tiles
                ld      c,PORTD
_l002:          ld      b,64
_l001:          outi
                outi
                outi
                outi
                outi
                outi
                outi
                outi
                jp      nz,_l001
                dec     e
                jp      nz,_l002

                ; Initialize screen map

                ld      a,WRMAP
                out     (PORTC),a
                ld      a,0F0h
                out     (PORTD),a
                ld      a,05h
                out     (PORTD),a

                ld      hl,level_map
                ld      c,PORTD
                ld      e,9                 ; 9 rows by 80 columns
_l004:          ld      b,80
_l003:          outi
                outi
                outi
                outi
                outi
                outi
                outi
                outi
                jp      nz,_l003
                dec     e
                jp      nz,_l004

                ; Initialize overlay map

                ld      a,WRMAP
                out     (PORTC),a
                ld      a,60h               ; overlay starts at end of normal video ram tiles map
                out     (PORTD),a
                ld      a,09h
                out     (PORTD),a

                ld      hl,radar_map
                ld      c,PORTD
                ld      e,4                 ; 4 rows by 40 columns
_l006:          ld      b,40
_l005:          outi
                outi
                outi
                outi
                outi
                outi
                outi
                outi
                jp      nz,_l005
                dec     e
                jp      nz,_l006

                ; Loop

loop:
                ld      c,06H               ; check keyboard
                ld      e,0FFH
                call    BDOS
                cp      03                  ; CTRL-C to exit
                jp      z,exit

                out     (PORTS),a           ; frame synchronization

                ld      a,WRSPR
                out     (PORTC),a
                xor     a
                out     (PORTD),a

                ld      a,(ship_x)          ; ship sprite
                out     (PORTD),a
                ld      a,(ship_y)
                out     (PORTD),a
                ld      a,14h
                out     (PORTD),a
                ld      a,40h
                out     (PORTD),a

                ld      a,SETXS             ; set scroll position
                out     (PORTC),a
                ld      a,(scroll_x)
                out     (PORTD),a
                ld      a,(scroll_x+1)
                out     (PORTD),a

                call    ay_play_music

                ld      hl,(scroll_x)       ; increment scroll position (right to left direction)
                inc     hl
                inc     hl
                ld      a,h                 ; wraps at 640 (0280h)
                cp      02h
                jp      nz,_l007
                ld      a,l
                cp      80h
                jp      nz,_l007
                ld      hl,0                ; restart from 0
_l007:          ld      (scroll_x),hl

                jp      loop

exit:
                call    ay_reset
                jp      WBOOT

scroll_x:       defw    0

ship_x:         defw    40
ship_y:         defw    116

tiles:
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 00
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H

                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H ; 01, name=tile048
                defb    0FCH, 0FCH, 000H, 000H, 000H, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 000H, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H ; 02, name=tile049
                defb    000H, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H ; 03, name=tile050
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H ; 04, name=tile051
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 000H, 000H, 0FCH, 0FCH, 0FCH, 000H, 000H ; 05, name=tile052
                defb    000H, 000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H ; 06, name=tile053
                defb    0FCH, 0FCH, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 000H, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H ; 07, name=tile054
                defb    000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H ; 08, name=tile055
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H ; 09, name=tile056
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H ; 0A, name=tile057
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H, 000H
                defb    000H, 0FCH, 0FCH, 0FCH, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 030H ; 0B
                defb    000H, 000H, 000H, 000H, 000H, 000H, 030H, 020H
                defb    000H, 000H, 000H, 000H, 000H, 030H, 020H, 020H
                defb    000H, 000H, 000H, 000H, 030H, 020H, 020H, 020H
                defb    000H, 000H, 000H, 030H, 020H, 020H, 020H, 020H
                defb    000H, 000H, 030H, 020H, 020H, 020H, 020H, 020H
                defb    000H, 030H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    030H, 020H, 020H, 020H, 020H, 020H, 020H, 020H

                defb    030H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 0C
                defb    020H, 030H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    020H, 020H, 030H, 000H, 000H, 000H, 000H, 000H
                defb    020H, 020H, 020H, 030H, 000H, 000H, 000H, 000H
                defb    020H, 020H, 020H, 020H, 030H, 000H, 000H, 000H
                defb    020H, 020H, 020H, 020H, 020H, 030H, 000H, 000H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 030H, 000H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 030H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 0D
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    030H, 030H, 030H, 030H, 030H, 030H, 030H, 030H

                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H ; 0E, name=FILLER
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H
                defb    020H, 020H, 020H, 020H, 020H, 020H, 020H, 020H

                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 0F
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H

                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H ; 10
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0E0H
                defb    0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H

                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 11
                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H ; 12
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 0E0H

                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 13
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    0E0H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 14, name=SHIP
                defb    0C0H, 0C0H, 0C0H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 0C0H, 0C0H, 0C0H, 001H, 001H, 001H, 001H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    001H, 0C0H, 0C0H, 0C0H, 0A8H, 0A8H, 0A8H, 0A8H
                defb    0C0H, 0C0H, 0C0H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H
                defb    001H, 0A8H, 0A8H, 0A8H, 0E0H, 0E0H, 0E0H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0C0H, 02CH, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0A8H, 00CH, 00CH, 00CH, 00CH, 001H, 001H, 001H
                defb    0A8H, 0A8H, 0A8H, 0A8H, 0E0H, 0E0H, 0E0H, 0E0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H

level_map:
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Ch, 00h, 00h, 0Bh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 00h, 00h, 00h, 00h, 00h, 00h, 0Bh, 0Ch, 00h, 00h
                defb    0Dh, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 0Dh, 0Dh, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 0Dh, 0Dh, 0Dh, 0Bh, 0Eh, 0Eh, 0Ch, 0Bh, 0Eh, 0Eh, 0Ch, 0Dh, 0Dh, 0Dh, 0Dh, 0Bh, 0Ch, 0Bh, 0Ch, 0Dh, 0Dh, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 0Dh, 0Dh, 0Dh, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Ch, 0Dh, 0Dh, 0Dh, 0Dh, 0Bh, 0Eh, 0Eh, 0Ch, 0Dh
                defb    0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh

radar_map:
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 13h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 12h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 01h, 01h, 01h, 01h, 01h, 01h, 00h, 00h, 13h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 12h, 00h, 00h, 01h, 01h, 01h, 01h, 01h, 01h, 00h, 00h, 00h
                defb    0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 11h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 10h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh
