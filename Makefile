
TOOLCHAIN_HOME ?= /opt/parallax/bin/
TOOLCHAIN = $(TOOLCHAIN_HOME)propeller-elf-

CC = $(TOOLCHAIN)gcc
CXX = $(TOOLCHAIN)g++
LD = $(TOOLCHAIN)ld
AS = $(TOOLCHAIN)as
AR = $(TOOLCHAIN)ar
OBJCOPY = $(TOOLCHAIN)objcopy
LOADER = $(TOOLCHAIN_HOME)propeller-load
SPINC = $(TOOLCHAIN_HOME)openspin

NAME = firmware
MODEL = lmm
DEPDIR = .deps
PORT ?= /dev/ttyUSB0

DEFS ?= -DCOGS=6 -DMAX_SPRITES=32

CFLAGS = -Os -Wall -m32bit-doubles -fdata-sections -ffunction-sections $(DEFS)
CXXFLAGS = $(CFLAGS) -fno-exceptions -fno-rtti -std=c++0x
ASFLAGS = -x assembler-with-cpp $(DEFS)
LDFLAGS = -fno-exceptions -fno-rtti
SPINFLAGS = -q -u

OBJS = \
	main.o \
	bus_interface.o \
	ntsc_scanline_driver_320x224.o \
	pal_scanline_driver_320x240.o \
	vga_scanline_driver_320x240.o \
	scanline_renderer_320x240.o

LIBS := 

all: $(NAME).elf


-include $(DEPDIR)/*.Po


$(NAME).elf: $(OBJS) Makefile
	$(CXX) -m$(MODEL) $(LDFLAGS) -Wl,-Map=$@.map -o $@ $(OBJS) $(LIBS)


#
# default rules
#
%.o: %.cpp
	@mkdir -p $(DEPDIR)/$(@D)
	$(CXX) -m$(MODEL) $(CXXFLAGS) -MD -MP -MF $(DEPDIR)/$*.Tpo -o $@ -c $<
	@mv -f $(DEPDIR)/$*.Tpo $(DEPDIR)/$*.Po

%.o: %.c
	@mkdir -p $(DEPDIR)/$(@D)
	$(CC) -m$(MODEL) $(CFLAGS) -MD -MP -MF $(DEPDIR)/$*.Tpo -o $@ -c $<
	@mv -f $(DEPDIR)/$*.Tpo $(DEPDIR)/$*.Po

%.o: %.s
	$(CC) $(ASFLAGS) -o $@ -c $<


#
# cleanup
#
clean:
	rm -f *.o *.d *.elf *.map *.a *.cog *.ecog *.binary
	rm -rf $(DEPDIR)


#
# upload and run
#
run:
	$(LOADER) -p $(PORT) -r $(NAME).elf


#
# upload, write to eeprom and run
#
burn:
	$(LOADER) -p $(PORT) -e -r $(NAME).elf

