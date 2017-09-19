//===-- RISCVFrameLowering.cpp - RISCV Frame Information ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the RISCV implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "RISCVFrameLowering.h"
#include "RISCVMachineFunctionInfo.h"
#include "RISCVSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"

using namespace llvm;

bool RISCVFrameLowering::hasFP(const MachineFunction &MF) const { return true; }

// Determines the size of the frame and maximum call frame size.
void RISCVFrameLowering::determineFrameLayout(MachineFunction &MF) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const RISCVRegisterInfo *RI = STI.getRegisterInfo();

  // Get the number of bytes to allocate from the FrameInfo.
  unsigned FrameSize = MFI.getStackSize();

  // Get the alignment.
  unsigned StackAlign = RI->needsStackRealignment(MF) ? MFI.getMaxAlignment()
                                                      : getStackAlignment();

  // Get the maximum call frame size of all the calls.
  unsigned MaxCallFrameSize = MFI.getMaxCallFrameSize();

  // If we have dynamic alloca then MaxCallFrameSize needs to be aligned so
  // that allocations will be aligned.
  if (MFI.hasVarSizedObjects())
    MaxCallFrameSize = alignTo(MaxCallFrameSize, StackAlign);

  // Update maximum call frame size.
  MFI.setMaxCallFrameSize(MaxCallFrameSize);

  // Include call frame size in total.
  if (!(hasReservedCallFrame(MF) && MFI.adjustsStack()))
    FrameSize += MaxCallFrameSize;

  // Make sure the frame is aligned.
  FrameSize = alignTo(FrameSize, StackAlign);

  // Update frame info.
  MFI.setStackSize(FrameSize);
}

void RISCVFrameLowering::adjustReg(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MBBI,
                                   const DebugLoc &DL, unsigned DestReg,
                                   unsigned SrcReg, int64_t Val,
                                   MachineInstr::MIFlag Flag) const {
  MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
  const RISCVInstrInfo *TII = STI.getInstrInfo();

  if (DestReg == SrcReg && Val == 0)
    return;

  if (isInt<12>(Val)) {
    BuildMI(MBB, MBBI, DL, TII->get(RISCV::ADDI), DestReg)
        .addReg(SrcReg)
        .addImm(Val)
        .setMIFlag(Flag);
  } else if (isInt<32>(Val)) {
    unsigned Opc = RISCV::ADD;
    bool isSub = Val < 0;
    if (isSub) {
      Val = -Val;
      Opc = RISCV::SUB;
    }

    unsigned ScratchReg = MRI.createVirtualRegister(&RISCV::GPRRegClass);
    uint64_t Hi20 = ((Val + 0x800) >> 12) & 0xfffff;
    uint64_t Lo12 = SignExtend64<12>(Val);
    BuildMI(MBB, MBBI, DL, TII->get(RISCV::LUI), ScratchReg)
        .addImm(Hi20)
        .setMIFlag(Flag);
    BuildMI(MBB, MBBI, DL, TII->get(RISCV::ADDI), ScratchReg)
        .addReg(ScratchReg, RegState::Kill)
        .addImm(Lo12)
        .setMIFlag(Flag);
    BuildMI(MBB, MBBI, DL, TII->get(Opc), DestReg)
        .addReg(SrcReg)
        .addReg(ScratchReg, RegState::Kill)
        .setMIFlag(Flag);
  } else {
    report_fatal_error("adjustReg cannot yet handle adjustments >32 bits");
  }
}

