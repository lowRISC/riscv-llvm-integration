//===-- RISCVRegisterInfo.cpp - RISCV Register Information ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the RISCV implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "RISCVRegisterInfo.h"
#include "RISCV.h"
#include "RISCVSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetInstrInfo.h"

#define GET_REGINFO_TARGET_DESC
#include "RISCVGenRegisterInfo.inc"

using namespace llvm;

RISCVRegisterInfo::RISCVRegisterInfo() : RISCVGenRegisterInfo(RISCV::X1_32) {}

const MCPhysReg *
RISCVRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_SaveList;
}

BitVector RISCVRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  // Use markSuperRegs to ensure any register aliases are also reserved
  markSuperRegs(Reserved, RISCV::X0_64); // zero
  markSuperRegs(Reserved, RISCV::X0_32); // zero
  markSuperRegs(Reserved, RISCV::X1_64); // ra
  markSuperRegs(Reserved, RISCV::X1_32); // ra
  markSuperRegs(Reserved, RISCV::X2_64); // sp
  markSuperRegs(Reserved, RISCV::X2_32); // sp
  markSuperRegs(Reserved, RISCV::X3_64); // gp
  markSuperRegs(Reserved, RISCV::X3_32); // gp
  markSuperRegs(Reserved, RISCV::X4_64); // tp
  markSuperRegs(Reserved, RISCV::X4_32); // tp
  markSuperRegs(Reserved, RISCV::X8_64); // fp
  markSuperRegs(Reserved, RISCV::X8_32); // fp
  assert(checkAllSuperRegsMarked(Reserved));
  return Reserved;
}

const uint32_t *RISCVRegisterInfo::getNoPreservedMask() const {
  return CSR_NoRegs_RegMask;
}

void RISCVRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                            int SPAdj, unsigned FIOperandNum,
                                            RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected non-zero SPAdj value");

  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
  const TargetInstrInfo *TII = MF.getSubtarget().getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();

  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();
  unsigned FrameReg;
  int Offset = MF.getFrameInfo().getObjectOffset(FrameIndex) +
               MI.getOperand(FIOperandNum + 1).getImm();

  // Callee-saved registers should be referenced relative to the stack
  // pointer (positive offset), otherwise use the frame pointer (negative
  // offset)
  const std::vector<CalleeSavedInfo> &CSI = MFI.getCalleeSavedInfo();
  int MinCSFI = 0;
  int MaxCSFI = -1;

  if (CSI.size()) {
    MinCSFI = CSI[0].getFrameIdx();
    MaxCSFI = CSI[CSI.size() - 1].getFrameIdx();
  }

  if ((FrameIndex >= MinCSFI && FrameIndex <= MaxCSFI)) {
    FrameReg = RISCV::X2_32;
    Offset += MF.getFrameInfo().getStackSize();
  } else {
    FrameReg = getFrameRegister(MF);
  }

  unsigned Reg = MI.getOperand(0).getReg();
  assert(RISCV::GPRRegClass.contains(Reg) && "Unexpected register operand");

  assert(TFI->hasFP(MF) && "eliminateFrameIndex currently requires hasFP");

  // Offsets must be directly encoded in a 12-bit immediate field
  if (!isInt<12>(Offset)) {
    report_fatal_error(
        "Frame offsets outside of the signed 12-bit range not supported");
  }

  MachineBasicBlock &MBB = *MI.getParent();
  switch (MI.getOpcode()) {
  case RISCV::LW_FI:
    BuildMI(MBB, II, DL, TII->get(RISCV::LW), Reg)
        .addReg(FrameReg)
        .addImm(Offset);
    break;
  case RISCV::SW_FI:
    BuildMI(MBB, II, DL, TII->get(RISCV::SW))
        .addReg(Reg, getKillRegState(MI.getOperand(0).isKill()))
        .addReg(FrameReg)
        .addImm(Offset);
    break;
  case RISCV::LEA_FI:
    BuildMI(MBB, II, DL, TII->get(RISCV::ADDI), Reg)
        .addReg(FrameReg)
        .addImm(Offset);
    break;
  default:
    llvm_unreachable("Unexpected opcode");
  }

  // Erase old instruction.
  MBB.erase(II);
  return;
}

unsigned RISCVRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return RISCV::X8_32;
}

const uint32_t *
RISCVRegisterInfo::getCallPreservedMask(const MachineFunction & /*MF*/,
                                        CallingConv::ID /*CC*/) const {
  return CSR_RegMask;
}
