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
	.file	"byte_mask_aes.c"
	.option nopic
	.text
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
	beq	a0,a5,.L12
.L10:
	li	a5,33554432
	sw	s0,8(a5)
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L12:
	li	a0,13
	call	putchar_func
	j	.L10
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
	beq	a0,zero,.L13
.L15:
	addi	s0,s0,1
	call	putchar_func
	lbu	a0,0(s0)
	bne	a0,zero,.L15
.L13:
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
	bgtu	a0,a5,.L19
	addi	a0,a0,48
	call	putchar_func
.L18:
	lw	ra,12(sp)
	addi	sp,sp,16
	jr	ra
.L19:
	addi	a0,a0,55
	call	putchar_func
	j	.L18
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
	beq	a1,zero,.L22
.L24:
	addi	s0,s0,-1
	slli	a0,s0,2
	srl	a0,s1,a0
	call	print_hex_digit
	bne	s0,zero,.L24
.L22:
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
	bgtu	a0,a5,.L58
	mv	s0,a0
	li	a5,899
	bgtu	a0,a5,.L59
	li	a5,799
	bgtu	a0,a5,.L60
	li	a5,699
	bgtu	a0,a5,.L61
	li	a5,599
	bgtu	a0,a5,.L62
	li	a5,499
	bgtu	a0,a5,.L63
	li	a5,399
	bgtu	a0,a5,.L64
	li	a5,299
	bgtu	a0,a5,.L65
	li	a5,199
	bgtu	a0,a5,.L66
	li	a5,99
	bleu	a0,a5,.L31
	li	a0,49
	call	putchar_func
	addi	s0,s0,-100
	j	.L31
.L58:
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	call	print
	j	.L27
.L59:
	li	a0,57
	call	putchar_func
	addi	s0,s0,-900
.L31:
	li	a5,89
	bgtu	s0,a5,.L67
	li	a5,79
	bgtu	s0,a5,.L68
	li	a5,69
	bgtu	s0,a5,.L69
	li	a5,59
	bgtu	s0,a5,.L70
	li	a5,49
	bgtu	s0,a5,.L71
	li	a5,39
	bgtu	s0,a5,.L72
	li	a5,29
	bgtu	s0,a5,.L73
	li	a5,19
	bgtu	s0,a5,.L74
	li	a5,9
	bleu	s0,a5,.L40
	li	a0,49
	call	putchar_func
	addi	s0,s0,-10
	j	.L40
.L60:
	li	a0,56
	call	putchar_func
	addi	s0,s0,-800
	j	.L31
.L61:
	li	a0,55
	call	putchar_func
	addi	s0,s0,-700
	j	.L31
.L62:
	li	a0,54
	call	putchar_func
	addi	s0,s0,-600
	j	.L31
.L63:
	li	a0,53
	call	putchar_func
	addi	s0,s0,-500
	j	.L31
.L64:
	li	a0,52
	call	putchar_func
	addi	s0,s0,-400
	j	.L31
.L65:
	li	a0,51
	call	putchar_func
	addi	s0,s0,-300
	j	.L31
.L66:
	li	a0,50
	call	putchar_func
	addi	s0,s0,-200
	j	.L31
.L67:
	li	a0,57
	call	putchar_func
	addi	s0,s0,-90
.L40:
	li	a5,8
	bgtu	s0,a5,.L75
	li	a5,8
	beq	s0,a5,.L76
	li	a5,6
	bgtu	s0,a5,.L77
	li	a5,6
	beq	s0,a5,.L78
	li	a5,4
	bgtu	s0,a5,.L79
	li	a5,4
	beq	s0,a5,.L80
	li	a5,2
	bgtu	s0,a5,.L81
	li	a5,2
	beq	s0,a5,.L82
	beq	s0,zero,.L56
	li	a0,49
	call	putchar_func
	j	.L27
.L68:
	li	a0,56
	call	putchar_func
	addi	s0,s0,-80
	j	.L40
