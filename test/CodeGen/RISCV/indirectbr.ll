; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define i32 @indirectbr(i8* %target) nounwind {
; CHECK-LABEL: indirectbr:
; CHECK: jalr zero, a0, 0
; CHECK: .LBB{{[0-9]+}}_1
; CHECK: addi a0, zero, 0
; CHECK: jalr zero, ra, 0
  indirectbr i8* %target, [label %test_label]
test_label:
  br label %ret
ret:
  ret i32 0
}

define i32 @indirectbr_with_offset(i8* %a) nounwind {
; CHECK-LABEL: indirectbr_with_offset:
; CHECK: jalr zero, a0, 1380
; CHECK: .LBB{{[0-9]+}}_1
; CHECK: addi a0, zero, 0
; CHECK: jalr zero, ra, 0
  %target = getelementptr inbounds i8, i8* %a, i32 1380
  indirectbr i8* %target, [label %test_label]
test_label:
  br label %ret
ret:
  ret i32 0
}
