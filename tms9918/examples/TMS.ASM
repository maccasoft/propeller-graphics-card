; TMS9918A graphics subroutines
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
;  * Compile with TASM31
;  * Adapted to run with the Propeller emulation firmware


; ---------------------------------------------------------------------------
; configuration parameters

TMSRAM          .EQU  40H               ; TMS9918A VRAM port
TMSREG          .EQU  41H               ; TMS9918A register port

TMSCLKDIV       .EQU  3                 ; Z80 clock divider
                                        ; 1 for <= 10 MHz
                                        ; 2 for <= 5 MHz
                                        ; 3 for <= 3.33 MHz
                                        ; ... and so on

; ---------------------------------------------------------------------------
; register constants

TMSWRITEBIT     .EQU  40H               ; bit to indicate memory write
TMSREGBIT       .EQU  80H               ; bit to indicate register write

TMSCTRL0        .EQU  0                 ; control bits
TMSMODE3        .EQU  1                 ;       mode bit 3
TMSEXTVID       .EQU  0                 ;       external video

TMSCTRL1        .EQU  1                 ; control bits
TMS4K16K        .EQU  7                 ;       4/16K RAM
TMSBLANK        .EQU  6                 ;       screen blank
TMSINTEN        .EQU  5                 ;       interrupt enable
TMSMODE1        .EQU  4                 ;       mode bit 1
TMSMODE2        .EQU  3                 ;       mode bit 2
TMSSPRSIZE      .EQU  1                 ;       sprite size
TMSSPRMAG       .EQU  0                 ;       sprite magnification

TMSNAMETBL      .EQU  2                 ; name table location (* $400)
TMSCOLORTBL     .EQU  3                 ; color table location (* $40)
                                        ;       graphics 2 mode: MSB 0 = $0000, MSB 1 = $2000
TMSPATTERN      .EQU  4                 ; pattern table location (* $800)
TMSSPRITEATTR   .EQU  5                 ; sprite attribute table (* $80)
TMSSPRITEPTTN   .EQU  6                 ; sprite pattern table (* $800)
TMSCOLOR        .EQU  7                 ; screen colors (upper = text, lower = background)

; ---------------------------------------------------------------------------
; color constants

TMSTRANSPARENT  .EQU  0
TMSBLACK        .EQU  1
TMSMEDGREEN     .EQU  2
TMSLIGHTGREEN   .EQU  3
TMSDARKBLUE     .EQU  4
TMSLIGHTBLUE    .EQU  5
TMSDARKRED      .EQU  6
TMSCYAN         .EQU  7
TMSMEDRED       .EQU  8
TMSLIGHTRED     .EQU  9
TMSDARKYELLOW   .EQU  0AH
TMSLIGHTYELLOW  .EQU  0BH
TMSDARKGREEN    .EQU  0CH
TMSMAGENTA      .EQU  0DH
TMSGRAY         .EQU  0EH
TMSWHITE        .EQU  0FH

; ---------------------------------------------------------------------------
; text routines
; set text color
;       A = requested color
TMSTEXTCOLOR
                ADD   A, A              ; shift text color into high nybble
                ADD   A, A
                ADD   A, A
                ADD   A, A
                LD    B, A              ; save for later
                LD    A, (TMSSHADOW + TMSCOLOR) ; get current colors
                AND   0FH               ; mask off old text color
                OR    B                 ; set new text color
                LD    E, TMSCOLOR
                JP    TMSSETREG         ; save it back

; set the address to place text at X/Y coordinate
;       A = X
;       E = Y
TMSTEXTPOS
                LD    D, 0
                LD    HL, 0
                ADD   HL, DE            ; Y x 1
                ADD   HL, HL            ; Y x 2
                ADD   HL, HL            ; Y x 4
                ADD   HL, DE            ; Y x 5
                ADD   HL, HL            ; Y x 10
                ADD   HL, HL            ; Y x 20
                ADD   HL, HL            ; Y x 40
                LD    E, A              ; zero the line
                ADD   HL, DE            ; add column for final address
                EX    DE, HL            ; send address to TMS
                CALL  TMSWRITEADDR
                RET

