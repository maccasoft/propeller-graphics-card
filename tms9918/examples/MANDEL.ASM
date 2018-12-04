; Z80 Mandelbrot with output to TMS9918 video chip
;
; Fixed point Mandelbrot routine from https://rosettacode.org/wiki/Mandelbrot_set#Z80_Assembly
;
; Adapted to TMS9918 by J.B. Langston
; Latest version at https://gist.github.com/jblang/2fe54044a9a71b7fd17d8f8d4c123fb5
;
; Modifications by Marco Maccaferri
;
;  * Run from monitor at address 5000H
;  * Compile with TASM31
;  * Adapted to run with the Propeller emulation firmware
;
; Compile with:
;
;   TASM -80 -h MANDEL.ASM MANDEL.HEX

                .ORG  5000H

                JP    MANDELBROT


                .INCLUDE "TMS.ASM"      ; TMS subroutines

; mandelbrot constants
SCALE           .EQU  256               ; Do NOT change this - the
                                        ; arithmetic routines rely on
                                        ; this scaling factor! :-)

DIVERGENT       .EQU  SCALE * 4

ITERATION_MAX   .EQU  14                ; How many iterations
X_START         .EQU  -2 * SCALE        ; Minimum x-coordinate
X_END           .EQU  SCALE - 1         ; Maximum x-coordinate
X_STEP          .EQU  3                 ; x-coordinate step-width
Y_START         .EQU  -9 * (SCALE / 8)  ; Minimum y-coordinate
Y_END           .EQU  9 * (SCALE / 8) - 1 ; Maximum y-coordinate
Y_STEP          .EQU  3                 ; y-coordinate step-width

; mandelbrot variables
X               .DW   0                 ; x-coordinate
Y               .DW   0                 ; y-coordinate
Z_0             .DW   0
Z_1             .DW   0
SCRATCH_0       .DW   0
Z_0_SQUARE_HIGH .DW   0
Z_0_SQUARE_LOW  .DW   0
Z_1_SQUARE_HIGH .DW   0
Z_1_SQUARE_LOW  .DW   0

; mandelbrot entry point
MANDELBROT
                CALL  TMSBITMAP
                LD    A, 0              ; clear pixel counters
                LD    (XYPOS), A
                LD    (XYPOS + 1), A
                LD    (BITINDEX), A
                LD    HL, Y_START       ; y = y_start
                LD    (Y), HL

