; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

declare void @notdead(i8*)

; These tests must ensure the stack pointer is restored using the frame
; pointer

define void @simple_alloca(i32 %n) {
; CHECK-LABEL: simple_alloca:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: addi a0, a0, 15
; CHECK: andi a0, a0, -16
; CHECK: sub a0, sp, a0
; CHECK: addi sp, a0, 0
; CHECK: lui a1, %hi(notdead)
; CHECK: addi a1, a1, %lo(notdead)
; CHECK: jalr ra, a1, 0
; CHECK: addi sp, s0, -16
; CHECK: lw s0, 8(sp)
; CHECK: lw ra, 12(sp)
; CHECK: addi sp, sp, 16
; CHECK: jalr zero, ra, 0
  %1 = alloca i8, i32 %n
  call void @notdead(i8* %1)
  ret void
}

declare i8* @llvm.stacksave()
declare void @llvm.stackrestore(i8*)

define void @scoped_alloca(i32 %n) {
; CHECK-LABEL: scoped_alloca:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: sw s1, 4(sp)
; CHECK: addi s0, sp, 16
; CHECK: addi s1, sp, 0
; CHECK: addi a0, a0, 15
; CHECK: andi a0, a0, -16
; CHECK: sub a0, sp, a0
; CHECK: addi sp, a0, 0
; CHECK: lui a1, %hi(notdead)
; CHECK: addi a1, a1, %lo(notdead)
; CHECK: jalr ra, a1, 0
; CHECK: addi sp, s1, 0
; CHECK: addi sp, s0, -16
; CHECK: lw s1, 4(sp)
; CHECK: lw s0, 8(sp)
; CHECK: lw ra, 12(sp)
; CHECK: addi sp, sp, 16
; CHECK: jalr zero, ra, 0
  %sp = call i8* @llvm.stacksave()
  %addr = alloca i8, i32 %n
  call void @notdead(i8* %addr)
  call void @llvm.stackrestore(i8* %sp)
  ret void
}
