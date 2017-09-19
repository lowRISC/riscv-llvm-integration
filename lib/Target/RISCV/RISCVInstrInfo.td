//===-- RISCVInstrInfo.td - Target Description for RISCV ---*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the RISC-V instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "RISCVInstrFormats.td"

def RetFlag : SDNode<"RISCVISD::RET_FLAG", SDTNone,
                     [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Operands
class ImmAsmOperand<string prefix, int width, string suffix> : AsmOperandClass {
  let Name = prefix # "Imm" # width # suffix;
  let RenderMethod = "addImmOperands";
  let DiagnosticType = !strconcat("Invalid", Name);
}

class SImmAsmOperand<int width, string suffix = "">
  : ImmAsmOperand<"S", width, suffix> {
}

class UImmAsmOperand<int width, string suffix = "">
  : ImmAsmOperand<"U", width, suffix> {
}

def FenceArg : AsmOperandClass {
  let Name = "FenceArg";
  let RenderMethod = "addFenceArgOperands";
  let DiagnosticType = "InvalidFenceArg";
}

def fencearg : Operand<i32> {
  let ParserMatchClass = FenceArg;
  let PrintMethod = "printFenceArg";
  let DecoderMethod = "decodeUImmOperand<4>";
}

def uimm5 : Operand<i32>, ImmLeaf<i32, [{return isUInt<5>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<5>;
  let DecoderMethod = "decodeUImmOperand<5>";
}

def simm12 : Operand<i32>, ImmLeaf<i32, [{return isInt<12>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<12>;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmOperand<12>";
}

def uimm12 : Operand<i32> {
  let ParserMatchClass = UImmAsmOperand<12>;
  let DecoderMethod = "decodeUImmOperand<12>";
}

// A 13-bit signed immediate where the least significant bit is zero.
def simm13_lsb0 : Operand<OtherVT> {
  let ParserMatchClass = SImmAsmOperand<13, "Lsb0">;
  let EncoderMethod = "getImmOpValueAsr1";
  let DecoderMethod = "decodeSImmOperandAndLsl1<13>";
}

def uimm20 : Operand<i32> {
  let ParserMatchClass = UImmAsmOperand<20>;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeUImmOperand<20>";
}

// A 21-bit signed immediate where the least significant bit is zero.
def simm21_lsb0 : Operand<OtherVT> {
  let ParserMatchClass = SImmAsmOperand<21, "Lsb0">;
  let EncoderMethod = "getImmOpValueAsr1";
  let DecoderMethod = "decodeSImmOperandAndLsl1<21>";
}

// Extract least significant 12 bits from an immediate value and sign extend
// them.
def LO12Sext : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(SignExtend64<12>(N->getZExtValue()),
                                   SDLoc(N), MVT::i32);
}]>;

// Extract the most significant 20 bits from an immediate value. Add 1 if bit
// 11 is 1, to compensate for the low 12 bits in the matching immediate addi
// or ld/st being negative.
def HI20 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(((N->getZExtValue()+0x800) >> 12) & 0xfffff,
                                   SDLoc(N), MVT::i32);
}]>;


// As noted in RISCVRegisterInfo.td, the hope is that support for
// variable-sized register classes will mean that instruction definitions do
// not need to be duplicated for 32-bit and 64-bit register classes. For now
// we use 'GPR', which is 32-bit. When codegen for both RV32 and RV64 is
// added, we will need to duplicate instruction definitions unless a proposal
// like <http://lists.llvm.org/pipermail/llvm-dev/2016-September/105027.html>
// is adopted.

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
def LUI : FU<0b0110111, (outs GPR:$rd), (ins uimm20:$imm20),
             "lui\t$rd, $imm20", []>;

def AUIPC : FU<0b0010111, (outs GPR:$rd), (ins uimm20:$imm20),
             "auipc\t$rd, $imm20", []>;

def JAL : FUJ<0b1101111, (outs GPR:$rd), (ins simm21_lsb0:$imm20),
              "jal\t$rd, $imm20", []>;

def JALR : FI<0b000, 0b1100111, (outs GPR:$rd), (ins GPR:$rs1, simm12:$imm12),
              "jalr\t$rd, $rs1, $imm12", []>;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Bcc<bits<3> funct3, string OpcodeStr> :
      FSB<funct3, 0b1100011, (outs), (ins GPR:$rs1, GPR:$rs2, simm13_lsb0:$imm12),
         OpcodeStr#"\t$rs1, $rs2, $imm12", []> {
  let isBranch = 1;
  let isTerminator = 1;
}

def BEQ   : Bcc<0b000, "beq">;
def BNE   : Bcc<0b001, "bne">;
def BLT   : Bcc<0b100, "blt">;
def BGE   : Bcc<0b101, "bge">;
def BLTU  : Bcc<0b110, "bltu">;
def BGEU  : Bcc<0b111, "bgeu">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class LD_ri<bits<3> funct3, string OpcodeStr> :
      FI<funct3, 0b0000011, (outs GPR:$rd), (ins GPR:$rs1, simm12:$imm12),
         OpcodeStr#"\t$rd, ${imm12}(${rs1})", []>;

