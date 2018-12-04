; Modifications by Marco Maccaferri
;
;  * Run from monitor at address 5000H
;  * Compile with TASM31
;  * Adapted to run with the Propeller emulation firmware
;
; Compile with:
;
;   TASM -80 -h SPRITE.ASM SPRITE.HEX

FRAMETICKS      .EQU  6                 ; number of interrupts per animation frame
FRAMECOUNT      .EQU  8                 ; number of frames in animation

                .ORG  5000H

                JP    START

                .INCLUDE "TMS.ASM"

START
                CALL  TMSBITMAP
                LD    BC, 0200H
                LD    DE, 1800H
                LD    HL, WORLD0
                CALL  TMSWRITE
                LD    A, FRAMETICKS     ; initialize interrupt counter to frame length
                LD    (TICKCOUNTER), A
MAINLOOP
                IN    A, (TMSREG)       ; wait for vertical sync
                AND   80H
                JR    Z, MAINLOOP
                CALL  DRAWFRAME         ; draw next frame, if it's time
                JR    MAINLOOP          ; busy wait and let interrupts do their thing

TICKCOUNTER     .DB   0                 ; interrupt down counter
CURRFRAME       .DB   0                 ; current frame of animation
XDELTA          .DB   1                 ; direction of x axis motion
YDELTA          .DB   1                 ; directino of y axis motion

; Sprite Attributes
SPRITE1Y        .DB   88
SPRITE1X        .DB   0
SPRITE1NAME     .DB   0
SPRITE1COLOR    .DB   TMSDARKBLUE

SPRITE2Y        .DB   88
SPRITE2X        .DB   0
SPRITE2NAME     .DB   4
SPRITE2COLOR    .DB   TMSLIGHTGREEN

                .DB   0D0H, 00H, 00H, 00H ; end of sprites processing

; change direction of motion
;       HL = pointer to direction variable
CHANGEDIR
                PUSH  AF
                LD    A, (HL)
                NEG
                LD    (HL), A
                POP   AF
                RET

; draw a single animation frame
;       HL = animation data base address
;       A = current animation frame number
DRAWFRAME
                LD    HL, XDELTA        ; move x position
                LD    A, (SPRITE1X)
                ADD   A, (HL)
                LD    (SPRITE1X), A
                LD    (SPRITE2X), A
                CP    240               ; bounce off the edge
                CALL  Z, CHANGEDIR
                CP    0
                CALL  Z, CHANGEDIR
                LD    HL, YDELTA        ; move y position
                LD    A, (SPRITE1Y)
                ADD   A, (HL)
                LD    (SPRITE1Y), A
                LD    (SPRITE2Y), A
                CP    176               ; bounce off the edge
                CALL  Z, CHANGEDIR
                CP    0
                CALL  Z, CHANGEDIR
                LD    A, (TICKCOUNTER)  ; check if we've been called frameticks times
                OR    A
                JR    NZ, FRAMEWAIT     ; if not, wait to draw next animation frame
                LD    A, (CURRFRAME)    ; next animation frame
                ADD   A, A              ; multiply current frame x 8
                ADD   A, A
                ADD   A, A
                LD    (SPRITE1NAME), A  ; set name for first sprite
                ADD   A, 4              ; add 4
                LD    (SPRITE2NAME), A  ; set name for second sprite
                LD    A, (CURRFRAME)    ; next animation frame
                INC   A
                CP    FRAMECOUNT        ; have we displayed all frames yet?
                JR    NZ, SKIPRESET     ; if not, display the next frame
                LD    A, 0              ; if so, start over at the first frame
SKIPRESET
                LD    (CURRFRAME), A    ; save next frame in memory
                LD    A, FRAMETICKS     ; reset interrupt down counter
                LD    (TICKCOUNTER), A
                RET
FRAMEWAIT
                LD    BC, 12            ; send updated sprite attribute table
                LD    DE, 3B00H
                LD    HL, SPRITE1Y
                CALL  TMSWRITE
                LD    HL, TICKCOUNTER   ; not time to switch animation frames yet
                DEC   (HL)              ; decrement down counter
                RET


; planet sprites from TI VDP Programmer's guide
                ; Sprite world0 pattern 1
WORLD0          .DB   007, 028, 056, 112, 120, 092, 014, 015
                .DB   015, 031, 127, 099, 115, 061, 031, 007
                .DB   224, 248, 124, 102, 242, 190, 220, 252
                .DB   248, 160, 192, 192, 226, 244, 248, 224
                ; Sprite world0 pattern 2
                .DB   000, 003, 007, 015, 007, 163, 241, 240
                .DB   240, 224, 128, 028, 012, 002, 000, 000
                .DB   000, 000, 128, 152, 012, 065, 035, 003
                .DB   007, 095, 063, 062, 028, 008, 000, 000

                ; Sprite world1 pattern 1
