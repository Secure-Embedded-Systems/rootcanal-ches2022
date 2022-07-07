/*

  read -format verilog {Stable.v}
  current_design Stable
  uniquify
  ungroup -flatten -all
  create_clock -name "clk" -period 50.0 {"clk"}
  compile -map_effort high
  report_area
  report_timing

*/

/* wolkerstorfer sbox */

module comp_sbox (address, data_out /*clk, reset*/);

	input  [7:0] address;

	output [7:0] data_out;	
    wire   [7:0] data;

    Stablec S(address, data_out);

endmodule

module comp_inv_sbox (address, data_out /*clk, reset*/);

	input  [7:0] address;
	output [7:0] data_out;	
    wire   [7:0] data;

    Stablec_inv S(address, data_out);

endmodule

module map(a, ah, al);
  input   [7:0] a;
  output  [3:0] ah, al;

  wire aA,  aB,  aC;
  wire ah3, ah2, ah1, ah0;
  wire al3, al2, al1, al0;

  assign aA  = a[1] ^ a[7];
  assign aB  = a[5] ^ a[7];
  assign aC  = a[4] ^ a[6];

  assign al3 = a[2] ^ a[4];
  assign al2 = aA;
  assign al1 = a[1] ^ a[2];
  assign al0 = aC ^ a[0] ^ a[5];
  assign al  = (al3 << 3) | (al2 << 2) | (al1 << 1) | al0;

  assign ah3 = aB;
  assign ah2 = aB ^ a[2] ^ a[3];
  assign ah1 = aA ^ aC;
  assign ah0 = aC ^ a[5];
  assign ah  = (ah3 << 3) | (ah2 << 2) | (ah1 << 1) | ah0;          

endmodule

module invmap(ah, al, a);
  input  [3:0] ah, al;
  output [7:0] a;

  wire aA, aB;
  wire a3, a2, a1, a0;
  wire a4, a5, a6, a7;

  assign   aA = al[1] ^ ah[3];
  assign   aB = ah[0] ^ ah[1];
  assign   a0 = al[0] ^ ah[0];
  assign   a1 = aB    ^ ah[3];
  assign   a2 = aA    ^ aB;
  assign   a3 = aB    ^ al[1] ^ ah[2];
  assign   a4 = aA    ^ aB ^ al[3];
  assign   a5 = aB    ^ al[2];
  assign   a6 = aA    ^ al[2] ^ al[3] ^ ah[0];
  assign   a7 = aB    ^ al[2] ^ ah[3];

  assign   a  = (a7 << 7) | (a6 << 6) | (a5 << 5) | (a4 << 4) |
         (a3 << 3) | (a2 << 2) | (a1 << 1) | a0;
endmodule

module sqr(a, c);
  input  [3:0] a;
  output [3:0] c;

  wire c0, c1, c2, c3;

  assign c0 = a[0] ^ a[2];
  assign c1 = a[2];
  assign c2 = a[1] ^ a[3];
  assign c3 = a[3];

  assign c = (c3 << 3) | (c2 << 2) | (c1 << 1) | c0;

endmodule

module invg4(a, c);
  input  [3:0] a;
  output [3:0] c;

  wire c0, c1, c2, c3, aA;

  assign aA = a[1] ^ a[2] ^ a[3] ^ (a[1] & a[2] & a[3]);
  assign c0 = aA ^ a[0] ^ (a[0] & a[2]) ^ (a[1] & a[2]) ^ (a[0] & a[1] & a[2]);
  assign c1 = (a[0] & a[1]) ^ (a[0] & a[2]) ^ (a[1] & a[2]) ^ a[3] ^
          (a[1] & a[3]) ^ (a[0] & a[1] & a[3]);
  assign c2 = (a[0] & a[1]) ^ a[2] ^ (a[0] & a[2]) ^ a[3] ^
          (a[0] & a[3]) ^ (a[0] & a[2] & a[3]);
  assign c3 = aA ^ (a[0] & a[3]) ^ (a[1] & a[3]) ^ (a[2] & a[3]);

  assign c = (c3 << 3) | (c2 << 2) | (c1 << 1) | c0;

endmodule

module add4(a, b, c);
  input [3:0] a,b;
  output [3:0] c;

  assign c = a ^ b;
endmodule

module mul4(a, b, q);
  input  [3:0] a, b;
  output [3:0] q;
  wire   aA,  aB, q0, q1, q2, q3;
  wire   acc0, acc1, acc2, acc3;

  assign  aA = a[0] ^ a[3];
  assign  aB = a[2] ^ a[3];
  assign  q0 = (a[0] & b[0]) ^ (a[3] & b[1]) ^ (a[2] & b[2]) ^  (a[1] & b[3]);
  assign  q1 = (a[1] & b[0]) ^ (aA   & b[1]) ^ (aB   & b[2]) ^ ((a[1] ^ a[2]) & b[3]);
  assign  q2 = (a[2] & b[0]) ^ (a[1] & b[1]) ^ (aA   & b[2]) ^  (aB & b[3]);
  assign  q3 = (a[3] & b[0]) ^ (a[2] & b[1]) ^ (a[1] & b[2]) ^  (aA & b[3]);
  assign  q = (q3 << 3) | (q2 << 2) | (q1 << 1) | q0;