def LB   : LD_ri<0b000, "lb">;
def LH   : LD_ri<0b001, "lh">;
def LW   : LD_ri<0b010, "lw">;
def LBU  : LD_ri<0b100, "lbu">;
def LHU  : LD_ri<0b101, "lhu">;

// Operands for stores are in the order srcreg, base, offset rather than
// reflecting the order these fields are specified in the instruction
// encoding.

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class ST_ri<bits<3> funct3, string OpcodeStr> :
      FS<funct3, 0b0100011, (outs), (ins GPR:$rs2, GPR:$rs1, simm12:$imm12),
         OpcodeStr#"\t$rs2, ${imm12}(${rs1})", []>;

def SB  : ST_ri<0b000, "sb">;
def SH  : ST_ri<0b001, "sh">;
def SW  : ST_ri<0b010, "sw">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class ALU_ri<bits<3> funct3, string OpcodeStr> :
      FI<funct3, 0b0010011, (outs GPR:$rd), (ins GPR:$rs1, simm12:$imm12),
         OpcodeStr#"\t$rd, $rs1, $imm12", []>;

def ADDI  : ALU_ri<0b000, "addi">;
def SLTI  : ALU_ri<0b010, "slti">;
def SLTIU : ALU_ri<0b011, "sltiu">;
def XORI  : ALU_ri<0b100, "xori">;
def ORI   : ALU_ri<0b110, "ori">;
def ANDI  : ALU_ri<0b111, "andi">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class SHIFT32_ri<bit arithshift, bits<3> funct3, string OpcodeStr> :
      FI32Shift<arithshift, funct3, 0b0010011, (outs GPR:$rd), (ins GPR:$rs1, uimm5:$shamt),
         OpcodeStr#"\t$rd, $rs1, $shamt", []>;

