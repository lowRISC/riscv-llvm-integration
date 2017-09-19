; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; TODO: the quality of the generated code is poor

define void @test() {
; CHECK-LABEL: test:
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1680
; CHECK: sub sp, sp, a0
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1676
; CHECK: add a0, sp, a0
; CHECK: sw ra, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1672
; CHECK: add a0, sp, a0
; CHECK: sw s0, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1680
; CHECK: add s0, sp, a0
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1672
; CHECK: add a0, sp, a0
; CHECK: lw s0, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1676
; CHECK: add a0, sp, a0
; CHECK: lw ra, 0(a0)
; CHECK: lui a0, 74565
; CHECK: addi a0, a0, 1680
; CHECK: add sp, sp, a0
; CHECK: jalr zero, ra, 0
  %tmp = alloca [ 305419896 x i8 ] , align 4
  ret void
}

; This test case artificially produces register pressure which should force use of the emergency spill slot.

define void @test_emergency_spill_slot(i32 %a) {
; CHECK-LABEL: test_emergency_spill_slot:
  %data = alloca [ 100000 x i32 ] , align 4
  %ptr = getelementptr inbounds [100000 x i32], [100000 x i32]* %data, i32 0, i32 80000
  %1 = tail call { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } asm sideeffect "nop", "=r,=r,=r,=r,=r,=r,=r,=r,=r,=r,=r,=r,=r,=r,=r"()
  %asmresult0 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 0
  %asmresult1 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 1
  %asmresult2 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 2
  %asmresult3 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 3
  %asmresult4 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 4
  %asmresult5 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 5
  %asmresult6 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 6
  %asmresult7 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 7
  %asmresult8 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 8
  %asmresult9 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 9
  %asmresult10 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 10
  %asmresult11 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 11
  %asmresult12 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 12
  %asmresult13 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 13
  %asmresult14 = extractvalue { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } %1, 14
  store volatile i32 %a, i32* %ptr
  tail call void asm sideeffect "nop", "r,r,r,r,r,r,r,r,r,r,r,r,r,r,r"(i32 %asmresult0, i32 %asmresult1, i32 %asmresult2, i32 %asmresult3, i32 %asmresult4, i32 %asmresult5, i32 %asmresult6, i32 %asmresult7, i32 %asmresult8, i32 %asmresult9, i32 %asmresult10, i32 %asmresult11, i32 %asmresult12, i32 %asmresult13, i32 %asmresult14)
  ret void
}
