; Nyan Cat for RC2014 with TMS9918 and YM2149
; Hand-written assembly by J.B. Langston
;
; Images and music from Nyan Cat for MSX: https://www.msx.org/news/en/nyan-cat-msx
;
; Modifications by Marco Maccaferri
;
;  * Run from monitor at address 5000H
;  * Compile with TASM31
;  * Adapted to run with the Propeller emulation firmware
;
; Compile with:
;
;   TASM -80 -h NYAN.ASM NYAN.HEX

FRAMETICKS      .EQU  3                 ; number of interrupts per animation frame
FRAMECOUNT      .EQU  12                ; number of frames in animation

                .ORG  5000H

                JP    START

ANIMATION
                .INCLUDE "NYAN.INC"
                .INCLUDE "TMS.ASM"

START
                LD    A, 0
                LD    (CURRFRAME), A
                LD    A, FRAMETICKS     ; initialize interrupt counter to frame length
                LD    (TICKCOUNTER), A

                CALL  TMSMULTICOLOR     ; initialize tms for multicolor mode
                LD    A, TMSDARKBLUE    ; set background color
                CALL  TMSBACKGROUND

MAINLOOP
                IN    A, (TMSREG)       ; wait for vertical sync
                AND   80H
                JR    Z, MAINLOOP
                CALL  DRAWFRAME
                JR    MAINLOOP

TICKCOUNTER     .DB   0                 ; interrupt down counter
CURRFRAME       .DB   0                 ; current frame of animation

; draw a single animation frame
;       HL = animation data base address
;       A = current animation frame number
DRAWFRAME
                LD    A, (TICKCOUNTER)  ; check if we've been called frameticks times
                OR    A
                JR    NZ, FRAMEWAIT     ; if not, wait to draw next animation frame
                LD    HL, ANIMATION     ; draw the current frame
                LD    A, (CURRFRAME)    ; calculate offset for current frame
                LD    D, A              ; x 1
                ADD   A, D              ; x 2
                ADD   A, D              ; x 3
                ADD   A, A              ; x 6
                LD    D, A              ; offset = frame x 600h
                LD    E, 0
                ADD   HL, DE            ; add offset to base address
                LD    DE, 00H           ; pattern table address in vram
                LD    BC, 0600H         ; length of one frame
                CALL  TMSWRITE          ; copy frame to pattern table
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
                LD    HL, TICKCOUNTER   ; not time to switch animation frames yet
                DEC   (HL)              ; decrement down counter
                RET

                .END