def SLLI : SHIFT32_ri<0, 0b001, "slli">;
def SRLI : SHIFT32_ri<0, 0b101, "srli">;
def SRAI : SHIFT32_ri<1, 0b101, "srai">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class ALU_rr<bits<7> funct7, bits<3> funct3, string OpcodeStr> :
      FR<funct7, funct3, 0b0110011, (outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
         OpcodeStr#"\t$rd, $rs1, $rs2", []>;

def ADD  : ALU_rr<0b0000000, 0b000, "add">;
def SUB  : ALU_rr<0b0100000, 0b000, "sub">;
def SLL  : ALU_rr<0b0000000, 0b001, "sll">;
def SLT  : ALU_rr<0b0000000, 0b010, "slt">;
def SLTU : ALU_rr<0b0000000, 0b011, "sltu">;
def XOR  : ALU_rr<0b0000000, 0b100, "xor">;
def SRL  : ALU_rr<0b0000000, 0b101, "srl">;
def SRA  : ALU_rr<0b0100000, 0b101, "sra">;
def OR   : ALU_rr<0b0000000, 0b110, "or">;
def AND  : ALU_rr<0b0000000, 0b111, "and">;

let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in {
def FENCE : FI<0b000, 0b0001111, (outs), (ins fencearg:$pred, fencearg:$succ),
               "fence\t$pred, $succ", []> {
  bits<4> pred;
  bits<4> succ;

  let rs1 = 0;
  let rd = 0;
  let imm12 = {0b0000,pred,succ};
}

def FENCEI : FI<0b001, 0b0001111, (outs), (ins), "fence.i", []> {
  let rs1 = 0;
  let rd = 0;
  let imm12 = 0;
}

let rs1 = 0, rd = 0 in {
  def ECALL  : FI<0b000, 0b1110011, (outs), (ins), "ecall", []> {
    let imm12 = 0;
  }
  def EBREAK : FI<0b000, 0b1110011, (outs), (ins), "ebreak", []> {
    let imm12 = 1;
  }
}
}

let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in
class CSR_rr<bits<3> funct3, string OpcodeStr> :
      FI<funct3, 0b1110011, (outs GPR:$rd), (ins uimm12:$imm12, GPR:$rs1),
         OpcodeStr#"\t$rd, $imm12, $rs1", []>;

def CSRRW : CSR_rr<0b001, "csrrw">;
def CSRRS : CSR_rr<0b010, "csrrs">;
def CSRRC : CSR_rr<0b011, "csrrc">;

let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in
class CSR_ri<bits<3> funct3, string OpcodeStr> :
      FI<funct3, 0b1110011, (outs GPR:$rd), (ins uimm12:$imm12, uimm5:$rs1),
         OpcodeStr#"\t$rd, $imm12, $rs1", []>;

def CSRRWI : CSR_ri<0b101, "csrrwi">;
def CSRRSI : CSR_ri<0b110, "csrrsi">;
def CSRRCI : CSR_ri<0b111, "csrrci">;

//===----------------------------------------------------------------------===//
// Pseudo-instructions and codegen patterns
//
// Naming convention: For 'generic' pattern classes, we use the naming
// convention PatTy1Ty2. For pattern classes which offer a more complex
// expension, prefix the class name, e.g. BccPat.

/// Generic pattern classes

class PatGprGpr<SDPatternOperator OpNode, FR Inst> :
      Pat<(OpNode GPR:$rs1, GPR:$rs2), (Inst GPR:$rs1, GPR:$rs2)>;
class PatGprSimm12<SDPatternOperator OpNode, FI Inst> :
      Pat<(OpNode GPR:$rs1, simm12:$imm12), (Inst GPR:$rs1, simm12:$imm12)>;
class PatGprUimm5<SDPatternOperator OpNode, FI32Shift Inst> :
      Pat<(OpNode GPR:$rs1, uimm5:$shamt), (Inst GPR:$rs1, uimm5:$shamt)>;

/// Immediates

def : Pat<(simm12:$imm), (ADDI X0_32, simm12:$imm)>;
def : Pat<(i32 imm:$imm), (ADDI (LUI (HI20 imm:$imm)), (LO12Sext imm:$imm))>;

/// Simple arithmetic operations

def : PatGprGpr<add, ADD>;
def : PatGprSimm12<add, ADDI>;
def : PatGprGpr<sub, SUB>;
def : PatGprGpr<or, OR>;
def : PatGprSimm12<or, ORI>;
def : PatGprGpr<and, AND>;
def : PatGprSimm12<and, ANDI>;
def : PatGprGpr<xor, XOR>;
def : PatGprSimm12<xor, XORI>;
def : PatGprGpr<shl, SLL>;
def : PatGprUimm5<shl, SLLI>;
def : PatGprGpr<srl, SRL>;
def : PatGprUimm5<srl, SRLI>;
def : PatGprGpr<sra, SRA>;
def : PatGprUimm5<sra, SRAI>;

/// Setcc

def : PatGprGpr<setlt, SLT>;
def : PatGprSimm12<setlt, SLTI>;
def : PatGprGpr<setult, SLTU>;
def : PatGprSimm12<setult, SLTIU>;

/// Branches and jumps

// Match `(brcond (CondOp ..), ..)` and lower to the appropriate RISC-V branch
// instruction.
class BccPat<PatFrag CondOp, FSB Inst> :
      Pat<(brcond (i32 (CondOp GPR:$rs1, GPR:$rs2)), bb:$imm12),
          (Inst GPR:$rs1, GPR:$rs2, simm13_lsb0:$imm12)>;

def : BccPat<seteq, BEQ>;
def : BccPat<setne, BNE>;
def : BccPat<setlt, BLT>;
def : BccPat<setge, BGE>;
def : BccPat<setult, BLTU>;
def : BccPat<setuge, BGEU>;

class BccSwapPat<PatFrag CondOp, RISCVInst InstBcc> : Pat<
  (brcond (i32 (CondOp GPR:$rs1, GPR:$rs2)), bb:$imm12),
  (InstBcc GPR:$rs2, GPR:$rs1, bb:$imm12)>;

// Condition codes that don't have matching RISC-V branch instructions, but
// are trivially supported by swapping the two input operands
def : BccSwapPat<setgt, BLT>;
def : BccSwapPat<setle, BGE>;
def : BccSwapPat<setugt, BLTU>;
def : BccSwapPat<setule, BGEU>;

// An extra pattern is needed for a brcond without a setcc (i.e. where the
// condition was calculated elsewhere).
def : Pat<(brcond GPR:$cond, bb:$imm12), (BNE GPR:$cond, X0_32, bb:$imm12)>;

let isBarrier = 1, isBranch = 1, isTerminator = 1 in
def PseudoBR : Pseudo<(outs), (ins simm21_lsb0:$imm20), [(br bb:$imm20)]>,
               PseudoInstExpansion<(JAL X0_32, simm21_lsb0:$imm20)>;

let isBarrier = 1, isReturn = 1, isTerminator = 1 in
def PseudoRET : Pseudo<(outs), (ins), [(RetFlag)]>,
                PseudoInstExpansion<(JALR X0_32, X1_32, 0)>;

/// Loads

multiclass LdPat<PatFrag LoadOp, RISCVInst Inst> {
  def : Pat<(LoadOp GPR:$rs1), (Inst GPR:$rs1, 0)>;
  def : Pat<(LoadOp (add GPR:$rs1, simm12:$imm12)),
            (Inst GPR:$rs1, simm12:$imm12)>;
}

defm : LdPat<sextloadi8, LB>;
defm : LdPat<extloadi8, LB>;
defm : LdPat<sextloadi16, LH>;
defm : LdPat<extloadi16, LH>;
defm : LdPat<load, LW>;
defm : LdPat<zextloadi8, LBU>;
defm : LdPat<zextloadi16, LHU>;

/// Stores

multiclass StPat<PatFrag StoreOp, RISCVInst Inst> {
  def : Pat<(StoreOp GPR:$rs2, GPR:$rs1), (Inst GPR:$rs2, GPR:$rs1, 0)>;
  def : Pat<(StoreOp GPR:$rs2, (add GPR:$rs1, simm12:$imm12)),
            (Inst GPR:$rs2, GPR:$rs1, simm12:$imm12)>;
}

defm : StPat<truncstorei8, SB>;
defm : StPat<truncstorei16, SH>;
defm : StPat<store, SW>;
