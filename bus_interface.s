/*
 * Propeller Graphics Card for RC2014 Computer
 *
 * I/O Addres line mapping:
 *
 *           P8 P7 P6 P5 P4 P3 P2 P1 P0
 *            -  1  1  0  x  x  1  0  0
 *            |  |  |  |  |  |  |  |  |
 *      D0 ---+  |  |  |  |  |  |  |  |
 *      M1 ------+  |  |  |  |  |  |  |
 *      RD ---------+  |  |  |  |  |  |
 *      WR ------------+  |  |  |  |  |
 *      A1 ---------------+  |  |  |  |
 *      A0 ------------------+  |  |  |
 *      A6 ---------------------+  |  |
 *      A7,A5,A4,A3,A2 ------------+  |
 *      IORQ -------------------------+
 *
 *      P8 must be masked out (data dbus line)
 *
 * Copyright (c) 2018 Marco Maccaferri
 * MIT Licensed
 *
 */

                    .pasm
                    .compress off

                    .section .cog_bus_interface, "ax"

                    .equ    i2c_scl_pin, 28
                    .equ    i2c_sda_pin, 29

                    .equ    I2C_ACK,     0
                    .equ    I2C_NAK,     1
                    .equ    I2C_WRITE,   0
                    .equ    I2C_READ,    1

                    .equ    EEPROM_ADDR, $A0

                    .equ    BUS_M1,      %10000000
                    .equ    BUS_RD,      %01000000
                    .equ    BUS_WR,      %00100000
                    .equ    BUS_A1,      %00010000
                    .equ    BUS_A0,      %00001000
                    .equ    BUS_A6,      %00000100
                    .equ    BUS_A1_A7,   %00000010
                    .equ    BUS_IORQ,    %00000001
                    .equ    BUS_PINS,    %11111111

                    .equ    mode_pin_0,  24
                    .equ    mode_pin_1,  25
                    .equ    wait_pin,    27

                    .equ    PORT_MASK,   %0000_11_100
                    .equ    PORT_40,     %0000_00_100_00  // $04
                    .equ    PORT_41,     %0000_01_100_00  // $0C
                    .equ    PORT_42,     %0000_10_100_00  // $14
                    .equ    PORT_43,     %0000_11_100_00  // $1C

                    .org    0

start               mov     OUTA, #0
                    mov     DIRA, bus_wait
                    jmp     #init

                    .org    PORT_40             // 40H / 64

port40_handler      shr     bus, #8
                    and     bus, #$0F
                    mov     a, bus
                    add     a, #_port40_table
                    movs    _p40_jmp, a
                    nop
_p40_jmp            jmp     0-0

                    .org    PORT_41             // 41H / 65

port41_handler      jmp     0-0

                    .org    PORT_42             // 42H / 66

port42_handler      jmp     #loop

                    .org    PORT_43             // 43H / 67

port43_handler      or      OUTA, bus_wait

                    rdlong  a, hub_fi
                    cmp     a, #239 wz
        if_z        jmp     #$-2                // wait for line counter reset (vsync)

                    rdlong  a, hub_fi
                    cmp     a, #239 wz
        if_nz       jmp     #$-2                // wait for line counter reset (vsync)

                    andn    OUTA, bus_wait
                    jmp     #loop

// ------------------------------------------------------------------------
// BUS Interface
// ------------------------------------------------------------------------

init
                    movs    port41_handler, #_port41_table
                    mov     hub_addr, hub_video_ram

                    mov     bus, #$00           // default video mode
                    jmp     #set_mode

loop
                    waitpeq bus_trigger, bus_mask
                    mov     bus, INA

                    mov     ptr, bus
                    and     ptr, #PORT_MASK
                    jmp     ptr

// ------------------------------------------------------------------------
// PORT 40H Commands
// ------------------------------------------------------------------------

_port40_table       long    set_mode            // 00
                    long    loop                // 01
                    long    loop                // 02
                    long    loop                // 03
                    long    loop                // 04
                    long    loop                // 05
                    long    set_tiles_ptr       // 06
                    long    set_sprites_ptr     // 07
                    long    loop                // 08
                    long    loop                // 09
                    long    loop                // 0A
                    long    loop                // 0B
                    long    write_sprite_ram    // 0C
                    long    write_video_ram     // 0D
                    long    write_bitmap_ram    // 0E
                    long    write_ram           // 0F

