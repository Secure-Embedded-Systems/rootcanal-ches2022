#ifndef DEFINES
	#include "defines.h"
#endif
#include "byte_mask_aes.h"

void aes128(volatile uint8_t* state) {	
	init_masking();

	remask(state,Mask[6],Mask[7],Mask[8],Mask[9],0,0,0,0);

	write_to_gpio_bit (0,1); // trigger on

	addRoundKey_masked(state, 0);  

	subBytes_masked(state);

	write_to_gpio_bit (0,0); // trigger on

	shiftRows(state);

	remask(state,Mask[0],Mask[1],Mask[2],Mask[3],Mask[5],Mask[5],Mask[5],Mask[5]); 
	mixColumns(state);
	addRoundKey_masked(state, 1);

	uint8_t i;
	for (i = 2; i <10; i++) {
		subBytes_masked(state);
		shiftRows(state);

		remask(state,Mask[0],Mask[1],Mask[2],Mask[3],Mask[5],Mask[5],Mask[5],Mask[5]); 
		mixColumns(state);
		addRoundKey_masked(state, i);
	}

	subBytes_masked(state);
	shiftRows(state);

	addRoundKey_masked(state, 10);

	write_to_gpio_bit (0,0); // trigger off

}

int main( int argc, char* argv[] ) {
	reg_uart_clkdiv = 104;

	volatile uint8_t plain[16];
	uint8_t key[16];

	// fixed expected memory address for key 
	volatile uint32_t* key32 = (volatile uint32_t*)0x00000008;// (0x00010000 << 2);// 0x00000008; 
	// fixed expected memory address for pt
	volatile uint32_t* pt = (volatile uint32_t*)0x00000018;// (0x000100004 << 2);// 0x00000018; 
	// fixed expected memory address for ct
	volatile uint32_t* ct = (volatile uint32_t*)0x00000028;// (0x000100008 << 2);// 0x00000028; 
	// fixed expected memory address for random number 
	volatile uint32_t* random_tb = (volatile uint32_t*)0x00000038;// (0x000100008 << 2);// 0x00000028; 

	// initialize pt and key
	int i, indx;
	for (i = 0; i < 16; i++) {
		indx = 3 - i/4;
		plain[15-i] = (pt[indx] >> ((i%4)*8)) & 0x000000ff;
		key[15-i] = (key32[indx] >> ((i%4)*8)) & 0x000000ff;
	}

	init_xorshift32_state(random_tb[0]); // initialize prng

	// initialize Masks:
	uint32_t mask; 
	for( i = 0; i < 6; i++ ) {
		mask = get_rand();
		Mask[i] = (uint8_t) mask;
	}

	KeyExpansion(key);
	aes128(plain);


	for (i=0; i<4 ; i++) {
		ct[i] = ((plain[4*i] << 24) & 0xff000000) | ((plain[4*i+1] << 16) & 0x00ff0000) | 
				((plain[4*i+2] << 8) & 0x0000ff00) | ((plain[4*i+3]) & 0x000000ff);
	}


	write_to_gpio_bit (0,1);


	return 0;
}
