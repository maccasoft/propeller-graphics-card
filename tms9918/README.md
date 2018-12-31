## TMS9918 Emulation Firmware

The TMS9918A was used in the TI-99/4A, MSX, ColecoVision and original Sega SG-1000.
This emulation firmware supports all graphics modes (mode 1, mode 2, multicolor mode) and the 40x24 text mode.

The emulation tries to be compatible with the original chip as much as possible however due to how
the Propeller operates there are some differences:

 * Wait states are automatically added by asserting the WAIT line. Unlike the original chip there is
   no need to add NOP instructions to delay writes.
 * Interrupts are not currently supported. To implement frame synchronization use the Frame flag readed from
   the status register. Alternatively, any OUT instruction to the port 43H will halt the processor until
   the next frame blanking period.
 * Collision flag and 5th sprite number doesn't yet work.
 * Palette colors may appear different compared to the original chip due to the different DAC configurations.
 * Emulation is not cycle perfect. Registers are readed at the beginning of each rendered line, however the
   timings are not comparable with the original chip and graphic tricks may not work as expected.
 * Undocumented modes are not supported.

The firmware maps the board's I/O ports as follows:

 *  **40H** - TMS9918 data port  
 *  **41H** - TMS9918 registers / address setup port  
 *  **42H** - Reserved  
 *  **43H** - Frame synchronization  

See here for a board to use the original chip with the RC2014 computer:  
[https://github.com/jblang/TMS9918A](https://github.com/jblang/TMS9918A)