.L69:
	li	a0,55
	call	putchar_func
	addi	s0,s0,-70
	j	.L40
.L70:
	li	a0,54
	call	putchar_func
	addi	s0,s0,-60
	j	.L40
.L71:
	li	a0,53
	call	putchar_func
	addi	s0,s0,-50
	j	.L40
.L72:
	li	a0,52
	call	putchar_func
	addi	s0,s0,-40
	j	.L40
.L73:
	li	a0,51
	call	putchar_func
	addi	s0,s0,-30
	j	.L40
.L74:
	li	a0,50
	call	putchar_func
	addi	s0,s0,-20
	j	.L40
.L75:
	li	a0,57
	call	putchar_func
.L27:
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L76:
	li	a0,56
	call	putchar_func
	j	.L27
.L77:
	li	a0,55
	call	putchar_func
	j	.L27
.L78:
	li	a0,54
	call	putchar_func
	j	.L27
.L79:
	li	a0,53
	call	putchar_func
	j	.L27
.L80:
	li	a0,52
	call	putchar_func
	j	.L27
.L81:
	li	a0,51
	call	putchar_func
	j	.L27
.L82:
	li	a0,50
	call	putchar_func
	j	.L27
.L56:
	li	a0,48
	call	putchar_func
	j	.L27
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
	bne	a5,zero,.L88
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	li	s2,33554432
	lui	s1,%hi(.LC1)
.L85:
	lw	s0,12(s2)
	addi	a0,s1,%lo(.LC1)
	call	print
	beq	s0,zero,.L85
	li	a5,33554432
	lw	a0,8(a5)
	andi	a0,a0,0xff
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
.L88:
	li	a5,33554432
	lw	a0,8(a5)
	andi	a0,a0,0xff
	ret
	.size	getchar, .-getchar
	.align	1
	.globl	getmessage
	.type	getmessage, @function
getmessage:
	ble	a0,zero,.L98
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	mv	s1,a1
	add	s2,a1,a0
	li	s0,33554432
.L93:
	lw	a5,12(s0)
	beq	a5,zero,.L93
	lw	a0,8(s0)
	sb	a0,0(s1)
	li	a1,2
	andi	a0,a0,0xff
	call	print_hex
	addi	s1,s1,1
	bne	s1,s2,.L93
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
.L98:
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
	ble	a0,zero,.L102
	mv	a3,a1
	add	a2,a1,a0
	li	a4,33554432
.L104:
	lw	a5,16(a4)
	bne	a5,zero,.L104
	lbu	a5,0(a3)
	sw	a5,8(a4)
	addi	a3,a3,1
	bne	a3,a2,.L104
.L102:
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
	bgtu	a0,a5,.L109
	slli	a0,a0,2
	li	a5,25165824
	add	a5,a5,a0
	li	a4,1
	sw	a4,0(a5)
	beq	a1,zero,.L111
	li	a5,16777216
	add	a0,a5,a0
	li	a5,1
	sw	a5,0(a0)
	ret
.L111:
	li	a5,16777216
	add	a0,a5,a0
	sw	zero,0(a0)
.L109:
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
	bgtu	a0,a5,.L119
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
.L119:
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
	.globl	KeyExpansion
	.type	KeyExpansion, @function
KeyExpansion:
	addi	sp,sp,-16
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
	addi	a3,a5,16
.L121:
	lbu	a4,0(a0)
	sb	a4,0(a5)
	lbu	a4,1(a0)
	sb	a4,1(a5)
	lbu	a4,2(a0)
	sb	a4,2(a5)
	lbu	a4,3(a0)
	sb	a4,3(a5)
	addi	a0,a0,4
	addi	a5,a5,4
	bne	a5,a3,.L121
	lui	a3,%hi(.LANCHOR0+12)
	addi	a3,a3,%lo(.LANCHOR0+12)
	li	a1,4
	addi	a0,sp,16
	lui	a6,%hi(.LANCHOR1)
	addi	a6,a6,%lo(.LANCHOR1)
	li	a7,44
	j	.L122
