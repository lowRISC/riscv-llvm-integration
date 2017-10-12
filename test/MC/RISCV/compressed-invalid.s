# RUN: not llvm-mc -mattr=+c < %s 2>&1 | FileCheck %s

.LBB:
## GPRC
c.lw  ra, 4(sp) # CHECK: :[[@LINE]]:7: error: invalid operand for instruction
c.sw  sp, 4(sp) # CHECK: :[[@LINE]]:7: error: invalid operand for instruction
c.beqz  t0, .LBB # CHECK: :[[@LINE]]:9: error: invalid operand for instruction
c.bnez  s8, .LBB # CHECK: :[[@LINE]]:9: error: invalid operand for instruction

# Out of range immediates

## uimm8_lsb00
c.lwsp  ra, 300(sp) # CHECK: :[[@LINE]]:13: error: immediate must be a multiple of 4 bytes in the range [0, 252]
c.swsp  ra, -20(sp) # CHECK: :[[@LINE]]:13: error: immediate must be a multiple of 4 bytes in the range [0, 252]
## uimm7_lsb00
c.lw  s0, -4(sp) # CHECK: :[[@LINE]]:11: error: immediate must be a multiple of 4 bytes in the range [0, 124]
c.sw  s0, 130(sp) # CHECK: :[[@LINE]]:11: error: immediate must be a multiple of 4 bytes in the range [0, 124]

## simm9_lsb0
c.bnez  s1, -1028 # CHECK: :[[@LINE]]:13: error: immediate must be a multiple of 2 bytes in the range [-256, 254]
c.beqz  a0, 280 # CHECK: :[[@LINE]]:13: error: immediate must be a multiple of 2 bytes in the range [-256, 254]

## simm12_lsb0
c.j 4096 # CHECK: :[[@LINE]]:5: error: immediate must be a multiple of 2 bytes in the range [-2048, 2046]
c.jal -3000 # CHECK: :[[@LINE]]:7: error: immediate must be a multiple of 2 bytes in the range [-2048, 2046]
