
#include "defines.inc"

start
                        add     cog_param_addr, #1

                        test    vram_expand_h_flag, PAR wz
        if_nz           shl     hub_vram_size, #1
                        test    vram_expand_v_flag, PAR wz
        if_nz           shl     hub_vram_size, #1
                        add     hub_bitmap_ram, hub_vram_size

                        rdbyte  a, cog_param_addr
                        and     a, #$0F wz
        if_nz           add     hub_bitmap_ram, #VRAM_TILES_H
        if_nz           djnz    a, #$-1

                        add     cog_param_addr, #1

                        rdbyte  a, cog_param_addr
                        and     a, #$0F wz
        if_nz           add     hub_bitmap_ram, #VRAM_TILES_H
        if_nz           djnz    a, #$-1

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
                        mov     a, PAR
                        shl     a, #14+3
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
cog_driver_addr         long    $7600
cog_param_addr          long    $7E00

inc_par_offset          long    %00000000000001_00000000000000_0_000

hub_sprite_ram          long    $0000
hub_video_ram           long    $0000 + (MAX_SPRITES * 4)
hub_bitmap_ram          long    $0000 + (MAX_SPRITES * 4)

hub_vram_size           long    VRAM_TILES_H * VRAM_TILES_V

hub_tiles_ptr           long    $7EB0
hub_sprites_ptr         long    $7EB2
hub_fi                  long    $7EBC

vram_expand_h_flag      long    VRAM_EXPAND_H << 2
vram_expand_v_flag      long    VRAM_EXPAND_V << 2

// uninitialised data and/or temporaries

a                       .res    1
b                       .res    1
ptr                     .res    1
data                    .res    1
ack                     .res    1
mask                    .res    1
ecnt                    .res    1
ccnt                    .res    1

i2c_addr                .res    1
i2c_hub_addr            .res    1
i2c_data                .res    1

                        fit     $1F0
