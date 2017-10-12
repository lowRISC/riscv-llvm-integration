# RUN: llvm-mc %s -mattr=+c -show-encoding \
# RUN:     | FileCheck -check-prefix=CHECK-FIXUP %s
# RUN: llvm-mc -filetype=obj -mattr=+c < %s \
# RUN:     | llvm-objdump -d - | FileCheck -check-prefix=CHECK-INSTR %s

.LBB0_2:
# CHECK-FIXUP: encoding: [0bAAAAAA01,0b101AAAAA]
# CHECK-FIXUP:   fixup A - offset: 0, value: .LBB0_2, kind: fixup_riscv_rvc_jump
# CHECK-INSTR: c.j     0
c.j     .LBB0_2
# CHECK-FIXUP: encoding: [0bAAAAAA01,0b110AAAAA]
# CHECK-FIXUP:   fixup A - offset: 0, value: .LBB0_2, kind: fixup_riscv_rvc_branch
# CHECK-INSTR: c.beqz  a3, -4
c.beqz  a3, .LBB0_2
# CHECK-FIXUP: encoding: [0bAAAAAA01,0b111AAAAA]
# CHECK-FIXUP:   fixup A - offset: 0, value: .LBB0_2, kind: fixup_riscv_rvc_branch
# CHECK-INSTR: c.bnez  a5, -8
c.bnez  a5, .LBB0_2

# CHECK: encoding: [0bAAAAAA01,0b001AAAAA]
# CHECK:   fixup A - offset: 0, value: func1, kind: fixup_riscv_rvc_jump
c.jal   func1
