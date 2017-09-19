; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

@x = local_unnamed_addr global fp128 0xL00000000000000007FFF000000000000, align 16
@y = local_unnamed_addr global fp128 0xL00000000000000007FFF000000000000, align 16

; Besides anything else, these tests help verify that libcall ABI lowering
; works correctly

define i32 @test_load_and_cmp() {
; CHECK-LABEL: test_load_and_cmp:
; CHECK: lui a0, %hi(__netf2)
; CHECK: addi a2, a0, %lo(__netf2)
; CHECK: addi a0, s0, -24
; CHECK: addi a1, s0, -40
; CHECK: jalr ra, a2, 0
  %1 = load fp128, fp128* @x, align 16
  %2 = load fp128, fp128* @y, align 16
  %cmp = fcmp une fp128 %1, %2
  %3 = zext i1 %cmp to i32
  ret i32 %3
}

define i32 @test_add_and_fptosi() {
; CHECK-LABEL: test_add_and_fptosi:
; CHECK: lui a0, %hi(__addtf3)
; CHECK: addi a3, a0, %lo(__addtf3)
; CHECK: addi a0, s0, -24
; CHECK: addi a1, s0, -40
; CHECK: addi a2, s0, -56
; CHECK: jalr ra, a3, 0
; CHECK: lui a0, %hi(__fixtfsi)
; CHECK: addi a1, a0, %lo(__fixtfsi)
; CHECK: addi a0, s0, -72
; CHECK: jalr ra, a1, 0
  %1 = load fp128, fp128* @x, align 16
  %2 = load fp128, fp128* @y, align 16
  %3 = fadd fp128 %1, %2
  %4 = fptosi fp128 %3 to i32
  ret i32 %4
}
