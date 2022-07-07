#ifndef _CELLS_H_
#define _CELLS_H_
#define MDTYPE uint32_t

static uint32_t state_xorshift32;
void init_xorshift32_state (uint32_t state_init) {
  state_xorshift32 = state_init;
}
/* The state word must be initialized to non-zero */
uint32_t xorshift32_()
{
        /* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
        uint32_t x = state_xorshift32;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        state_xorshift32 = x;
        return state_xorshift32;
}
 
uint32_t get_rand() {
  return xorshift32_();
}


#ifdef RV32

/* architecture-specific */
#define AND2(a,b,r) {					\
	asm volatile("and %[r_], %[a_], %[b_]\n\t"	\
		: [r_]"=r" (r) 				\
		: [a_] "r" (a), [b_] "r" (b) :);	\
}

#define OR2(a,b,r) { 					\
	asm volatile("or %[r_], %[a_], %[b_]\n\t"	\
		: [r_]"=r" (r) 				\
		: [a_] "r" (a), [b_] "r" (b) :);	\
}

#define XOR2(a,b,r) { 					\
	asm volatile("xor %[r_], %[a_], %[b_]\n\t"	\
		: [r_]"=r" (r) 				\
		: [a_] "r" (a), [b_] "r" (b) :);	\
}

#define NOT1(a,r) { 					\
	asm volatile("xori %[r_], %[a_], -1\n\t"		\
		: [r_]"=r" (r) 				\
		: [a_] "r" (a) :);			\
}

/* general */

#define DFF(clk,d,q) { q = d; }

#endif

#ifdef X86
#define AND2(a,b,r) { r = a & b; }
#define OR2(a,b,r) { r = a | b; }
#define XOR2(a,b,r) { r = a ^ b; }
#define NOT1(a,r) { r = ~a; }
#define DFF(clk,d,q) { q = d; }
#define DFFSR(clk,d, q, rst, set) {q = rst ? 0 : (set ? 1 : d);}

#endif

#endif
//========================== skiva
#ifdef SKIVA

#define RAND() (unsigned int) *((volatile unsigned int*)0x80000600)

#ifndef D_
	#define D_ 1
#endif
#ifndef FD
	#define FD 1
#endif


#if D_==1
	#if FD == 1
	#define _FD_AND_TI1 "and"
	#define _FD_XOR_TI1 "xor"
	#elif FD == 2
	#define _FD_AND_TI1 "andc16"
	#define _FD_XOR_TI1 "xorc16"
	#elif FD == 4
	#define _FD_AND_TI1 "andc8"
	#define _FD_XOR_TI1 "xorc8"
	#endif
#elif D_==2
	#if FD == 1
	#define _FD_AND_TI2 "and"
	#define _FD_XOR_TI2 "xor"
	#elif FD == 2
	#define _FD_AND_TI2 "andc16"
	#define _FD_XOR_TI2 "xorc16"
	#elif FD == 4
	#define _FD_AND_TI2 "andc8"
	#define _FD_XOR_TI2 "xorc8"
	#endif
#elif D_==4
	#if FD == 1
	#define _FD_AND_TI4 "and"
	#define _FD_XOR_TI4 "xor"
	#elif FD == 2
	#define _FD_AND_TI4 "andc16"
	#define _FD_XOR_TI4 "xorc16"
	#elif FD == 4
	#define _FD_AND_TI4 "andc8"
	#define _FD_XOR_TI4 "xorc8"
	#endif
#endif

///**************** AND:
#if D_==1
        #define AND2(a,b,r) MASKED_AND_1(r,a,b)
#elif D_==2
	//#define AND2(a,b,r) MASKED_AND_2(r,a,b)
	#define AND2(a,b,r,r1,r2) MASKED_AND_2_inp_rand(r,a,b,r1,r2)
#elif D_==4
	#define AND2(a,b,r) MASKED_AND_4(r,a,b)
#endif

// new:
#define MASKED_AND_1(r,a,b) {					\
	asm volatile(_FD_AND_TI1 " %[r_], %[a_], %[b_]\n\t"	\
		: [r_]"=r" (r) 				\
		: [a_] "r" (a), [b_] "r" (b) :);	\
}

