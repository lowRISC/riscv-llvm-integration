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
#include "RISCVMachineFunctionInfo.h"
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

RISCVRegisterInfo::RISCVRegisterInfo(unsigned HwMode)
    : RISCVGenRegisterInfo(RISCV::X1, /*DwarfFlavour*/0, /*EHFlavor*/0,
                           /*PC*/0, HwMode) {}

const MCPhysReg *
RISCVRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_SaveList;
}

BitVector RISCVRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  // Use markSuperRegs to ensure any register aliases are also reserved
  markSuperRegs(Reserved, RISCV::X0); // zero
  markSuperRegs(Reserved, RISCV::X1); // ra
  markSuperRegs(Reserved, RISCV::X2); // sp
  markSuperRegs(Reserved, RISCV::X3); // gp
  markSuperRegs(Reserved, RISCV::X4); // tp
  markSuperRegs(Reserved, RISCV::X8); // fp
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
  RISCVMachineFunctionInfo *RVFI = MF.getInfo<RISCVMachineFunctionInfo>();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &MRI = MF.getRegInfo();
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
    FrameReg = RISCV::X2;
    Offset += MF.getFrameInfo().getStackSize();
  } else {
    FrameReg = getFrameRegister(MF);
    Offset += RVFI->getVarArgsSaveSize();
  }

  unsigned Reg = MI.getOperand(0).getReg();
  assert(RISCV::GPRRegClass.contains(Reg) && "Unexpected register operand");

  assert(TFI->hasFP(MF) && "eliminateFrameIndex currently requires hasFP");

  if (!isInt<32>(Offset)) {
    report_fatal_error(
        "Frame offsets outside of the signed 32-bit range not supported");
  }

  MachineBasicBlock &MBB = *MI.getParent();
  unsigned FrameRegFlags = 0;

  if (!isInt<12>(Offset)) {
    // The offset won't fit in an immediate, so use a scratch register instead
    // Modify Offset and FrameReg appropriately
    unsigned ScratchReg = MRI.createVirtualRegister(&RISCV::GPRRegClass);
    uint64_t Hi20 = ((Offset + 0x800) >> 12) & 0xfffff;
    uint64_t Lo12 = SignExtend64<12>(Offset);
    BuildMI(MBB, II, DL, TII->get(RISCV::LUI), ScratchReg).addImm(Hi20);
    BuildMI(MBB, II, DL, TII->get(RISCV::ADDI), ScratchReg)
        .addReg(ScratchReg, RegState::Kill)
        .addImm(Lo12);
    BuildMI(MBB, II, DL, TII->get(RISCV::ADD), ScratchReg)
        .addReg(FrameReg)
        .addReg(ScratchReg, RegState::Kill);
    Offset = 0;
    FrameReg = ScratchReg;
    FrameRegFlags = RegState::Kill;
  }

  switch (MI.getOpcode()) {
  case RISCV::LW_FI:
    BuildMI(MBB, II, DL, TII->get(RISCV::LW), Reg)
        .addReg(FrameReg, FrameRegFlags)
        .addImm(Offset);
    break;
  case RISCV::SW_FI:
    BuildMI(MBB, II, DL, TII->get(RISCV::SW))
        .addReg(Reg, getKillRegState(MI.getOperand(0).isKill()))
        .addReg(FrameReg, FrameRegFlags | RegState::Kill)
        .addImm(Offset);
    break;
  case RISCV::LEA_FI:
    BuildMI(MBB, II, DL, TII->get(RISCV::ADDI), Reg)
        .addReg(FrameReg, FrameRegFlags)
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
  return RISCV::X8;
}

const uint32_t *
RISCVRegisterInfo::getCallPreservedMask(const MachineFunction & /*MF*/,
                                        CallingConv::ID /*CC*/) const {
  return CSR_RegMask;
}
