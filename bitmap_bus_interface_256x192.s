
#include "defines.inc"

#define H_RES   256
#define V_RES   192
#define BPP     4

                        .pasm
                        .compress off

                        .section .cog_bitmap_bus_interface_256x192, "ax"

#include "bitmap_bus_interface.inc"
