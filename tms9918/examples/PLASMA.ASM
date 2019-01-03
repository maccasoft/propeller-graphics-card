; Plasma Effect for TMS9918
;
; Based on 6809 Plasma Code by Matt Sarnoff (msarnoff.org)
; Ported to Z80 by J.B. Langston
;
; Original source: https://github.com/74hc595/Ultim809/blob/master/code/user/plasma/plasma.asm
;
; Modifications by Marco Maccaferri
;
;  * Run from monitor at address 5000H
;  * Compile with TASM31
;  * Adapted to run with the Propeller emulation firmware

RAMTOP          .EQU  0FFFFH
IM1VECT         .EQU  38H               ; location of interrupt mode 1 vector
NMIVECT         .EQU  66H

SPRPATTBL       .EQU  00H
PATTBL          .EQU  0800H
SPRATTTBL       .EQU  1000H
NAMETBL         .EQU  1400H
COLORTBL        .EQU  2000H

GRIDWIDTH       .EQU  32
GRIDHEIGHT      .EQU  24
GRIDSIZE        .EQU  GRIDWIDTH * GRIDHEIGHT
NUMCOLORS       .EQU  8
CELLFN          .EQU  WAVE2

                .ORG  5000H

                JP    START

                .INCLUDE "TMS.ASM"

CURGRID         .DW   0                 ; pointers to grid buffers
NEXTGRID        .DW   0

GRID1           .DS   GRIDSIZE          ; grid buffers
GRID2           .DS   GRIDSIZE

START
                CALL  TMSGRAPH1

                LD    DE, PATTBL        ; load pattern table
                LD    B, NUMCOLORS      ; (one copy for each color)
PATLOOP
                PUSH  BC
                LD    HL, PATTERNS
                LD    BC, PATLEN
                CALL  TMSWRITE
                POP   BC
                EX    DE, HL
                LD    DE, PATLEN
                ADD   HL, DE
                EX    DE, HL
                DJNZ  PATLOOP

                LD    HL, COLORS        ; load color table
                LD    DE, COLORTBL
                LD    BC, COLORLEN
                CALL  TMSWRITE

                LD    HL, GRID1         ; init variables
                LD    (CURGRID), HL
                LD    HL, GRID2
                LD    (NEXTGRID), HL
                LD    IX, 3             ; divide by 3 counter

                LD    DE, 0             ; clear frame counter
MAINLOOP
                LD    HL, (NEXTGRID)    ; init cell pointer
                LD    C, GRIDHEIGHT     ; init row counter
YLOOP
                LD    B, GRIDWIDTH      ; init column counter
XLOOP
                CALL  CELLFN            ; calculate current cell
                AND   7FH
                LD    (HL), A           ; save cell in buffer
                INC   HL                ; cell pointer
                DJNZ  XLOOP             ; next column
                DEC   C                 ; next row
                JP    NZ, YLOOP
                INC   D                 ; frame counter
                DEC   IX
                JP    NZ, FLIPBUFFERS
                LD    IX, 3
                INC   E                 ; frame/3 counter
FLIPBUFFERS
                LD    BC, (NEXTGRID)    ; swap buffer pointers
                LD    HL, (CURGRID)
                LD    (CURGRID), BC
                LD    (NEXTGRID), HL

WAIT            IN    A, (TMSREG)       ; wait for vertical sync
                AND   80H
                JR    Z, WAIT

                PUSH  DE
                LD    HL, (CURGRID)     ; copy current frame buffer to name table
                LD    DE, NAMETBL
                LD    BC, GRIDSIZE
                CALL  TMSWRITE
                POP   DE

                JP    MAINLOOP

GRADIENT                                ; diagonal gradient
                LD    A, B              ; x
                ADD   A, C              ; x + y
                SUB   D                 ; x + y - time
                RET

MUNCHING                                ; munching squares
                LD    A, B              ; x
                DEC   A                 ; x - 1
                XOR   C                 ; (x - 1) xor y
                ADD   A, D              ; ((x - 1) xor y) + time
                RET

WAVE                                    ; plasma 1
                PUSH  HL
                LD    H, SIN8 >> 8
                LD    A, B              ; x
                ADD   A, D              ; x + time
                LD    L, A
                LD    A, (HL)           ; sin(x + time)
                ADD   A, C              ; sin(x + time) + y
                SUB   D                 ; sin(x + time) + y - time
                LD    L, A
                LD    A, (HL)           ; sin(sin(x + time) + y - time)
                POP   HL
                RET

WAVE2                                   ; plasma 2
                PUSH  HL
                PUSH  BC
                LD    H, SIN8 >> 8
                LD    A, B              ; x
                ADD   A, E              ; x + time/3
                LD    L, A
                LD    A, (HL)           ; sin(x + time/3)
                ADD   A, D              ; sin(X + time/3) + time
                LD    L, A
                LD    B, (HL)           ; sin(sin(X + time/3) + time)
                LD    A, C              ; y
                ADD   A, D              ; y + time
                LD    L, A
                LD    A, (HL)           ; sin(y + time)
                ADD   A, E              ; sin(y + time) + time/3
                LD    L, A
                LD    A, (HL)           ; sin(sin(y + time) + time/3)
                ADD   A, B              ; sin(sin(y + time) + time/3) + sin(sin(X + time/3) + time)
                POP   BC
                POP   HL
                RET

; sine table

                .ORG  ($ + 255) & 0FF00H ; ALIGN 256

