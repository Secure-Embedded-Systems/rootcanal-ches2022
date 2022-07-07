	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
kernel: 
	addi	zero,zero,0
	addi	ra,zero,0
	addi	sp,zero,1536
	addi	gp,zero,0
	addi	tp,zero,0
	addi	t0,zero,0
	addi	t1,zero,0
	addi	t2,zero,0
	addi	s0,zero,0
	addi	a0,zero,0
	addi	a1,zero,0
	addi	a2,zero,0
	addi	s3,zero,0
	addi	a4,zero,0
	addi	a5,zero,0
	addi	a6,zero,0
	addi	a7,zero,0
	addi	s2,zero,0
	addi	s3,zero,0
	addi	s4,zero,0
	addi	s5,zero,0
	addi	s6,zero,0
	addi	s7,zero,0
	addi	s8,zero,0
	addi	s9,zero,0
	addi	s10,zero,0
	addi	s11,zero,0
	addi	t3,zero,0
	addi	t4,zero,0
	addi	t5,zero,0
	addi	t6,zero,0
	call	main
	addi	zero,zero,0
	mv	    s1,a0
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	auipc	ra,0x0
	jalr	ra,0(ra)
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	.file	"present_tornado.c"
	.option nopic
	.text
	.align	1
	.globl	init_xorshift32_state
	.type	init_xorshift32_state, @function
init_xorshift32_state:
	lui	a5,%hi(state_xorshift32)
	sw	a0,%lo(state_xorshift32)(a5)
	ret
	.size	init_xorshift32_state, .-init_xorshift32_state
	.align	1
	.globl	xorshift32_
	.type	xorshift32_, @function
xorshift32_:
	lui	a4,%hi(state_xorshift32)
	lw	a0,%lo(state_xorshift32)(a4)
	slli	a5,a0,13
	xor	a5,a5,a0
	srli	a0,a5,17
	xor	a5,a0,a5
	slli	a0,a5,5
	xor	a0,a0,a5
	sw	a0,%lo(state_xorshift32)(a4)
	ret
	.size	xorshift32_, .-xorshift32_
	.align	1
	.type	isw_mult, @function
isw_mult:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	mv	s0,a0
	mv	s2,a1
	mv	s1,a2
	sw	zero,0(a0)
	sw	zero,4(a0)
	lw	a5,0(a2)
	lw	a4,0(a1)
	and	a5,a5,a4
	sw	a5,0(a0)
	call	xorshift32_
	lw	a5,0(s0)
	xor	a5,a5,a0
	sw	a5,0(s0)
	lw	a5,4(s2)
	lw	a4,0(s1)
	and	a5,a5,a4
	lw	a4,4(s0)
	xor	a5,a5,a4
	lw	a4,0(s2)
	lw	a3,4(s1)
	and	a4,a4,a3
	xor	a5,a5,a4
	xor	a5,a5,a0
	sw	a5,4(s0)
	lw	a4,4(s2)
	lw	a3,4(s1)
	and	a4,a4,a3
	xor	a5,a4,a5
	sw	a5,4(s0)
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
	.size	isw_mult, .-isw_mult
	.align	1
	.globl	get_rand
	.type	get_rand, @function
get_rand:
	addi	sp,sp,-16
	sw	ra,12(sp)
	call	xorshift32_
	lw	ra,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	get_rand, .-get_rand
	.align	1
	.globl	TDMA_WriteSrcAddr
	.type	TDMA_WriteSrcAddr, @function
TDMA_WriteSrcAddr:
	li	a5,50331648
	sw	a0,0(a5)
	ret
	.size	TDMA_WriteSrcAddr, .-TDMA_WriteSrcAddr
	.align	1
	.globl	TDMA_WriteConfigReg
	.type	TDMA_WriteConfigReg, @function
TDMA_WriteConfigReg:
	slli	a2,a2,16
	li	a5,268369920
	and	a2,a2,a5
	slli	a3,a3,16
	srli	a3,a3,16
	or	a2,a2,a3
	slli	a0,a0,30
	or	a2,a2,a0
	slli	a1,a1,28
	li	a5,805306368
	and	a1,a1,a5
	or	a2,a2,a1
	li	a5,50331648
	sw	a2,4(a5)
	ret
	.size	TDMA_WriteConfigReg, .-TDMA_WriteConfigReg
	.align	1
	.globl	TDMA_WriteConfigReg2
	.type	TDMA_WriteConfigReg2, @function
