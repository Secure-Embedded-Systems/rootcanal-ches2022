#include <stdint.h>
#include <stdbool.h>
#define DEFINES

#define reg_gpio ((volatile uint32_t*)0x01000000) // 8 gpios
#define reg_gpioctrl ((volatile uint32_t*)0x01800000) // 8 gpio ctrls
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_uart_rcv_valid (*(volatile uint32_t*)0x0200000C)
#define reg_uart_dat_wait (*(volatile uint32_t*)0x02000010)
#define reg_timer (*(volatile uint32_t*)0x02000044) // timer counter address


// -------- tdma

#define TDMA_BASE_ADDR		0x03000000 // pk: 0x03000000

#define TDMA_SRC_ADDR   	(TDMA_BASE_ADDR + 0x0 )
#define TDMA_CONFIG_REG 	(TDMA_BASE_ADDR + 0x4 )
#define TDMA_CONFIG_REG2	(TDMA_BASE_ADDR + 0x8 )
#define TDMA_PRNG_SEED  	(TDMA_BASE_ADDR + 0xC )
#define TDMA_DST_ADDR   	(TDMA_BASE_ADDR + 0x10)
#define TDMA_STATUS_REG   	(TDMA_BASE_ADDR + 0x14)
#define TDMA_BUSY_FLAG   	(TDMA_BASE_ADDR + 0x18)

#define TDMA_D_1	0
#define TDMA_D_2	1
#define TDMA_D_4	2

#define TDMA_R_S_1	0
#define TDMA_R_S_2	1
#define TDMA_R_S_4	2

#define TDMA_DIR_FORWARD	0
#define TDMA_DIR_REVERSE	1

#define TDMA_RED_DIRECT 0
#define TDMA_RED_COMP	1

#define TDMA_STATUS_OK		0
#define TDMA_STATUS_AXI_ERR	1
#define TDMA_STATUS_RED_ERR	2

void TDMA_WriteSrcAddr(unsigned *src_addr)
{
	*((volatile unsigned *) TDMA_SRC_ADDR) = (unsigned) src_addr;
}

void TDMA_WriteConfigReg(unsigned D, unsigned R_s,
		unsigned data_word_length, unsigned data_word_count)
{
	*((volatile unsigned *) TDMA_CONFIG_REG) =
			(D << 30) |
			((R_s & 0x3) << 28) |
			((data_word_length & 0xFFF) << 16) |
			(data_word_count & 0xFFFF);
}

void TDMA_WriteConfigReg2(unsigned redundancy, unsigned direction)
{
	*((volatile unsigned *) TDMA_CONFIG_REG2) =
				(redundancy << 1) |
				(direction & 0x1);
}

void TDMA_WritePRNGSeed(unsigned seed)
{
	*((volatile unsigned *) TDMA_PRNG_SEED)  = seed;
}

void TDMA_WriteDstAddr(unsigned *dst_addr)
{
	*((volatile unsigned *) TDMA_DST_ADDR) = (unsigned) dst_addr;
}

unsigned TDMA_ReadStatusReg()
{
	return *((volatile unsigned *) TDMA_STATUS_REG);
}

unsigned TDMA_ReadBusyFlag() // new
{
	return *((volatile unsigned *) TDMA_BUSY_FLAG);
}


// -------- timer

uint32_t read_timer() 
{
	return reg_timer;
}


// -------- prints 

void putchar_func(char c)
{
	if (c == '\n')
		putchar_func('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar_func(*(p++));
}

void print_hex_digit(uint32_t v) {
	v &= 0xf;
	if (v < 10)
		putchar_func(v + '0');
	else
		putchar_func(v - 10 + 'A');
}

void print_hex(uint32_t v, int digits) {
	uint32_t i;
	for (i = digits; i > 0; i--) {
		print_hex_digit(v >> (4*(i-1)));
	}
}


void print_dec(uint32_t v)
{
	if (v >= 1000) {
		print(">=1000");
		return;
	}

	if      (v >= 900) { putchar_func('9'); v -= 900; }
	else if (v >= 800) { putchar_func('8'); v -= 800; }
	else if (v >= 700) { putchar_func('7'); v -= 700; }
	else if (v >= 600) { putchar_func('6'); v -= 600; }
	else if (v >= 500) { putchar_func('5'); v -= 500; }
	else if (v >= 400) { putchar_func('4'); v -= 400; }
	else if (v >= 300) { putchar_func('3'); v -= 300; }
	else if (v >= 200) { putchar_func('2'); v -= 200; }
	else if (v >= 100) { putchar_func('1'); v -= 100; }

	if      (v >= 90) { putchar_func('9'); v -= 90; }
	else if (v >= 80) { putchar_func('8'); v -= 80; }
	else if (v >= 70) { putchar_func('7'); v -= 70; }
	else if (v >= 60) { putchar_func('6'); v -= 60; }
	else if (v >= 50) { putchar_func('5'); v -= 50; }
	else if (v >= 40) { putchar_func('4'); v -= 40; }
	else if (v >= 30) { putchar_func('3'); v -= 30; }
	else if (v >= 20) { putchar_func('2'); v -= 20; }
	else if (v >= 10) { putchar_func('1'); v -= 10; }

	if      (v >= 9) { putchar_func('9'); v -= 9; }
	else if (v >= 8) { putchar_func('8'); v -= 8; }
	else if (v >= 7) { putchar_func('7'); v -= 7; }
	else if (v >= 6) { putchar_func('6'); v -= 6; }
	else if (v >= 5) { putchar_func('5'); v -= 5; }
	else if (v >= 4) { putchar_func('4'); v -= 4; }
	else if (v >= 3) { putchar_func('3'); v -= 3; }
	else if (v >= 2) { putchar_func('2'); v -= 2; }
	else if (v >= 1) { putchar_func('1'); v -= 1; }
	else putchar_func('0');
}

uint8_t getchar ()
{
	int32_t valid = reg_uart_rcv_valid;
	int8_t data;

//	print("getchar");
	while (valid == 0) {
		valid = reg_uart_rcv_valid;
		print("notvalid");
	}

	data = (uint8_t) reg_uart_data;

	return data;
}



void getmessage (int len, uint8_t* message)
{
	int i; 
	for (i=0 ; i<len ; i++) {
		while (reg_uart_rcv_valid == 0); // wait for data on uart to be valid 
		message[i] = (uint8_t) reg_uart_data;
		print_hex(message[i],2);
	}
		
	return ;
}


void put_func (uint8_t c)
{
	reg_uart_data = c;
}

void putmessage (int len, uint8_t* message)
{
	int i; 
	for (i=0 ; i<len ; i++) {
		//putchar_func((char)message[i]);
		//print_hex((uint32_t)message[i],2);
		while(reg_uart_dat_wait!=0) {}
		put_func (message[i]);
	}
		
	return;
}

// ---------- prng

uint32_t xorshift32(uint32_t *state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	uint32_t x = *state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	*state = x;

	return x;
}

// --------- gpio

void write_to_gpio_bit (uint8_t bit, bool val) {
	if (bit >= 8) {
	//	print("Error : There are 8 gpios\n");
	} else {
		reg_gpioctrl[bit] = 1; // enable output
		if (val) {
			reg_gpio[bit] = 1;
		} else {
			reg_gpio[bit] = 0;
		}
	}
}

bool read_from_gpio_bit (uint8_t bit) {
	if (bit >= 8) {
		print("Error : There are 8 gpios\n");
		return false;
	} else {
		reg_gpioctrl[bit] = 0; // disable output
		if (reg_gpio[bit] == 1) {
			return true;
		} else {
			return false;
		}
	}
}
