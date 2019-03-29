# RUN: not llvm-mc -triple=riscv32 < %s 2>&1 | FileCheck %s
# RUN: not llvm-mc -triple=riscv64 < %s 2>&1 | FileCheck %s

.insn 1 # CHECK: :[[@LINE]]:7: error: .insn should be followed by an instruction format
.insn foo # CHECK: :[[@LINE]]:7: error: invalid operand for instruction