TDMA_WriteConfigReg2:
	slli	a0,a0,1
	andi	a1,a1,1
	or	a0,a0,a1
	li	a5,50331648
	sw	a0,8(a5)
	ret
	.size	TDMA_WriteConfigReg2, .-TDMA_WriteConfigReg2
	.align	1
	.globl	TDMA_WritePRNGSeed
	.type	TDMA_WritePRNGSeed, @function
TDMA_WritePRNGSeed:
	li	a5,50331648
	sw	a0,12(a5)
	ret
	.size	TDMA_WritePRNGSeed, .-TDMA_WritePRNGSeed
	.align	1
	.globl	TDMA_WriteDstAddr
	.type	TDMA_WriteDstAddr, @function
TDMA_WriteDstAddr:
	li	a5,50331648
	sw	a0,16(a5)
	ret
	.size	TDMA_WriteDstAddr, .-TDMA_WriteDstAddr
	.align	1
	.globl	TDMA_ReadStatusReg
	.type	TDMA_ReadStatusReg, @function
TDMA_ReadStatusReg:
	li	a5,50331648
	lw	a0,20(a5)
	ret
	.size	TDMA_ReadStatusReg, .-TDMA_ReadStatusReg
	.align	1
	.globl	TDMA_ReadBusyFlag
	.type	TDMA_ReadBusyFlag, @function
TDMA_ReadBusyFlag:
	li	a5,50331648
	lw	a0,24(a5)
	ret
	.size	TDMA_ReadBusyFlag, .-TDMA_ReadBusyFlag
	.align	1
	.globl	read_timer
	.type	read_timer, @function
read_timer:
	li	a5,33554432
	lw	a0,68(a5)
	ret
	.size	read_timer, .-read_timer
	.align	1
	.globl	putchar_func
	.type	putchar_func, @function
putchar_func:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	mv	s0,a0
	li	a5,10
	beq	a0,a5,.L18
.L16:
	li	a5,33554432
	sw	s0,8(a5)
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L18:
	li	a0,13
	call	putchar_func
	j	.L16
	.size	putchar_func, .-putchar_func
	.align	1
	.globl	print
	.type	print, @function
print:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	mv	s0,a0
	lbu	a0,0(a0)
	beq	a0,zero,.L19
.L21:
	addi	s0,s0,1
	call	putchar_func
	lbu	a0,0(s0)
	bne	a0,zero,.L21
.L19:
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	print, .-print
	.align	1
	.globl	print_hex_digit
	.type	print_hex_digit, @function
print_hex_digit:
	addi	sp,sp,-16
	sw	ra,12(sp)
	andi	a0,a0,15
	li	a5,9
	bgtu	a0,a5,.L25
	addi	a0,a0,48
	call	putchar_func
.L24:
	lw	ra,12(sp)
	addi	sp,sp,16
	jr	ra
.L25:
	addi	a0,a0,55
	call	putchar_func
	j	.L24
	.size	print_hex_digit, .-print_hex_digit
	.align	1
	.globl	print_hex
	.type	print_hex, @function
print_hex:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	mv	s1,a0
	mv	s0,a1
	beq	a1,zero,.L28
.L30:
	addi	s0,s0,-1
	slli	a0,s0,2
	srl	a0,s1,a0
	call	print_hex_digit
	bne	s0,zero,.L30
.L28:
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	addi	sp,sp,16
	jr	ra
	.size	print_hex, .-print_hex
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	">=1000"
	.text
	.align	1
	.globl	print_dec
	.type	print_dec, @function
print_dec:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	li	a5,999
	bgtu	a0,a5,.L64
	mv	s0,a0
	li	a5,899
	bgtu	a0,a5,.L65
	li	a5,799
	bgtu	a0,a5,.L66
	li	a5,699
	bgtu	a0,a5,.L67
	li	a5,599
	bgtu	a0,a5,.L68
	li	a5,499
	bgtu	a0,a5,.L69
	li	a5,399
	bgtu	a0,a5,.L70
	li	a5,299
	bgtu	a0,a5,.L71
	li	a5,199
	bgtu	a0,a5,.L72
	li	a5,99
	bleu	a0,a5,.L37
	li	a0,49
	call	putchar_func
	addi	s0,s0,-100
	j	.L37
.L64:
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	call	print
	j	.L33
.L65:
	li	a0,57
	call	putchar_func
	addi	s0,s0,-900