SIN8            .DB   0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 34, 37, 39
                .DB   42, 45, 48, 51, 54, 57, 60, 62, 65, 68, 70, 73, 75
                .DB   78, 80, 83, 85, 87, 90, 92, 94, 96, 98, 100, 102
                .DB   104, 106, 107, 109, 110, 112, 113, 115, 116, 117
                .DB   118, 120, 121, 122, 122, 123, 124, 125, 125, 126
                .DB   126, 126, 127, 127, 127, 127, 127, 127, 127, 126
                .DB   126, 126, 125, 125, 124, 123, 122, 122, 121, 120
                .DB   118, 117, 116, 115, 113, 112, 110, 109, 107, 106
                .DB   104, 102, 100, 98, 96, 94, 92, 90, 87, 85, 83, 80
                .DB   78, 75, 73, 70, 68, 65, 62, 60, 57, 54, 51, 48, 45
                .DB   42, 39, 37, 34, 30, 27, 24, 21, 18, 15, 12, 9, 6, 3
                .DB   -4, -7, -10, -13, -16, -19, -22, -25, -28, -31
                .DB   -35, -38, -40, -43, -46, -49, -52, -55, -58, -61
                .DB   -63, -66, -69, -71, -74, -76, -79, -81, -84, -86
                .DB   -88, -91, -93, -95, -97, -99, -101, -103, -105
                .DB   -107, -108, -110, -111, -113, -114, -116, -117
                .DB   -118, -119, -121, -122, -123, -123, -124, -125
                .DB   -126, -126, -127, -127, -127, -128, -128, -128
                .DB   -128, -128, -128, -128, -127, -127, -127, -126
                .DB   -126, -125, -124, -123, -123, -122, -121, -119
                .DB   -118, -117, -116, -114, -113, -111, -110, -108
                .DB   -107, -105, -103, -101, -99, -97, -95, -93, -91
                .DB   -88, -86, -84, -81, -79, -76, -74, -71, -69, -66
                .DB   -63, -61, -58, -55, -52, -49, -46, -43, -40, -38
                .DB   -35, -31, -28, -25, -22, -19, -16, -13, -10, -7, -4, -1

; color table

COLORS          .DB   98H, 98H
                .DB   0B9H, 0B9H
                .DB   3BH, 3BH
                .DB   73H, 73H
                .DB   57H, 57H
                .DB   45H, 45H
                .DB   0D4H, 0D4H
                .DB   8DH, 8DH
COLORLEN        .EQU  $ - COLORS

; pattern table

PATTERNS
                ; tile (0,0)-(7,7)
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                ; tile (8,0)-(15,7)
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00000000B
                .DB   00010000B
                .DB   00000000B
                .DB   00000000B
                ; tile (16,0)-(23,7)
                .DB   00000000B
                .DB   00000001B
                .DB   10010000B
                .DB   00001000B
                .DB   00000010B
                .DB   10000000B
                .DB   00010000B
                .DB   00000010B
                ; tile (24,0)-(31,7)
                .DB   00000000B
                .DB   00101010B
                .DB   00000000B
                .DB   01001001B
                .DB   00010000B
                .DB   10000100B
                .DB   00100000B
                .DB   00010010B
                ; tile (32,0)-(39,7)
                .DB   00100001B
                .DB   01001010B
                .DB   00100001B
                .DB   00010100B
                .DB   01100000B
                .DB   10101001B
                .DB   01000100B
                .DB   00010010B
                ; tile (40,0)-(47,7)
                .DB   00100100B
                .DB   10010010B
                .DB   01001010B
                .DB   01010100B
                .DB   10001010B
                .DB   00010010B
                .DB   10101010B
                .DB   10010000B
                ; tile (48,0)-(55,7)
                .DB   10101010B
                .DB   01001001B
                .DB   01010101B
                .DB   10010010B
                .DB   01010101B
                .DB   10101010B
                .DB   01001010B
                .DB   01010101B
                ; tile (56,0)-(63,7)
                .DB   10101010B
                .DB   01010101B
                .DB   10101010B
                .DB   01010101B
                .DB   10101010B
                .DB   01010101B
                .DB   10101010B
                .DB   01010101B
                ; tile (64,0)-(71,7)
                .DB   10101010B
                .DB   01101101B
                .DB   10101011B
                .DB   10101010B
                .DB   11010010B
                .DB   10101010B
                .DB   01101101B
                .DB   01010101B
                ; tile (72,0)-(79,7)
                .DB   11011011B
                .DB   01101010B
                .DB   10111011B
                .DB   01010110B
                .DB   10101001B
                .DB   01010111B
                .DB   11111010B
                .DB   01010110B
                ; tile (80,0)-(87,7)
                .DB   10111101B
                .DB   11010111B
                .DB   01111010B
                .DB   10101111B
                .DB   11101010B
                .DB   10111110B
                .DB   11010101B
                .DB   11011101B
                ; tile (88,0)-(95,7)
                .DB   11111111B
                .DB   01010101B
                .DB   11111111B
                .DB   10101010B
                .DB   11111111B
                .DB   11010101B
                .DB   10111111B
                .DB   11101011B
                ; tile (96,0)-(103,7)
                .DB   11111111B
                .DB   01101101B
                .DB   11111111B
                .DB   11011011B
                .DB   10111111B
                .DB   11101101B
                .DB   01111111B
                .DB   11101101B
                ; tile (104,0)-(111,7)
                .DB   11111111B
                .DB   11111111B
                .DB   01101111B
                .DB   11110110B
                .DB   11111111B
                .DB   01111111B
                .DB   11101101B
                .DB   11111111B
                ; tile (112,0)-(119,7)
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11101111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                ; tile (120,0)-(127,7)
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
                .DB   11111111B
PATLEN          .EQU  $ - PATTERNS

                .END
