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

void RISCVRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                            int SPAdj, unsigned FIOperandNum,
                                            RegScavenger *RS) const {
  report_fatal_error("Subroutines not supported yet");
}

unsigned RISCVRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return RISCV::X8_32;
}
