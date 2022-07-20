/** @module : ALU
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory

 *  Copyright (c) 2019 BRISC-V (ASCS/ECE/BU)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

module ALU #(
  parameter DATA_WIDTH = 32
) (
  input [5:0] ALU_operation,
  input [DATA_WIDTH-1:0] operand_A,
  input [DATA_WIDTH-1:0] operand_B,
  output [DATA_WIDTH-1:0] ALU_result
);

wire signed [DATA_WIDTH-1:0] signed_operand_A;
wire signed [DATA_WIDTH-1:0] signed_operand_B;

wire [4:0] shamt;

// wires for signed operations
wire [(DATA_WIDTH*2)-1:0] arithmetic_right_shift_double;
wire [DATA_WIDTH-1:0] arithmetic_right_shift;
wire signed [DATA_WIDTH-1:0] signed_less_than;
wire signed [DATA_WIDTH-1:0] signed_greater_than_equal;

assign shamt = operand_B [4:0];     // I_immediate[4:0];

assign signed_operand_A = operand_A;
assign signed_operand_B = operand_B;

// Signed Operations
assign arithmetic_right_shift_double = ({ {DATA_WIDTH{operand_A[DATA_WIDTH-1]}}, operand_A }) >> shamt;
assign arithmetic_right_shift = arithmetic_right_shift_double[DATA_WIDTH-1:0];
assign signed_less_than = signed_operand_A < signed_operand_B;
assign signed_greater_than_equal = signed_operand_A >= signed_operand_B;

assign ALU_result =
  (ALU_operation == 6'd0 )? operand_A + operand_B:     /* ADD, ADDI, LB, LH, LW,
                                                          LBU, LHU, SB, SH, SW,
                                                          AUIPC, LUI */
  (ALU_operation == 6'd1 )? operand_A:                 /* JAL, JALR */
  (ALU_operation == 6'd2 )? operand_A == operand_B:    /* BEQ */
  (ALU_operation == 6'd3 )? operand_A != operand_B:    /* BNE */
  (ALU_operation == 6'd4 )? signed_less_than:          /* BLT, SLTI, SLT */
  (ALU_operation == 6'd5 )? signed_greater_than_equal: /* BGE */
  (ALU_operation == 6'd6 )? operand_A < operand_B:     /* BLTU, SLTIU, SLTU*/
  (ALU_operation == 6'd7 )? operand_A >= operand_B:    /* BGEU */
  (ALU_operation == 6'd8 )? operand_A ^ operand_B:     /* XOR, XORI*/
  (ALU_operation == 6'd9 )? operand_A | operand_B:     /* OR, ORI */
  (ALU_operation == 6'd10)? operand_A & operand_B:     /* AND, ANDI */
  (ALU_operation == 6'd11)? operand_A << shamt:        /* SLL, SLLI */
  (ALU_operation == 6'd12)? operand_A >> shamt:        /* SRL, SRLI */
  (ALU_operation == 6'd13)? arithmetic_right_shift:    /* SRA, SRAI */
  (ALU_operation == 6'd14)? operand_A - operand_B:     /* SUB */

  (ALU_operation == 6'd15)? 						   /* pk SUBROT */
		(operand_B[2:0] == 3'h2) ? ((operand_A & 32'h55555555) << 1) | ((operand_A & 32'haaaaaaaa) >> 1):
		(operand_B[2:0] == 3'h4) ? ((operand_A & 32'h77777777) << 1) | ((operand_A & 32'h88888888) >> 3):
		32'h00000000:

  (ALU_operation == 6'd16)?      					   /* pk REDL */
		(operand_B[2:0] == 3'h2) ? {operand_A[15:0], operand_A[15:0]}: // 2L
		(operand_B[2:0] == 3'h3) ? {~operand_A[15:0], operand_A[15:0]}: // 3L
		(operand_B[2:0] == 3'h4) ? {operand_A[7:0], operand_A[7:0], operand_A[7:0], operand_A[7:0]}: // 4L
		(operand_B[2:0] == 3'h5) ? {~operand_A[7:0], operand_A[7:0], ~operand_A[7:0], operand_A[7:0]}: // 5L
		(operand_B[2:0] == 3'h6) ? {operand_A[23:16], operand_A[23:16], operand_A[23:16], operand_A[23:16]}: // 6L
		(operand_B[2:0] == 3'h7) ? {~operand_A[23:16], operand_A[23:16], ~operand_A[23:16], operand_A[23:16]}: // 7L
		32'h00000000:

  (ALU_operation == 6'd17)?      					   /* pk REDH */
		(operand_B[2:0] == 3'h2) ? {operand_A[31:16], operand_A[31:16]}: // 2H
		(operand_B[2:0] == 3'h3) ? {~operand_A[31:16], operand_A[31:16]}: // 3H
		(operand_B[2:0] == 3'h4) ? {operand_A[15:8], operand_A[15:8], operand_A[15:8], operand_A[15:8]}: // 4H
		(operand_B[2:0] == 3'h5) ? {~operand_A[15:8], operand_A[15:8], ~operand_A[15:8], operand_A[15:8]}: // 5H
		(operand_B[2:0] == 3'h6) ? {operand_A[31:24], operand_A[31:24], operand_A[31:24], operand_A[31:24]}: // 6H
		(operand_B[2:0] == 3'h7) ? {~operand_A[31:24], operand_A[31:24], ~operand_A[31:24], operand_A[31:24]}: // 7H
		32'h00000000:

  (ALU_operation == 6'd18)?      /* pk FTCHK */
		(operand_B[3:0] == 4'h2) ? {(operand_A[31:16] ^ operand_A[15:0]), (operand_A[31:16] ^ operand_A[15:0])}:
		(operand_B[3:0] == 4'ha) ? {~(operand_A[31:16] ^ operand_A[15:0]), (operand_A[31:16] ^ operand_A[15:0])}:
		(operand_B[3:0] == 4'h3) ? {~(operand_A[31:16] ^ operand_A[15:0]), ~(operand_A[31:16] ^ operand_A[15:0])}:
		(operand_B[3:0] == 4'hb) ? {(operand_A[31:16] ^ operand_A[15:0]), ~(operand_A[31:16] ^ operand_A[15:0])}:
		(operand_B[3:0] == 4'h4) ? {((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])),
									((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])),
									((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])),
									((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])) }:
		(operand_B[3:0] == 4'hc) ? {~((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])),
									 ((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])),
									~((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])),
									 ((operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | (operand_A[7:0] ^ operand_A[31:24])) }:
		(operand_B[3:0] == 4'h5) ? {(~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])),
									(~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])),
									(~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])),
									(~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])) }:
		(operand_B[3:0] == 4'hd) ? {~(~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])),
									 (~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])),
									~(~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])),
									 (~(operand_A[7:0] ^ operand_A[15:8]) | (operand_A[7:0] ^ operand_A[23:16]) | ~(operand_A[7:0] ^ operand_A[31:24])) }:
		32'h00000000:
  
  (ALU_operation == 6'd19)? {(operand_A[31:16] | operand_B[31:16]),     /* pk ANDC16 */
			     			 (operand_A[15:0]  & operand_B[15:0]) }:
				 
  (ALU_operation == 6'd20)? {(operand_A[31:24] | operand_B[31:24]),     /* pk ANDC8 */
			 			     (operand_A[23:16] & operand_B[23:16]),
						     (operand_A[15:8]  | operand_B[15:8]),
			 			     (operand_A[7:0]   & operand_B[7:0]) }:

  (ALU_operation == 6'd21)? {~(operand_A[31:16] ^ operand_B[31:16]),     /* pk XORC16 */
						      (operand_A[15:0]  ^ operand_B[15:0]) }:

  (ALU_operation == 6'd22)? {~(operand_A[31:24] ^ operand_B[31:24]),     /* pk XORC8 */
			 			      (operand_A[23:16] ^ operand_B[23:16]),
						     ~(operand_A[15:8]  ^ operand_B[15:8]),
			 			      (operand_A[7:0]   ^ operand_B[7:0]) }:

  (ALU_operation == 6'd23)? { (operand_A[31:16] ^ operand_B[31:16]),     /* pk XNORC16 */
						     ~(operand_A[15:0]  ^ operand_B[15:0]) }:

  (ALU_operation == 6'd24)? { (operand_A[31:24] ^ operand_B[31:24]),     /* pk XNORC8 */
			 			     ~(operand_A[23:16] ^ operand_B[23:16]),
			 			      (operand_A[15:8]  ^ operand_B[15:8]),
						     ~(operand_A[7:0]   ^ operand_B[7:0]) }:

  (ALU_operation == 6'd25)? {operand_A[15], operand_B[15], operand_A[14], operand_B[14],      /* pk TR2L */
  							 operand_A[13], operand_B[13], operand_A[12], operand_B[12], 
							 operand_A[11], operand_B[11], operand_A[10], operand_B[10], 
							 operand_A[9],  operand_B[9],  operand_A[8],  operand_B[8], 
							 operand_A[7],  operand_B[7],  operand_A[6],  operand_B[6], 
							 operand_A[5],  operand_B[5],  operand_A[4],  operand_B[4], 
							 operand_A[3],  operand_B[3],  operand_A[2],  operand_B[2], 
							 operand_A[1],  operand_B[1],  operand_A[0],  operand_B[0]} :

  (ALU_operation == 6'd26)? {operand_A[31], operand_B[31], operand_A[30], operand_B[30],      /* pk TR2H */
  							 operand_A[29], operand_B[29], operand_A[28], operand_B[28], 
							 operand_A[27], operand_B[27], operand_A[26], operand_B[26], 
							 operand_A[25], operand_B[25], operand_A[24], operand_B[24], 
							 operand_A[23], operand_B[23], operand_A[22], operand_B[22], 
							 operand_A[21], operand_B[21], operand_A[20], operand_B[20], 
							 operand_A[19], operand_B[19], operand_A[18], operand_B[18], 
							 operand_A[17], operand_B[17], operand_A[16], operand_B[16]}:

  (ALU_operation == 6'd27)? {operand_A[30], operand_A[28], operand_A[26], operand_A[24],      /* pk INVTR2L */
  							 operand_A[22], operand_A[20], operand_A[18], operand_A[16], 
							 operand_A[14], operand_A[12], operand_A[10], operand_A[8], 
							 operand_A[6],  operand_A[4],  operand_A[2],  operand_A[0], 
							 operand_B[30], operand_B[28], operand_B[26], operand_B[24],
  							 operand_B[22], operand_B[20], operand_B[18], operand_B[16], 
							 operand_B[14], operand_B[12], operand_B[10], operand_B[8], 
							 operand_B[6],  operand_B[4],  operand_B[2],  operand_B[0]}:

  (ALU_operation == 6'd28)? {operand_A[31], operand_A[29], operand_A[27], operand_A[25],      /* pk INVTR2H */
  							 operand_A[23], operand_A[21], operand_A[19], operand_A[17], 
							 operand_A[15], operand_A[13], operand_A[11], operand_A[9], 
							 operand_A[7],  operand_A[5],  operand_A[3],  operand_A[1], 
							 operand_B[31], operand_B[29], operand_B[27], operand_B[25],
  							 operand_B[23], operand_B[21], operand_B[19], operand_B[17], 
							 operand_B[15], operand_B[13], operand_B[11], operand_B[9], 
							 operand_B[7],  operand_B[5],  operand_B[3],  operand_B[1]}:
  {DATA_WIDTH{1'b0}};

endmodule
