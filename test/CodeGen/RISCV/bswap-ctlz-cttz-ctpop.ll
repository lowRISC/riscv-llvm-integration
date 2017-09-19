; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

declare i16 @llvm.bswap.i16(i16)
declare i32 @llvm.bswap.i32(i32)
declare i64 @llvm.bswap.i64(i64)
declare i8 @llvm.cttz.i8(i8, i1)
declare i16 @llvm.cttz.i16(i16, i1)
declare i32 @llvm.cttz.i32(i32, i1)
declare i64 @llvm.cttz.i64(i64, i1)
declare i32 @llvm.ctlz.i32(i32, i1)
declare i32 @llvm.ctpop.i32(i32)

define i16 @test_bswap_i16(i16 %a) {
; CHECK-LABEL: test_bswap_i16:
  %tmp = call i16 @llvm.bswap.i16(i16 %a)
  ret i16 %tmp
}

define i32 @test_bswap_i32(i32 %a) {
; CHECK-LABEL: test_bswap_i32:
  %tmp = call i32 @llvm.bswap.i32(i32 %a)
  ret i32 %tmp
}

define i64 @test_bswap_i64(i64 %a) {
; CHECK-LABEL: test_bswap_i64:
  %tmp = call i64 @llvm.bswap.i64(i64 %a)
  ret i64 %tmp
}

define i8 @test_cttz_i8(i8 %a) {
; CHECK-LABEL: test_cttz_i8:
  %tmp = call i8 @llvm.cttz.i8(i8 %a, i1 false)
  ret i8 %tmp
}

define i16 @test_cttz_i16(i16 %a) {
; CHECK-LABEL: test_cttz_i16:
  %tmp = call i16 @llvm.cttz.i16(i16 %a, i1 false)
  ret i16 %tmp
}

define i32 @test_cttz_i32(i32 %a) {
; CHECK-LABEL: test_cttz_i32:
  %tmp = call i32 @llvm.cttz.i32(i32 %a, i1 false)
  ret i32 %tmp
}

define i32 @test_ctlz_i32(i32 %a) {
; CHECK-LABEL: test_ctlz_i32:
  %tmp = call i32 @llvm.ctlz.i32(i32 %a, i1 false)
  ret i32 %tmp
}

define i64 @test_cttz_i64(i64 %a) {
; CHECK-LABEL: test_cttz_i64:
  %tmp = call i64 @llvm.cttz.i64(i64 %a, i1 false)
  ret i64 %tmp
}

define i8 @test_cttz_i8_zero_undef(i8 %a) {
; CHECK-LABEL: test_cttz_i8_zero_undef:
  %tmp = call i8 @llvm.cttz.i8(i8 %a, i1 true)
  ret i8 %tmp
}

define i16 @test_cttz_i16_zero_undef(i16 %a) {
; CHECK-LABEL: test_cttz_i16_zero_undef:
  %tmp = call i16 @llvm.cttz.i16(i16 %a, i1 true)
  ret i16 %tmp
}

define i32 @test_cttz_i32_zero_undef(i32 %a) {
; CHECK-LABEL: test_cttz_i32_zero_undef:
  %tmp = call i32 @llvm.cttz.i32(i32 %a, i1 true)
  ret i32 %tmp
}

define i64 @test_cttz_i64_zero_undef(i64 %a) {
; CHECK-LABEL: test_cttz_i64_zero_undef:
  %tmp = call i64 @llvm.cttz.i64(i64 %a, i1 true)
  ret i64 %tmp
}

define i32 @test_ctpop_i32(i32 %a) {
; CHECK-LABEL: test_ctpop_i32:
  %1 = call i32 @llvm.ctpop.i32(i32 %a)
  ret i32 %1
}
