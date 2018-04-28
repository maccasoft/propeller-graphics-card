/*

	Z88DK base graphics libraries examples
	Simple 3D math function drawing using the Z-buffer algorithm
	
	The picture size is automatically adapted to the target display size
	
	to build:  zcc +<target> <stdio options> -lm -create-app sinwave.c
	
	Examples:
	  zcc +zx -lm -lndos -create-app sinwave.c
	  zcc +aquarius -lm -create-app sinwave.c
	
	$Id: coswave.c,v 1.4 2011-04-01 06:50:45 stefano Exp $

*/

#pragma output noprotectmsdos
#pragma output noredir
#pragma output nogfxglobals

#include <graphics.h>
#include <stdio.h>
#include <math.h>

#define PORTC       0x40
#define PORTD       0x41

#define SETMODE     0x00
#define SETPIX      0x01
#define CLRSCR      0x09
#define WRPAL       0x0B
#define WRBMP       0x0D

#define MODE_320240 0x03
#define MODE_256192 0x04
#define MODE_256224 0x05

#define getmaxx()   255
#define getmaxy()   191

void clg()
{
    outp(PORTC, SETMODE);
    outp(PORTD, MODE_256192);
    outp(PORTD, 0x00);
    outp(PORTD, 0x00);

    outp(PORTC, SETPIX);
}

void plot(int x, int y)
{
    if (x >= 0 && x <= getmaxx() && y >= 0 && y <= getmaxy()) {
        outp(PORTD, y);
        outp(PORTD, x);
        outp(PORTD, 15);
    }
}

void main()
{
    float x,y,incr,yenlarge;
    int z,buf;

	clg();
	incr=2.0/(float)getmaxx();
	yenlarge=(float)getmaxy() / 6.0;

	for (x=-3.0; x<0; x=x+incr)
	{
		buf=255;
		for (y=-3.0; y<3.0; y=y+0.2)
		{
			z = (unsigned char) (float)getmaxy() - (yenlarge * (y + 3.0) + yenlarge * (cos (x*x + y*y)) );

			if (buf>z)
			{
				buf = z;
				plot ( (int) ((float)getmaxx() / 6.0 * (x + 3.0)),  z);
				plot ( (int) ((float)getmaxx() / 6.0 * (3.0 - x)),  z);
			}
		}
	}
}

