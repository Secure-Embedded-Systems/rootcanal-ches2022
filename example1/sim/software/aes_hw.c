#ifndef DEFINES
  #include "defines.h"
#endif


#define AES_BASE_ADDR 0x04000000

static volatile int *coprocessor_base_ptr;


/************************************************/
/*--------------Register Space------------------*/

/* base_ptr - Control Reg - Bits 31-5 -> 0
 *                          Bits 4-3 -> AES Mode (00-ECB, 01-CBC)
 *                          Bit 2 -> encr/decr (1-encrypt, 0-decrypt) 
 *                          Bit 1 -> Inputs valid (assert to begin coprocessor operation)
 *                          Bit 0 -> Soft rst
 *
 * base_ptr[1] - Key word 0
 * base_ptr[2] - Key word 1
 * base_ptr[3] - Key word 2
 * base_ptr[4] - Key word 3
 *
 * base_ptr[5] - Input text word 0
 * base_ptr[6] - Input text word 1
 * base_ptr[7] - Input text word 2
 * base_ptr[8] - Input text word 3
 *
 * base_ptr[9] - IV word 0
 * base_ptr[10] - IV word 1
 * base_ptr[11] - IV word 2
 * base_ptr[12] - IV word 3
 *
 * base_ptr[13] - Output text word 0
 * base_ptr[14] - Output text word 1
 * base_ptr[15] - Output text word 2
 * base_ptr[16] - Output text word 3
 *
 * base_ptr[17] - Status Reg - Bits 31:1 -> 0
 *                             Bit 0 -> output ready
 *                              
 ***************************************************/                               

int main()
{
    reg_uart_clkdiv = 104;
    int i, read_data;

    // fixed expected memory address for key 
    int* key = (int*)0x00000008;
    // fixed expected memory address for pt
    int* pt = (int*)0x00000018;
    // fixed expected memory address for ct
    volatile int* ct = (int*)0x00000028;

    coprocessor_base_ptr = (volatile int*) AES_BASE_ADDR;
    coprocessor_base_ptr[0] = 0x00000001;	// soft reset
    coprocessor_base_ptr[0] = 0x00000000;	// clear soft reset
    
    write_to_gpio_bit(0,1);

    coprocessor_base_ptr[1] = key[0];	//key_encrypt_0
    coprocessor_base_ptr[2] = key[1];	//key_encrypt_1
    coprocessor_base_ptr[3] = key[2];	//key_encrypt_2
    coprocessor_base_ptr[4] = key[3];	//key_encrypt_3
	
    coprocessor_base_ptr[5] = pt[0];	//data_encrypt_0
    coprocessor_base_ptr[6] = pt[1];	//data_encrypt_1
    coprocessor_base_ptr[7] = pt[2];	//data_encrypt_2
    coprocessor_base_ptr[8] = pt[3];	//data_encrypt_3
	
    coprocessor_base_ptr[0] = 0x00000006;	//control_register
    coprocessor_base_ptr[0] = 0x00000004;	//control_register valid clear
	
    while(coprocessor_base_ptr[17] != 0x00000001);

    // Read result

    for (i=0;i<4;i++) {
        ct[i] = coprocessor_base_ptr[13+i];
    }
    write_to_gpio_bit(0,0);
    write_to_gpio_bit(0,1);

    return 0;
}