; for (y = <initial_value> ; y <= y_end; y += y_step)
; {
OUTER_LOOP      LD    HL, Y_END         ; Is y <= y_end?
                LD    DE, (Y)
                AND   A                 ; Clear carry
                SBC   HL, DE            ; Perform the comparison
                JP    M, MANDEL_END     ; End of outer loop reached

;    for (x = x_start; x <= x_end; x += x_step)
;    {
                LD    HL, X_START       ; x = x_start
                LD    (X), HL
INNER_LOOP      LD    HL, X_END         ; Is x <= x_end?
                LD    DE, (X)
                AND   A
                SBC   HL, DE
                JP    M, INNER_LOOP_END ; End of inner loop reached

;      z_0 = z_1 = 0;
                LD    HL, 0
                LD    (Z_0), HL
                LD    (Z_1), HL

;      for (iteration = iteration_max; iteration; iteration--)
;      {
                LD    A, ITERATION_MAX
                LD    B, A
ITERATION_LOOP  PUSH  BC                ; iteration -> stack
;        z2 = (z_0 * z_0 - z_1 * z_1) / SCALE;
                LD    DE, (Z_1)         ; Compute DE HL = z_1 * z_1
                LD    B, D
                LD    C, E
                CALL  MUL_16
                LD    (Z_0_SQUARE_LOW), HL ; z_0 ** 2 is needed later again
                LD    (Z_0_SQUARE_HIGH), DE

                LD    DE, (Z_0)         ; Compute DE HL = z_0 * z_0
                LD    B, D
                LD    C, E
                CALL  MUL_16
                LD    (Z_1_SQUARE_LOW), HL ; z_1 ** 2 will be also needed
                LD    (Z_1_SQUARE_HIGH), DE

                AND   A                 ; Compute subtraction
                LD    BC, (Z_0_SQUARE_LOW)
                SBC   HL, BC
                LD    (SCRATCH_0), HL   ; Save lower 16 bit of result
                LD    H, D
                LD    L, E
                LD    BC, (Z_0_SQUARE_HIGH)
                SBC   HL, BC
                LD    BC, (SCRATCH_0)   ; HL BC = z_0 ** 2 - z_1 ** 2

                LD    C, B              ; Divide by scale = 256
                LD    B, L              ; Discard the rest
                PUSH  BC                ; We need BC later

;        z3 = 2 * z0 * z1 / SCALE;
                LD    HL, (Z_0)         ; Compute DE HL = 2 * z_0 * z_1
                ADD   HL, HL
                LD    D, H
                LD    E, L
                LD    BC, (Z_1)
                CALL  MUL_16

                LD    B, E              ; Divide by scale (= 256)
                LD    C, H              ; BC contains now z_3

;        z1 = z3 + y;
                LD    HL, (Y)
                ADD   HL, BC
                LD    (Z_1), HL

;        z_0 = z_2 + x;
                POP   BC                ; Here BC is needed again :-)
                LD    HL, (X)
                ADD   HL, BC
                LD    (Z_0), HL

;        if (z0 * z0 / SCALE + z1 * z1 / SCALE > 4 * SCALE)
                LD    HL, (Z_0_SQUARE_LOW) ; Use the squares computed
                LD    DE, (Z_1_SQUARE_LOW) ; above
                ADD   HL, DE
                LD    B, H              ; BC contains lower word of sum
                LD    C, L

                LD    HL, (Z_0_SQUARE_HIGH)
                LD    DE, (Z_1_SQUARE_HIGH)
                ADC   HL, DE

                LD    H, L              ; HL now contains (z_0 ** 2 +
                LD    L, B              ; z_1 ** 2) / scale

                LD    BC, DIVERGENT
                AND   A
                SBC   HL, BC

;          break;
                JP    C, ITERATION_DEC  ; No break
                POP   BC                ; Get latest iteration counter
                JR    ITERATION_END     ; Exit loop

;        iteration++;
ITERATION_DEC   POP   BC                ; Get iteration counter
                DJNZ  ITERATION_LOOP    ; We might fall through!
;      }
ITERATION_END
;      printf("%c", display[iteration % 7]);
                INC   B                 ; increment iteration count to get color
                CALL  DRAWPIXEL         ; plot it

                LD    DE, X_STEP        ; x += x_step
                LD    HL, (X)
                ADD   HL, DE
                LD    (X), HL

                JP    INNER_LOOP
;    }
;    printf("\n");
INNER_LOOP_END

                LD    DE, Y_STEP        ; y += y_step
                LD    HL, (Y)
                ADD   HL, DE
                LD    (Y), HL           ; Store new y-value

                JP    OUTER_LOOP
; }

MANDEL_END
                RET

;
;   Compute DEHL = BC * DE (signed): This routine is not too clever but it
; works. It is based on a standard 16-by-16 multiplication routine for unsigned
; integers. At the beginning the sign of the result is determined based on the
; signs of the operands which are negated if necessary. Then the unsigned
; multiplication takes place, followed by negating the result if necessary.
;
MUL_16          XOR   A                 ; Clear carry and A (-> +)
                BIT   7, B              ; Is BC negative?
                JR    Z, BC_POSITIVE    ; No
                SUB   C                 ; A is still zero, complement
                LD    C, A
                LD    A, 0
                SBC   A, B
                LD    B, A
                SCF                     ; Set carry (-> -)
BC_POSITIVE     BIT   7, D              ; Is DE negative?
                JR    Z, DE_POSITIVE    ; No
                PUSH  AF                ; Remember carry for later!
                XOR   A
                SUB   E
                LD    E, A
                LD    A, 0
                SBC   A, D
                LD    D, A
                POP   AF                ; Restore carry for complement
                CCF                     ; Complement Carry (-> +/-?)
