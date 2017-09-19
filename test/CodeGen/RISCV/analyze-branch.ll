; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; This test checks that LLVM can do basic stripping and reapplying of branches
; to basic blocks.

declare void @test_true()
declare void @test_false()

; !0 corresponds to a branch being taken, !1 to not being takne.
!0 = !{!"branch_weights", i32 64, i32 4}
!1 = !{!"branch_weights", i32 4, i32 64}

define void @test_bcc_fallthrough_taken(i32 %in) {
; CHECK-LABEL: test_bcc_fallthrough_taken:
  %tst = icmp eq i32 %in, 42
  br i1 %tst, label %true, label %false, !prof !0

; Expected layout order is: Entry, TrueBlock, FalseBlock
; Entry->TrueBlock is the common path, which should be taken whenever the
; conditional branch is false.

; CHECK: bne a0, a1, [[FALSE:.LBB[0-9]+_[0-9]+]]
; CHECK-NEXT: # BB#
; CHECK-NEXT: lui a0, %hi(test_true)

; CHECK: [[FALSE]]:
; CHECK-NEXT: lui a0, %hi(test_false)

true:
  call void @test_true()
  ret void

false:
  call void @test_false()
  ret void
}

define void @test_bcc_fallthrough_nottaken(i32 %in) {
; CHECK-LABEL: test_bcc_fallthrough_nottaken:
  %tst = icmp eq i32 %in, 42
  br i1 %tst, label %true, label %false, !prof !1

; Expected layout order is: Entry, FalseBlock, TrueBlock
; Entry->FalseBlock is the common path, which should be taken whenever the
; conditional branch is false

; CHECK: beq a0, a1, [[TRUE:.LBB[0-9]+_[0-9]+]]
; CHECK-NEXT: # BB#
; CHECK-NEXT: lui a0, %hi(test_false)

; CHECK: [[TRUE]]:
; CHECK-NEXT: lui a0, %hi(test_true)

true:
  call void @test_true()
  ret void

false:
  call void @test_false()
  ret void
}

; TODO: how can we expand the coverage of the branch analysis functions?