.L124:
	lbu	a5,-12(a3)
	lbu	a4,12(sp)
	xor	a5,a5,a4
	sb	a5,4(a3)
	lbu	a5,-11(a3)
	lbu	a4,13(sp)
	xor	a5,a5,a4
	sb	a5,5(a3)
	lbu	a5,-10(a3)
	lbu	a4,14(sp)
	xor	a5,a5,a4
	sb	a5,6(a3)
	lbu	a5,-9(a3)
	lbu	a4,15(sp)
	xor	a5,a5,a4
	sb	a5,7(a3)
	addi	a1,a1,1
	addi	a3,a3,4
	beq	a1,a7,.L120
.L122:
	addi	a5,sp,12
	mv	a4,a3
.L123:
	lbu	a2,0(a4)
	sb	a2,0(a5)
	addi	a4,a4,1
	addi	a5,a5,1
	bne	a5,a0,.L123
	andi	a5,a1,3
	bne	a5,zero,.L124
	lbu	a4,12(sp)
	lbu	a2,15(sp)
	lbu	a5,13(sp)
	add	a5,a6,a5
	lbu	a5,0(a5)
	lbu	t1,14(sp)
	add	t1,a6,t1
	lbu	t1,0(t1)
	sb	t1,13(sp)
	add	a2,a6,a2
	lbu	a2,0(a2)
	sb	a2,14(sp)
	add	a4,a6,a4
	lbu	a4,0(a4)
	sb	a4,15(sp)
	srli	a4,a1,2
	add	a4,a6,a4
	lbu	a4,256(a4)
	xor	a5,a5,a4
	sb	a5,12(sp)
	j	.L124
.L120:
	addi	sp,sp,16
	jr	ra
	.size	KeyExpansion, .-KeyExpansion
	.align	1
	.globl	mixColumns
	.type	mixColumns, @function
mixColumns:
	addi	t1,a0,16
	lui	a6,%hi(.LANCHOR1)
	addi	a6,a6,%lo(.LANCHOR1)
.L130:
	lbu	a4,0(a0)
	andi	a4,a4,0xff
	lbu	a5,1(a0)
	andi	a5,a5,0xff
	lbu	a1,2(a0)
	andi	a1,a1,0xff
	lbu	a3,3(a0)
	andi	a3,a3,0xff
	add	a7,a6,a4
	xor	a2,a1,a3
	lbu	t3,512(a7)
	xor	a2,a2,t3
	add	t3,a6,a5
	lbu	t4,768(t3)
	xor	a2,a2,t4
	andi	a2,a2,0xff
	sb	a2,0(a0)
	xor	a2,a4,a3
	lbu	t3,512(t3)
	xor	a2,a2,t3
	add	t3,a6,a1
	lbu	t4,768(t3)
	xor	a2,a2,t4
	andi	a2,a2,0xff
	sb	a2,1(a0)
	xor	a4,a4,a5
	lbu	a2,512(t3)
	xor	a4,a4,a2
	add	a3,a6,a3
	lbu	a2,768(a3)
	xor	a4,a4,a2
	andi	a4,a4,0xff
	sb	a4,2(a0)
	xor	a5,a5,a1
	lbu	a4,768(a7)
	xor	a5,a5,a4
	lbu	a4,512(a3)
	xor	a5,a5,a4
	andi	a5,a5,0xff
	sb	a5,3(a0)
	addi	a0,a0,4
	bne	a0,t1,.L130
	ret
	.size	mixColumns, .-mixColumns
	.align	1
	.globl	shiftRows
	.type	shiftRows, @function
