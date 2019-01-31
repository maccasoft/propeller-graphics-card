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

#include "../defines.inc"

                        .org    0

start                   mov     OUTA, bus_wait
                        mov     DIRA, bus_wait
                        jmp     #init

// ------------------------------------------------------------------------
                        .org    PORT_40             // 40H / 64

                        test    bus, #BUS_RD wz
        if_z            jmp     #ram_read
                        andn    DIRA, data_bus_mask
                        jmp     #ram_write

// ------------------------------------------------------------------------
                        .org    PORT_41             // 41H / 65

                        test    bus, #BUS_RD wz
        if_z            jmp     #vdp_read
                        andn    DIRA, data_bus_mask
port41_handler          jmp     0-0

// ------------------------------------------------------------------------
                        .org    PORT_42             // 42H / 66

                        test    bus, #BUS_WR wz
        if_nz           jmp     #loop
                        shr     bus, #8
                        and     bus, #$FF
port42_handler          jmp     #upload

// ------------------------------------------------------------------------
                        .org    PORT_43             // 43H / 67

port43_handler
                        test    bus, #BUS_WR wz
        if_nz           jmp     #loop

                        rdlong  a, hub_fi
                        cmp     a, vsync_line wz
        if_z            jmp     #$-2                // wait for line counter reset (vsync)

                        rdlong  a, hub_fi
                        cmp     a, vsync_line wz
        if_nz           jmp     #$-2                // wait for line counter reset (vsync)

                        andn    OUTA, bus_wait      // release CPU

                        jmp     #loop

// ------------------------------------------------------------------------
// BUS Interface
// ------------------------------------------------------------------------

init
                        // select driver from pin configuration
                        mov     a, INA
                        shr     a, #mode_pin_0
                        and     a, #$03
                        movs    _drv0, #video_drivers
                        add     _drv0, a

                        // load the scanline renderers from eeprom
                        mov     i2c_addr, scanline_renderer
                        mov     i2c_hub_addr, hub_driver_addr
                        mov     ccnt, hub_driver_size
                        call    #eeprom_read

                        // start the renderers
                        mov     a, data
                        shl     a, #16+3
                        or      a, hub_driver_addr
                        shl     a, #2
                        or      a, #%1000
                        mov     ecnt, #COGS
_l6                     coginit a
                        add     a, inc_par_offset
                        djnz    ecnt, #_l6

                        // load the video driver code from eeprom
_drv0                   mov     i2c_addr, 0-0
                        mov     i2c_hub_addr, hub_driver_addr
                        mov     ccnt, hub_driver_size
                        call    #eeprom_read

                        // start the video driver
                        mov     a, hub_fi
                        shl     a, #14
                        or      a, hub_driver_addr
                        shl     a, #2
                        or      a, #%1000
                        coginit a

                        // clear hub memory
                        mov     a, #0
                        mov     ptr, #0
                        mov     ecnt, #$20
                        shl     ecnt, #8
_l7                     wrlong  a, ptr
                        add     ptr, #4
                        djnz    ecnt, #_l7

                        rdlong  a, hub_fi wz        // wait for drivers to start
        if_nz           jmp     #$-1

                        mov     hub_addr, #0
                        movs    port41_handler, #_port41_table

loop
                        mov     OUTA, bus_trigger
                        waitpne OUTA, bus_mask
                        waitpeq OUTA, bus_mask wr   // wr asserts wait line immediately
                        mov     bus, INA
                        test    bus, #1 wz          // check if IOREQ still asserted
        if_nz           jmp     #loop

                        mov     ptr, bus
                        and     ptr, #PORT_MASK
                        jmp     ptr

// ------------------------------------------------------------------------
// PORT 40H Commands
// ------------------------------------------------------------------------

_port41_table           long    vdp_cmd_1
                        long    vdp_cmd_2           // +1

