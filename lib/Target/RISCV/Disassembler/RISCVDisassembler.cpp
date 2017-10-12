//===-- RISCVDisassembler.cpp - Disassembler for RISCV --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the RISCVDisassembler class.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/RISCVMCTargetDesc.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCFixedLenDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "riscv-disassembler"

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {
class RISCVDisassembler : public MCDisassembler {

public:
  RISCVDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
      : MCDisassembler(STI, Ctx) {}

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &VStream,
                              raw_ostream &CStream) const override;
};
} // end anonymous namespace

static MCDisassembler *createRISCVDisassembler(const Target &T,
                                               const MCSubtargetInfo &STI,
                                               MCContext &Ctx) {
  return new RISCVDisassembler(STI, Ctx);
}

extern "C" void LLVMInitializeRISCVDisassembler() {
  // Register the disassembler for each target.
  TargetRegistry::RegisterMCDisassembler(getTheRISCV32Target(),
                                         createRISCVDisassembler);
  TargetRegistry::RegisterMCDisassembler(getTheRISCV64Target(),
                                         createRISCVDisassembler);
}

static const unsigned GPRDecoderTable[] = {
  RISCV::X0,  RISCV::X1,  RISCV::X2,  RISCV::X3,
  RISCV::X4,  RISCV::X5,  RISCV::X6,  RISCV::X7,
  RISCV::X8,  RISCV::X9,  RISCV::X10, RISCV::X11,
  RISCV::X12, RISCV::X13, RISCV::X14, RISCV::X15,
  RISCV::X16, RISCV::X17, RISCV::X18, RISCV::X19,
  RISCV::X20, RISCV::X21, RISCV::X22, RISCV::X23,
  RISCV::X24, RISCV::X25, RISCV::X26, RISCV::X27,
  RISCV::X28, RISCV::X29, RISCV::X30, RISCV::X31
};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, uint64_t RegNo,
                                           uint64_t Address,
                                           const void *Decoder) {
   if (RegNo > sizeof(GPRDecoderTable)) {
     return MCDisassembler::Fail;
   }

   // We must define our own mapping from RegNo to register identifier.
   // Accessing index RegNo in the register class will work in the case that
   // registers were added in ascending order, but not in general.
   unsigned Reg = GPRDecoderTable[RegNo];
   Inst.addOperand(MCOperand::createReg(Reg));
   return MCDisassembler::Success;
}

static DecodeStatus DecodeGPRCRegisterClass(MCInst &Inst, uint64_t RegNo,
                                            uint64_t Address,
                                            const void *Decoder) {
   if (RegNo > sizeof(GPRDecoderTable)) {
     return MCDisassembler::Fail;
   }
   unsigned Reg = GPRDecoderTable[RegNo + 8];
   Inst.addOperand(MCOperand::createReg(Reg));
   return MCDisassembler::Success;
}

static const unsigned FPR32DecoderTable[] = {
  RISCV::F0_32,  RISCV::F1_32,  RISCV::F2_32,  RISCV::F3_32,
  RISCV::F4_32,  RISCV::F5_32,  RISCV::F6_32,  RISCV::F7_32,
  RISCV::F8_32,  RISCV::F9_32,  RISCV::F10_32, RISCV::F11_32,
  RISCV::F12_32, RISCV::F13_32, RISCV::F14_32, RISCV::F15_32,
  RISCV::F16_32, RISCV::F17_32, RISCV::F18_32, RISCV::F19_32,
  RISCV::F20_32, RISCV::F21_32, RISCV::F22_32, RISCV::F23_32,
  RISCV::F24_32, RISCV::F25_32, RISCV::F26_32, RISCV::F27_32,
  RISCV::F28_32, RISCV::F29_32, RISCV::F30_32, RISCV::F31_32
};