shiftRows:
	lbu	a5,1(a0)
	andi	a5,a5,0xff
	lbu	a4,5(a0)
	andi	a4,a4,0xff
	sb	a4,1(a0)
	lbu	a4,9(a0)
	andi	a4,a4,0xff
	sb	a4,5(a0)
	lbu	a4,13(a0)
	andi	a4,a4,0xff
	sb	a4,9(a0)
	sb	a5,13(a0)
	lbu	a5,10(a0)
	andi	a5,a5,0xff
	lbu	a4,2(a0)
	andi	a4,a4,0xff
	sb	a4,10(a0)
	sb	a5,2(a0)
	lbu	a5,14(a0)
	andi	a5,a5,0xff
	lbu	a4,6(a0)
	andi	a4,a4,0xff
	sb	a4,14(a0)
	sb	a5,6(a0)
	lbu	a5,3(a0)
	andi	a5,a5,0xff
	lbu	a4,15(a0)
	andi	a4,a4,0xff
	sb	a4,3(a0)
	lbu	a4,11(a0)
	andi	a4,a4,0xff
	sb	a4,15(a0)
	lbu	a4,7(a0)
	andi	a4,a4,0xff
	sb	a4,11(a0)
	sb	a5,7(a0)
	ret
	.size	shiftRows, .-shiftRows
	.align	1
	.globl	addRoundKey_masked
	.type	addRoundKey_masked, @function
addRoundKey_masked:
	mv	a4,a0
	lui	a5,%hi(.LANCHOR0+176)
	slli	a3,a1,4
	addi	a5,a5,%lo(.LANCHOR0+176)
	add	a3,a5,a3
	addi	a1,a0,16
.L134:
	lbu	a2,0(a4)
	lbu	a5,0(a3)
	xor	a5,a5,a2
	andi	a5,a5,0xff
	sb	a5,0(a4)
	addi	a4,a4,1
	addi	a3,a3,1
	bne	a4,a1,.L134
	ret
	.size	addRoundKey_masked, .-addRoundKey_masked
	.align	1
	.globl	masked
	.type	masked, @function
masked:
	addi	a3,a0,16
	lui	a4,%hi(.LANCHOR0)
	addi	a4,a4,%lo(.LANCHOR0)
.L137:
	lbu	a5,0(a0)
	andi	a5,a5,0xff
	add	a5,a4,a5
	lbu	a5,352(a5)
	sb	a5,0(a0)
	addi	a0,a0,1
	bne	a0,a3,.L137
	ret
	.size	masked, .-masked
	.align	1
	.globl	remask
	.type	remask, @function
remask:
	mv	t1,a0
	addi	t3,a0,16
	xor	a5,a1,a5
	xor	a2,a2,a6
	xor	a3,a3,a7
	lbu	a1,0(sp)
	xor	a4,a4,a1
.L140:
	lbu	a0,0(t1)
	andi	a0,a0,0xff
	xor	a0,a0,a5
	sb	a0,0(t1)
	lbu	a0,1(t1)
	andi	a0,a0,0xff
	xor	a0,a0,a2
	sb	a0,1(t1)
	lbu	a0,2(t1)
	andi	a0,a0,0xff
	xor	a0,a0,a3
	sb	a0,2(t1)
	lbu	a0,3(t1)
	andi	a0,a0,0xff
	xor	a0,a0,a4
	sb	a0,3(t1)
	addi	t1,t1,4
	bne	t1,t3,.L140
	ret
	.size	remask, .-remask
	.align	1
	.globl	calcMixColMask
	.type	calcMixColMask, @function
