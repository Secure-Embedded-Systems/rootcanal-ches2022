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

	uint32_t pt_masked[4];
	uint32_t ct_masked[4];
	int i;
	for (i=0 ; i<4 ; i++) {
		pt_masked[i] = pt[i];
	}

	PRESENT_ENCRYPT_SBOX(ct_masked, pt_masked);
	
	for (i=0 ; i<4 ; i++) {
		ct[i] = ct_masked[i];
	}

	write_to_gpio_bit (0,1);

	return 0;
}
