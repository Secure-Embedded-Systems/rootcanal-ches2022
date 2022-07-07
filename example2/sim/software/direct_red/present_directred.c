#define SKIVA
#define D_ 1
#define FD 1
#ifndef DEFINES
	#include "defines.h"
#endif
#include "present_cells.h"
#include "present_sbox.h"


int main( int argc, char* argv[] ) {
	reg_uart_clkdiv = 104;

	// fixed expected memory address for key 
	volatile uint32_t* key32 = (volatile uint32_t*)0x00000008;
	// fixed expected memory address for pt
	volatile uint32_t* pt = (volatile uint32_t*)0x00000018;
	// fixed expected memory address for ct
	volatile uint32_t* ct = (volatile uint32_t*)0x00000028;

	uint32_t pt_red[4];
	uint32_t ct_red[4];
	int i;//,rand;
	for (i=0 ; i<4 ; i++) {
		pt_red[i] = pt[i] & 0x0000ffff;
		pt_red[i] = pt_red[i] | ((pt[i] & 0x0000ffff) << 16);
	}

	PRESENT_ENCRYPT_SBOX(ct_red, pt_red);
	
	for (i=0 ; i<4 ; i++) {
		ct[i] = ct_red[i];
	}

	write_to_gpio_bit (0,1);

	return 0;
}