calcMixColMask:
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
	lbu	a2,608(a5)
	lbu	a4,609(a5)
	lbu	a0,610(a5)
	lbu	a6,611(a5)
	lui	a3,%hi(.LANCHOR1)
	addi	a3,a3,%lo(.LANCHOR1)
	add	a7,a3,a2
	xor	a1,a0,a6
	lbu	t1,512(a7)
	xor	a1,a1,t1
	add	t1,a3,a4
	lbu	t3,768(t1)
	xor	a1,a1,t3
	sb	a1,614(a5)
	xor	a1,a2,a6
	lbu	t1,512(t1)
	xor	a1,a1,t1
	add	t1,a3,a0
	lbu	t3,768(t1)
	xor	a1,a1,t3
	sb	a1,615(a5)
	xor	a2,a2,a4
	lbu	a1,512(t1)
	xor	a2,a2,a1
	add	a3,a3,a6
	lbu	a1,768(a3)
	xor	a2,a2,a1
	sb	a2,616(a5)
	xor	a4,a4,a0
	lbu	a2,768(a7)
	xor	a4,a4,a2
	lbu	a3,512(a3)
	xor	a4,a4,a3
	sb	a4,617(a5)
	ret
	.size	calcMixColMask, .-calcMixColMask
	.align	1
	.globl	calcSbox_masked
	.type	calcSbox_masked, @function
calcSbox_masked:
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
	lbu	a7,613(a5)
	lbu	a6,612(a5)
	lui	a2,%hi(.LANCHOR1)
	addi	a2,a2,%lo(.LANCHOR1)
	li	a5,0
	lui	a1,%hi(.LANCHOR0)
	addi	a1,a1,%lo(.LANCHOR0)
	li	a0,256
.L144:
	xor	a4,a6,a5
	add	a4,a1,a4
	lbu	a3,0(a2)
	xor	a3,a7,a3
	sb	a3,352(a4)
	addi	a5,a5,1
	addi	a2,a2,1
	bne	a5,a0,.L144
	ret
	.size	calcSbox_masked, .-calcSbox_masked
	.align	1
	.globl	init_masked_round_keys
	.type	init_masked_round_keys, @function
init_masked_round_keys:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	lui	s2,%hi(.LANCHOR0)
	addi	s2,s2,%lo(.LANCHOR0)
	addi	s1,s2,176
	addi	s2,s2,336
	lui	s0,%hi(.LANCHOR0)
	addi	s0,s0,%lo(.LANCHOR0)
.L147:
	lbu	a5,612(s0)
	sw	a5,0(sp)
	mv	a7,a5
	mv	a6,a5
	lbu	a4,617(s0)
	lbu	a3,616(s0)
	lbu	a2,615(s0)
	lbu	a1,614(s0)
	mv	a0,s1
	call	remask
	addi	s1,s1,16
	bne	s1,s2,.L147
	lui	a0,%hi(.LANCHOR0)
	addi	a0,a0,%lo(.LANCHOR0)
	lbu	a5,613(a0)
	sw	a5,0(sp)
	mv	a7,a5
	mv	a6,a5
	li	a4,0
	li	a3,0
	li	a2,0
	li	a1,0
	addi	a0,a0,336
	call	remask
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	addi	sp,sp,32
	jr	ra
	.size	init_masked_round_keys, .-init_masked_round_keys
	.align	1
	.globl	copy_key
	.type	copy_key, @function
copy_key:
	lui	a0,%hi(.LANCHOR0)
	addi	a0,a0,%lo(.LANCHOR0)
	addi	a1,a0,176
	addi	a2,a0,16
	addi	a0,a0,192
.L151:
	addi	a5,a2,-16
	mv	a4,a1
.L152:
	lbu	a3,0(a5)
	sb	a3,0(a4)
	addi	a5,a5,1
	addi	a4,a4,1
	bne	a5,a2,.L152
	addi	a1,a1,16
	addi	a2,a2,16
	bne	a2,a0,.L151
	ret
	.size	copy_key, .-copy_key
	.align	1
	.globl	init_masking
	.type	init_masking, @function
init_masking:
	addi	sp,sp,-16
	sw	ra,12(sp)
	call	copy_key
	call	calcMixColMask
	call	calcSbox_masked
	call	init_masked_round_keys
	lw	ra,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	init_masking, .-init_masking
	.align	1
	.globl	subBytes_masked
	.type	subBytes_masked, @function
subBytes_masked:
	addi	a3,a0,16
	lui	a4,%hi(.LANCHOR0)
	addi	a4,a4,%lo(.LANCHOR0)
