#include <stdint.h>

/* Do NOT change the order of those define/include */
#define MASKING_ORDER 2

#ifndef BITS_PER_REG
#define BITS_PER_REG 32
#endif
/* including the architecture specific .h */
#include "MASKED_UA.h"


#ifndef DEFINES
	#include "defines.h"
#endif
#include "present_tornado_sbox.h"


int main( int argc, char* argv[] ) {
	reg_uart_clkdiv = 104;

	// fixed expected memory address for key 
	volatile uint32_t* key32 = (volatile uint32_t*)0x00000008;
	// fixed expected memory address for pt
	volatile uint32_t* pt = (volatile uint32_t*)0x00000018;
	// fixed expected memory address for ct
	volatile uint32_t* ct = (volatile uint32_t*)0x00000028;
	// fixed expected memory address for random number 
	volatile uint32_t* random_tb = (volatile uint32_t*)0x00000038;

	init_xorshift32_state(random_tb[0]); // initialize prng

	uint32_t pt_masked[4][MASKING_ORDER];
	uint32_t ct_masked[4][MASKING_ORDER];
	int i,rand;
	for (i=0 ; i<4 ; i++) {
		rand = get_rand();
		pt_masked[i][0] = pt[i] ^ rand;
		pt_masked[i][1] = rand;
	}

	sbox__B1 (pt_masked[3],pt_masked[2],pt_masked[1],pt_masked[0], ct_masked[3],ct_masked[2],ct_masked[1],ct_masked[0]);
	
	for (i=0 ; i<4 ; i++) {
		ct[i] = ct_masked[i][0] ^ ct_masked[i][1];
	}

	write_to_gpio_bit (0,1);

	return 0;
}
