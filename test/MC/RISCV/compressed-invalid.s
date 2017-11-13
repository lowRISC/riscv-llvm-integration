# RUN: not llvm-mc -mattr=+c < %s 2>&1 | FileCheck %s

.LBB:
## GPRC
c.lw  ra, 4(sp) # CHECK: :[[@LINE]]:7: error: invalid operand for instruction
c.sw  sp, 4(sp) # CHECK: :[[@LINE]]:7: error: invalid operand for instruction
c.beqz  t0, .LBB # CHECK: :[[@LINE]]:9: error: invalid operand for instruction
c.bnez  s8, .LBB # CHECK: :[[@LINE]]:9: error: invalid operand for instruction
c.addi4spn  s4, sp, 12 # CHECK: :[[@LINE]]:13: error: invalid operand for instruction
c.srli  s7, 12 # CHECK: :[[@LINE]]:9: error: invalid operand for instruction
c.srai  t0, 12 # CHECK: :[[@LINE]]:9: error: invalid operand for instruction
c.andi  t1, 12 # CHECK: :[[@LINE]]:9: error: invalid operand for instruction
c.and  t1, a0 # CHECK: :[[@LINE]]:8: error: invalid operand for instruction
c.or   a0, s8 # CHECK: :[[@LINE]]:12: error: invalid operand for instruction
c.xor  t2, a0 # CHECK: :[[@LINE]]:8: error: invalid operand for instruction
c.sub  a0, s8 # CHECK: :[[@LINE]]:12: error: invalid operand for instruction

## SP
c.addi4spn  a0, a0, 12 # CHECK: :[[@LINE]]:17: error: invalid operand for instruction
c.addi16sp  t0, 16 # CHECK: :[[@LINE]]:13: error: invalid operand for instruction

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

## simm6
c.li t0, 128 # CHECK: :[[@LINE]]:10: error: immediate must be an integer in the range [-32, 31]
c.addi t0, 64 # CHECK: :[[@LINE]]:12: error: immediate must be an integer in the range [-32, 31]
c.andi a0, -64 # CHECK: :[[@LINE]]:12: error: immediate must be an integer in the range [-32, 31]

## uimm6
c.lui t0, 128 # CHECK: :[[@LINE]]:11: error: immediate must be an integer in the range [0, 63]

## uimm10_2lsb0
c.addi4spn  a0, sp, 2048 # CHECK: :[[@LINE]]:21: error: immediate must be a multiple of 4 bytes in the range [0, 1020]
c.addi4spn  a0, sp, -4 # CHECK: :[[@LINE]]:21: error: immediate must be a multiple of 4 bytes in the range [0, 1020]
c.addi4spn  a0, sp, 2 # CHECK: :[[@LINE]]:21: error: immediate must be a multiple of 4 bytes in the range [0, 1020]

## simm10_4lsb0
c.addi16sp  sp, 2048 # CHECK: :[[@LINE]]:17: error: immediate must be a multiple of 16 bytes in the range [-1024, 1008]
c.addi16sp  sp, -2048 # CHECK: :[[@LINE]]:17: error: immediate must be a multiple of 16 bytes in the range [-1024, 1008]
c.addi16sp  sp, 8 # CHECK: :[[@LINE]]:17: error: immediate must be a multiple of 16 bytes in the range [-1024, 1008]

## uimm5
c.slli t0, 64 # CHECK: :[[@LINE]]:12: error: immediate must be an integer in the range [0, 31]
c.srli a0, 32 # CHECK: :[[@LINE]]:12: error: immediate must be an integer in the range [0, 31]
c.srai a0, -1 # CHECK: :[[@LINE]]:12: error: immediate must be an integer in the range [0, 31]