set_mode
                    or      OUTA, bus_wait

                    // stops all cogs except the current
                    cogid   a
                    mov     ecnt, #0
_l1                 cmp     ecnt, a wz
        if_nz       cogstop ecnt
                    add     ecnt, #1
                    cmp     ecnt, #8 wz
        if_nz       jmp     #_l1

                    // clear hub memory
                    mov     a, #0
                    mov     ptr, #0
                    mov     ecnt, #$20
                    shl     ecnt, #8
_l7                 wrlong  a, ptr
                    add     ptr, #4
                    djnz    ecnt, #_l7

                    // default tiles and sprites bitmap pointers
                    mov     hub_tiles_data, hub_bitmap_ram
                    mov     hub_sprites_data, hub_bitmap_ram
                    wrword  hub_tiles_data, hub_tiles_ptr
                    wrword  hub_sprites_data, hub_sprites_ptr

                    mov     a, bus              // multiply a by 5 (4 video drivers + renderer)
                    shl     a, #2
                    add     a, bus
                    add     a, #video_drivers

                    movs    _drv0, a
                    movs    _drv1, a

                    mov     a, INA              // adjust for user selection
                    shr     a, #mode_pin_0
                    and     a, #$03
                    add     _drv0, a
                    add     _drv1, #4

                    // load the video driver code from eeprom
_drv0               mov     i2c_addr, 0-0
                    mov     i2c_hub_addr, cog_driver_addr
                    mov     ccnt, cog_driver_size
                    call    #eeprom_read

                    // start the video driver cog
                    mov     a, hub_fi
                    shl     a, #14
                    or      a, cog_driver_addr
                    shl     a, #2
                    or      a, #%1000
                    coginit a

_drv1               mov     i2c_addr, 0-0
                    mov     i2c_hub_addr, cog_driver_addr
                    mov     ccnt, cog_driver_size
                    call    #eeprom_read

                    mov     a, cog_driver_addr
                    shl     a, #2
                    or      a, #%1000
                    mov     ecnt, #COGS
_l6                 coginit a
                    add     a, inc_par_offset
                    djnz    ecnt, #_l6

                    // waits for the cogs to fully load
                    mov     a, cog_driver_size
                    shl     a, #2
                    add     a, CNT
                    waitcnt a, #0

                    andn    OUTA, bus_wait

                    jmp     #loop

set_tiles_ptr
                    movs    port41_handler, #_port41_table+3
                    jmp     #loop

set_sprites_ptr
                    movs    port41_handler, #_port41_table+5
                    jmp     #loop

write_sprite_ram
                    mov     hub_addr, hub_sprite_ram
                    movs    port41_handler, #_port41_table+1
                    jmp     #loop

write_video_ram
                    mov     hub_addr, hub_video_ram
                    movs    port41_handler, #_port41_table+1
                    jmp     #loop

write_bitmap_ram
                    mov     hub_addr, hub_bitmap_ram
                    movs    port41_handler, #_port41_table+1
                    jmp     #loop

write_ram
                    mov     hub_addr, #0
                    movs    port41_handler, #_port41_table+1
                    jmp     #loop

// ------------------------------------------------------------------------
// PORT 41H Commands
// ------------------------------------------------------------------------

_port41_table       long    write_byte
                    long    add_hub_addr        // +1
                    long    add_hub_addr_hi     // +2
                    long    set_tiles_addr      // +3
                    long    set_tiles_addr_hi   // +4
                    long    set_sprites_addr    // +5
                    long    set_sprites_addr_hi // +6

write_byte
                    shr     bus, #8
                    wrbyte  bus, hub_addr
                    add     hub_addr, #1
                    jmp     #loop

add_hub_addr
                    and     bus, data_bus_mask
                    shr     bus, #8
                    add     hub_addr, bus
                    add     port41_handler, #1
                    jmp     #loop

add_hub_addr_hi
                    and     bus, data_bus_mask
                    add     hub_addr, bus
                    movs    port41_handler, #_port41_table
                    jmp     #loop

set_tiles_addr
                    and     bus, data_bus_mask
                    shr     bus, #8
                    mov     hub_tiles_data, hub_bitmap_ram
                    add     hub_tiles_data, bus
                    add     port41_handler, #1
                    jmp     #loop

set_tiles_addr_hi
                    and     bus, data_bus_mask
                    add     hub_tiles_data, bus
                    wrword  hub_tiles_data, hub_tiles_ptr
                    movs    port41_handler, #_port41_table
                    jmp     #loop

