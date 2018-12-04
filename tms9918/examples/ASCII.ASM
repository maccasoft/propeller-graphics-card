; Copyright 2018 J.B. Langston
;
; Permission is hereby granted, free of charge, to any person obtaining a
; copy of this software and associated documentation files (the "Software"),
; to deal in the Software without restriction, including without limitation
; the rights to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to whom the
; Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
; DEALINGS IN THE SOFTWARE.
;
; Modifications by Marco Maccaferri
;
;  * Run from monitor at address 5000H
;  * Compile with TASM31
;  * Adapted to run with the Propeller emulation firmware
;
; Compile with:
;
;   TASM -80 -h ASCII.ASM ASCII.HEX

LINELEN         .EQU  32
DBLHORIZONTAL   .EQU  205
DBLVERTICAL     .EQU  186
DBLTOPLEFT      .EQU  201
DBLTOPRIGHT     .EQU  187
DBLBOTTOMLEFT   .EQU  200
DBLBOTTOMRIGHT  .EQU  188

                .ORG  5000H

                JP    START

                .INCLUDE "TMS.ASM"
                .INCLUDE "TMSFONT.ASM"

START
                LD    HL, TMSFONT       ; pointer to font
                CALL  TMSTEXTMODE       ; initialize text mode
                LD    A, TMSDARKBLUE    ; set blue background
                CALL  TMSBACKGROUND
                CALL  TEXTBORDER
                LD    A, 11             ; put title at 11, 1
                LD    E, 2
                CALL  TMSTEXTPOS
                LD    HL, MSG           ; output title
                CALL  TMSSTROUT
                LD    A, 0              ; start at character 0
                LD    B, LINELEN        ; 32 chars per line
                LD    C, 6              ; start at line 6
                PUSH  AF                ; save current character
NEXTLINE
                LD    A, (40 - LINELEN) / 2 ; center text
                LD    E, C              ; on current line
                CALL  TMSTEXTPOS
                POP   AF                ; get current character
NEXTCHAR
                OUT   (TMSRAM), A       ; output current character
                CP    255               ; see if we have output everything
                JP    Z, DONE
                INC   A                 ; next character
                CP    B                 ; time for a new line?
                JP    NZ, NEXTCHAR      ; if not, output the next character
                PUSH  AF                ; if so, save the next character
                ADD   A, LINELEN        ; 32 characters on the next line
                LD    B, A
                INC   C                 ; skip two lines
                INC   C
                JP    NEXTLINE          ; do the next line
DONE
                RET

TEXTBORDER
                LD    A, 0              ; start at upper left
                LD    E, 0
                CALL  TMSTEXTPOS
                LD    A, DBLTOPLEFT     ; output corner
                CALL  TMSCHROUT
                LD    B, 38             ; output top border
                LD    A, DBLHORIZONTAL
                CALL  TMSCHRRPT
                LD    A, DBLTOPRIGHT    ; output corner
                CALL  TMSCHROUT
                LD    C, 22             ; output left/right borders for 22 lines
NEXT
                LD    A, DBLVERTICAL    ; vertical border
                CALL  TMSCHROUT
                LD    A, ' '            ; space
                LD    B, 38
                CALL  TMSCHRRPT
                LD    A, DBLVERTICAL    ; vertical border
                CALL  TMSCHROUT
                DEC   C
                JR    NZ, NEXT
                LD    A, DBLBOTTOMLEFT  ; bottom right
                CALL  TMSCHROUT
                LD    A, DBLHORIZONTAL
                LD    B, 38
                CALL  TMSCHRRPT
                LD    A, DBLBOTTOMRIGHT
                CALL  TMSCHROUT
                RET

MSG             .DB   "ASCII Character Set", 0

                .END