#ifdef LEAKY_SUBROT
#define MASKED_AND_2_inp_rand(res,a,b,r,r_input) {                                             \
    MDTYPE a2 = a;                                           						\
                                                                        \
                                                                        \
    register MDTYPE c1, c2, d1, d2, r_r, r_input_r, a2_2, a2_3;  \
    asm volatile(                                                       \
        _FD_XOR_TI2 " %[a2_2_], %[a2_], %[r_input_]\n\t"     /* random + a */ \
        "subrot %[r_input_r_], %[r_input_], 2\n\t"          /* rotate random */ \
        _FD_XOR_TI2 " %[a2_3_], %[a2_2_], %[r_input_r_]\n\t"  /* a + rot(random) */\
        _FD_AND_TI2 " %[c1_], %[b_], %[a2_3_]\n\t"      /* partial product 1 */   \
        "subrot %[a2_3_], %[a2_3_], 2\n\t"             /* share rotate */     \
        _FD_AND_TI2 " %[c2_], %[a2_3_], %[b_]\n\t"     /* partial product 2 */ \
        _FD_XOR_TI2 " %[d1_], %[r_], %[c1_]\n\t"      /* random + parprod 1 */ \
        _FD_XOR_TI2 " %[d2_], %[d1_], %[c2_]\n\t"     /*    + parprod 2 */   \
        "subrot %[r_r_], %[r_], 2\n\t"              /* parallel refresh */ \
        _FD_XOR_TI2 " %[res_], %[r_r_], %[d2_]\n\t"   /* output */           \
                                                                        \
        : [res_] "=&r" (res), [c1_] "=&r" (c1), [c2_] "=&r" (c2),       \
          [d1_] "=&r" (d1), [d2_] "=&r" (d2),                           \
          [r_r_] "=&r" (r_r),                       \
          [a2_2_] "=&r" (a2_2), [a2_3_] "=&r" (a2_3), [r_input_r_] "=&r" (r_input_r) \
        : [r_] "r" (r), [a2_] "r" (a2), [b_] "r" (b), [r_input_] "r" (r_input)); \
                                                                        \
}
#else
#define MASKED_AND_2_inp_rand(res,a,b,r,r_input) {                                             \
    MDTYPE a2 = a;                                           						\
                                                                        \
                                                                        \
    register MDTYPE c1, c2, d1, d2, r_r, a_r, r_input_r, a2_2, a2_3;  \
    asm volatile(                                                       \
        _FD_XOR_TI2 " %[a2_2_], %[a2_], %[r_input_]\n\t"     /* random + a */ \
        "subrot %[r_input_r_], %[r_input_], 2\n\t"          /* rotate random */ \
        _FD_XOR_TI2 " %[a2_3_], %[a2_2_], %[r_input_r_]\n\t"  /* a + rot(random) */\
        "xor %[r_input_r_], %[r_input_r_], %[r_input_r_]\n\t" /* clear subrot output */ \
        _FD_AND_TI2 " %[c1_], %[b_], %[a2_3_]\n\t"      /* partial product 1 */   \
        "subrot %[a_r_], %[a2_3_], 2\n\t"             /* share rotate */     \
        _FD_AND_TI2 " %[c2_], %[a_r_], %[b_]\n\t"     /* partial product 2 */ \
        "xor %[a_r_], %[a_r_], %[a_r_]\n\t"           /* clear subrot output */\
        _FD_XOR_TI2 " %[d1_], %[r_], %[c1_]\n\t"      /* random + parprod 1 */ \
        _FD_XOR_TI2 " %[d2_], %[d1_], %[c2_]\n\t"     /*    + parprod 2 */   \
        "subrot %[r_r_], %[r_], 2\n\t"              /* parallel refresh */ \
        _FD_XOR_TI2 " %[res_], %[r_r_], %[d2_]\n\t"   /* output */           \
                                                                        \
        : [res_] "=&r" (res), [c1_] "=&r" (c1), [c2_] "=&r" (c2),       \
          [d1_] "=&r" (d1), [d2_] "=&r" (d2),                           \
          [a_r_] "=&r" (a_r), [r_r_] "=&r" (r_r),                       \
          [a2_2_] "=&r" (a2_2), [a2_3_] "=&r" (a2_3), [r_input_r_] "=&r" (r_input_r) \
        : [r_] "r" (r), [a2_] "r" (a2), [b_] "r" (b), [r_input_] "r" (r_input)); \
                                                                        \
}
#endif

