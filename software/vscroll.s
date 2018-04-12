; Propeller Graphics Card for RC2014
; https://github.com/maccasoft/propeller-graphics-card
;
; Vertical scroll demo.
;
; Compile:
;
;   z80asm --cpu=z80 -b -r0100h --output=vscroll.com vscroll.s music.s
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
                ld      a,M320240+EXPANDV   ; set video mode 1 (320x240) with vertical tilemap expand
                out     (PORTD),a
                ld      a,21h               ; add 1 overlay row starting from row 2
                out     (PORTD),a
                ld      a,13h               ; add 3 overlay rows starting from row 26
                out     (PORTD),a

                call    ay_init

                ; Upload tiles

                ld      a,WRBMP
                out     (PORTC),a
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ld      e,26h               ; number of tiles
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
                xor     a
                out     (PORTD),a
                out     (PORTD),a

                ld      hl,level_map
                ld      c,PORTD
                ld      e,60                ; 60 rows by 40 columns
_l004:          ld      b,40
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

                ld      hl,score_map
                ld      c,PORTD
                ld      e,1+3               ; 1 top and 3 bottom rows by 40 columns
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
                ld      a,22h
                out     (PORTD),a
                ld      a,50h
                out     (PORTD),a

                ld      a,SETYS             ; set scroll position
                out     (PORTC),a
                ld      a,(scroll_y)
                out     (PORTD),a
                ld      a,(scroll_y+1)
                out     (PORTD),a

                call    ay_play_music

                ld      hl,(scroll_y)       ; decrement scroll position (top to bottom direction)
                dec     hl
                dec     hl
                ld      a,h                 ; wrap at -2 (0FFFEh)
                cp      0FFh
                jp      nz,_l007
                ld      a,l
                cp      0FEh
                jp      nz,_l007
                ld      hl,478              ; restart from 478
_l007:          ld      (scroll_y),hl

                jp      loop

exit:
                call    ay_reset
                jp      WBOOT

scroll_y:       defw    0

ship_x:         defw    152
ship_y:         defw    184

