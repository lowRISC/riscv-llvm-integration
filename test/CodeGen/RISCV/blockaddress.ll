; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s
@addr = global i8* null

define void @test_blockaddress() {
; CHECK-LABEL: test_blockaddress:
; CHECK: lui a0, %hi(addr)
; CHECK: addi a0, a0, %lo(addr)
; CHECK: lui a1, %hi(.Ltmp0)
; CHECK: addi a1, a1, %lo(.Ltmp0)
; CHECK: sw a1, 0(a0)
; CHECK: lw a0, 0(a0)
; CHECK: jalr zero, a0, 0
  store volatile i8* blockaddress(@test_blockaddress, %block), i8** @addr
  %val = load volatile i8*, i8** @addr
  indirectbr i8* %val, [label %block]

block:
  ret void
}
