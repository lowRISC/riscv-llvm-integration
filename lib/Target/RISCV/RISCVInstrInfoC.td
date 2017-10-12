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
