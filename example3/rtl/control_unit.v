/*  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory

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
 *
 *
 */

module control_unit #(
  parameter CORE            = 0,
  parameter ADDRESS_BITS    = 20,
  parameter NUM_BYTES       = 32/8,
  parameter LOG2_NUM_BYTES  = log2(NUM_BYTES),
  parameter SCAN_CYCLES_MIN = 0,
  parameter SCAN_CYCLES_MAX = 1000
) (
  input clock,
  input reset,
  input [6:0] opcode_decode,
  input [6:0] opcode_execute,
  input [2:0] funct3, // decode
  input [6:0] funct7, // decode

  input [ADDRESS_BITS-1:0] JALR_target_execute,
  input [ADDRESS_BITS-1:0] branch_target_execute,
  input [ADDRESS_BITS-1:0] JAL_target_decode,
  input branch_execute,

  input true_data_hazard,
  input d_mem_hazard,
  input i_mem_hazard,
  input JALR_branch_hazard,
  input JAL_hazard,

  output branch_op,
  output memRead,
  output [5:0] ALU_operation, // use 6-bits to leave room for extensions
  output memWrite,
  output [LOG2_NUM_BYTES-1:0] log2_bytes,
  output unsigned_load,
  output [1:0] next_PC_sel,
  output [1:0] operand_A_sel,
  output operand_B_sel,
  output [1:0] extend_sel,
  output regWrite,

  output [ADDRESS_BITS-1:0] target_PC,
  output i_mem_read,

  input  scan
);

//define the log2 function
function integer log2;
input integer value;
begin
  value = value-1;
  for (log2=0; value>0; log2=log2+1)
    value = value >> 1;
end
endfunction


localparam [6:0]R_TYPE  = 7'b0110011,
                I_TYPE  = 7'b0010011,
                SKIVA_TYPE  = 7'b0001011, // pk
                STORE   = 7'b0100011,
                LOAD    = 7'b0000011,
                BRANCH  = 7'b1100011,
                JALR    = 7'b1100111,
                JAL     = 7'b1101111,
                AUIPC   = 7'b0010111,
                LUI     = 7'b0110111,
                FENCES  = 7'b0001111,
                SYSCALL = 7'b1110011;


assign regWrite      = (opcode_decode == R_TYPE) | (opcode_decode == I_TYPE) | (opcode_decode == LOAD)
                       | (opcode_decode == JALR) | (opcode_decode == JAL)    | (opcode_decode == AUIPC)
                       | (opcode_decode == LUI)  | (opcode_decode == SKIVA_TYPE)/* pk */;

assign memWrite      = (opcode_decode == STORE);
assign branch_op     = (opcode_decode == BRANCH);
assign memRead       = (opcode_decode == LOAD);


