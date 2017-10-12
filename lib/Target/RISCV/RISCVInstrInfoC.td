//===- RISCVInstrInfoC.td - Compressed RISCV instructions -*- tblgen-*-----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

include "RISCVInstrFormatsC.td"

//===----------------------------------------------------------------------===//
// Operand definitions.
//===----------------------------------------------------------------------===//

def uimm6 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isUInt<6>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<6>;
  let DecoderMethod = "decodeUImmOperand<6>";
}

def simm6 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isInt<6>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<6>;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmOperand<6>";
}

// A 8-bit unsigned immediate where the least two bits are zero.
def uimm8_lsb00 : Operand<XLenVT>,
                  ImmLeaf<XLenVT, [{return isShiftedUInt<6, 2>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<8, "Lsb00">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeUImmOperand<8>";
}

// A 7-bit unsigned immediate where the least two bits are zero.
def uimm7_lsb00 : Operand<XLenVT>,
                  ImmLeaf<XLenVT, [{return isShiftedUInt<5, 2>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<7, "Lsb00">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeUImmOperand<7>";
}

// A 9-bit signed immediate where the least significant bit is zero.
def simm9_lsb0 : Operand<OtherVT> {
  let ParserMatchClass = SImmAsmOperand<9, "Lsb0">;
  let EncoderMethod = "getImmOpValueAsr1";
  let DecoderMethod = "decodeSImmOperandAndLsl1<9>";
}

// A 12-bit signed immediate where the least significant bit is zero.
def simm12_lsb0 : Operand<OtherVT> {
  let ParserMatchClass = SImmAsmOperand<12, "Lsb0">;
  let EncoderMethod = "getImmOpValueAsr1";
  let DecoderMethod = "decodeSImmOperandAndLsl1<12>";
}

def uimm10_2lsb0 : Operand<XLenVT>,
                   ImmLeaf<XLenVT, [{return isShiftedUInt<8, 2>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<10, "Lsb00">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeUImmOperand<10>";
}

def simm10_4lsb0 : Operand<XLenVT>,
                   ImmLeaf<XLenVT, [{return isShiftedInt<6, 4>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<10, "Lsb0000">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmOperand<10>";
}

//===----------------------------------------------------------------------===//
// Instruction Class Templates
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class Stack_Load<bits<3> funct3, string OpcodeStr,
                 RegisterClass cls> :
      CI<funct3, 0b10, (outs cls:$rd), (ins SP:$rs1, uimm8_lsb00:$imm),
         OpcodeStr#"\t$rd, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class Stack_Store<bits<3> funct3, string OpcodeStr,
                  RegisterClass cls> :
      CSS<funct3, 0b10, (outs), (ins cls:$rs2, SP:$rs1, uimm8_lsb00:$imm),
          OpcodeStr#"\t$rs2, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class Reg_Load<bits<3> funct3, string OpcodeStr, SDPatternOperator Op,
               RegisterClass cls> :
      CL<funct3, 0b00, (outs cls:$rd), (ins cls:$rs1, uimm7_lsb00:$imm),
         OpcodeStr#"\t$rd, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class Reg_Store<bits<3> funct3, string OpcodeStr, SDPatternOperator Op,
                RegisterClass cls> :
      CS<funct3, 0b00, (outs), (ins cls:$rs2, cls:$rs1, uimm7_lsb00:$imm),
         OpcodeStr#"\t$rs2, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Jump_Imm : CJ<0b101, 0b01, (outs), (ins simm12_lsb0:$offset),
                    "c.j\t$offset"> {
  let isBranch = 1;
  let isTerminator=1;
  let isBarrier=1;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0, isCall = 1 in
class Call_Imm : CJ<0b001, 0b01, (outs), (ins simm12_lsb0:$offset),
                    "c.jal\t$offset">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Jump_Reg<RegisterClass cls> :
      CR<0b1000, 0b10, (outs), (ins cls:$rs1),
         "c.jr\t$rs1"> {
  let isBranch = 1;
  let isBarrier = 1;
  let isTerminator = 1;
  let isIndirectBranch = 1;
  let rs2 = 0;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0,
    isCall=1, Defs=[X1], rs2 = 0 in
class Call_Reg<RegisterClass cls> :
      CR<0b1001, 0b10, (outs), (ins cls:$rs1),
         "c.jalr\t$rs1">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Bcz<bits<3> funct3, string OpcodeStr, PatFrag CondOp,
          RegisterClass cls> :
      CB<funct3, 0b01, (outs), (ins cls:$rs1, simm9_lsb0:$imm),
         OpcodeStr#"\t$rs1, $imm"> {
  let isBranch = 1;
  let isTerminator = 1;
  let Inst{12} = imm{8};
  let Inst{11-10} = imm{4-3};
  let Inst{6-5} = imm{7-6};
  let Inst{4-3} = imm{2-1};
  let Inst{2} = imm{5};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Move_Imm<RegisterClass cls, Operand ImmOpnd> :
      CI<0b010, 0b01, (outs cls:$rd), (ins ImmOpnd:$imm),
         "c.li\t$rd, $imm"> {
  let Inst{6-2} = imm{4-0};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Move_High<RegisterClass cls, Operand ImmOpnd> :
      CI<0b011, 0b01, (outs cls:$rd), (ins ImmOpnd:$imm),
         "c.lui\t$rd, $imm"> {
  let Inst{6-2} = imm{4-0};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Add_Imm<RegisterClass cls, Operand ImmOpnd> :
      CI<0b000, 0b01, (outs cls:$rd_wb), (ins cls:$rd, ImmOpnd:$imm),
         "c.addi\t$rd, $imm"> {
  let Constraints = "$rd = $rd_wb";
  let Inst{6-2} = imm{4-0};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class ADDI_16SP<RegisterClass cls> :
      CI<0b011, 0b01, (outs cls:$rd_wb),
         (ins cls:$rd, simm10_4lsb0:$imm),
         "c.addi16sp\t$rd, $imm"> {
  let Constraints = "$rd = $rd_wb";
  let Inst{12} = imm{9};
  let Inst{11-7} = 2;
  let Inst{6} = imm{4};
  let Inst{5} = imm{6};
  let Inst{4-3} = imm{8-7};
  let Inst{2} = imm{5};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class ADDI_4SPN<RegisterClass cls, RegisterClass spcls> :
      CIW<0b000, 0b00, (outs cls:$rd),
          (ins spcls:$rs1, uimm10_2lsb0:$imm),
          "c.addi4spn\t$rd, $rs1, $imm"> {
  bits<5> rs1;
  let Inst{12-11} = imm{5-4};
  let Inst{10-7} = imm{9-6};
  let Inst{6} = imm{2};
  let Inst{5} = imm{3};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Shift_left<RegisterClass cls, Operand ImmOpnd> :
      CI<0b000, 0b10, (outs cls:$rd_wb),
         (ins cls:$rd, ImmOpnd:$imm),
         "c.slli\t$rd, $imm"> {
  let Constraints = "$rd = $rd_wb";
  let Inst{6-2} = imm{4-0};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Shift_right<bits<2> funct2, string OpcodeStr, SDPatternOperator OpNode,
                  RegisterClass cls, Operand ImmOpnd> :
      CB<0b100, 0b01, (outs cls:$rs1_wb), (ins cls:$rs1, ImmOpnd:$imm),
         OpcodeStr#"\t$rs1, $imm"> {
  let Constraints = "$rs1 = $rs1_wb";
  let Inst{12} = imm{5};
  let Inst{11-10} = funct2;
  let Inst{6-2} = imm{4-0};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class And_Imm<RegisterClass cls, Operand ImmOpnd> :
      CB<0b100, 0b01, (outs cls:$rs1_wb), (ins cls:$rs1, ImmOpnd:$imm),
               "c.andi\t$rs1, $imm"> {
  let Constraints = "$rs1 = $rs1_wb";
  let Inst{12} = imm{5};
  let Inst{11-10} = 0b10;
  let Inst{6-2} = imm{4-0};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Move_Reg<RegisterClass cls> :
      CR<0b1000, 0b10, (outs cls:$rs1), (ins cls:$rs2),
         "c.mv\t$rs1, $rs2">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Add_Reg<RegisterClass cls> :
      CR<0b1001, 0b10, (outs cls:$rs1_wb), (ins cls:$rs1, cls:$rs2),
              "c.add\t$rs1, $rs2"> {
  let Constraints = "$rs1 = $rs1_wb";
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class CS_ALU<bits<2> funct2, string OpcodeStr, SDPatternOperator OpNode,
             RegisterClass cls, bit RV64only> :
      CS<0b100, 0b01, (outs cls:$rd_wb), (ins cls:$rd, cls:$rs2),
         OpcodeStr#"\t$rd, $rs2"> {
  bits<3> rd;
  let Constraints = "$rd = $rd_wb";
  let Inst{12} = RV64only;
  let Inst{11-10} = 0b11;
  let Inst{9-7} = rd;
  let Inst{6-5} = funct2;
}

//===----------------------------------------------------------------------===//
// Stack-Pointer-Based Loads and Stores
//===----------------------------------------------------------------------===//

def CLWSP  : Stack_Load<0b010, "c.lwsp", GPR>,
             Requires<[HasStdExtC]> {
  let Inst{6-4} = imm{4-2};
  let Inst{3-2} = imm{7-6};
}

def CSWSP  : Stack_Store<0b110, "c.swsp", GPR>,
             Requires<[HasStdExtC]> {
  let Inst{12-9} = imm{5-2};
  let Inst{8-7}  = imm{7-6};
}

//===----------------------------------------------------------------------===//
// Register-Based Loads and Stores
//===----------------------------------------------------------------------===//

def CLW  : Reg_Load<0b010, "c.lw", load, GPRC>, Requires<[HasStdExtC]> {
  bits<7> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6} = imm{2};
  let Inst{5} = imm{6};
}

def CSW  : Reg_Store<0b110, "c.sw", store, GPRC>,
           Requires<[HasStdExtC]> {
  bits<7> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6} = imm{2};
  let Inst{5} = imm{6};
}

//===----------------------------------------------------------------------===//
// Control Transfer Instructions
//===----------------------------------------------------------------------===//

def CJ : Jump_Imm, Requires<[HasStdExtC]>;

def CJAL : Call_Imm, Requires<[HasStdExtC]>;

def CJR : Jump_Reg<GPR>, Requires<[HasStdExtC]>;

def CJALR : Call_Reg<GPR>, Requires<[HasStdExtC]>;

def CBEQZ   : Bcz<0b110, "c.beqz",  seteq, GPRC>, Requires<[HasStdExtC]>;
def CBNEZ   : Bcz<0b111, "c.bnez",  setne, GPRC>, Requires<[HasStdExtC]>;

//===----------------------------------------------------------------------===//
// Integer Computational Instructions
//===----------------------------------------------------------------------===//

def CLI   : Move_Imm<GPR, simm6>, Requires<[HasStdExtC]>;

def CLUI   : Move_High<GPR, uimm6>, Requires<[HasStdExtC]>;

def CADDI   : Add_Imm<GPR, simm6>, Requires<[HasStdExtC]>;

def CADDI16SP : ADDI_16SP<SP>, Requires<[HasStdExtC]>;

def CADDI4SPN : ADDI_4SPN<GPRC, SP>, Requires<[HasStdExtC]>;

def CSLLI   : Shift_left<GPR, uimm5>, Requires<[HasStdExtC]>;

def CSRLI   : Shift_right<0b00, "c.srli",  srl, GPRC,   uimm5>,
              Requires<[HasStdExtC]>;
def CSRAI   : Shift_right<0b01, "c.srai",  sra, GPRC,   uimm5>,
              Requires<[HasStdExtC]>;

def CANDI  : And_Imm<GPRC, simm6>, Requires<[HasStdExtC]>;

def CMV    : Move_Reg<GPR>, Requires<[HasStdExtC]>;

def CADD   : Add_Reg<GPR>, Requires<[HasStdExtC]>;

def CAND   : CS_ALU<0b11, "c.and",  and, GPRC, 0>, Requires<[HasStdExtC]>;
def COR    : CS_ALU<0b10, "c.or" ,   or, GPRC, 0>, Requires<[HasStdExtC]>;
def CXOR   : CS_ALU<0b01, "c.xor",  xor, GPRC, 0>, Requires<[HasStdExtC]>;
def CSUB   : CS_ALU<0b00, "c.sub",  sub, GPRC, 0>, Requires<[HasStdExtC]>;

let rd = 0, imm = 0, hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def CNOP : CI<0b000, 0b01, (outs), (ins), "c.nop">, Requires<[HasStdExtC]>;

let rs1 = 0, rs2 = 0, hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def CEBREAK : CR<0b1001, 0b10, (outs), (ins), "c.ebreak">, Requires<[HasStdExtC]>;
