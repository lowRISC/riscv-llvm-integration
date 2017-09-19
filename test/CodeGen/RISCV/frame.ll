; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

%struct.key_t = type { i32, [16 x i8] }

; FIXME: prologue and epilogue insertion must be implemented to complete this
; test

; Function Attrs: nounwind uwtable
define i32 @test() {
; CHECK-LABEL: test:
; CHECK: sw ra, 28(s0)
; CHECK: sw zero, 24(s0)
; CHECK: sw zero, 20(s0)
; CHECK: sw zero, 16(s0)
; CHECK: sw zero, 12(s0)
; CHECK: sw zero, 8(s0)
; CHECK: addi a0, s0, 8
; CHECK: ori a0, a0, 4
; CHECK: lui a1, %hi(test1)
; CHECK: addi a1, a1, %lo(test1)
; CHECK: jalr ra, a1, 0
  %key = alloca %struct.key_t, align 4
  %1 = bitcast %struct.key_t* %key to i8*
  call void @llvm.memset.p0i8.i64(i8* %1, i8 0, i64 20, i32 4, i1 false)
  %2 = getelementptr inbounds %struct.key_t, %struct.key_t* %key, i64 0, i32 1, i64 0
  call void @test1(i8* %2) #3
  ret i32 0
}

; Function Attrs: nounwind argmemonly
declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1)

declare void @test1(i8*)
