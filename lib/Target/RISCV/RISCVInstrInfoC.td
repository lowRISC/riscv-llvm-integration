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