assign log2_bytes = (opcode_decode == LOAD  & funct3 == 3'b000) ? 0 : // LB
                    (opcode_decode == LOAD  & funct3 == 3'b001) ? 1 : // LH
                    (opcode_decode == LOAD  & funct3 == 3'b010) ? 2 : // LW
                    (opcode_decode == LOAD  & funct3 == 3'b100) ? 0 : // LBU
                    (opcode_decode == LOAD  & funct3 == 3'b101) ? 1 : // LHU
                    (opcode_decode == STORE & funct3 == 3'b000) ? 0 : // SB
                    (opcode_decode == STORE & funct3 == 3'b001) ? 1 : // SH
                    (opcode_decode == STORE & funct3 == 3'b010) ? 2 : // SW
                    {LOG2_NUM_BYTES{1'b0}};

assign unsigned_load = (opcode_decode == LOAD & funct3 == 3'b100) | // LBU
                       (opcode_decode == LOAD & funct3 == 3'b101);  // LHU

/* old
assign ALU_operation = (opcode_decode == R_TYPE) ?  3'b000 :
                       (opcode_decode == I_TYPE) ?  3'b001 :
                       (opcode_decode == STORE)  ?  3'b101 :
                       (opcode_decode == LOAD)   ?  3'b100 :
                       (opcode_decode == BRANCH) ?  3'b010 :
                       ((opcode_decode == JALR)  | (opcode_decode == JAL)) ? 3'b011 :
                       ((opcode_decode == AUIPC) | (opcode_decode == LUI)) ? 3'b110 : 2'b00;
*/

// Check for operations other than addition. Use addition as default case
assign ALU_operation =
  (opcode_decode == JAL) ? 6'd1 : // JAL: Pass through
  (opcode_decode == JALR & funct3 == 3'b000) ? 6'd1 : // JALR: Pass through
  (opcode_decode == BRANCH & funct3 == 3'b000) ? 6'd2 : // BEQ: equal
  (opcode_decode == BRANCH & funct3 == 3'b001) ? 6'd3 : // BNE: not equal
  (opcode_decode == BRANCH & funct3 == 3'b100) ? 6'd4 : // BLT: signed less than
  (opcode_decode == BRANCH & funct3 == 3'b101) ? 6'd5 : // BGE: signed greater than, equal
  (opcode_decode == BRANCH & funct3 == 3'b110) ? 6'd6 : // BLTU: unsigned less than
  (opcode_decode == BRANCH & funct3 == 3'b111) ? 6'd7 : // BGEU: unsigned greater than, equal
  (opcode_decode == I_TYPE & funct3 == 3'b010) ? 6'd4 : // SLTI: signed less than
  (opcode_decode == I_TYPE & funct3 == 3'b011) ? 6'd6 : // SLTIU: unsigned less than
  (opcode_decode == I_TYPE & funct3 == 3'b100) ? 6'd8 : // XORI: xor
  (opcode_decode == I_TYPE & funct3 == 3'b110) ? 6'd9 : // ORI: or
  (opcode_decode == I_TYPE & funct3 == 3'b111) ? 6'd10 : // ANDI: and
  (opcode_decode == I_TYPE & funct3 == 3'b001 & funct7 == 7'b0000000) ? 6'd11 : // SLLI: logical left shift
  (opcode_decode == I_TYPE & funct3 == 3'b101 & funct7 == 7'b0000000) ? 6'd12 : // SRLI: logical right shift
  (opcode_decode == I_TYPE & funct3 == 3'b101 & funct7 == 7'b0100000) ? 6'd13 : // SRAI: arithemtic right shift
  (opcode_decode == R_TYPE & funct3 == 3'b000 & funct7 == 7'b0100000) ? 6'd14 : // SUB: subtract
  (opcode_decode == R_TYPE & funct3 == 3'b001 & funct7 == 7'b0000000) ? 6'd11 : // SLL: logical left shift
  (opcode_decode == R_TYPE & funct3 == 3'b010 & funct7 == 7'b0000000) ? 6'd4  : // SLT: signed less than
  (opcode_decode == R_TYPE & funct3 == 3'b011 & funct7 == 7'b0000000) ? 6'd6  : // SLTU: signed less than
  (opcode_decode == R_TYPE & funct3 == 3'b100 & funct7 == 7'b0000000) ? 6'd8  : // XOR: xor
  (opcode_decode == R_TYPE & funct3 == 3'b101 & funct7 == 7'b0000000) ? 6'd12 : // SRL: logical right shift
  (opcode_decode == R_TYPE & funct3 == 3'b101 & funct7 == 7'b0100000) ? 6'd13 : // SRA: arithmetic right shift
  (opcode_decode == R_TYPE & funct3 == 3'b110 & funct7 == 7'b0000000) ? 6'd9  : // OR: or
  (opcode_decode == R_TYPE & funct3 == 3'b111 & funct7 == 7'b0000000) ? 6'd10 : // AND: and
// pk skiva - i-instructions:
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b000) ? 6'd15 : // SUBROT: subrotation of shares
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b001) ? 6'd16 : // REDL: redundancy generation - lower half
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b010) ? 6'd17 : // REDH: redundancy generation - upper half
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b011) ? 6'd18 : // FTCHK: fault check 
// pk skiva - r-instructions:
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b100 & funct7 == 7'b0010000) ? 6'd19 : // ANDC16: complementary AND on 16 bits 
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b100 & funct7 == 7'b0000000) ? 6'd20 : // ANDC8: complementary AND on 8 bits 
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b100 & funct7 == 7'b0010001) ? 6'd21 : // XORC16: complementary XOR on 16 bits 
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b100 & funct7 == 7'b0000001) ? 6'd22 : // XORC8: complementary XOR on 8 bits 
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b100 & funct7 == 7'b0010010) ? 6'd23 : // XNORC16: complementary XNOR on 16 bits 
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b100 & funct7 == 7'b0000010) ? 6'd24 : // XNORC8: complementary XNOR on 8 bits 
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b101 & funct7 == 7'b0000000) ? 6'd25 : // TR2L: transposition lower half
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b101 & funct7 == 7'b0010000) ? 6'd26 : // TR2H: transposition upper half
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b101 & funct7 == 7'b0000001) ? 6'd27 : // INVTR2L: transposition lower half
  (opcode_decode == SKIVA_TYPE & funct3 == 3'b101 & funct7 == 7'b0010001) ? 6'd28 : // INVTR2H: transposition upper half
  6'd0; // Use addition by default

assign operand_A_sel = (opcode_decode == AUIPC) ?  2'b01 :
                       (opcode_decode == LUI)   ?  2'b11 :
                       ((opcode_decode == JALR)  | (opcode_decode == JAL)) ? 2'b10 : 2'b00;

assign operand_B_sel = (opcode_decode == I_TYPE) | (opcode_decode == STORE) |
                       (opcode_decode == LOAD)   | (opcode_decode == AUIPC) |
                       (opcode_decode == LUI)    | ((opcode_decode == SKIVA_TYPE) && (funct3 < 3'd4)) /* pk */;

assign extend_sel    = ((opcode_decode == I_TYPE) | (opcode_decode == LOAD) | ((opcode_decode == SKIVA_TYPE) && (funct3 < 3'd4))/* pk */) ? 2'b00 :
                       (opcode_decode == STORE)                       ? 2'b01 :
                       ((opcode_decode == AUIPC)  | (opcode_decode == LUI))  ? 2'b10 : 2'b00;

assign target_PC = (opcode_execute == JALR)                    ? JALR_target_execute   :
                   (opcode_execute == BRANCH) & branch_execute ? branch_target_execute :
                   (opcode_decode  == JAL)                     ? JAL_target_decode     :
                   {ADDRESS_BITS{1'b0}};

assign next_PC_sel = JALR_branch_hazard ? 2'b10 : // target_PC
                     true_data_hazard   ? 2'b01 : // stall
                     JAL_hazard         ? 2'b10 : // targeet_PC
                     i_mem_hazard       ? 2'b01 : // stall
                     d_mem_hazard       ? 2'b01 : // stall
                     2'b00;                       // PC + 4

assign i_mem_read = 1'b1;

// synthesis translate_off
reg [31: 0] cycles;
always @ (posedge clock) begin
  cycles <= reset? 0 : cycles + 1;
  if (scan  & ((cycles >= SCAN_CYCLES_MIN) & (cycles <= SCAN_CYCLES_MAX)) )begin
    $display ("------ Core %d Control Unit - Current Cycle %d ------", CORE, cycles);
    $display ("| Opcode decode  [%b]", opcode_decode);
    $display ("| Opcode execute [%b]", opcode_execute);
    $display ("| Branch_op      [%b]", branch_op);
    $display ("| memRead        [%b]", memRead);
    $display ("| memWrite       [%b]", memWrite);
    $display ("| RegWrite       [%b]", regWrite);
    $display ("| log2_bytes     [%b]", log2_bytes);
    $display ("| unsigned_load  [%b]", unsigned_load);
    $display ("| ALU_operation  [%b]", ALU_operation);
    $display ("| Extend_sel     [%b]", extend_sel);
    $display ("| ALUSrc_A       [%b]", operand_A_sel);
    $display ("| ALUSrc_B       [%b]", operand_B_sel);
    $display ("| Next PC sel    [%b]", next_PC_sel);
    $display ("| Target PC      [%h]", target_PC);
    $display ("----------------------------------------------------------------------");
  end
end
// synthesis translate_on

endmodule
