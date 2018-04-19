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

                    .section .cog_bitmap_bus_interface_320x240, "ax"

#include "defines.inc"

                    .org    0

start               mov     OUTA, bus_wait
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

port42_handler      jmp     #upload

                    .org    PORT_43             // 43H / 67

port43_handler      or      OUTA, bus_wait

                    rdlong  a, hub_fi
                    cmp     a, vsync_line wz
        if_z        jmp     #$-2                // wait for line counter reset (vsync)

                    rdlong  a, hub_fi
                    cmp     a, vsync_line wz
        if_nz       jmp     #$-2                // wait for line counter reset (vsync)

                    andn    OUTA, bus_wait
                    jmp     #loop

// ------------------------------------------------------------------------
// BUS Interface
// ------------------------------------------------------------------------

init
                    mov     ptr, PAR
                    rdbyte  data, ptr
                    add     ptr, #1
                    rdbyte  data1, ptr
                    add     ptr, #1
                    rdbyte  data2, ptr
                    jmp     #set_mode_param_end

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
                    long    set_pixel           // 01
                    long    loop                // 02
                    long    loop                // 03
                    long    loop                // 04
                    long    loop                // 05
                    long    loop                // 06
                    long    loop                // 07
                    long    loop                // 08
                    long    clear_screen        // 09
                    long    loop                // 0A
                    long    write_palette       // 0B
                    long    loop                // 0C
                    long    loop                // 0D
                    long    loop                // 0E
                    long    loop                // 0F

set_mode
                    mov     data, #0
                    mov     data1, #0
                    mov     data2, #0
                    movs    port41_handler, #_port41_table+1
                    jmp     #loop

set_pixel
                    mov     data, #0
                    mov     data1, #0
                    mov     data2, #0
                    movs    port41_handler, #_port41_table+4
                    jmp     #loop

clear_screen
                    or      OUTA, bus_wait

                    mov     a, #0
                    mov     ptr, #0
                    mov     ecnt, #$1E
                    shl     ecnt, #8
_l6                 wrlong  a, ptr
                    add     ptr, #4
                    djnz    ecnt, #_l6

                    andn    OUTA, bus_wait
                    jmp     #loop

write_palette
                    mov     hub_addr, hub_palette
                    mov     hub_addr_top, hub_palette_top
                    mov     hub_addr_low, hub_palette
                    movs    port41_handler, #_port41_table+7
                    jmp     #loop

// ------------------------------------------------------------------------
// PORT 41H Commands
// ------------------------------------------------------------------------

_port41_table       long    write_byte
                    long    set_mode_param      // +1
                    long    set_mode_param1     // +2
                    long    set_mode_param2     // +3
                    long    set_pixel_param     // +4
                    long    set_pixel_param1    // +5
                    long    set_pixel_param2    // +6
                    long    add_palette_offset  // +7

write_byte
                    shr     bus, #8
                    wrbyte  bus, hub_addr
                    add     hub_addr, #1
                    cmp     hub_addr, hub_addr_top wc,wz
        if_ae       mov     hub_addr, hub_addr_low
                    jmp     #loop

set_mode_param
                    shr     bus, #8
                    mov     data, bus
                    add     port41_handler, #1
                    jmp     #loop

set_mode_param1
                    shr     bus, #8
                    mov     data1, bus
                    add     port41_handler, #1
                    jmp     #loop

set_mode_param2
                    shr     bus, #8
                    mov     data2, bus

set_mode_param_end
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

                    mov     a, data
                    and     a, #$07
                    add     a, #video_mode_loaders
                    movs    _drv0, a
                    mov     i2c_hub_addr, cog_driver_addr
_drv0               mov     i2c_addr, 0-0 wz
        if_z        jmp     #default_driver
                    mov     ccnt, cog_driver_size
                    call    #eeprom_read

                    mov     ptr, cog_param_addr
                    wrbyte  data, ptr
                    add     ptr, #1
                    wrbyte  data1, ptr
                    add     ptr, #1
                    wrbyte  data2, ptr

                    neg     b, #1
                    wrlong  b, hub_fi

                    mov     a, cog_param_addr
                    shl     a, #14
                    or      a, cog_driver_addr
                    shl     a, #2
                    or      a, #%1000
                    coginit a

                    rdlong  b, hub_fi wz
        if_nz       jmp     #$-1

                    movs    port41_handler, #_port41_table+4

                    jmp     #clear_screen