WORLD1          .DB   003, 031, 062, 124, 126, 151, 003, 003
                .DB   003, 007, 031, 120, 124, 063, 031, 007
                .DB   224, 056, 028, 024, 060, 047, 183, 255
                .DB   254, 232, 240, 240, 248, 124, 248, 224
                ; Sprite world1 pattern 2
                .DB   000, 000, 001, 003, 001, 104, 252, 252
                .DB   252, 248, 224, 007, 003, 000, 000, 000
                .DB   000, 192, 224, 230, 194, 208, 072, 000
                .DB   001, 023, 015, 014, 006, 128, 000, 000

                ; Sprite world2 pattern 1
WORLD2          .DB   007, 031, 063, 127, 063, 229, 192, 192
                .DB   128, 001, 007, 030, 063, 063, 031, 007
                .DB   224, 200, 132, 006, 142, 203, 237, 255
                .DB   255, 250, 252, 060, 062, 220, 248, 224
                ; Sprite world2 pattern 2
                .DB   000, 000, 000, 000, 064, 026, 063, 063
                .DB   127, 254, 248, 097, 064, 000, 000, 000
                .DB   000, 048, 120, 248, 112, 052, 018, 000
                .DB   000, 005, 003, 194, 192, 032, 000, 000

                ; Sprite world3 pattern 1
WORLD3          .DB   007, 031, 063, 031, 079, 249, 112, 240
                .DB   224, 128, 001, 007, 015, 031, 031, 007
                .DB   224, 240, 224, 194, 226, 114, 059, 063
                .DB   063, 126, 255, 142, 206, 244, 248, 224
                ; Sprite world3 pattern 2
                .DB   000, 000, 000, 096, 048, 006, 143, 015
                .DB   031, 127, 254, 120, 112, 032, 000, 000
                .DB   000, 008, 028, 060, 028, 141, 196, 192
                .DB   192, 129, 000, 112, 048, 008, 000, 000

                ; Sprite world4 pattern 1
WORLD4          .DB   007, 031, 063, 103, 115, 190, 220, 252
                .DB   248, 160, 192, 065, 099, 055, 031, 007
                .DB   224, 248, 248, 240, 248, 092, 014, 015
                .DB   015, 031, 127, 226, 242, 252, 248, 224
                ; Sprite world4 pattern 2
                .DB   000, 000, 000, 024, 012, 065, 035, 003
                .DB   007, 095, 063, 062, 028, 008, 000, 000
                .DB   000, 000, 004, 014, 006, 163, 241, 240
                .DB   240, 224, 128, 028, 012, 000, 000, 000

                ; Sprite world5 pattern 1
WORLD5          .DB   007, 031, 031, 025, 060, 047, 183, 255
                .DB   254, 232, 240, 112, 120, 061, 031, 007
                .DB   224, 248, 252, 252, 254, 151, 003, 003
                .DB   003, 007, 031, 120, 252, 252, 248, 224
                ; Sprite world5 pattern 2
                .DB   000, 000, 032, 102, 067, 208, 072, 000
                .DB   001, 023, 015, 015, 007, 002, 000, 000
                .DB   000, 000, 000, 002, 000, 104, 252, 252
                .DB   252, 248, 224, 134, 002, 000, 000, 000

                ; Sprite world6 pattern 1
WORLD6          .DB   007, 015, 007, 006, 015, 203, 237, 255
                .DB   255, 250, 252, 060, 062, 031, 031, 007
                .DB   224, 248, 252, 126, 062, 229, 192, 192
                .DB   128, 001, 007, 030, 062, 124, 248, 224
                ; Sprite world6 pattern 2
                .DB   000, 016, 056, 121, 112, 052, 018, 000
                .DB   000, 005, 003, 067, 065, 032, 000, 000
                .DB   000, 000, 000, 128, 192, 026, 063, 063
                .DB   127, 254, 248, 224, 192, 128, 000, 000

                ; Sprite world7 pattern 1
WORLD7          .DB   007, 019, 033, 065, 099, 114, 059, 063
                .DB   063, 126, 255, 015, 079, 055, 031, 007
                .DB   224, 248, 252, 158, 206, 249, 112, 240
                .DB   224, 128, 001, 006, 142, 220, 248, 224
                ; Sprite world7 pattern 2
                .DB   000, 012, 030, 062, 028, 141, 196, 192
                .DB   192, 129, 000, 112, 048, 008, 000, 000
                .DB   000, 000, 000, 096, 048, 006, 143, 015
                .DB   031, 127, 254, 248, 112, 032, 000, 000

                .END