endmodule
  
module mul4e(a, c);
  input  [3:0] a;
  output [3:0] c;
  wire c0, c1, c2, c3, aA, aB;
  wire acc0, acc1, acc2, acc3;
  wire b;

  assign  aA = a[0] ^ a[1];
  assign  aB = a[2] ^ a[3];
  assign  c0 = a[1] ^ aB;
  assign  c1 = aA;
  assign  c2 = aA ^ a[2];
  assign  c3 = aA ^ aB;

  assign  c = (c3 << 3) | (c2 << 2) | (c1 << 1) | c0;

endmodule

module afine(a,q);
  input  [7:0] a;
  output [7:0] q;
  wire q0, q1, q2, q3, q4, q5, q6, q7;
  wire aA, aB, aC, aD;

  assign aA = a[0] ^ a[1];
  assign aB = a[2] ^ a[3];
  assign aC = a[4] ^ a[5];
  assign aD = a[6] ^ a[7];
  assign q0 = ~a[0] ^ aC ^ aD;
  assign q1 = ~a[5] ^ aA ^ aD;
  assign q2 =  a[2] ^ aA ^ aD;
  assign q3 =  a[7] ^ aA ^ aB;
  assign q4 =  a[4] ^ aA ^ aB;
  assign q5 = ~a[1] ^ aB ^ aC;
  assign q6 = ~a[6] ^ aB ^ aC;
  assign q7 =  a[3] ^ aC ^ aD;

  assign   q  = (q7 << 7) | (q6 << 6) | (q5 << 5) | (q4 << 4) |
                (q3 << 3) | (q2 << 2) | (q1 << 1) | q0;

endmodule

module inv_afine(a,q);
  input  [7:0] a;
  output [7:0] q;
  wire q0, q1, q2, q3, q4, q5, q6, q7;
  wire aA, aB, aC, aD;

  assign aA =  a[0] ^ a[5];
  assign aB =  a[1] ^ a[4];
  assign aC =  a[2] ^ a[7];
  assign aD =  a[3] ^ a[6];
  assign q0 = ~a[5] ^ aC;
  assign q1 =  a[0] ^ aD;
  assign q2 = ~a[7] ^ aB;
  assign q3 =  a[2] ^ aA;
  assign q4 =  a[1] ^ aD;
  assign q5 =  a[4] ^ aC;
  assign q6 =  a[3] ^ aA;
  assign q7 =  a[6] ^ aB;

  assign   q  = {q7, q6, q5, q4, q3, q2, q1, q0};

endmodule

module Stablec (address, data);
        input [7:0] address;
        output [7:0] data;      

   wire [3:0] in_h, in_l, in_h_sqr, in_l_sqr;
   wire [3:0] mul4_1o, add4_1o, mul4e_o, add4_2o, add4_3o;
   wire [3:0] d, mul4_2o, mul4_3o;
   wire [7:0] invmap_out;

   map    m1(address,    in_h, in_l          );
   sqr    m2(in_h,       in_h_sqr            );
   sqr    m3(in_l,       in_l_sqr            );
   mul4   m4(in_h,       in_l,     mul4_1o   );    
   add4   m5(in_h,       in_l,     add4_1o   );    
   mul4e  m6(in_h_sqr,   mul4e_o             );
   add4   m7(in_l_sqr,   mul4e_o,  add4_2o   );
   add4   m8(add4_2o,    mul4_1o,  add4_3o   );
   invg4  m9(add4_3o,    d                   );
   mul4   ma(in_h,       d,        mul4_2o   );
   mul4   mb(d,          add4_1o,  mul4_3o   );
   invmap mc(mul4_2o,    mul4_3o,  invmap_out);
   afine  md(invmap_out, data                );

endmodule

// To compute inverse SBox
module Stablec_inv (address, data);
        input [7:0] address;
        output [7:0] data;      

   wire [3:0] in_h, in_l, in_h_sqr, in_l_sqr;
   wire [3:0] mul4_1o, add4_1o, mul4e_o, add4_2o, add4_3o;
   wire [3:0] d, mul4_2o, mul4_3o;
   wire [7:0] invafine_out;

   inv_afine md(address, invafine_out        );
   map    m1(invafine_out,in_h, in_l         );
   sqr    m2(in_h,       in_h_sqr            );
   sqr    m3(in_l,       in_l_sqr            );
   mul4   m4(in_h,       in_l,     mul4_1o   );    
   add4   m5(in_h,       in_l,     add4_1o   );    
   mul4e  m6(in_h_sqr,   mul4e_o             );
   add4   m7(in_l_sqr,   mul4e_o,  add4_2o   );
   add4   m8(add4_2o,    mul4_1o,  add4_3o   );
   invg4  m9(add4_3o,    d                   );
   mul4   ma(in_h,       d,        mul4_2o   );
   mul4   mb(d,          add4_1o,  mul4_3o   );
   invmap mc(mul4_2o,    mul4_3o,  data      );

endmodule