.L158:
	lbu	a5,0(a0)
	andi	a5,a5,0xff
	add	a5,a4,a5
	lbu	a5,352(a5)
	sb	a5,0(a0)
	addi	a0,a0,1
	bne	a0,a3,.L158
	ret
	.size	subBytes_masked, .-subBytes_masked
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
	.globl	aes128
	.type	aes128, @function
aes128:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s1,36(sp)
	sw	s2,32(sp)
	sw	s3,28(sp)
	sw	s4,24(sp)
	mv	s0,a0
	call	init_masking
	lui	s1,%hi(.LANCHOR0)
	addi	s1,s1,%lo(.LANCHOR0)
	sw	zero,0(sp)
	li	a7,0
	li	a6,0
	li	a5,0
	lbu	a4,617(s1)
	lbu	a3,616(s1)
	lbu	a2,615(s1)
	lbu	a1,614(s1)
	mv	a0,s0
	call	remask
	li	s4,25165824
	li	s2,1
	sw	s2,0(s4)
	li	s3,16777216
	sw	s2,0(s3)
	li	a1,0
	mv	a0,s0
	call	addRoundKey_masked
	mv	a0,s0
	call	subBytes_masked
	sw	s2,0(s4)
	sw	zero,0(s3)
	mv	a0,s0
	call	shiftRows
	lbu	a5,613(s1)
	sw	a5,0(sp)
	mv	a7,a5
	mv	a6,a5
	lbu	a4,611(s1)
	lbu	a3,610(s1)
	lbu	a2,609(s1)
	lbu	a1,608(s1)
	mv	a0,s0
	call	remask
	mv	a0,s0
	call	mixColumns
	li	a1,1
	mv	a0,s0
	call	addRoundKey_masked
	li	s1,2
	lui	s2,%hi(.LANCHOR0)
	addi	s2,s2,%lo(.LANCHOR0)
	li	s3,10
.L165:
	mv	a0,s0
	call	subBytes_masked
	mv	a0,s0
	call	shiftRows
	lbu	a5,613(s2)
	sw	a5,0(sp)
	mv	a7,a5
	mv	a6,a5
	lbu	a4,611(s2)
	lbu	a3,610(s2)
	lbu	a2,609(s2)
	lbu	a1,608(s2)
	mv	a0,s0
	call	remask
	mv	a0,s0
	call	mixColumns
	mv	a1,s1
	mv	a0,s0
	call	addRoundKey_masked
	addi	s1,s1,1
	andi	s1,s1,0xff
	bne	s1,s3,.L165
	mv	a0,s0
	call	subBytes_masked
	mv	a0,s0
	call	shiftRows
	li	a1,10
	mv	a0,s0
	call	addRoundKey_masked
	li	a5,25165824
	li	a4,1
	sw	a4,0(a5)
	li	a5,16777216
	sw	zero,0(a5)
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	addi	sp,sp,48
	jr	ra
	.size	aes128, .-aes128
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s1,36(sp)
	li	a5,33554432
	li	a4,104
	sw	a4,4(a5)
	addi	a0,sp,15
	li	a3,0
	li	a7,15
	li	a6,16
.L169:
	srai	a4,a3,31
	andi	a5,a4,3
	add	a5,a5,a3
	srai	a5,a5,2
	neg	a5,a5
	addi	a5,a5,3
	slli	a5,a5,2
	lw	a2,24(a5)
	srli	a1,a4,30
	add	a4,a3,a1
	andi	a4,a4,3
	sub	a4,a4,a1
	slli	a4,a4,3
	sub	a1,a7,a3
	srl	a2,a2,a4
	andi	a2,a2,0xff
	addi	s0,sp,32
	add	a1,s0,a1
	sb	a2,-16(a1)
	lw	a5,8(a5)
	srl	a4,a5,a4
	sb	a4,0(a0)
	addi	a3,a3,1
	addi	a0,a0,-1
	bne	a3,a6,.L169
	lw	a4,56(zero)
	lui	a5,%hi(state_xorshift32)
	sw	a4,%lo(state_xorshift32)(a5)
	lui	s1,%hi(.LANCHOR0)
	addi	s1,s1,%lo(.LANCHOR0)
	addi	s0,s1,608
	addi	s1,s1,614
