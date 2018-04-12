; YM-2149 / AY-3-8912 Example Play Routine
;
; Based on the player from AYcog emulator written by Johannes Ahlebrand
; http://forums.parallax.com/showthread.php?122454
;
; Ported to Z80-CP/M by Marco Maccaferri <macca@maccasoft.com>

                defc    AY_CTRL    = 0D8h   ; control port
                defc    AY_DATA    = 0D0h   ; data port

                xdef    ay_init
                xdef    ay_play_music
                xdef    ay_reset

ay_init:
                call    ay_reset

                ld      a,7                 ; enable tone on ch.A and C
                out     (AY_CTRL),a         ; noise on ch.B
                ld      a,00101010b
                out     (AY_DATA),a

                ld      a,11                ; set envelope rate to 845 (034Dh)
                out     (AY_CTRL),a
                ld      a,4Dh
                out     (AY_DATA),a
                ld      a,12
                out     (AY_CTRL),a
                ld      a,03h
                out     (AY_DATA),a

                ld      hl,music
                ld      (music_ptr),hl
                ld      a,0
                ld      (music_cnt),a

                ret

ay_play_music:
                ld      a,(music_cnt)
                cp      0
                jp      z,_l001
                dec     a
                ld      (music_cnt),a
                ret

_l001:          ld      hl,(music_ptr)

                ; channel 0
                ld      a,(hl)
                cp      255
                jr      nz,_l002

                ld      hl,music
                ld      a,(hl)

_l002:          inc     hl

                cp      0
                jr      z,_l003

                sub     43
                call    note2freq
                ld      a,0
                out     (AY_CTRL),a
                ld      a,c
                out     (AY_DATA),a
                ld      a,1
                out     (AY_CTRL),a
                ld      a,b
                out     (AY_DATA),a

                ld      a,15
                jr      _l004

_l003:          ld      a,(volume+0)
                sub     2
                jr      nc,_l004
                xor     a
_l004:          ld      (volume+0),a

                ld      a,8
                out     (AY_CTRL),a
                ld      a,(volume+0)
                out     (AY_DATA),a

                ; channel 1
                ld      a,(hl)
                cp      255
                jr      nz,_l005

                ld      hl,music
                ld      a,(hl)

_l005:          inc     hl

                cp      0
                jr      z,_l006

                ld      c,a
                ld      a,6
                out     (AY_CTRL),a
                ld      a,c
                out     (AY_DATA),a

                ld      a,13
                out     (AY_CTRL),a
                ld      a,0
                out     (AY_DATA),a

_l006:          ld      a,9
                out     (AY_CTRL),a
                ld      a,16
                out     (AY_DATA),a

                ; channel 2
                ld      a,(hl)
                cp      255
                jr      nz,_l007

                ld      hl,music
                ld      a,(hl)

_l007:          inc     hl

                cp      0
                jr      z,_l008

                sub     43
                call    note2freq
                ld      a,4
                out     (AY_CTRL),a
                ld      a,c
                out     (AY_DATA),a
                ld      a,5
                out     (AY_CTRL),a
                ld      a,b
                out     (AY_DATA),a

                ld      a,15
                jr      _l009

_l008:          ld      a,(volume+2)
                sub     2
                jr      nc,_l009
                xor     a
_l009:          ld      (volume+2),a

                ld      a,10
                out     (AY_CTRL),a
                ld      a,(volume+2)
                out     (AY_DATA),a

                ld      (music_ptr),hl

                ld      a,2
                ld      (music_cnt),a

                ret

; BC = Frequency for note in A

note2freq:
                push    hl

                ld      d,a               ; Divide note by 12 (octave)
                ld      e,12
                call    div_d_e

                ld      b,0               ; D=octave, E=note
                ld      c,e
                ld      hl,note_table
                add     hl,bc
                add     hl,bc
                ld      c,(hl)
                inc     hl
                ld      b,(hl)

                ld      a,d
                cp      0
                jr      z,_l011

