
#include "defines.inc"

#define H_RES   320
#define V_RES   240
#define BPP     3

                        .pasm
                        .compress off

                        .section .cog_bitmap_bus_interface_320x240, "ax"

#include "bitmap_bus_interface.inc"
