; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define i32 @urem(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: urem:
; CHECK: lui a2, %hi(__umodsi3)
; CHECK: addi a2, a2, %lo(__umodsi3)
; CHECK: jalr ra, a2, 0
  %1 = urem i32 %a, %b
  ret i32 %1
}

define i32 @srem(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: srem:
; CHECK: lui a2, %hi(__modsi3)
; CHECK: addi a2, a2, %lo(__modsi3)
; CHECK: jalr ra, a2, 0
  %1 = srem i32 %a, %b
  ret i32 %1
}
