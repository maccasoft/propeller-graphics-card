
#include "defines.inc"

start
                        mov     ptr, PAR
                        rdbyte  data, ptr
                        add     ptr, #1
                        rdbyte  data1, ptr
                        add     ptr, #1
                        rdbyte  data2, ptr

                        test    data, #VRAM_EXPAND_H wz
        if_nz           shl     hub_vram_size, #1
                        test    data, #VRAM_EXPAND_V wz
        if_nz           shl     hub_vram_size, #1
                        add     hub_bitmap_ram, hub_vram_size

                        and     data1, #$0F wz
        if_nz           add     hub_bitmap_ram, #VRAM_TILES_H
        if_nz           djnz    data1, #$-1

                        and     data2, #$0F wz
        if_nz           add     hub_bitmap_ram, #VRAM_TILES_H
        if_nz           djnz    data2, #$-1

                        wrword  hub_bitmap_ram, hub_tiles_ptr
                        wrword  hub_bitmap_ram, hub_sprites_ptr

                        // select driver from user selection
                        mov     a, INA
                        shr     a, #mode_pin_0
                        and     a, #$03
                        movs    _drv0, #video_drivers
                        add     _drv0, a

                        // load the scanline renderers from eeprom
                        mov     i2c_addr, scanline_renderer
                        mov     i2c_hub_addr, cog_driver_addr
                        mov     ccnt, cog_driver_size
                        call    #eeprom_read

                        // start the renderers
                        mov     a, data
                        shl     a, #16+3
                        or      a, cog_driver_addr
                        shl     a, #2
                        or      a, #%1000
                        mov     ecnt, #COGS
_l6                     coginit a
                        add     a, inc_par_offset
                        djnz    ecnt, #_l6

                        // load the video driver code from eeprom
_drv0                   mov     i2c_addr, 0-0
                        mov     i2c_hub_addr, cog_driver_addr
                        mov     ccnt, cog_driver_size
                        call    #eeprom_read

                        // restart ourselves with the video driver
                        mov     a, hub_fi
                        shl     a, #14
                        or      a, cog_driver_addr
                        shl     a, #2
                        cogid   b
                        or      a, b
                        coginit a

                        cogid   a
                        cogstop a

// ---------------------------------------------------------------

#include "i2c.inc"

// ---------------------------------------------------------------

i2c_scl                 long    1 << i2c_scl_pin
i2c_sda                 long    1 << i2c_sda_pin
block_boundary          long    $0000_FFFF

cog_driver_size         long    2048
cog_driver_addr         long    $6600

inc_par_offset          long    %00000000000001_00000000000000_0_000

hub_sprite_ram          long    $0000
hub_video_ram           long    $0000 + (MAX_SPRITES * 4)
hub_bitmap_ram          long    $0000 + (MAX_SPRITES * 4)

hub_vram_size           long    VRAM_TILES_H * VRAM_TILES_V

hub_tiles_ptr           long    $7EB0
hub_sprites_ptr         long    $7EB2
hub_fi                  long    $7EBC

// uninitialised data and/or temporaries

a                       res     1
b                       res     1
ptr                     res     1
data                    res     1
data1                   res     1
data2                   res     1
ack                     res     1
mask                    res     1
ecnt                    res     1
ccnt                    res     1

                        fit     $1F0
