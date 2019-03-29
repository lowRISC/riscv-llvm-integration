# RUN: llvm-mc %s -triple=riscv32 -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM,CHECK-ASM-AND-OBJ %s
# RUN: llvm-mc %s -triple riscv64 -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM,CHECK-ASM-AND-OBJ %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 < %s \
# RUN:     | llvm-objdump -riscv-no-aliases -d -r - \
# RUN:     | FileCheck -check-prefixes=CHECK-OBJ,CHECK-ASM-AND-OBJ %s
# RUN: llvm-mc -filetype=obj -triple=riscv64 < %s \
# RUN:     | llvm-objdump -riscv-no-aliases -d -r - \
# RUN:     | FileCheck -check-prefixes=CHECK-OBJ,CHECK-ASM-AND-OBJ %s

# CHECK-ASM: .insn r 51, 0, 0, a0, a1, a2
# CHECK-ASM: encoding: [0x33,0x85,0xc5,0x00]
# CHECK-OBJ: add a0, a1, a2
.insn r 0x33, 0, 0, a0, a1, a2
# CHECK-ASM: .insn r 0, 0, 0, zero, ra, sp
# CHECK-ASM: encoding: [0x00,0x80,0x20,0x00]
# CHECK-OBJ: <unknown>
# CHECK-OBJ: <unknown>
.insn r 0, 0, 0, x0, x1, x2
# CHECK-ASM: .insn r 127, 0, 0, zero, ra, sp
# CHECK-ASM: encoding: [0x7f,0x80,0x20,0x00]
# CHECK-OBJ: <unknown>
.insn r 127, 0, 0, x0, x1, x2

# TODO: test range of funct3, funct7

# TODO: r format with four registers

# CHECK-ASM: .insn i 19, 0, a0, a1, 111
# CHECK-ASM: encoding: [0x13,0x85,0xf5,0x06]
# CHECK-OBJ: addi	a0, a1, 111
.insn i 0x13, 0, a0, a1, 111

# CHECK-ASM: .insn s 35, 0, a0, a1, 222
# CHECK-ASM: encoding: [0x23,0x0f,0xb5,0x0c]
# CHECK-OBJ: sb	a1, 222(a0)
.insn s 0x23, 0, a0, a1, 222

# CHECK-ASM: .insn b 99, 0, a0, a2, 334
# CHECK-ASM: encoding: [0x63,0x07,0xc5,0x14]
# CHECK-OBJ: beq a0, a2, 334
.insn b 0x63, 0, a0, a2, 334

# CHECK-ASM: .insn u 55, a0, 1048575
# CHECK-ASM: encoding: [0x37,0xf5,0xff,0xff]
# CHECK-OBJ: lui a0, 1048575
.insn u 0x37, a0, 1048575

# CHECK-ASM: .insn j 111, a0, 1048574
# CHECK-ASM: encoding: [0x6f,0xf5,0xff,0x7f]
# CHECK-OBJ: jal a0, 1048574
.insn j 0x6f, a0, 1048574
