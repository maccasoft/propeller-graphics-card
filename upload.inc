
// ------------------------------------------------------------------------
// PORT 42H Firmware Upload
// ------------------------------------------------------------------------

                        .equ    EEPROM_PAGE_SIZE, 128

upload                  cmp     bus, #$50 wz
        if_z            movs    port42_handler, #_upload1
                        jmp     #loop

_upload1                cmp     bus, #$38 wz
        if_z            movs    port42_handler, #_upload2
        if_nz           movs    port42_handler, #upload
                        jmp     #loop

_upload2                cmp     bus, #$58 wz
        if_z            movs    port42_handler, #_upload3
        if_nz           movs    port42_handler, #upload
                        jmp     #loop

_upload3                cmp     bus, #$31 wz
        if_nz           cmp     bus, #$32 wz
        if_nz           movs    port42_handler, #upload
        if_nz           jmp     #loop

                        or      OUTA, bus_wait

                        cogid   a
                        mov     b, #0
_l8                     cmp     b, a wz
        if_nz           cogstop b
                        add     b, #1
                        cmp     b, #8 wz
        if_nz           jmp     #_l8

                        andn    OUTA, bus_wait

                        mov     hub_addr, #0
                        mov     i2c_addr, #0
                        mov     ccnt, #EEPROM_PAGE_SIZE

                        cmp     bus, #$32 wz
        if_z            mov     ecnt, eeprom_size
        if_z            movs    port42_handler, #upload_eeprom
        if_z            jmp     #loop

                        mov     ecnt, hub_ram_size
                        movs    port42_handler, #upload_ram
                        jmp     #loop

upload_ram
                        wrbyte  bus, hub_addr
                        add     hub_addr, #1
                        djnz    ecnt, #loop

                        cogid   a
                        or      a, restart
                        coginit a

upload_eeprom
                        wrbyte  bus, hub_addr
                        add     hub_addr, #1
                        sub     ecnt, #1 wz
        if_nz           djnz    ccnt, #loop

                        or      OUTA, bus_wait

                        mov     i2c_hub_addr, #0
                        mov     ccnt, #EEPROM_PAGE_SIZE
                        call    #eeprom_write

                        mov     hub_addr, #0
                        mov     ccnt, #EEPROM_PAGE_SIZE
                        andn    OUTA, bus_wait

                        cmp     ecnt, #0 wz
        if_nz           jmp     #loop

                        clkset  reset

reset                   long    $80
restart                 long    ($0004 << 16) | ($F004 << 2)

// ---------------------------------------------------------------

eeprom_write
                        // Select the device & send address
                        call    #i2c_start
                        mov     i2c_data, i2c_addr
                        shr     i2c_data, #15
                        and     i2c_data, #$02
                        or      i2c_data, #EEPROM_ADDR | I2C_WRITE
                        call    #i2c_write
                        mov     i2c_data, i2c_addr
                        shr     i2c_data, #8
                        call    #i2c_write
                        mov     i2c_data, i2c_addr
                        call    #i2c_write

                        // Write data
_l4w                    rdbyte  i2c_data, i2c_hub_addr
                        call    #i2c_write
                        add     i2c_hub_addr, #1
                        add     i2c_addr, #1
                        sub     ccnt, #1 wz
        if_z            jmp     #_l5w
                        test    i2c_addr, #EEPROM_PAGE_SIZE-1 wz
        if_nz           jmp     #_l4w

_l5w                    call    #i2c_stop

                        // 5ms delay to allow write cycle
                        mov     a, ms5_delay
                        add     a, CNT
                        waitcnt a, #0

                        cmp     ccnt, #0 wz
        if_nz           jmp     #eeprom_write

eeprom_write_ret        ret

hub_ram_size            long    $8000
eeprom_size             long    $10000