.L37:
	li	a5,89
	bgtu	s0,a5,.L73
	li	a5,79
	bgtu	s0,a5,.L74
	li	a5,69
	bgtu	s0,a5,.L75
	li	a5,59
	bgtu	s0,a5,.L76
	li	a5,49
	bgtu	s0,a5,.L77
	li	a5,39
	bgtu	s0,a5,.L78
	li	a5,29
	bgtu	s0,a5,.L79
	li	a5,19
	bgtu	s0,a5,.L80
	li	a5,9
	bleu	s0,a5,.L46
	li	a0,49
	call	putchar_func
	addi	s0,s0,-10
	j	.L46
.L66:
	li	a0,56
	call	putchar_func
	addi	s0,s0,-800
	j	.L37
.L67:
	li	a0,55
	call	putchar_func
	addi	s0,s0,-700
	j	.L37
.L68:
	li	a0,54
	call	putchar_func
	addi	s0,s0,-600
	j	.L37
.L69:
	li	a0,53
	call	putchar_func
	addi	s0,s0,-500
	j	.L37
.L70:
	li	a0,52
	call	putchar_func
	addi	s0,s0,-400
	j	.L37
.L71:
	li	a0,51
	call	putchar_func
	addi	s0,s0,-300
	j	.L37
.L72:
	li	a0,50
	call	putchar_func
	addi	s0,s0,-200
	j	.L37
.L73:
	li	a0,57
	call	putchar_func
	addi	s0,s0,-90
.L46:
	li	a5,8
	bgtu	s0,a5,.L81
	li	a5,8
	beq	s0,a5,.L82
	li	a5,6
	bgtu	s0,a5,.L83
	li	a5,6
	beq	s0,a5,.L84
	li	a5,4
	bgtu	s0,a5,.L85
	li	a5,4
	beq	s0,a5,.L86
	li	a5,2
	bgtu	s0,a5,.L87
	li	a5,2
	beq	s0,a5,.L88
	beq	s0,zero,.L62
	li	a0,49
	call	putchar_func
	j	.L33
.L74:
	li	a0,56
	call	putchar_func
	addi	s0,s0,-80
	j	.L46
.L75:
	li	a0,55
	call	putchar_func
	addi	s0,s0,-70
	j	.L46
.L76:
	li	a0,54
	call	putchar_func
	addi	s0,s0,-60
	j	.L46
.L77:
	li	a0,53
	call	putchar_func
	addi	s0,s0,-50
	j	.L46
.L78:
	li	a0,52
	call	putchar_func
	addi	s0,s0,-40
	j	.L46
.L79:
	li	a0,51
	call	putchar_func
	addi	s0,s0,-30
	j	.L46
.L80:
	li	a0,50
	call	putchar_func
	addi	s0,s0,-20
	j	.L46
.L81:
	li	a0,57
	call	putchar_func
.L33:
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L82:
	li	a0,56
	call	putchar_func
	j	.L33
.L83:
	li	a0,55
	call	putchar_func
	j	.L33
.L84:
	li	a0,54
	call	putchar_func
	j	.L33
.L85:
	li	a0,53
	call	putchar_func
	j	.L33
.L86:
	li	a0,52
	call	putchar_func
	j	.L33
.L87:
	li	a0,51
	call	putchar_func
	j	.L33
.L88:
	li	a0,50
	call	putchar_func
	j	.L33
.L62:
	li	a0,48
	call	putchar_func
	j	.L33
	.size	print_dec, .-print_dec
	.section	.rodata.str1.4
	.align	2
.LC1:
	.string	"notvalid"
	.text
	.align	1
	.globl	getchar
	.type	getchar, @function
getchar:
	li	a5,33554432
	lw	a5,12(a5)
	bne	a5,zero,.L94
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	li	s2,33554432
	lui	s1,%hi(.LC1)
.L91:
	lw	s0,12(s2)
	addi	a0,s1,%lo(.LC1)
	call	print
	beq	s0,zero,.L91
	li	a5,33554432
	lw	a0,8(a5)
	andi	a0,a0,0xff
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
.L94:
	li	a5,33554432
	lw	a0,8(a5)
	andi	a0,a0,0xff
	ret
	.size	getchar, .-getchar
	.align	1
	.globl	getmessage
	.type	getmessage, @function
getmessage:
	ble	a0,zero,.L104
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	mv	s1,a1
	add	s2,a1,a0
	li	s0,33554432
.L99:
	lw	a5,12(s0)
	beq	a5,zero,.L99
	lw	a0,8(s0)
	sb	a0,0(s1)
	li	a1,2
	andi	a0,a0,0xff
	call	print_hex
	addi	s1,s1,1
	bne	s1,s2,.L99
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
.L104:
	ret
	.size	getmessage, .-getmessage
	.align	1
	.globl	put_func
	.type	put_func, @function