DE_POSITIVE     PUSH  AF                ; Remember state of carry
                AND   A                 ; Start multiplication
                SBC   HL, HL
                LD    A, 16             ; 16 rounds
MUL_16_LOOP     ADD   HL, HL
                RL    E
                RL    D
                JR    NC, MUL_16_EXIT
                ADD   HL, BC
                JR    NC, MUL_16_EXIT
                INC   DE
MUL_16_EXIT     DEC   A
                JR    NZ, MUL_16_LOOP
                POP   AF                ; Restore carry from beginning
                RET   NC                ; No sign inversion necessary
                XOR   A                 ; Complement DE HL
                SUB   L
                LD    L, A
                LD    A, 0
                SBC   A, H
                LD    H, A
                LD    A, 0
                SBC   A, E
                LD    E, A
                LD    A, 0
                SBC   A, D
                LD    D, A
                RET

; working area for 8 pixels at a time
PRIMARY         .DB   0                 ; primary color
SECONDARY       .DB   0                 ; secondary color
PATTERN         .DB   0                 ; color bit pattern
BITINDEX        .DB   0                 ; current bit within byte
XYPOS           .DW   0                 ; current x, y position on the screen

; plot a pixel to TMS9918 screen
;       B = color of pixel
DRAWPIXEL
                LD    A, (BITINDEX)     ; check whether this is the first bit of a byte
                OR    A
                LD    A, B              ; load the current color in a
                JR    NZ, COMPARECOLOR  ; for subsequent bits, proceed to comparison
                LD    (PRIMARY), A      ; for first bit, set both colors to current color
                LD    (SECONDARY), A
COMPARECOLOR
                LD    HL, PRIMARY       ; compare the current color to primary color
                CP    (HL)
                SCF
                JR    Z, SETBIT         ; if it's the same, set the pattern bit
                CP    1                 ; if it's different, is the current color black?
                JR    Z, SWAPBLACK      ; if so, make it the primary color
                LD    (SECONDARY), A    ; otherwise, set secondary color to current color
                OR    A                 ; and clear the pattern bit
                JR    SETBIT
SWAPBLACK
                LD    (PRIMARY), A      ; set the primary color to black
                LD    A, 0              ; clear all previous pattern bits
                LD    (PATTERN), A
                SCF                     ; and set the current pattern bit
SETBIT
                LD    HL, PATTERN       ; pull the current pattern bit into the byte
                RL    (HL)

                LD    A, (BITINDEX)
                INC   A                 ; increment the bit index
                AND   7                 ; mask it to a maximum of 7
                LD    (BITINDEX), A     ; save it back in memory
                CP    0                 ; if this wasn't the last bit, we're done
                RET   NZ

                LD    DE, (XYPOS)       ; calculate address for current x, y position
                LD    A, D              ; h = (y / 8)
                RRCA
                RRCA
                RRCA
                AND   1FH
                LD    H, A
                LD    A, E              ; l = (x & f8) + (y & 7)
                AND   0F8H
                LD    L, A
                LD    A, D
                AND   7
                LD    D, 0
                LD    E, A
                ADD   HL, DE

                EX    DE, HL
                CALL  TMSWRITEADDR      ; set write address within pattern table
                LD    A, (PATTERN)      ; send the pattern to the TMS
                OUT   (TMSRAM), A

                LD    BC, 2000H         ; add the color table base address
                EX    DE, HL
                ADD   HL, BC
                EX    DE, HL
                CALL  TMSWRITEADDR      ; set write address within color table
                LD    A, (PRIMARY)      ; load primary color into upper 4 bits
                ADD   A, A
                ADD   A, A
                ADD   A, A
                ADD   A, A
                LD    HL, SECONDARY     ; load secondary color into lower 4 bits
                OR    (HL)
                OUT   (TMSRAM), A       ; send to TMS

                LD    HL, (XYPOS)       ; increase next x/y position by 8 pixels
                LD    DE, 8
                ADD   HL, DE
                LD    (XYPOS), HL
                RET

                .END