_l010:          srl     b                 ; Shift frequency to octave
                rr      c
                dec     a
                jr      nz,_l010

_l011:          pop     hl
                ret

; Resets the sound chip regisers

ay_reset:
                ld      a,7
                out     (AY_CTRL),a
                ld      a,00111111b
                out     (AY_DATA),a

                ld      hl,reg_values
                ld      b,0
_l012:          ld      a,b
                out     (AY_CTRL),a
                ld      a,(hl)
                out     (AY_DATA),a
                inc     b
                ld      a,b
                cp      14
                jr      nz,_l012
                ret

reg_values:     defb     0,  0            ; Default register values
                defb     0,  0
                defb     0,  0
                defb    0
                defb    00111111b
                defb     0,  0,  0
                defb     0,  0
                defb    0

; 8-bit division and module
;
; D = D / E
; E = D % E

div_d_e:
                xor     a
                ld      b,8

_l013:
                sla     d
                rla
                cp      e
                jr      c,_l014
                sub     e
                inc     d

_l014:          djnz    _l013

                ld      e,a

                ret

music_cnt:      defb    0
music_ptr:      defw    0
volume:         defb     0,  0,  0

note_table:     defw    3087, 2914, 2750, 2596, 2450, 2312, 2183, 2060, 1945, 1835, 1732, 1635

