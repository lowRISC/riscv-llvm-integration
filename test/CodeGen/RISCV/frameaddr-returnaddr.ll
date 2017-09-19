; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

declare void @notdead(i8*)
declare i8* @llvm.frameaddress(i32)
declare i8* @llvm.returnaddress(i32)

define i8* @test_frameaddress_0() {
; CHECK-LABEL: test_frameaddress_0:
; CHECK: addi sp, sp, -16
; CHECK: addi s0, sp, 16
; CHECK: addi a0, s0, 0
; CHECK: jalr zero, ra, 0
  %1 = call i8* @llvm.frameaddress(i32 0)
  ret i8* %1
}

define i8* @test_frameaddress_2() {
; CHECK-LABEL: test_frameaddress_2:
; CHECK: addi sp, sp, -16
; CHECK: addi s0, sp, 16
; CHECK: lw a0, -8(s0)
; CHECK: lw a0, -8(a0)
; CHECK: jalr zero, ra, 0
  %1 = call i8* @llvm.frameaddress(i32 2)
  ret i8* %1
}

define i8* @test_frameaddress_3_alloca() {
; CHECK-LABEL: test_frameaddress_3_alloca:
; CHECK: addi sp, sp, -112
; CHECK: sw ra, 108(sp)
; CHECK: sw s0, 104(sp)
; CHECK: addi s0, sp, 112
; CHECK: lw a0, -8(s0)
; CHECK: lw a0, -8(a0)
; CHECK: lw a0, -8(a0)
; CHECK: jalr zero, ra, 0
  %1 = alloca [100 x i8]
  %2 = bitcast [100 x i8]* %1 to i8*
  call void @notdead(i8* %2)
  %3 = call i8* @llvm.frameaddress(i32 3)
  ret i8* %3
}

define i8* @test_returnaddress_0() {
; CHECK-LABEL: test_returnaddress_0:
; CHECK: addi a0, ra, 0
; CHECK: jalr zero, ra, 0
  %1 = call i8* @llvm.returnaddress(i32 0)
  ret i8* %1
}

define i8* @test_returnaddress_2() {
; CHECK-LABEL: test_returnaddress_2:
; CHECK: addi sp, sp, -16
; CHECK: addi s0, sp, 16
; CHECK: lw a0, -8(s0)
; CHECK: lw a0, -8(a0)
; CHECK: lw a0, -4(a0)
; CHECK: jalr zero, ra, 0
  %1 = call i8* @llvm.returnaddress(i32 2)
  ret i8* %1
}