; copy a null-terminated string to VRAM
;       HL = ram source address
TMSSTROUT
                LD    A, (HL)           ; get the current byte from ram
                CP    0                 ; return when NULL is encountered
                RET   Z
                OUT   (TMSRAM), A       ; send it to vram
                .FILL 14 / TMSCLKDIV, 0 ; nops to waste time
                INC   HL                ; next byte
                JR    TMSSTROUT

; repeat a character a certain number of times
;       A = character to output
;       B = count
TMSCHRRPT
                OUT   (TMSRAM), A
                .FILL 14 / TMSCLKDIV, 0
                DJNZ  TMSCHRRPT
                RET

; output a character
;       A = character to output
TMSCHROUT
                OUT   (TMSRAM), A
                .FILL 14 / TMSCLKDIV, 0
                RET


; ---------------------------------------------------------------------------
; register configuration routines

; shadow copy of register values
TMSSHADOW
                .FILL 8, 0

; set a single register value
;       A = register value
;       E = register to set
TMSSETREG
                LD    HL, TMSSHADOW     ; get shadow table address
                LD    D, 0
                ADD   HL, DE            ; add offset to selected register
                LD    (HL), A           ; save to shadow slot
                OUT   (TMSREG), A       ; send to TMS
                LD    A, TMSREGBIT      ; select requested register
                OR    E
                OUT   (TMSREG), A
                RET

; set the background color
;       A = requested color
TMSBACKGROUND
                AND   0FH               ; mask off high nybble
                LD    B, A              ; save for later
                LD    A, (TMSSHADOW + TMSCOLOR) ; get current colors
                AND   0F0H              ; mask off old background
                OR    B                 ; set new background
                LD    E, TMSCOLOR
                JP    TMSSETREG         ; set the color

; enable vblank interrupts
TMSINTENABLE
                LD    A, (TMSSHADOW + TMSCTRL1) ; get current control register value
                SET   TMSINTEN, A       ; set interrupt enable bit
                LD    E, TMSCTRL1
                JP    TMSSETREG         ; save it back

; disable vblank interrupts
TMSINTDISABLE
                LD    A, (TMSSHADOW + TMSCTRL1) ; get current control register value
                RES   TMSINTEN, A       ; clear interrupt enable bit
                LD    E, TMSCTRL1
                JP    TMSSETREG         ; save it back

; configure tms from specified register table
;       HL = register table
TMSCONFIG
                LD    DE, TMSSHADOW     ; start of shadow area
                LD    C, 8              ; 8 registers
REGLOOP
                LD    A, (HL)           ; get register value from table
                OUT   (TMSREG), A       ; send it to the TMS
                LD    A, 8              ; calculate current register number
                SUB   C
                OR    TMSREGBIT         ; set high bit to indicate a register
                LDI                     ; shadow, then inc pointers and dec counter
                OUT   (TMSREG), A       ; send it to the TMS
                XOR   A                 ; continue until count reaches 0
                OR    C
                JR    NZ, REGLOOP
                RET

; ---------------------------------------------------------------------------
; memory access routines

; set the next address of vram to write
;       DE = address
TMSWRITEADDR
                LD    A, E              ; send lsb
                OUT   (TMSREG), A
                LD    A, D              ; mask off msb to max of 16KB
                AND   3FH
                OR    40H               ; set second highest bit to indicate write
                OUT   (TMSREG), A       ; send msb
                RET

; copy bytes from ram to vram
;       HL = ram source address
;       DE = vram destination address
;       BC = byte count (0 for null terminated)
TMSWRITE
                CALL  TMSWRITEADDR      ; set the starting address
COPYLOOP
                LD    A, (HL)           ; get the current byte from ram
                OUT   (TMSRAM), A       ; send it to vram
                .FILL 11 / TMSCLKDIV, 0 ; nops to waste time
                INC   HL                ; next byte
                DEC   BC                ; continue until count is zero
                LD    A, B
                OR    C
                JR    NZ, COPYLOOP
                RET

; ---------------------------------------------------------------------------
; initialization routines

; register values for blanked screen with 16KB RAM enabled
TMSBLANKREG
                .DB   00H, 80H, 00H, 00H, 00H, 00H, 00H, 00H

