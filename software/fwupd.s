; Propeller Graphics Card for RC2014
; https://github.com/maccasoft/propeller-graphics-card
;
; Firmware Update
;
; Usage:
;
;   FWUPD FIRMWARE.BIN
;
;   Writes the FIRMWARE.BIN file (or any other file passed on the command line)
;   to the card's EEPROM and restarts the GPU.
;
; Compile:
;
;   z80asm --cpu=z80 -b -r0100h --output=fwupd.com fwupd.s
;
; Copyright (c) 2018 Marco Maccaferri

                defc    PORT    = 42h

                defc    WBOOT   = 0000h
                defc    BDOS    = 0005h
                defc    COMFCB  = 005Ch
                defc    COMBUF  = 0080h

                defc    BCONOT  = 02h
                defc    BPRINT  = 09h
                defc    BOPEN   = 0Fh
                defc    BCLOSE  = 10h
                defc    BRRAND  = 21h

start:
                ld      hl,COMFCB
                ld      de,fcb
                ld      bc,12
                ldir

                ld      c,BOPEN
                ld      de,fcb
                call    BDOS
                cp      0FFH
                jp      z,err1

                ld      a,50h           ; Failsafe sequence
                out     (PORT),a
                ld      a,38h
                out     (PORT),a
                ld      a,58h
                out     (PORT),a

                ld      a,32h           ; Write to EEPROM
                out     (PORT),a

                ld      bc,200h         ; 512 x 128 bytes blocks

_l001:          push    bc

                ld      c,BRRAND
                ld      de,fcb
                call    BDOS
                cp      00h
                jp      nz,fill

                ld      b,128
                ld      hl,COMBUF
_l002:          ld      a,(hl)
                out     (PORT),a
                inc     hl
                djnz    _l002

                ld      hl,(fcb+33)
                inc     hl
                ld      (fcb+33),hl

                ld      c,BCONOT
                ld      e,'.'
                call    BDOS

                pop     bc

                dec     bc
                ld      a,b
                or      c
                jp      nz,_l001

exit:
                ld      c,BCLOSE
                ld      de,fcb
                call    BDOS

                ld      c,BPRINT
                ld      de,msg2
                call    BDOS

                jp      WBOOT

fill:
                pop     bc

_l004:          push    bc              ; Fill remaining bytes with 0

                ld      b,128
                xor     a
_l003:          out     (PORT),a
                nop
                djnz    _l003

                ld      c,BCONOT
                ld      e,'.'
                call    BDOS

                pop     bc

                dec     bc
                ld      a,b
                or      c
                jp      nz,_l004

                jp      exit

err1:
                ld      c,BPRINT
                ld      de,msg1
                call    BDOS

                jp      WBOOT

msg1:           defb    "Error opening file", 13, 10, "$"
msg2:           defb    13, 10, "Done", 13, 10, "$"

fcb:            defb     0                       ; (dr) use default drive
                defb     "FIRMWARE"              ; (f1-f8)
                defb     "BIN"                   ; (t1-t3)
                defb     0, 0, 0, 0              ; (ex,s1,s2,rc)
                defb     0, 0, 0, 0, 0, 0, 0, 0  ; (d0-d15)
                defb     0, 0, 0, 0, 0, 0, 0, 0
                defb     0                       ; (cr)
                defb     0, 0, 0                 ; (r0,r1,r2)