#define MASKED_AND_2(res,a,b) {                                             \
    MDTYPE a2 = a;                                           						\
                                                                        \
    volatile MDTYPE r = get_rand(); \
    volatile MDTYPE r_input = get_rand();                              \
                                                                        \
    register MDTYPE c1, c2, d1, d2, r_r, a_r, r_input_r, a2_2, a2_3;  \
    asm volatile(                                                       \
        _FD_XOR_TI2 " %[a2_2_], %[a2_], %[r_input_]\n\t"     /* random + a */ \
        "subrot %[r_input_r_], %[r_input_], 2\n\t"          /* rotate random */ \
        _FD_XOR_TI2 " %[a2_3_], %[a2_2_], %[r_input_r_]\n\t"  /* a + rot(random) */\
        "xor %[r_input_r_], %[r_input_r_], %[r_input_r_]\n\t" /* clear subrot output */ \
        _FD_AND_TI2 " %[c1_], %[b_], %[a2_3_]\n\t"      /* partial product 1 */   \
        "subrot %[a_r_], %[a2_3_], 2\n\t"             /* share rotate */     \
        _FD_AND_TI2 " %[c2_], %[a_r_], %[b_]\n\t"     /* partial product 2 */ \
        "xor %[a_r_], %[a_r_], %[a_r_]\n\t"           /* clear subrot output */\
        _FD_XOR_TI2 " %[d1_], %[r_], %[c1_]\n\t"      /* random + parprod 1 */ \
        _FD_XOR_TI2 " %[d2_], %[d1_], %[c2_]\n\t"     /*    + parprod 2 */   \
        "subrot %[r_r_], %[r_], 2\n\t"              /* parallel refresh */ \
        _FD_XOR_TI2 " %[res_], %[r_r_], %[d2_]\n\t"   /* output */           \
                                                                        \
        : [res_] "=&r" (res), [c1_] "=&r" (c1), [c2_] "=&r" (c2),       \
          [d1_] "=&r" (d1), [d2_] "=&r" (d2),                           \
          [a_r_] "=&r" (a_r), [r_r_] "=&r" (r_r),                       \
          [a2_2_] "=&r" (a2_2), [a2_3_] "=&r" (a2_3), [r_input_r_] "=&r" (r_input_r) \
        : [r_] "r" (r), [a2_] "r" (a2), [b_] "r" (b), [r_input_] "r" (r_input)); \
                                                                        \
}

#define MASKED_AND_4(res,a,b) {                                         \
    MDTYPE a2 = a;                                       					\
                                                                    \
    volatile MDTYPE r = get_rand(); \
    volatile MDTYPE r_input = get_rand();                          \
                                                                    \
    register MDTYPE c1, c2, c3, c4, a_r1, a_r2, b_r, r_r, d1, d2, d3, d4, a2_2, a2_3, r_input_r; \
    asm volatile(                                                   \
        _FD_XOR_TI4 " %[a2_2_], %[a2_], %[r_input_]\n\t"     /* random + a */ \
        "subrot %[r_input_r_], %[r_input_], 4\n\t"          /* rotate random */ \
        _FD_XOR_TI4 " %[a2_3_], %[a2_2_], %[r_input_r_]\n\t"  /* a + rot(random) */\
        "xor %[r_input_r_], %[r_input_r_], %[r_input_r_]\n\t" /* clear subrot output */ \
        _FD_AND_TI4 " %[c1_], %[a2_3_], %[b_]\n\t"   /* partial product 1 */ \
        "subrot %[a_r1_], %[a2_3_], 4\n\t"          /* share rotate */   \
        _FD_AND_TI4 " %[c2_], %[a_r1_], %[b_]\n\t" /* partial product 2 */ \
        "subrot %[b_r_], %[b_], 4\n\t"            /* share rotate */   \
        _FD_AND_TI4 " %[c3_], %[b_r_], %[a2_3_]\n\t"  /* partial product 3 */ \
        "subrot %[a_r2_], %[a_r1_], 4\n\t"        /* share rotate */   \
        _FD_AND_TI4 " %[c4_], %[a_r2_], %[b_]\n\t" /* partial product 4 */ \
        "xor %[a_r1_], %[a_r1_], %[a_r1_]\n\t"     /* clear subrot output */ \
        "xor %[b_r_], %[b_r_], %[b_r_]\n\t"        /* clear subrot output */ \
        "xor %[a_r2_], %[a_r2_], %[a_r2_]\n\t"     /* clear subrot output */ \
        _FD_XOR_TI4 " %[d1_], %[r_], %[c1_]\n\t"   /* random + parprod 1 */ \
        _FD_XOR_TI4 " %[d2_], %[d1_], %[c2_]\n\t"  /*    + parprod 2 */ \
        _FD_XOR_TI4 " %[d3_], %[d2_], %[c3_]\n\t"  /*    + parprod 3 */ \
        "subrot %[r_r_], %[r_], 4\n\t"            /* parallel refresh */ \
        _FD_XOR_TI4 " %[d4_], %[d3_], %[r_r_]\n\t"                      \
        _FD_XOR_TI4 " %[res_], %[d4_], %[c4_]\n\t" /* output */       \
                                                                      \
        : [res_] "=&r" (res),                                         \
          [c1_] "=&r" (c1), [c2_] "=&r" (c2), [c3_] "=&r" (c3), [c4_] "=&r" (c4), \
          [d1_] "=&r" (d1), [d2_] "=&r" (d2), [d3_] "=&r" (d3), [d4_] "=&r" (d4), \
          [a_r1_] "=&r" (a_r1), [a_r2_] "=&r" (a_r2),                   \
          [b_r_] "=&r" (b_r),  [r_r_] "=&r" (r_r),                      \
          [a2_2_] "=&r" (a2_2), [a2_3_] "=&r" (a2_3), [r_input_r_] "=&r" (r_input_r) \
        : [r_] "r" (r), [a2_] "r" (a2), [b_] "r" (b), [r_input_] "r" (r_input)); \
                                                                        \
}