set_sprites_addr
                    and     bus, data_bus_mask
                    shr     bus, #8
                    mov     hub_sprites_data, hub_bitmap_ram
                    add     hub_sprites_data, bus
                    add     port41_handler, #1
                    jmp     #loop

set_sprites_addr_hi
                    and     bus, data_bus_mask
                    add     hub_sprites_data, bus
                    wrword  hub_sprites_data, hub_sprites_ptr
                    movs    port41_handler, #_port41_table
                    jmp     #loop

// ------------------------------------------------------------------------
// I2C EEPROM Interface
// ------------------------------------------------------------------------

eeprom_read
                    // Select the device & send address
                    call    #i2c_start
                    mov     data, i2c_addr
                    shr     data, #15
                    and     data, #$02
                    or      data, #EEPROM_ADDR | I2C_WRITE
                    call    #i2c_write
                    mov     data, i2c_addr
                    shr     data, #8
                    call    #i2c_write
                    mov     data, i2c_addr
                    call    #i2c_write

                    // Reselect the device for reading
                    call    #i2c_start
                    mov     data, i2c_addr
                    shr     data, #15
                    and     data, #$02
                    or      data, #EEPROM_ADDR | I2C_READ
                    call    #i2c_write

                    // Read data
_l4                 cmp     ccnt, #1 wz
            if_z    jmp     #_l5
                    add     i2c_addr, #1
                    test    i2c_addr, block_boundary wz
            if_z    jmp     #_l5
                    mov     ack, #I2C_ACK
                    call    #i2c_read
                    wrbyte  data, i2c_hub_addr
                    add     i2c_hub_addr, #1
                    sub     ccnt, #1
                    jmp     #_l4

_l5                 mov     ack, #I2C_NAK
                    call    #i2c_read
                    wrbyte  data, i2c_hub_addr
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

                    or      OUTA, i2c_scl
                    andn    DIRA, i2c_sda
i2c_stop_ret        ret

i2c_write
                    mov     mask, #$80

_l2                 test    data, mask wz
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
                    mov     data, #0
                    andn    DIRA, i2c_sda

                    mov     ecnt, #8
_l3
                    nop
                    nop
                    or      OUTA, i2c_scl
                    test    i2c_sda, INA wc
                    rcl     data, #1
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

// ---------------------------------------------------------------

bus_trigger         long    BUS_M1|BUS_A6|BUS_RD        // pins state
bus_mask            long    BUS_PINS ^ (BUS_A0|BUS_A1)  // monitored pins

bus_wait            long    1 << wait_pin

data_bus_mask       long    %00000000_00000000_11111111_00000000
inc_par_offset      long    %00000000000001_00000000000000_0_000

i2c_scl             long    1 << i2c_scl_pin
i2c_sda             long    1 << i2c_sda_pin
block_boundary      long    $0000_FFFF

cog_driver_size     long    2048
cog_driver_addr     long    $76B0

hub_sprite_ram      long    $0000
hub_video_ram       long    $0000 + (MAX_SPRITES * 4)
hub_bitmap_ram      long    $0000 + (MAX_SPRITES * 4) + (40 * 30)

hub_tiles_data      long    $0000 + (MAX_SPRITES * 4) + (40 * 30)
hub_sprites_data    long    $0000 + (MAX_SPRITES * 4) + (40 * 30)

hub_tiles_ptr       long    $7EB0
hub_sprites_ptr     long    $7EB2
hub_fi              long    $7EBC
hub_sbuf            long    $7EC0

hub_addr            long    0

video_drivers
                    // mode 1
                    long    @__load_start_cog_ntsc_320x240_video_driver
                    long    @__load_start_cog_pal_320x240_video_driver
                    long    @__load_start_cog_vga_320x240_video_driver
                    long    @__load_start_cog_vga_320x240_video_driver
                    long    @__load_start_cog_scanline_renderer_320x240

// uninitialised data and/or temporaries

a                   .res    1
b                   .res    1
c                   .res    1
ptr                 .res    1
data                .res    1
ack                 .res    1
mask                .res    1
bus                 .res    1
ecnt                .res    1
ccnt                .res    1

i2c_addr            .res    1
i2c_hub_addr        .res    1

                    fit     $1F0

/*
 * TERMS OF USE: MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
