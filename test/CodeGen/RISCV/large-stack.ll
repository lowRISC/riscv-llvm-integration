; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; TODO: the quality of the generated code is poor

define void @test() {
; CHECK-LABEL: test:
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1664
; CHECK: sub sp, sp, a0
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1660
; CHECK: add a0, sp, a0
; CHECK: sw s0, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1664
; CHECK: add s0, sp, a0
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1656
; CHECK: add a0, sp, a0
; CHECK: lw s0, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1660
; CHECK: add a0, sp, a0
; CHECK: lw ra, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1664
; CHECK: add sp, sp, a0
; CHECK: jalr zero, ra, 0
  %tmp = alloca [ 305419896 x i8 ] , align 4
  ret void
}
