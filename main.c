/*
 * Propeller Graphics Card for RC2014 Computer
 *
 * Copyright (c) 2018 Marco Maccaferri
 * MIT Licensed
 *
 */

#include <stdint.h>
#include <propeller.h>

extern uint32_t _load_start_cog_bus_interface[];

static uint8_t default_mode[3] = {
    0x00, 0x00, 0x00
};

int main()
{
    // starts the bus interface code replacing the current cog
    coginit(cogid(), _load_start_cog_bus_interface, (uint32_t)default_mode);
    return 0;
}
