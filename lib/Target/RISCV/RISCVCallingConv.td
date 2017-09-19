//===-- RISCVCallingConv.td - Calling Conventions RISCV ----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This describes the calling conventions for the RISCV architecture.
//
//===----------------------------------------------------------------------===//

// RISCV 32-bit C return-value convention.
def RetCC_RISCV32 : CallingConv<[CCIfType<[i32], CCAssignToReg<[X10_32, X11_32]>>]>;

// RISCV 32-bit C Calling convention.
def CC_RISCV32 : CallingConv<[
  // Promote i8/i16 args to i32
  CCIfType<[ i8, i16 ], CCPromoteToType<i32>>,

  // All arguments get passed in integer registers if there is space.
  CCIfType<[i32], CCAssignToReg<[ X10_32, X11_32, X12_32, X13_32, X14_32,
                                  X15_32, X16_32, X17_32 ]>>,

  // Could be assigned to the stack in 8-byte aligned units, but unsupported
  CCAssignToStack<8, 8>
]>;

def CSR : CalleeSavedRegs<(add X1_32, X3_32, X4_32, X8_32, X9_32,
                          (sequence "X%u_32", 18, 27))>;

// Needed for implementation of RISCVRegisterInfo::getNoPreservedMask()
def CSR_NoRegs : CalleeSavedRegs<(add)>;