default_driver
                    mov     ptr, hub_palette
                    wrlong  palette, ptr
                    add     ptr, #4
                    wrlong  palette+1, ptr

                    // select driver from user selection
                    mov     a, INA
                    shr     a, #mode_pin_0
                    and     a, #$03
                    movs    _drv1, #video_drivers
                    add     _drv1, a

                    // load the scanline renderers from eeprom
                    mov     i2c_addr, scanline_renderer
                    mov     i2c_hub_addr, cog_driver_addr
                    mov     ccnt, cog_driver_size
                    call    #eeprom_read

                    // start the renderers
                    mov     a, cog_driver_addr
                    shl     a, #2
                    or      a, #%1000
                    mov     ecnt, #COGS
_l6b                coginit a
                    add     a, inc_par_offset
                    djnz    ecnt, #_l6b

                    // load the video driver code from eeprom
_drv1               mov     i2c_addr, 0-0
                    mov     i2c_hub_addr, cog_driver_addr
                    mov     ccnt, cog_driver_size
                    call    #eeprom_read

                    neg     b, #1
                    wrlong  b, hub_fi

                    mov     a, hub_fi
                    shl     a, #14
                    or      a, cog_driver_addr
                    shl     a, #2
                    or      a, #%1000
                    coginit a

                    rdlong  b, hub_fi wz
        if_nz       jmp     #$-1

                    movs    port41_handler, #_port41_table+4

                    jmp     #clear_screen

set_pixel_param
                    shr     bus, #8
                    mov     data, bus
                    and     data, #$FF
                    add     port41_handler, #1
                    jmp     #loop

set_pixel_param1
                    shr     bus, #8
                    mov     data1, bus
                    and     data1, #$FF
                    add     port41_handler, #1
                    jmp     #loop

set_pixel_param2
                    shr     bus, #8
                    mov     data2, bus
                    and     data2, #$FF
                    movs    port41_handler, #_port41_table+4

                    // data  = y

                    mov     ptr, data
                    shl     ptr, #7

                    // data1 = x

                    test    data2, #$80 wz      // add 8th bit from data2
        if_nz       add     data1, #256

                    cmpsub  data1, #160 wc      // fast division
        if_c        add     ptr, #64
                    cmpsub  data1, #80 wc
        if_c        add     ptr, #32
                    cmpsub  data1, #40 wc
        if_c        add     ptr, #16
                    cmpsub  data1, #20 wc
        if_c        add     ptr, #8
                    cmpsub  data1, #10 wc
        if_c        add     ptr, #4

                    mov     b, data1
                    shl     data1, #1
                    add     data1, b

                    // data2 = pixel (0-7)

                    rdlong  data, ptr

                    mov     a, #7
                    shl     a, data1
                    andn    data, a

                    and     data2, #7
                    shl     data2, data1
                    or      data, data2

                    wrlong  data, ptr

                    jmp     #loop

add_palette_offset
                    shr     bus, #8
                    and     bus, #7
                    add     hub_addr, bus
                    movs    port41_handler, #_port41_table
                    jmp     #loop

// ------------------------------------------------------------------------
// PORT 42H Firmware Upload
// ------------------------------------------------------------------------

upload              shr     bus, #8
                    and     bus, #$FF
                    cmp     bus, #$50 wz
        if_z        movs    port42_handler, #_upload1
                    jmp     #loop

_upload1            shr     bus, #8
                    and     bus, #$FF
                    cmp     bus, #$38 wz
        if_z        movs    port42_handler, #_upload2
        if_nz       movs    port42_handler, #upload
                    jmp     #loop

_upload2            shr     bus, #8
                    and     bus, #$FF
                    cmp     bus, #$58 wz
        if_z        movs    port42_handler, #_upload3
        if_nz       movs    port42_handler, #upload
                    jmp     #loop

_upload3            shr     bus, #8
                    and     bus, #$FF
                    mov     data, bus

                    cmp     data, #$31 wz
        if_nz       cmp     data, #$32 wz
        if_z        movs    port42_handler, #_upload_cnt
        if_nz       movs    port42_handler, #upload
                    jmp     #loop