tiles:
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 00
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 01, name=road
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H ; 02, name=ovl_num0
                defb    0FCH, 0FCH, 000H, 000H, 000H, 0FCH, 0FCH, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 000H, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    001H, 001H, 000H, 000H, 000H, 000H, 000H, 001H

                defb    001H, 001H, 0FCH, 0FCH, 001H, 001H, 001H, 001H ; 03
                defb    001H, 0FCH, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H
                defb    001H, 000H, 000H, 000H, 000H, 000H, 000H, 001H

                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H ; 04
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    001H, 000H, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 000H, 000H, 001H, 001H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 001H
                defb    001H, 000H, 000H, 000H, 000H, 000H, 000H, 001H

                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H ; 05
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    001H, 000H, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 001H, 001H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    0FCH, 0FCH, 001H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 001H, 000H, 000H, 000H, 000H, 001H, 001H

                defb    001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 001H, 001H ; 06
                defb    001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H
                defb    001H, 000H, 000H, 000H, 0FCH, 0FCH, 000H, 000H
                defb    001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 001H
                defb    001H, 001H, 001H, 001H, 000H, 000H, 000H, 000H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H ; 07
                defb    0FCH, 0FCH, 000H, 000H, 000H, 000H, 000H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
                defb    001H, 000H, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    001H, 001H, 001H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 001H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 001H, 000H, 000H, 000H, 000H, 001H, 001H

                defb    001H, 001H, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H ; 08
                defb    001H, 0FCH, 0FCH, 000H, 000H, 000H, 001H, 001H
                defb    0FCH, 0FCH, 000H, 000H, 001H, 001H, 001H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 001H, 000H, 000H, 000H, 000H, 001H, 001H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H ; 09
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 000H, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 001H, 001H, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 000H, 001H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    001H, 001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 000H, 000H, 001H, 001H, 001H

                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H ; 0A
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 001H, 000H, 000H, 000H, 000H, 001H, 001H

                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H ; 0B
                defb    0FCH, 0FCH, 000H, 000H, 0FCH, 0FCH, 001H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 001H
                defb    001H, 001H, 000H, 000H, 0FCH, 0FCH, 000H, 001H
                defb    001H, 001H, 001H, 0FCH, 0FCH, 000H, 000H, 001H
                defb    001H, 0FCH, 0FCH, 0FCH, 000H, 000H, 001H, 001H
                defb    001H, 001H, 000H, 000H, 000H, 001H, 001H, 001H

                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H ; 0C, name=terrain
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H

                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH ; 0D, name=terrain_border_left
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH

                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H ; 0E, name=terrain_border_right
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 0F, name=road_terrain_bottom
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H

                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H ; 10, name=road_terrain_top
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    090H, 090H, 090H, 090H, 090H, 090H, 090H, 090H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 11, name=road_river_bottom
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH

                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH ; 12, name=road_river_top
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH ; 13, name=river
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH
                defb    02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH, 02CH

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 14, name=road_intersect_1
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 15, name=road_intersect_2
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H

                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH ; 16, name=road_intersect_3
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    090H, 090H, 090H, 054H, 054H, 02CH, 02CH, 02CH
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H ; 17, name=road_intersect_4
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    02CH, 02CH, 02CH, 054H, 054H, 090H, 090H, 090H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    054H, 054H, 054H, 054H, 054H, 054H, 054H, 054H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 18, name=road_sep
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
                defb    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H ; 19, name=fuel_border
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0F0H

                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 1A
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 0F0H, 0F0H, 0F0H, 0F0H, 0F0H, 0F0H, 0F0H

                defb    0F0H, 0F0H, 0F0H, 0F0H, 0F0H, 0F0H, 0F0H, 0F0H ; 1B
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H

                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H ; 1C
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0F0H, 001H, 001H, 001H, 001H, 001H, 001H, 001H

                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H ; 1D, name=fuel_red
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H
                defb    0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H, 0C0H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H ; 1E, name=fuel
                defb    001H, 0FCH, 0FCH, 000H, 000H, 000H, 0FCH, 000H
                defb    001H, 0FCH, 0FCH, 000H, 0FCH, 001H, 001H, 000H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 0FCH, 000H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 001H, 000H, 001H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
                defb    001H, 000H, 000H, 000H, 000H, 001H, 001H, 001H

                defb    0FCH, 0FCH, 001H, 001H, 0FCH, 0FCH, 001H, 001H ; 1F
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 001H
                defb    001H, 000H, 000H, 000H, 000H, 000H, 000H, 001H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H ; 20
                defb    001H, 0FCH, 0FCH, 000H, 000H, 000H, 0FCH, 000H
                defb    001H, 0FCH, 0FCH, 000H, 0FCH, 001H, 001H, 000H
                defb    001H, 0FCH, 0FCH, 0FCH, 0FCH, 000H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 0FCH, 000H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 001H, 000H, 0FCH, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H
                defb    001H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H ; 21
                defb    001H, 0FCH, 0FCH, 000H, 000H, 001H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 001H, 001H, 001H, 001H
                defb    001H, 0FCH, 0FCH, 000H, 001H, 001H, 0FCH, 001H
                defb    001H, 0FCH, 0FCH, 000H, 001H, 0FCH, 0FCH, 000H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 000H
                defb    001H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0FCH ; 22, name=ship_v
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0FCH
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 0FCH
                defb    001H, 001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH
                defb    001H, 001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH
                defb    001H, 001H, 001H, 0C0H, 001H, 001H, 0FCH, 0FCH
                defb    001H, 001H, 001H, 0C0H, 001H, 001H, 0FCH, 0FCH
                defb    001H, 001H, 001H, 0FCH, 001H, 0FCH, 0FCH, 0FCH
                defb    0C0H, 001H, 001H, 0FCH, 01CH, 0FCH, 0FCH, 0C0H
                defb    0C0H, 001H, 001H, 01CH, 0FCH, 0FCH, 0C0H, 0C0H
                defb    0FCH, 001H, 001H, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
                defb    0FCH, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH, 0FCH
                defb    0FCH, 0FCH, 0FCH, 001H, 0C0H, 0C0H, 0FCH, 0FCH
                defb    0FCH, 0FCH, 001H, 001H, 0C0H, 0C0H, 001H, 0FCH
                defb    0FCH, 001H, 001H, 001H, 001H, 001H, 001H, 0FCH
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0FCH, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0FCH, 001H, 001H, 001H, 001H, 001H, 001H, 001H
                defb    0FCH, 001H, 001H, 0C0H, 001H, 001H, 001H, 001H
                defb    0FCH, 001H, 001H, 0C0H, 001H, 001H, 001H, 001H
                defb    0FCH, 0FCH, 001H, 0FCH, 001H, 001H, 001H, 001H
                defb    0FCH, 0FCH, 01CH, 0FCH, 001H, 001H, 0C0H, 001H
                defb    0C0H, 0FCH, 0FCH, 01CH, 001H, 001H, 0C0H, 001H
                defb    0C0H, 0FCH, 0FCH, 0FCH, 001H, 001H, 0FCH, 001H
                defb    0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 0FCH, 001H
                defb    0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H
                defb    0FCH, 0C0H, 0C0H, 001H, 0FCH, 0FCH, 0FCH, 001H
                defb    001H, 0C0H, 0C0H, 001H, 001H, 0FCH, 0FCH, 001H
                defb    001H, 001H, 001H, 001H, 001H, 001H, 0FCH, 001H

level_map:
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch

                defb    10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 16h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 17h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h
                defb    01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h
                defb    18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h
                defb    01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h
                defb    0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 14h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 15h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh

                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch

                defb    10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 16h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 17h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h
                defb    01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h
                defb    18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h
                defb    01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h
                defb    0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 14h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 15h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh

                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch

                defb    10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 16h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 12h, 17h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h, 10h
                defb    01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h
                defb    18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h, 18h
                defb    01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h
                defb    0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 14h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 11h, 15h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh

                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch
                defb    0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Dh, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 13h, 0Eh, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch

score_map:
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 02h, 02h, 02h, 02h, 02h, 02h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h

fuel_map:
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 1Ah, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 22h, 24h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 1Eh, 1Fh, 20h, 21h, 19h, 1Dh, 1Dh, 1Dh, 1Dh, 1Dh, 1Dh, 1Dh, 1Dh, 00h, 00h, 00h, 00h, 1Ch, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 23h, 25h, 00h, 00h, 00h
                defb    00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 1Bh, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h