void RISCVFrameLowering::emitPrologue(MachineFunction &MF,
                                      MachineBasicBlock &MBB) const {
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");

  if (!hasFP(MF)) {
    report_fatal_error(
        "emitPrologue doesn't support framepointer-less functions");
  }

  MachineFrameInfo &MFI = MF.getFrameInfo();
  RISCVMachineFunctionInfo *RVFI = MF.getInfo<RISCVMachineFunctionInfo>();
  MachineBasicBlock::iterator MBBI = MBB.begin();

  unsigned FPReg = RISCV::X8_32;
  unsigned SPReg = RISCV::X2_32;

  // Debug location must be unknown since the first debug location is used
  // to determine the end of the prologue.
  DebugLoc DL;

  // Determine the correct frame layout
  determineFrameLayout(MF);

  // FIXME (note copied from Lanai): This appears to be overallocating.  Needs
  // investigation. Get the number of bytes to allocate from the FrameInfo.
  uint64_t StackSize = MFI.getStackSize();

  // Early exit if there is no need to allocate on the stack
  if (StackSize == 0 && !MFI.adjustsStack())
    return;

  // Allocate space on the stack if necessary
  adjustReg(MBB, MBBI, DL, SPReg, SPReg, -StackSize, MachineInstr::FrameSetup);

  // The frame pointer is callee-saved, and code has been generated for us to
  // save it to the stack. We need to skip over the storing of callee-saved
  // registers as the frame pointer must be modified after it has been saved
  // to the stack, not before.
  MachineBasicBlock::iterator End = MBB.end();
  while (MBBI != End && MBBI->getFlag(MachineInstr::FrameSetup)) {
    ++MBBI;
  }

  // Generate new FP
  adjustReg(MBB, MBBI, DL, FPReg, SPReg, StackSize - RVFI->getVarArgsSaveSize(),
            MachineInstr::FrameSetup);
}

void RISCVFrameLowering::emitEpilogue(MachineFunction &MF,
                                      MachineBasicBlock &MBB) const {
  if (!hasFP(MF)) {
    report_fatal_error(
        "emitEpilogue doesn't support framepointer-less functions");
  }

  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  const RISCVRegisterInfo *RI = STI.getRegisterInfo();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  RISCVMachineFunctionInfo *RVFI = MF.getInfo<RISCVMachineFunctionInfo>();
  DebugLoc DL = MBBI->getDebugLoc();
  unsigned FPReg = RISCV::X8_32;
  unsigned SPReg = RISCV::X2_32;

  // Skip to before the restores of callee-saved registers
  MachineBasicBlock::iterator Begin = MBB.begin();
  MachineBasicBlock::iterator LastFrameDestroy = MBBI;
  while (LastFrameDestroy != Begin) {
    if (!std::prev(LastFrameDestroy)->getFlag(MachineInstr::FrameDestroy))
      break;
    --LastFrameDestroy;
  }

  uint64_t StackSize = MFI.getStackSize();

  // Restore the stack pointer using the value of the frame pointer. Only
  // necessary if the stack pointer was modified, meaning the stack size is
  // unknown.
  if (RI->needsStackRealignment(MF) || MFI.hasVarSizedObjects()) {
    adjustReg(MBB, LastFrameDestroy, DL, SPReg, FPReg,
              -StackSize + RVFI->getVarArgsSaveSize(),
              MachineInstr::FrameDestroy);
  }

  // Deallocate stack
  adjustReg(MBB, MBBI, DL, SPReg, SPReg, StackSize, MachineInstr::FrameDestroy);
}

void RISCVFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                              BitVector &SavedRegs,
                                              RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  SavedRegs.set(RISCV::X8_32);
  return;
}

void RISCVFrameLowering::processFunctionBeforeFrameFinalized(
    MachineFunction &MF, RegScavenger *RS) const {
  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetRegisterClass *RC = &RISCV::GPRRegClass;
  // estimateStackSize has been observed to under-estimate the final stack
  // size, so give ourselves wiggle-room by checking for stack size
  // representable an 11-bit signed field rather than 12-bits.
  // FIXME: It may be possible to craft a function with a small stack that
  // still needs an emergency spill slot for branch relaxation. This case
  // would currently be missed.
  if (!isInt<11>(MFI.estimateStackSize(MF))) {
    int RegScavFI = MFI.CreateStackObject(
        RegInfo->getSpillSize(*RC), RegInfo->getSpillAlignment(*RC), false);
    RS->addScavengingFrameIndex(RegScavFI);
  }
}
