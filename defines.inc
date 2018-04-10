
                    .equ    i2c_scl_pin, 28
                    .equ    i2c_sda_pin, 29

                    .equ    I2C_ACK,     0
                    .equ    I2C_NAK,     1
                    .equ    I2C_WRITE,   0
                    .equ    I2C_READ,    1

                    .equ    EEPROM_ADDR, $A0

                    .equ    BUS_M1,      %10000000
                    .equ    BUS_RD,      %01000000
                    .equ    BUS_WR,      %00100000
                    .equ    BUS_A1,      %00010000
                    .equ    BUS_A0,      %00001000
                    .equ    BUS_A6,      %00000100
                    .equ    BUS_A1_A7,   %00000010
                    .equ    BUS_IORQ,    %00000001
                    .equ    BUS_PINS,    %11111111

                    .equ    mode_pin_0,  24
                    .equ    mode_pin_1,  25
                    .equ    wait_pin,    27

                    .equ    PORT_MASK,   %0000_11_100
                    .equ    PORT_40,     %0000_00_100_00  // $04
                    .equ    PORT_41,     %0000_01_100_00  // $0C
                    .equ    PORT_42,     %0000_10_100_00  // $14
                    .equ    PORT_43,     %0000_11_100_00  // $1C
