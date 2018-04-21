
#include "defines.inc"

#define H_RES   256
#define V_RES   224
#define BPP     4

                        .pasm
                        .compress off

                        .section .cog_bitmap_bus_interface_256x224, "ax"

#include "bitmap_bus_interface.inc"
