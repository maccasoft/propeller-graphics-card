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

#include "defines.inc"

                        .org    0

start                   mov     OUTA, bus_wait
                        mov     DIRA, bus_wait
                        jmp     #init

                        .org    PORT_40             // 40H / 64

port40_handler          shr     bus, #8
                        and     bus, #$0F
                        mov     a, bus
                        add     a, #_port40_table
                        movs    _p40_jmp, a
                        nop
_p40_jmp                jmp     0-0

                        .org    PORT_41             // 41H / 65

port41_handler          jmp     0-0

                        .org    PORT_42             // 42H / 66

                        shr     bus, #8
                        and     bus, #$FF
port42_handler          jmp     #upload

                        .org    PORT_43             // 43H / 67

port43_handler          or      OUTA, bus_wait

                        rdlong  a, hub_fi
                        cmp     a, vsync_line wz
        if_z            jmp     #$-2                // wait for line counter reset (vsync)

                        rdlong  a, hub_fi
                        cmp     a, vsync_line wz
        if_nz           jmp     #$-2                // wait for line counter reset (vsync)

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

_port40_table           long    set_mode            // 00
                        long    loop                // 01
                        long    loop                // 02
                        long    set_x_scroll        // 03
                        long    set_y_scroll        // 04
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
                        mov     data, #0
                        mov     data1, #0
                        mov     data2, #0
                        movs    port41_handler, #_port41_table+12
                        jmp     #loop

set_x_scroll
                        movs    port41_handler, #_port41_table+8
                        jmp     #loop

set_y_scroll
                        movs    port41_handler, #_port41_table+10
                        jmp     #loop

set_tiles_ptr
                        movs    port41_handler, #_port41_table+3
                        jmp     #loop

set_sprites_ptr
                        movs    port41_handler, #_port41_table+5
                        jmp     #loop

write_sprite_ram
                        mov     hub_addr, hub_sprite_ram
                        mov     hub_addr_top, hub_video_ram
                        mov     hub_addr_low, hub_sprite_ram
                        movs    port41_handler, #_port41_table+7
                        jmp     #loop

write_video_ram
                        mov     hub_addr, hub_video_ram
                        mov     hub_addr_top, hub_bitmap_ram
                        mov     hub_addr_low, hub_video_ram
                        movs    port41_handler, #_port41_table+1
                        jmp     #loop

write_bitmap_ram
                        mov     hub_addr, hub_bitmap_ram
                        mov     hub_addr_top, hub_bitmap_ram_top
                        mov     hub_addr_low, hub_bitmap_ram
                        movs    port41_handler, #_port41_table+1
                        jmp     #loop

write_ram
                        mov     hub_addr, #0
                        mov     hub_addr_top, hub_ram_top
                        mov     hub_addr_low, #0
                        movs    port41_handler, #_port41_table+1
                        jmp     #loop

// ------------------------------------------------------------------------
// PORT 41H Handlers
// ------------------------------------------------------------------------

_port41_table           long    write_byte
                        long    add_hub_addr        // +1
                        long    add_hub_addr_hi     // +2
                        long    set_tiles_addr      // +3
                        long    set_tiles_addr_hi   // +4
                        long    set_sprites_addr    // +5
                        long    set_sprites_addr_hi // +6
                        long    add_sprite_offset   // +7
                        long    set_scroll          // +8
                        long    set_xs              // +9
                        long    set_scroll          // +10
                        long    set_ys              // +11
                        long    set_mode_param      // +12
                        long    set_mode_param1     // +13
                        long    set_mode_param2     // +14

write_byte
                        shr     bus, #8
                        wrbyte  bus, hub_addr
                        add     hub_addr, #1
                        cmp     hub_addr, hub_addr_top wc,wz
        if_ae           mov     hub_addr, hub_addr_low
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

add_sprite_offset
                        and     bus, data_bus_mask
                        shr     bus, #6
                        add     hub_addr, bus
                        movs    port41_handler, #_port41_table
                        jmp     #loop

set_scroll
                        and     bus, data_bus_mask
                        shr     bus, #8
                        mov     data, bus
                        add     port41_handler, #1
                        jmp     #loop

set_xs
                        and     bus, data_bus_mask wz
                        or      bus, data
                        wrword  bus, hub_xs_ptr
                        movs    port41_handler, #_port41_table
                        jmp     #loop