put_func:
	li	a5,33554432
	sw	a0,8(a5)
	ret
	.size	put_func, .-put_func
	.align	1
	.globl	putmessage
	.type	putmessage, @function
putmessage:
	ble	a0,zero,.L108
	mv	a3,a1
	add	a2,a1,a0
	li	a4,33554432
.L110:
	lw	a5,16(a4)
	bne	a5,zero,.L110
	lbu	a5,0(a3)
	sw	a5,8(a4)
	addi	a3,a3,1
	bne	a3,a2,.L110
.L108:
	ret
	.size	putmessage, .-putmessage
	.align	1
	.globl	xorshift32
	.type	xorshift32, @function
xorshift32:
	mv	a4,a0
	lw	a5,0(a0)
	slli	a0,a5,13
	xor	a5,a0,a5
	srli	a0,a5,17
	xor	a0,a0,a5
	slli	a5,a0,5
	xor	a0,a5,a0
	sw	a0,0(a4)
	ret
	.size	xorshift32, .-xorshift32
	.align	1
	.globl	write_to_gpio_bit
	.type	write_to_gpio_bit, @function
write_to_gpio_bit:
	li	a5,7
	bgtu	a0,a5,.L115
	slli	a0,a0,2
	li	a5,25165824
	add	a5,a5,a0
	li	a4,1
	sw	a4,0(a5)
	beq	a1,zero,.L117
	li	a5,16777216
	add	a0,a5,a0
	li	a5,1
	sw	a5,0(a0)
	ret
.L117:
	li	a5,16777216
	add	a0,a5,a0
	sw	zero,0(a0)
.L115:
	ret
	.size	write_to_gpio_bit, .-write_to_gpio_bit
	.section	.rodata.str1.4
	.align	2
.LC2:
	.string	"Error : There are 8 gpios\n"
	.text
	.align	1
	.globl	read_from_gpio_bit
	.type	read_from_gpio_bit, @function
read_from_gpio_bit:
	li	a5,7
	bgtu	a0,a5,.L125
	slli	a0,a0,2
	li	a5,25165824
	add	a5,a5,a0
	sw	zero,0(a5)
	li	a5,16777216
	add	a0,a5,a0
	lw	a0,0(a0)
	addi	a0,a0,-1
	seqz	a0,a0
	ret
.L125:
	addi	sp,sp,-16
	sw	ra,12(sp)
	lui	a0,%hi(.LC2)
	addi	a0,a0,%lo(.LC2)
	call	print
	li	a0,0
	lw	ra,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	read_from_gpio_bit, .-read_from_gpio_bit
	.align	1
	.globl	sbox__B1
	.type	sbox__B1, @function