.L170:
	call	xorshift32_
	sb	a0,0(s0)
	addi	s0,s0,1
	bne	s0,s1,.L170
	mv	a0,sp
	call	KeyExpansion
	addi	a0,sp,16
	call	aes128
	li	a4,0
	li	a0,16
.L171:
	addi	a5,sp,32
	add	a5,a5,a4
	lbu	a5,-16(a5)
	addi	a3,a4,1
	addi	a2,sp,32
	add	a3,a2,a3
	lbu	a2,-16(a3)
	andi	a2,a2,0xff
	addi	a3,a4,2
	addi	a1,sp,32
	add	a3,a1,a3
	lbu	a3,-16(a3)
	andi	a3,a3,0xff
	addi	a1,a4,3
	addi	s0,sp,32
	add	a1,s0,a1
	lbu	a1,-16(a1)
	andi	a1,a1,0xff
	slli	a5,a5,24
	or	a5,a5,a1
	slli	a2,a2,16
	or	a5,a5,a2
	slli	a3,a3,8
	or	a5,a5,a3
	sw	a5,40(a4)
	addi	a4,a4,4
	bne	a4,a0,.L171
	li	a5,1
	li	a4,25165824
	sw	a5,0(a4)
	li	a4,16777216
	sw	a5,0(a4)
	li	a0,0
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.globl	RoundKey_masked
	.globl	Mask
	.globl	Sbox_masked
	.globl	mul_03
	.globl	mul_02
	.globl	sbox
	.globl	roundKey
	.section	.rodata
	.align	2
	.set	.LANCHOR1,. + 0
	.type	sbox, @object
	.size	sbox, 256
sbox:
	.string	"c|w{\362ko\3050\001g+\376\327\253v\312\202\311}\372YG\360\255\324\242\257\234\244r\300\267\375\223&6?\367\3144\245\345\361q\3301\025\004\307#\303\030\226\005\232\007\022\200\342\353'\262u\t\203,\032\033nZ\240R;\326\263)\343/\204S\321"
	.ascii	"\355 \374\261[j\313\2769JLX\317\320\357\252\373CM3\205E\371\002"
	.ascii	"\177P<\237\250Q\243@\217\222\2358\365\274\266\332!\020\377\363"
	.ascii	"\322\315\f\023\354_\227D\027\304\247~=d]\031s`\201O\334\"*\220"
	.ascii	"\210F\356\270\024\336^\013\333\3402:\nI\006$\\\302\323\254b\221"
	.ascii	"\225\344y\347\3107m\215\325N\251lV\364\352ez\256\b\272x%.\034"
	.ascii	"\246\264\306\350\335t\037K\275\213\212p>\265fH\003\366\016a5"
	.ascii	"W\271\206\301\035\236\341\370\230\021i\331\216\224\233\036\207"
	.ascii	"\351\316U(\337\214\241\211\r\277\346BhA\231-\017\260T\273\026"
	.type	Rcon, @object
	.size	Rcon, 255
Rcon:
	.ascii	"\215\001\002\004\b\020 @\200\0336l\330\253M\232/^\274c\306\227"
	.ascii	"5j\324\263}\372\357\305\2219r\344\323\275a\302\237%J\2243f\314"
	.ascii	"\203\035:t\350\313\215\001\002\004\b\020 @\200\0336l\330\253"
	.ascii	"M\232/^\274c\306\2275j\324\263}\372\357\305\2219r\344\323\275"
	.ascii	"a\302\237%J\2243f\314\203\035:t\350\313\215\001\002\004\b\020"
	.ascii	" @\200\0336l\330\253M\232/^\274c\306\2275j\324\263}\372\357\305"
	.ascii	"\2219r\344\323\275a\302\237%J\2243f\314\203\035:t\350\313\215"
	.ascii	"\001\002\004\b\020 @\200\0336l\330\253M\232/^\274c\306\2275j"
	.ascii	"\324\263}\372\357\305\2219r\344\323\275a\302\237%J\2243f\314"
	.ascii	"\203\035:t\350\313\215\001\002\004\b\020 @\200\0336l\330\253"
	.ascii	"M\232/^\274c\306\2275j\324\263}\372\357\305\2219r\344\323\275"
	.ascii	"a\302\237%J\2243f\314\203\035:t\350\313"
	.zero	1
	.type	mul_02, @object
	.size	mul_02, 256