set_ys
                        and     bus, data_bus_mask wz
                        or      bus, data
                        wrword  bus, hub_ys_ptr
                        movs    port41_handler, #_port41_table
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
_l1                     cmp     ecnt, a wz
        if_nz           cogstop ecnt
                        add     ecnt, #1
                        cmp     ecnt, #8 wz
        if_nz           jmp     #_l1

                        // clear hub memory
                        mov     a, #0
                        mov     ptr, #0
                        mov     ecnt, #$20
                        shl     ecnt, #8
_l7                     wrlong  a, ptr
                        add     ptr, #4
                        djnz    ecnt, #_l7

                        mov     a, data
                        and     a, #$07
                        add     a, #video_mode_loaders
                        movs    _drv0, a
                        mov     i2c_hub_addr, cog_driver_addr
_drv0                   mov     i2c_addr, 0-0
                        mov     ccnt, cog_driver_size
                        call    #eeprom_read

                        mov     ptr, cog_driver_addr
                        add     ptr, #4+2
                        rdword  vsync_line, ptr

                        mov     ptr, cog_param_addr
                        wrbyte  data, ptr
                        add     ptr, #1
                        wrbyte  data1, ptr
                        add     ptr, #1
                        wrbyte  data2, ptr

                        neg     a, #1
                        wrlong  a, hub_fi

                        mov     a, cog_param_addr
                        shl     a, #14
                        or      a, cog_driver_addr
                        shl     a, #2
                        or      a, #%1000
                        coginit a

                        rdlong  a, hub_fi wz
        if_nz           jmp     #$-1

                        rdword  hub_bitmap_ram, hub_tiles_ptr
                        mov     hub_tiles_data, hub_bitmap_ram
                        mov     hub_sprites_data, hub_bitmap_ram

                        mov     hub_bitmap_ram_top, hub_attributes_ptr
                        sub     hub_bitmap_ram_top, hub_bitmap_ram
                        andn    hub_bitmap_ram_top, #$3F
                        add     hub_bitmap_ram_top, hub_bitmap_ram

                        mov     hub_addr, hub_video_ram
                        mov     hub_addr_top, hub_bitmap_ram
                        mov     hub_addr_low, hub_video_ram

                        movs    port41_handler, #_port41_table

                        andn    OUTA, bus_wait

                        jmp     #loop

// ------------------------------------------------------------------------

#include "i2c.inc"
#include "upload.inc"

// ------------------------------------------------------------------------

bus_trigger             long    BUS_M1|BUS_A6|BUS_RD        // pins state
bus_mask                long    BUS_PINS ^ (BUS_A0|BUS_A1)  // monitored pins

bus_wait                long    1 << wait_pin

data_bus_mask           long    %00000000_00000000_11111111_00000000
inc_par_offset          long    %00000000000001_00000000000000_0_000

i2c_scl                 long    1 << i2c_scl_pin
i2c_sda                 long    1 << i2c_sda_pin
block_boundary          long    $0000_FFFF

cog_driver_size         long    2048
cog_driver_addr         long    $6600
cog_param_addr          long    $6E00

hub_sprite_ram          long    $0000
hub_video_ram           long    $0000 + (MAX_SPRITES * 4)
hub_bitmap_ram          long    $0000 + (MAX_SPRITES * 4)
hub_bitmap_ram_top      long    $0000 + (MAX_SPRITES * 4)
hub_ram_top             long    $8000

hub_tiles_data          long    $0000 + (MAX_SPRITES * 4)
hub_sprites_data        long    $0000 + (MAX_SPRITES * 4)

hub_attributes_ptr
hub_tiles_ptr           long    $7EB0
hub_sprites_ptr         long    $7EB2
hub_xs_ptr              long    $7EB4
hub_ys_ptr              long    $7EB6
hub_fi                  long    $7EBC
hub_sbuf                long    $7EC0

vsync_line              long    239

ms5_delay               long    80_000 * 5

video_mode_loaders
                        long    @__load_start_cog_320x240_video_mode            // 00h
                        long    @__load_start_cog_256x192_video_mode            // 01h
                        long    @__load_start_cog_256x224_video_mode            // 02h
                        long    @__load_start_cog_bitmap_bus_interface_320x240  // 03h
                        long    @__load_start_cog_bitmap_bus_interface_256x192  // 04h
                        long    @__load_start_cog_bitmap_bus_interface_256x224  // 05h

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
