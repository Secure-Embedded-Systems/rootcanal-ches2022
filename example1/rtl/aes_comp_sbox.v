//======================================================================
//
// aes_sbox.v
// ----------
// The AES S-box. This implementation
// contains four parallel S-boxes to handle a 32 bit word.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2014, Secworks Sweden AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module aes_comp_sbox4(
                input wire [31 : 0]  sboxw,
                output wire [31 : 0] new_sboxw
               );


  //----------------------------------------------------------------
  // Instantiate The sboxes
  //----------------------------------------------------------------

  wire [7:0] sbox_out1;
  wire [7:0] sbox_out2;
  wire [7:0] sbox_out3;
  wire [7:0] sbox_out4;

  comp_sbox u_sbox1 (sboxw[7:0], sbox_out1);
  comp_sbox u_sbox2 (sboxw[15:8], sbox_out2);
  comp_sbox u_sbox3 (sboxw[23:16], sbox_out3);
  comp_sbox u_sbox4 (sboxw[31:24], sbox_out4);

  //----------------------------------------------------------------
  // Four parallel muxes.
  //----------------------------------------------------------------
  assign new_sboxw[31 : 24] = sbox_out4;
  assign new_sboxw[23 : 16] = sbox_out3;
  assign new_sboxw[15 : 08] = sbox_out2;
  assign new_sboxw[07 : 00] = sbox_out1;

endmodule // aes_sbox

//======================================================================
// EOF aes_sbox.v
//======================================================================