mul_02:
	.string	""
	.ascii	"\002\004\006\b\n\f\016\020\022\024\026\030\032\034\036 \"$&("
	.ascii	"*,.02468:<>@BDFHJLNPRTVXZ\\^`bdfhjlnprtvxz|~\200\202\204\206"
	.ascii	"\210\212\214\216\220\222\224\226\230\232\234\236\240\242\244"
	.ascii	"\246\250\252\254\256\260\262\264\266\270\272\274\276\300\302"
	.ascii	"\304\306\310\312\314\316\320\322\324\326\330\332\334\336\340"
	.ascii	"\342\344\346\350\352\354\356\360\362\364\366\370\372\374\376"
	.ascii	"\033\031\037\035\023\021\027\025\013\t\017\r\003\001\007\005"
	.ascii	";9?=3175+)/-#!'%[Y_]SQWUKIOMCAGE{y\177}sqwukiomcage\233\231\237"
	.ascii	"\235\223\221\227\225\213\211\217\215\203\201\207\205\273\271"
	.ascii	"\277\275\263\261\267\265\253\251\257\255\243\241\247\245\333"
	.ascii	"\331\337\335\323\321\327\325\313\311\317\315\303\301\307\305"
	.ascii	"\373\371\377\375\363\361\367\365\353\351\357\355\343\341\347"
	.ascii	"\345"
	.type	mul_03, @object
	.size	mul_03, 256
mul_03:
	.string	""
	.ascii	"\003\006\005\f\017\n\t\030\033\036\035\024\027\022\0210365<?"
	.ascii	":9(+.-$'\"!`cfelojix{~}twrqPSVU\\_ZYHKNMDGBA\300\303\306\305"
	.ascii	"\314\317\312\311\330\333\336\335\324\327\322\321\360\363\366"
	.ascii	"\365\374\377\372\371\350\353\356\355\344\347\342\341\240\243"
	.ascii	"\246\245\254\257\252\251\270\273\276\275\264\267\262\261\220"
	.ascii	"\223\226\225\234\237\232\231\210\213\216\215\204\207\202\201"
	.ascii	"\233\230\235\236\227\224\221\222\203\200\205\206\217\214\211"
	.ascii	"\212\253\250\255\256\247\244\241\242\263\260\265\266\277\274"
	.ascii	"\271\272\373\370\375\376\367\364\361\362\343\340\345\346\357"
	.ascii	"\354\351\352\313\310\315\316\307\304\301\302\323\320\325\326"
	.ascii	"\337\334\331\332[X]^WTQRC@EFOLIJkhmngdabspuv\177|yz;8=>7412#"
	.ascii	" %&/,)*\013\b\r\016\007\004\001\002\023\020\025\026\037\034\031"
	.ascii	"\032"
	.bss
	.align	2
	.set	.LANCHOR0,. + 0
	.type	roundKey, @object
	.size	roundKey, 176
roundKey:
	.zero	176
	.type	RoundKey_masked, @object
	.size	RoundKey_masked, 176
RoundKey_masked:
	.zero	176
	.type	Sbox_masked, @object
	.size	Sbox_masked, 256
Sbox_masked:
	.zero	256
	.type	Mask, @object
	.size	Mask, 10
Mask:
	.zero	10
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