sbox__B1:
	addi	sp,sp,-112
	sw	ra,108(sp)
	sw	s0,104(sp)
	sw	s1,100(sp)
	sw	s2,96(sp)
	sw	s3,92(sp)
	sw	s4,88(sp)
	sw	s5,84(sp)
	sw	s6,80(sp)
	sw	s7,76(sp)
	sw	s8,72(sp)
	sw	s9,68(sp)
	sw	s10,64(sp)
	mv	s1,a0
	mv	s3,a1
	mv	s2,a3
	mv	s6,a4
	mv	s5,a5
	mv	s4,a6
	mv	s10,a7
	li	s9,25165824
	li	s7,1
	sw	s7,0(s9)
	li	s8,16777216
	sw	s7,0(s8)
	lw	a5,0(a2)
	lw	a4,0(a1)
	xor	a5,a5,a4
	sw	a5,56(sp)
	lw	a5,4(a2)
	lw	a4,4(a1)
	xor	a5,a5,a4
	sw	a5,60(sp)
	addi	a2,sp,56
	addi	a0,sp,48
	call	isw_mult
	lw	a5,0(s1)
	lw	s0,48(sp)
	xor	s0,s0,a5
	sw	s0,40(sp)
	lw	a5,0(s2)
	xor	s0,s0,a5
	sw	s0,0(s10)
	lw	a5,56(sp)
	xor	s0,s0,a5
	lw	s1,4(s1)
	lw	a5,52(sp)
	xor	s1,s1,a5
	sw	s1,44(sp)
	lw	a5,4(s2)
	xor	s1,s1,a5
	sw	s1,4(s10)
	lw	a5,60(sp)
	xor	s1,s1,a5
	addi	a2,sp,40
	addi	a1,sp,56
	addi	a0,sp,32
	call	isw_mult
	lw	a5,0(s3)
	lw	s10,32(sp)
	xor	s10,s10,a5
	lw	a5,4(s3)
	lw	s3,36(sp)
	xor	s3,s3,a5
	lw	a5,0(s2)
	not	a5,a5
	sw	a5,8(sp)
	lw	a5,4(s2)
	sw	a5,12(sp)
	not	a5,s10
	sw	a5,16(sp)
	sw	s3,20(sp)
	addi	a2,sp,16
	addi	a1,sp,8
	addi	a0,sp,24
	call	isw_mult
	lw	a2,24(sp)
	xor	a2,a2,s0
	not	a2,a2
	sw	a2,0(s4)
	lw	a5,28(sp)
	xor	a5,s1,a5
	sw	a5,4(s4)
	lw	a5,4(s2)
	lw	a4,0(s2)
	xor	s10,s10,a4
	not	a4,s10
	xor	a2,a2,a4
	sw	a2,0(s6)
	xor	s3,s3,a5
	lw	a5,4(s4)
	xor	a5,a5,s3
	sw	a5,4(s6)
	sw	s10,8(sp)
	sw	s3,12(sp)
	not	s0,s0
	sw	s0,16(sp)
	sw	s1,20(sp)
	addi	a2,sp,16
	addi	a1,sp,8
	addi	a0,sp,24
	call	isw_mult
	lw	a5,24(sp)
	lw	a4,40(sp)
	xor	a5,a5,a4
	not	a5,a5
	sw	a5,0(s5)
	lw	a4,28(sp)
	lw	a5,44(sp)
	xor	a5,a5,a4
	sw	a5,4(s5)
	sw	s7,0(s9)
	sw	zero,0(s8)
	lw	ra,108(sp)
	lw	s0,104(sp)
	lw	s1,100(sp)
	lw	s2,96(sp)
	lw	s3,92(sp)
	lw	s4,88(sp)
	lw	s5,84(sp)
	lw	s6,80(sp)
	lw	s7,76(sp)
	lw	s8,72(sp)
	lw	s9,68(sp)
	lw	s10,64(sp)
	addi	sp,sp,112
	jr	ra
	.size	sbox__B1, .-sbox__B1
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-80
	sw	ra,76(sp)
	sw	s0,72(sp)
	sw	s1,68(sp)
	sw	s2,64(sp)
	li	a5,33554432
	li	a4,104
	sw	a4,4(a5)
	lw	a4,56(zero)
	lui	a5,%hi(state_xorshift32)
	sw	a4,%lo(state_xorshift32)(a5)
	addi	s1,sp,32
	li	s0,24
	li	s2,40
.L129:
	call	xorshift32_
	lw	a5,0(s0)
	xor	a5,a5,a0
	sw	a5,0(s1)
	sw	a0,4(s1)
	addi	s0,s0,4
	addi	s1,s1,8
	bne	s0,s2,.L129
	mv	a7,sp
	addi	a6,sp,8
	addi	a5,sp,16
	addi	a4,sp,24
	addi	a3,sp,32
	addi	a2,sp,40
	addi	a1,sp,48
	addi	a0,sp,56
	call	sbox__B1
	lw	a5,4(sp)
	lw	a4,0(sp)
	xor	a5,a5,a4
	sw	a5,40(zero)
	lw	a5,8(sp)
	lw	a4,12(sp)
	xor	a5,a5,a4
	sw	a5,44(zero)
	lw	a5,16(sp)
	lw	a4,20(sp)
	xor	a5,a5,a4
	sw	a5,48(zero)
	lw	a5,24(sp)
	lw	a4,28(sp)
	xor	a5,a5,a4
	sw	a5,52(zero)
	li	a5,1
	li	a4,25165824
	sw	a5,0(a4)
	li	a4,16777216
	sw	a5,0(a4)
	li	a0,0
	lw	ra,76(sp)
	lw	s0,72(sp)
	lw	s1,68(sp)
	lw	s2,64(sp)
	addi	sp,sp,80
	jr	ra
	.size	main, .-main
	.section	.sbss,"aw",@nobits
	.align	2
	.type	state_xorshift32, @object
	.size	state_xorshift32, 4
state_xorshift32:
	.zero	4
	.ident	"GCC: (GNU) 10.2.0"
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	auipc	ra,0x0
	jalr	ra,0(ra)
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
	addi	zero,zero,0
