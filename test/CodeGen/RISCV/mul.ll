; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define i32 @square(i32 %a) {
; CHECK-LABEL: square:
; CHECK: lui a1, %hi(__mulsi3)
; CHECK: addi a2, a1, %lo(__mulsi3)
; CHECK: addi a1, a0, 0
; CHECK: jalr ra, a2, 0
  %1 = mul i32 %a, %a
  ret i32 %1
}

define i32 @mul(i32 %a, i32 %b) {
; CHECK-LABEL: mul:
; CHECK: lui a2, %hi(__mulsi3)
; CHECK: addi a2, a2, %lo(__mulsi3)
; CHECK: jalr ra, a2, 0
  %1 = mul i32 %a, %b
  ret i32 %1
}

define i32 @mul_constant(i32 %a) {
; CHECK-LABEL: mul_constant:
; CHECK: lui a1, %hi(__mulsi3)
; CHECK: addi a2, a1, %lo(__mulsi3)
; CHECK: addi a1, zero, 5
; CHECK: jalr ra, a2, 0
  %1 = mul i32 %a, 5
  ret i32 %1
}

define i32 @mul_pow2(i32 %a) {
; CHECK-LABEL: mul_pow2:
; CHECK: slli a0, a0, 3
; CHECK: jalr zero, ra, 0
  %1 = mul i32 %a, 8
  ret i32 %1
}

define i64 @mul64(i64 %a, i64 %b) {
; CHECK-LABEL: mul64:
; CHECK: lui a4, %hi(__muldi3)
; CHECK: addi a4, a4, %lo(__muldi3)
; CHECK: jalr ra, a4, 0
  %1 = mul i64 %a, %b
  ret i64 %1
}

define i64 @mul64_constant(i64 %a) {
; CHECK-LABEL: mul64_constant:
; CHECK: lui a2, %hi(__muldi3)
; CHECK: addi a4, a2, %lo(__muldi3)
; CHECK: addi a2, zero, 5
; CHECK: addi a3, zero, 0
; CHECK: jalr ra, a4, 0
  %1 = mul i64 %a, 5
  ret i64 %1
}
