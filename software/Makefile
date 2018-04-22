
CC := zcc
ASM := z80asm

ASMFLAGS := --cpu=z80 -r0100h

all: fwupd.com hscroll.com vscroll.com bars.com


fwupd.com: fwupd.s Makefile
	$(ASM) $(ASMFLAGS) -b --output=$@ $<

hscroll.com: hscroll.s music.s Makefile
	$(ASM) $(ASMFLAGS) -b --output=$@ hscroll.s music.s

vscroll.com: vscroll.s music.s Makefile
	$(ASM) $(ASMFLAGS) -b --output=$@ vscroll.s music.s

bars.com: bars.s Makefile
	$(ASM) $(ASMFLAGS) -b --output=$@ bars.s


%.o: %.s
	$(ASM) $(ASMFLAGS) --output=$@ $<


clean:
	rm -f *.com *.o *.map *.err *.lis