music:
                defb    50,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0

                defb    55,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    65,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    65,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0

                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0

                defb    60,  0,  0
                defb    60,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    60,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  0,  0
                defb     0,  0,  0
                defb    67,  0,  0
                defb     0,  0,  0

                defb    50, 31,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  8,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  8,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0

                defb    55, 31,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    65,  8,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    65, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  8,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  8,  0
                defb     0,  0,  0
                defb    55,  8,  0
                defb     0,  0,  0

                defb    50, 31,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  8,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  8,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0
                defb    62,  0,  0
                defb     0,  0,  0

                defb    60, 31,  0
                defb    60,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  8,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    60,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  0,  0
                defb     0,  0,  0
                defb     0, 31,  0
                defb     0,  0,  0
                defb    55,  8,  0
                defb    55,  0,  0
                defb     0, 31,  0
                defb     0,  0,  0
                defb    67,  8,  0
                defb     0,  0,  0
                defb    67,  8,  0
                defb     0,  0,  0

                defb    50, 31,  0
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  8, 86
                defb     0,  0, 86
                defb     0,  0, 86
                defb     0,  0, 86
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50, 31, 86
                defb     0,  0,  86
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62, 31, 93
                defb     0,  0, 93
                defb     0,  0, 93
                defb     0,  0, 93
                defb    50,  8, 93
                defb    50,  0, 93
                defb     0,  0, 93
                defb     0,  0, 93
                defb    62,  0, 93
                defb     0,  0, 93
                defb    62,  0,  0
                defb     0,  0,  0

                defb    55, 31, 79
                defb    55,  0, 79
                defb    55,  0, 79
                defb     0,  0, 79
                defb    55,  0, 79
                defb     0,  0, 79
                defb     0,  0, 79
                defb     0,  0, 79
                defb    65,  8,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55, 31, 77
                defb     0,  0, 77
                defb     0,  0, 77
                defb     0,  0, 77
                defb    65, 31, 77
                defb     0,  0, 77
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  8, 83
                defb    55,  0, 83
                defb     0,  0, 83
                defb     0,  0, 83
                defb    62,  8,  0
                defb     0,  0,  0
                defb    55,  8,  0
                defb     0,  0,  0

                defb    50, 31, 81
                defb     0,  0, 81
                defb    50,  0, 81
                defb     0,  0, 81
                defb    50,  0, 81
                defb     0,  0, 81
                defb     0,  0, 81
                defb     0,  0, 81
                defb    62,  8, 81
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0, 79
                defb    50,  0, 79
                defb     0,  0, 79
                defb     0,  0, 79
                defb    50, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62, 31, 77
                defb     0,  0, 77
                defb     0,  0, 77
                defb     0,  0, 77
                defb    50,  8,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  0, 84
                defb     0,  0, 84
                defb    62,  0,  0
                defb     0,  0,  0

                defb    60, 31, 86
                defb    60,  0, 86
                defb    60,  0, 86
                defb     0,  0, 86
                defb    60, 31, 86
                defb     0,  0, 86
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  8, 86
                defb     0,  0, 86
                defb     0,  0,  0
                defb     0,  0,  0
                defb    60,  0,  0
                defb    60,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55, 31, 89
                defb     0,  0, 89
                defb     0,  0, 89
                defb     0,  0, 89
                defb    67,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  8, 88
                defb    55,  0, 88
                defb     0, 31, 88
                defb     0,  0, 88
                defb    67,  8, 88
                defb     0,  0, 88
                defb    67,  8, 88
                defb     0,  0, 88

                defb    50, 31, 88
                defb    50,  0, 88
                defb    50,  0,  0
                defb     0,  0,  0
                defb    50,  0, 81
                defb     0,  0, 81
                defb     0,  0, 81
                defb     0,  0, 81
                defb    62,  8, 90
                defb     0,  0, 89
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  0, 81
                defb    50,  0, 81
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50, 31, 89
                defb     0,  0, 88
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62, 31, 89
                defb     0,  0, 89
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50,  8, 81
                defb    50,  0, 81
                defb     0,  0, 81
                defb     0,  0, 81
                defb    62,  0, 81
                defb     0,  0, 81
                defb    62,  0,  0
                defb     0,  0,  0

                defb    55, 31, 84
                defb    55,  0, 84
                defb    55,  0, 84
                defb     0,  0, 84
                defb    55,  0, 84
                defb     0,  0, 84
                defb     0,  0, 84
                defb     0,  0, 84
                defb    65,  8, 84
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  0,  0
                defb    55,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55, 31, 83
                defb     0,  0, 83
                defb     0,  0,  0
                defb     0,  0,  0
                defb    65, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  8, 79
                defb    55,  0, 79
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62,  8,  0
                defb     0,  0,  0
                defb    55,  8,  0
                defb     0,  0,  0

                defb    50, 31, 86
                defb     0,  0, 86
                defb    50,  0, 86
                defb     0,  0, 86
                defb    50,  0, 86
                defb     0,  0, 86
                defb     0,  0, 86
                defb     0,  0, 86
                defb    62,  8, 86
                defb     0,  0, 86
                defb     0,  0, 86
                defb     0,  0, 86
                defb    50,  0,  0
                defb    50,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    50, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    62, 31, 82
                defb     0,  0, 81
                defb     0,  0, 81
                defb     0,  0, 81
                defb    50,  8,  0
                defb    50,  0,  0
                defb     0,  0,  8
                defb     0,  0, 79
                defb    62,  0, 79
                defb     0,  0, 79
                defb    62,  0,  0
                defb     0,  0,  0

                defb    60, 31, 82
                defb    60,  0, 81
                defb    60,  0, 81
                defb     0,  0, 81
                defb    60, 31, 81
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  8, 84
                defb     0,  0, 84
                defb     0,  0,  0
                defb     0,  0,  0
                defb    60,  0,  8
                defb    60,  0, 79
                defb     0,  0, 79
                defb     0,  0, 79
                defb    55, 31,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb     0,  0,  0
                defb    67,  0, 79
                defb     0,  0, 79
                defb     0,  0,  0
                defb     0,  0,  0
                defb    55,  8, 77
                defb    55,  0, 77
                defb     0, 31,  0
                defb     0,  0,  0
                defb    67,  8, 72
                defb     0,  0, 72
                defb    67,  8, 72
                defb     0,  0, 72

                defb   255