; reset registers and clear all 16KB of video memory
TMSRESET
                LD    HL, TMSBLANKREG   ; blank the screen with 16KB enabled
                CALL  TMSCONFIG
                LD    DE, 0             ; start a address 0000H
                CALL  TMSWRITEADDR
                LD    DE, 4000H         ; write 16KB
                LD    BC, TMSRAM        ; writing 0s to vram
CLEARLOOP
                OUT   (C), B            ; send to vram
                DEC   DE                ; continue until counter is 0
                LD    A, D
                OR    E
                JR    NZ, CLEARLOOP
                RET

; register values for multicolor mode
TMSMCREG
                .DB   00000000B         ; external video disabled
                .DB   11001000B         ; 16KB, display enabled, multicolor mode
                .DB   02H               ; name table at $8000
                .DB   00H               ; color table not used
                .DB   00H               ; pattern table at $0000
                .DB   76H               ; sprite attribute table at $3B00
                .DB   03H               ; sprite pattern table at $1800
                .DB   00H               ; black background

; initialize tms for multicolor mode
TMSMULTICOLOR
                CALL  TMSRESET          ; blank the screen and clear vram
                LD    DE, 0800H         ; set name table start address
                CALL  TMSWRITEADDR
                LD    D, 6              ; nametable has 6 different sections
                LD    E, 0              ; first section starts at 0
SECTIONLOOP
                LD    C, 4              ; each section has 4 identical lines
LINELOOP
                LD    B, 32             ; each line is 32 bytes long
                LD    A, E              ; load the section's starting value
BYTELOOP
                OUT   (TMSRAM), A       ; output current name byte
                NOP                     ; extra time to finish vram write
                INC   A                 ; increment name byte
                DJNZ  BYTELOOP          ; next byte
                DEC   C                 ; decrement line counter
                JR    NZ, LINELOOP      ; next line
                LD    A, E              ; next section's starting value is 32
                ADD   A, 32             ; ...more than the previous section
                LD    E, A
                DEC   D                 ; decrement section counter
                JR    NZ, SECTIONLOOP   ; next section
                LD    HL, TMSMCREG      ; switch to multicolor mode
                CALL  TMSCONFIG
                RET

; register values for bitmapped graphics
TMSBITMAPREG
                .DB   00000010B         ; bitmap mode, no external video
                .DB   11000010B         ; 16KB ram; enable display
                .DB   0EH               ; name table at 3800H
                .DB   0FFH              ; color table at 2000H
                .DB   03H               ; pattern table at 0000H
                .DB   76H               ; sprite attribute table at 3B00H
                .DB   03H               ; sprite pattern table at 1800H
                .DB   01H               ; black background

; initialize TMS for bitmapped graphics
TMSBITMAP
                CALL  TMSRESET
                LD    DE, 3800H         ; initialize nametable with 3 sets
                CALL  TMSWRITEADDR      ; of 256 bytes ranging from 00-FF
                LD    B, 3
                LD    A, 0
NAMELOOP
                OUT   (TMSRAM), A
                NOP
                INC   A
                JR    NZ, NAMELOOP
                DJNZ  NAMELOOP
                LD    HL, TMSBITMAPREG  ; configure registers for bitmapped graphics
                CALL  TMSCONFIG
                RET

TMSTEXTREG
                .DB   00000000B         ; text mode, no external video
                .DB   11010000B         ; 16K, Enable Display, Disable Interrupt
                .DB   00H               ; name table at $0000
                .DB   00H               ; color table not used
                .DB   01H               ; pattern table at $0800
                .DB   00H               ; sprite attribute table not used
                .DB   00H               ; sprite pattern table not used
                .DB   0F1H              ; white text on black background

; initialize TMS for text mode
;       HL = address of font to load
TMSTEXTMODE
                PUSH  HL                ; save address of font
                CALL  TMSRESET
                POP   HL                ; load font into pattern table
                LD    DE, 0800H
                LD    BC, 0800H
                CALL  TMSWRITE
                LD    HL, TMSTEXTREG
                CALL  TMSCONFIG
                RET
