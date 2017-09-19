; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

declare i32 @external_function(i32) nounwind

define i32 @test_call_external(i32 %a) {
; CHECK-LABEL: test_call_external:
; CHECK: lui a1, %hi(external_function)
; CHECK: addi a1, a1, %lo(external_function)
; CHECK: jalr ra, a1, 0
  %1 = call i32 @external_function(i32 %a) nounwind
  ret i32 %1
}

define i32 @defined_function(i32 %a) nounwind noinline {
  %1 = add i32 %a, 1
  ret i32 %1
}

define i32 @test_call_defined(i32 %a) {
; CHECK-LABEL: test_call_defined:
; CHECK: lui a1, %hi(defined_function)
; CHECK: addi a1, a1, %lo(defined_function)
; CHECK: jalr ra, a1, 0
  %1 = call i32 @defined_function(i32 %a) nounwind
  ret i32 %1
}

define i32 @test_call_indirect(i32 (i32)* %a, i32 %b) {
; CHECK-LABEL: test_call_indirect:
; CHECK: addi a2, a0, 0
; CHECK: addi a0, a1, 0
; CHECK: jalr ra, a2, 0
  %1 = call i32 %a(i32 %b)
  ret i32 %1
}

; Ensure that calls to fastcc functions aren't rejected. Such calls may be
; introduced when compiling with optimisation.

define fastcc i32 @fastcc_function(i32 %a, i32 %b) {
 %1 = add i32 %a, %b
 ret i32 %1
}

define i32 @test_call_fastcc(i32 %a, i32 %b) {
; CHECK-LABEL: test_call_fastcc:
  %1 = call fastcc i32 @fastcc_function(i32 %a, i32 %b)
  ret i32 %a
}