static DecodeStatus DecodeFPR32RegisterClass(MCInst &Inst, uint64_t RegNo,
                                             uint64_t Address,
                                             const void *Decoder) {
  if (RegNo > sizeof(FPR32DecoderTable)) {
    return MCDisassembler::Fail;
  }

  // We must define our own mapping from RegNo to register identifier.
  // Accessing index RegNo in the register class will work in the case that
  // registers were added in ascending order, but not in general.
  unsigned Reg = FPR32DecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static const unsigned FPR64DecoderTable[] = {
  RISCV::F0_64,  RISCV::F1_64,  RISCV::F2_64,  RISCV::F3_64,
  RISCV::F4_64,  RISCV::F5_64,  RISCV::F6_64,  RISCV::F7_64,
  RISCV::F8_64,  RISCV::F9_64,  RISCV::F10_64, RISCV::F11_64,
  RISCV::F12_64, RISCV::F13_64, RISCV::F14_64, RISCV::F15_64,
  RISCV::F16_64, RISCV::F17_64, RISCV::F18_64, RISCV::F19_64,
  RISCV::F20_64, RISCV::F21_64, RISCV::F22_64, RISCV::F23_64,
  RISCV::F24_64, RISCV::F25_64, RISCV::F26_64, RISCV::F27_64,
  RISCV::F28_64, RISCV::F29_64, RISCV::F30_64, RISCV::F31_64
};

static DecodeStatus DecodeFPR64RegisterClass(MCInst &Inst, uint64_t RegNo,
                                             uint64_t Address,
                                             const void *Decoder) {
  if (RegNo > sizeof(FPR64DecoderTable)) {
    return MCDisassembler::Fail;
  }

  // We must define our own mapping from RegNo to register identifier.
  // Accessing index RegNo in the register class will work in the case that
  // registers were added in ascending order, but not in general.
  unsigned Reg = FPR64DecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

// Add Imply SP operand for SP imply instructions(The instruction SP not encode
// in bit field)
static void addImplySP(MCInst &Inst, int64_t Address, const void *Decoder) {
  if (Inst.getOpcode() == RISCV::CLWSP ||
      Inst.getOpcode() == RISCV::CSWSP) {
    DecodeGPRRegisterClass(Inst, 2, Address, Decoder);
  }
}

template <unsigned N>
static DecodeStatus decodeUImmOperand(MCInst &Inst, uint64_t Imm,
                                      int64_t Address, const void *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");

  addImplySP(Inst, Address, Decoder);
  Inst.addOperand(MCOperand::createImm(Imm));
  return MCDisassembler::Success;
}

template <unsigned N>
static DecodeStatus decodeSImmOperand(MCInst &Inst, uint64_t Imm,
                                      int64_t Address, const void *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  // Sign-extend the number in the bottom N bits of Imm
  Inst.addOperand(MCOperand::createImm(SignExtend64<N>(Imm)));
  return MCDisassembler::Success;
}

template <unsigned N>
static DecodeStatus decodeSImmOperandAndLsl1(MCInst &Inst, uint64_t Imm,
                                             int64_t Address,
                                             const void *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  // Sign-extend the number in the bottom N bits of Imm after accounting for
  // the fact that the N bit immediate is stored in N-1 bits (the LSB is
  // always zero)
  Inst.addOperand(MCOperand::createImm(SignExtend64<N>(Imm << 1)));
  return MCDisassembler::Success;
}

#include "RISCVGenDisassemblerTables.inc"

/// Read two bytes from the ArrayRef and return 16 bit halfword
static DecodeStatus readInstruction16(ArrayRef<uint8_t> Bytes, uint64_t Address,
                                      uint64_t &Size, uint32_t &Insn) {
  // We want to read exactly 2 Bytes of data.
  if (Bytes.size() < 2) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  Insn = (Bytes[1] << 8) | Bytes[0];

  return MCDisassembler::Success;
}

/// Read four bytes from the ArrayRef and return 32 bit word
static DecodeStatus readInstruction32(ArrayRef<uint8_t> Bytes, uint64_t Address,
                                      uint64_t &Size, uint32_t &Insn) {
  // We want to read exactly 4 Bytes of data.
  if (Bytes.size() < 4) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  Insn = (Bytes[0] << 0) | (Bytes[1] << 8) | (Bytes[2] << 16) |
         (Bytes[3] << 24);

  return MCDisassembler::Success;
}

DecodeStatus RISCVDisassembler::getInstruction(MCInst &MI, uint64_t &Size,
                                               ArrayRef<uint8_t> Bytes,
                                               uint64_t Address,
                                               raw_ostream &OS,
                                               raw_ostream &CS) const {
  // TODO: This will need modification when supporting the instruction
  // set extensions have the option of defining instructions up to
  // 176 bits wide.
  uint32_t Insn;
  DecodeStatus Result;

  // It's a 32 bit instruction if bit 0 and 1 is 1.
  if ((Bytes[0] & 0x3) == 0x3) {
    Result = readInstruction32(Bytes, Address, Size, Insn);
    if (Result == MCDisassembler::Fail)
      return MCDisassembler::Fail;

    DEBUG(dbgs() << "Trying RISCV32 table :\n");
    Result = decodeInstruction(DecoderTable32, MI, Insn, Address, this, STI);
    Size = 4;
  } else {
    Result = readInstruction16(Bytes, Address, Size, Insn);
    if (Result == MCDisassembler::Fail)
      return MCDisassembler::Fail;

    DEBUG(dbgs() << "Trying RISCV_C table (16-bit Instruction):\n");
    // Calling the auto-generated decoder function.
    Result =
      decodeInstruction(DecoderTable16, MI, Insn, Address, this, STI);
    Size = 2;
  }

  if (Result != MCDisassembler::Fail) {
    return Result;
  }

  return MCDisassembler::Fail;
}
