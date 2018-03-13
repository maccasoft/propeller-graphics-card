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

int main()
{
    // starts the bus interface code replacing the current cog
    coginit(cogid(), _load_start_cog_bus_interface, 0);
    return 0;
}
