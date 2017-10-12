# RUN: llvm-mc %s -mattr=+c -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK,CHECK-INST %s
# RUN: llvm-mc -filetype=obj -mattr=+c < %s \
# RUN:     | llvm-objdump -d - | FileCheck -check-prefix=CHECK-INST %s

# CHECK-INST: c.lwsp  ra, 12(sp)
# CHECK: encoding: [0xb2,0x40]
c.lwsp  ra, 12(sp)
# CHECK-INST: c.swsp  ra, 12(sp)
# CHECK: encoding: [0x06,0xc6]
c.swsp  ra, 12(sp)
# CHECK-INST: c.lw    a2, 4(a0)
# CHECK: encoding: [0x50,0x41]
c.lw    a2, 4(a0)
# CHECK-INST: c.sw    a5, 8(a3)
# CHECK: encoding: [0x9c,0xc6]
c.sw    a5, 8(a3)

# CHECK-INST: c.j     -16
# CHECK: encoding: [0xe5,0xbf]
c.j     -16
# CHECK-INST: c.jr    a7
# CHECK: encoding: [0x82,0x88]
c.jr    a7
# CHECK-INST: c.jalr  a1
# CHECK: encoding: [0x82,0x95]
c.jalr  a1
# CHECK-INST: c.beqz  a3, -8
# CHECK: encoding: [0xf5,0xde]
c.beqz  a3, -8
# CHECK-INST: c.bnez  a5, -12
# CHECK: encoding: [0xed,0xff]
c.bnez  a5, -12