///********* OR:

#if D_==1
	#define OR2(a,b,r) MASKED_OR_1(r,a,b)
#elif D_==2
	//#define OR2(a,b,r) MASKED_OR_2(r,a,b)
	#define OR2(a,b,r,r1,r2) MASKED_OR_2_inp_rand(r,a,b,r1,r2)
#elif D_==4
	#define OR2(a,b,r) MASKED_OR_4(r,a,b)
#endif


#define MASKED_OR_1(r,a,b) {                        \
    MDTYPE nota, notb, notr;                  \
    MASKED_NOT_1(nota,a);                           \
    MASKED_NOT_1(notb,b);                           \
    MASKED_AND_1(notr,nota,notb);                   \
    MASKED_NOT_1(r,notr);                           \
}

#define MASKED_OR_2_inp_rand(a,b,c,r,r_input) {                        \
    MDTYPE notb, notc, nota;                  \
    MASKED_NOT_2(notb,b);                           \
    MASKED_NOT_2(notc,c);                           \
    MASKED_AND_2_inp_rand(nota,notb,notc,r,r_input);                   \
    MASKED_NOT_2(a,nota);                           \
  }

#define MASKED_OR_2(a,b,c) {                        \
    MDTYPE notb, notc, nota;                  \
    MASKED_NOT_2(notb,b);                           \
    MASKED_NOT_2(notc,c);                           \
    MASKED_AND_2(nota,notb,notc);                   \
    MASKED_NOT_2(a,nota);                           \
  }

#define MASKED_OR_4(a,b,c) {                        \
    MDTYPE notb, notc, nota;                  \
    MASKED_NOT_4(notb,b);                           \
    MASKED_NOT_4(notc,c);                           \
    MASKED_AND_4(nota,notb,notc);                   \
    MASKED_NOT_4(a,nota);                           \
  }


//// *********** XOR: 

#define XOR2(a,b,r) {                                   \
        asm volatile(_FD_XOR_TI1 " %[r_], %[a_], %[b_]\n\t"     \
                : [r_]"=r" (r)                          \
                : [a_] "r" (a), [b_] "r" (b) :);        \
}

//// *********** NOT:

#if D_==1
	#define NOT1(a,r) MASKED_NOT_1(r,a)
#elif D_==2
	#define NOT1(a,r) MASKED_NOT_2(r,a)
#elif D_==4
	#define NOT1(a,r) MASKED_NOT_4(r,a)
#endif

#define MASKED_NOT_1(r,a) { r = a ^ 0xffffffff; }

#define MASKED_NOT_2(r,a) { r = a ^ 0x55555555; } 

#define MASKED_NOT_4(r,a) { r = a ^ 0x11111111; }


//// *********** DFF:

#define DFF(clk,d,q) { q = d; }


#endif
