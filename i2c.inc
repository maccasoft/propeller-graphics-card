
eeprom_read
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

                    // Reselect the device for reading
                    call    #i2c_start
                    mov     i2c_data, i2c_addr
                    shr     i2c_data, #15
                    and     i2c_data, #$02
                    or      i2c_data, #EEPROM_ADDR | I2C_READ
                    call    #i2c_write

                    // Read i2c_data
_l4r                cmp     ccnt, #1 wz
            if_z    jmp     #_l5r
                    add     i2c_addr, #1
                    test    i2c_addr, block_boundary wz
            if_z    jmp     #_l5r
                    mov     ack, #I2C_ACK
                    call    #i2c_read
                    wrbyte  i2c_data, i2c_hub_addr
                    add     i2c_hub_addr, #1
                    sub     ccnt, #1
                    jmp     #_l4r

_l5r                mov     ack, #I2C_NAK
                    call    #i2c_read
                    wrbyte  i2c_data, i2c_hub_addr
                    add     i2c_hub_addr, #1

                    call    #i2c_stop
                    djnz    ccnt, #eeprom_read
eeprom_read_ret     ret

i2c_start
                    or      OUTA, i2c_scl
                    or      DIRA, i2c_scl
                    nop
                    or      OUTA, i2c_sda
                    or      DIRA, i2c_sda
                    nop
                    nop
                    andn    OUTA, i2c_sda
                    nop
                    andn    OUTA, i2c_scl
                    nop
i2c_start_ret       ret

// SDA goes LOW to HIGH with SCL High
i2c_stop
                    andn    OUTA, i2c_scl
                    nop
                    andn    OUTA, i2c_sda
                    nop
                    nop

                    andn    DIRA, i2c_scl
                    nop
                    andn    DIRA, i2c_sda
                    nop
i2c_stop_ret        ret

i2c_write
                    mov     mask, #$80

_l2                 test    i2c_data, mask wz
            if_nz   or      OUTA, i2c_sda
            if_z    andn    OUTA, i2c_sda
                    or      OUTA, i2c_scl               // Toggle SCL from LOW to HIGH to LOW
                    nop
                    nop
                    andn    OUTA, i2c_scl
                    shr     mask, #1 wz
            if_nz   jmp     #_l2

                    andn    DIRA, i2c_sda
                    nop
                    nop

                    or      OUTA, i2c_scl
                    test    i2c_sda, INA wc
                    rcl     ack, #1
                    andn    OUTA, i2c_scl

                    or      OUTA, i2c_sda
                    or      DIRA, i2c_sda

i2c_write_ret       ret

i2c_read
                    mov     i2c_data, #0
                    andn    DIRA, i2c_sda

                    mov     ecnt, #8
_l3
                    nop
                    nop
                    or      OUTA, i2c_scl
                    test    i2c_sda, INA wc
                    rcl     i2c_data, #1
                    andn    OUTA, i2c_scl
                    djnz    ecnt, #_l3

                    cmp     ack, #I2C_NAK wz
            if_z    or      OUTA, i2c_sda
            if_nz   andn    OUTA, i2c_sda
                    or      DIRA, i2c_sda
                    or      OUTA, i2c_scl
                    nop
                    nop
                    andn    OUTA, i2c_scl

                    andn    OUTA, i2c_sda
i2c_read_ret        ret
