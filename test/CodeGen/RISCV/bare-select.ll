; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define i32 @bare_select(i1 %a, i32 %b, i32 %c) {
; CHECK-LABEL: bare_select:
; CHECK: andi a0, a0, 1
; CHECK: addi a3, zero, 0
; CHECK: bne a0, a3, .LBB0_2
; CHECK: addi a1, a2, 0
; CHECK: .LBB0_2:
; CHECK: addi a0, a1, 0
  %1 = select i1 %a, i32 %b, i32 %c
  ret i32 %1
}
