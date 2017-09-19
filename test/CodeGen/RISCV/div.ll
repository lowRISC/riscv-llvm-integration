; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define i32 @udiv(i32 %a, i32 %b) {
; CHECK-LABEL: udiv:
; CHECK: lui a2, %hi(__udivsi3)
; CHECK: addi a2, a2, %lo(__udivsi3)
; CHECK: jalr ra, a2, 0
  %1 = udiv i32 %a, %b
  ret i32 %1
}

define i32 @udiv_constant(i32 %a) {
; CHECK-LABEL: udiv_constant:
; CHECK: lui a1, %hi(__udivsi3)
; CHECK: addi a2, a1, %lo(__udivsi3)
; CHECK: addi a1, zero, 5
; CHECK: jalr ra, a2, 0
  %1 = udiv i32 %a, 5
  ret i32 %1
}

define i32 @udiv_pow2(i32 %a) {
; CHECK-LABEL: udiv_pow2:
; CHECK: srli a0, a0, 3
  %1 = udiv i32 %a, 8
  ret i32 %1
}

define i64 @udiv64(i64 %a, i64 %b) {
; CHECK-LABEL: udiv64:
; CHECK: lui a4, %hi(__udivdi3)
; CHECK: addi a4, a4, %lo(__udivdi3)
; CHECK: jalr ra, a4, 0
  %1 = udiv i64 %a, %b
  ret i64 %1
}

define i64 @udiv64_constant(i64 %a) {
; CHECK-LABEL: udiv64_constant:
; CHECK: lui a2, %hi(__udivdi3)
; CHECK: addi a4, a2, %lo(__udivdi3)
; CHECK: addi a2, zero, 5
; CHECK: addi a3, zero, 0
; CHECK: jalr ra, a4, 0
  %1 = udiv i64 %a, 5
  ret i64 %1
}

define i32 @sdiv(i32 %a, i32 %b) {
; CHECK-LABEL: sdiv:
; CHECK: lui a2, %hi(__divsi3)
; CHECK: addi a2, a2, %lo(__divsi3)
; CHECK: jalr ra, a2, 0
  %1 = sdiv i32 %a, %b
  ret i32 %1
}

define i32 @sdiv_constant(i32 %a) {
; CHECK-LABEL: sdiv_constant:
; CHECK: lui a1, %hi(__divsi3)
; CHECK: addi a2, a1, %lo(__divsi3)
; CHECK: addi a1, zero, 5
; CHECK: jalr ra, a2, 0
  %1 = sdiv i32 %a, 5
  ret i32 %1
}

define i32 @sdiv_pow2(i32 %a) {
; CHECK-LABEL: sdiv_pow2
; CHECK: srai a1, a0, 31
; CHECK: srli a1, a1, 29
; CHECK: add a0, a0, a1
; CHECK: srai a0, a0, 3
  %1 = sdiv i32 %a, 8
  ret i32 %1
}

define i64 @sdiv64(i64 %a, i64 %b) {
; CHECK-LABEL: sdiv64:
; CHECK: lui a4, %hi(__divdi3)
; CHECK: addi a4, a4, %lo(__divdi3)
; CHECK: jalr ra, a4, 0
  %1 = sdiv i64 %a, %b
  ret i64 %1
}

define i64 @sdiv64_constant(i64 %a) {
; CHECK-LABEL: sdiv64_constant:
; CHECK: lui a2, %hi(__divdi3)
; CHECK: addi a4, a2, %lo(__divdi3)
; CHECK: addi a2, zero, 5
; CHECK: addi a3, zero, 0
; CHECK: jalr ra, a4, 0
  %1 = sdiv i64 %a, 5
  ret i64 %1
}