_upload_cnt         and     bus, data_bus_mask
                    shr     bus, #8
                    mov     ecnt, bus
                    movs    port42_handler, #_upload_cnt_hi
                    jmp     #loop

_upload_cnt_hi      and     bus, data_bus_mask
                    or      ecnt, bus

                    or      OUTA, bus_wait

                    cogid   a
                    mov     b, #0
_l8                 cmp     b, a wz
        if_nz       cogstop b
                    add     b, #1
                    cmp     b, #8 wz
        if_nz       jmp     #_l8

                    andn    OUTA, bus_wait

                    mov     hub_addr, #0
                    mov     i2c_addr, #0
                    mov     ccnt, #32

                    cmp     data, #$31 wz
        if_z        movs    port42_handler, #upload_ram
        if_z        jmp     #loop
                    cmp     data, #$32 wz
        if_z        movs    port42_handler, #upload_eeprom
                    jmp     #loop

upload_ram
                    shr     bus, #8
                    wrbyte  bus, hub_addr
                    add     hub_addr, #1
                    djnz    ecnt, #loop

                    cogid   a
                    or      a, restart
                    coginit a

upload_eeprom
                    shr     bus, #8
                    wrbyte  bus, hub_addr
                    add     hub_addr, #1
                    sub     ecnt, #1 wz
        if_nz       djnz    ccnt, #loop

                    or      OUTA, bus_wait

                    mov     i2c_hub_addr, #0
                    mov     ccnt, #32
                    call    #eeprom_write

                    mov     hub_addr, #0
                    mov     ccnt, #32
                    andn    OUTA, bus_wait

                    cmp     ecnt, #0 wz
        if_nz       jmp     #loop

                    clkset  reset

reset               long    $80
restart             long    ($0004 << 16) | ($F004 << 2)

// ------------------------------------------------------------------------

#include "i2c.inc"

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
_l4w                rdbyte  i2c_data, i2c_hub_addr
                    call    #i2c_write
                    add     i2c_hub_addr, #1
                    add     i2c_addr, #1
                    sub     ccnt, #1 wz
        if_z        jmp     #_l5w
                    test    i2c_addr, #$3F wz
        if_nz       jmp     #_l4w

_l5w                call    #i2c_stop

                    // 5ms delay to allow write cycle
                    mov     a, ms5_delay
                    add     a, CNT
                    waitcnt a, #0

                    cmp     ccnt, #0 wz
        if_nz       jmp     #eeprom_write

eeprom_write_ret    ret

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
cog_driver_addr     long    $6600
cog_param_addr      long    $6E00

hub_video_ram       long    $0000
hub_palette         long    $7800
hub_palette_top     long    $7808

hub_fi              long    $7EBC
hub_sbuf            long    $7EC0

vsync_line          long    239

ms5_delay           long    80_000 * 5

palette             long    $F0_30_C0_00, $FC_3C_CC_0C

video_drivers       long    @__load_start_cog_ntsc_320x240_video_driver
                    long    @__load_start_cog_pal_320x240_video_driver
                    long    @__load_start_cog_vga_320x240_video_driver
                    long    @__load_start_cog_vga_320x240_video_driver

scanline_renderer   long    @__load_start_cog_bitmap_scanline_renderer_320x240

video_mode_loaders
                    long    @__load_start_cog_bus_interface                 // 00h
                    long    @__load_start_cog_bus_interface                 // 01h
                    long    @__load_start_cog_bus_interface                 // 02h
                    long    0                                               // 03h
                    long    @__load_start_cog_bitmap_bus_interface_256x192  // 04h
                    long    @__load_start_cog_bitmap_bus_interface_256x224  // 05h

// uninitialised data and/or temporaries

a                   .res    1
b                   .res    1
c                   .res    1
ptr                 .res    1
data                .res    1
data1               .res    1
data2               .res    1
ack                 .res    1
mask                .res    1
bus                 .res    1
ecnt                .res    1
ccnt                .res    1

i2c_addr            .res    1
i2c_hub_addr        .res    1
i2c_data            .res    1

hub_addr            .res    1
hub_addr_top        .res    1
hub_addr_low        .res    1

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