vdp_cmd_1
                        and     bus, data_bus_mask
                        shr     bus, #8
                        mov     data, bus
                        add     port41_handler, #1
                        jmp     #loop

vdp_cmd_2
                        test    bus, data_bus_reg_bit wz
        if_nz           jmp     #vdp_write_reg

                        and     bus, data_bus_msb_mask
                        or      data, bus
                        mov     hub_addr, data
                        movs    port41_handler, #_port41_table
                        jmp     #loop

vdp_write_reg
                        mov     ptr, bus
                        shr     ptr, #8
                        and     ptr, #$07
                        add     ptr, hub_registers
                        wrbyte  data, ptr
                        movs    port41_handler, #_port41_table
                        jmp     #loop

vdp_read
                        rdbyte  bus, hub_status_register
                        shl     bus, #8
                        or      DIRA, data_bus_mask
                        mov     OUTA, bus

                        waitpne bus_trigger, bus_mask
                        andn    DIRA, data_bus_mask

                        shr     bus, #8
                        test    bus, #$80 wz
        if_nz           andn    bus, #$80
        if_nz           wrbyte  bus, hub_status_register

                        jmp     #loop

// ------------------------------------------------------------------------
// PORT 41H Commands
// ------------------------------------------------------------------------

ram_write
                        shr     bus, #8
                        wrbyte  bus, hub_addr
                        add     hub_addr, #1
                        cmp     hub_addr, hub_ram_wrap wc,wz
        if_ae           mov     hub_addr, #0
                        jmp     #loop

ram_read
                        rdbyte  bus, hub_addr
                        shl     bus, #8
                        or      DIRA, data_bus_mask
                        mov     OUTA, bus

                        waitpne bus_trigger, bus_mask
                        andn    DIRA, data_bus_mask

                        add     hub_addr, #1
                        cmp     hub_addr, hub_ram_wrap wc,wz
        if_ae           mov     hub_addr, #0
                        jmp     #loop

// ------------------------------------------------------------------------

#include "../i2c.inc"
#include "../upload.inc"

// ------------------------------------------------------------------------

bus_trigger             long    BUS_M1|BUS_A6                               // pins state
bus_mask                long    BUS_M1|BUS_A6|BUS_A2_A7|BUS_IORQ|BUS_WAIT   // monitored pins

bus_wait                long    BUS_WAIT
bus_write_bit           long    BUS_WR
bus_read_bit            long    BUS_RD

data_bus_mask           long    %00000000_00000000_11111111_00000000
data_bus_reg_bit        long    %00000000_00000000_10000000_00000000
data_bus_write_bit      long    %00000000_00000000_01000000_00000000
data_bus_msb_mask       long    %00000000_00000000_00111111_00000000

inc_par_offset          long    %00000000000001_00000000000000_0_000

i2c_scl                 long    1 << i2c_scl_pin
i2c_sda                 long    1 << i2c_sda_pin
block_boundary          long    $0000_FFFF

hub_ram_wrap            long    $4000
hub_registers           long    $4000
hub_status_register     long    $4008

hub_driver_size         long    2048
hub_driver_addr         long    $7EBC - 2048
hub_fi                  long    $7EBC
hub_sbuf                long    $7EC0

vsync_line              long    239

ms5_delay               long    80_000 * 5

video_drivers           long    @__load_start_cog_ntsc_video_driver
                        long    @__load_start_cog_pal_video_driver
                        long    @__load_start_cog_vga_video_driver
                        long    @__load_start_cog_vga_video_driver

scanline_renderer       long    @__load_start_cog_scanline_renderer

// uninitialised data and/or temporaries

a                       res     1
b                       res     1
ptr                     res     1
data                    res     1
data1                   res     1
data2                   res     1
ack                     res     1
mask                    res     1
bus                     res     1
ecnt                    res     1
ccnt                    res     1

hub_addr                res     1
hub_addr_top            res     1
hub_addr_low            res     1

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
