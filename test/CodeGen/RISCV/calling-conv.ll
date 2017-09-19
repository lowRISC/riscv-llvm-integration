; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; As well as calling convention details, we check that ra and fp are
; consistently stored to fp-4 and fp-8.

; Check that on RV32, i64 and double are passed in a pair of registers. Unlike
; the convention for varargs, this need not be an aligned pair.

define i32 @callee_scalars(i32 %a, i64 %b, i32 %c, i32 %d, double %e) {
; CHECK-LABEL: callee_scalars:
; CHECK: addi sp, sp, -32
; CHECK: sw ra, 28(sp)
; CHECK: sw s0, 24(sp)
; CHECK: addi s0, sp, 32
; CHECK: addi s1, a4, 0
; CHECK: addi s2, a3, 0
; CHECK: addi s3, a1, 0
; CHECK: addi s4, a0, 0
; CHECK: lui a0, %hi(__fixdfsi)
; CHECK: addi a2, a0, %lo(__fixdfsi)
; CHECK: addi a0, a5, 0
; CHECK: addi a1, a6, 0
; CHECK: jalr ra, a2, 0
; CHECK: add a1, s4, s3
; CHECK: add a1, a1, s2
; CHECK: add a1, a1, s1
; CHECK: add a0, a1, a0
  %b_trunc = trunc i64 %b to i32
  %e_fptosi = fptosi double %e to i32
  %1 = add i32 %a, %b_trunc
  %2 = add i32 %1, %c
  %3 = add i32 %2, %d
  %4 = add i32 %3, %e_fptosi
  ret i32 %4
}

define i32 @caller_scalars() {
; CHECK-LABEL: caller_scalars:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lui a0, 262464
; CHECK: addi a6, a0, 0
; CHECK: lui a0, %hi(callee_scalars)
; CHECK: addi a7, a0, %lo(callee_scalars)
; CHECK: addi a0, zero, 1
; CHECK: addi a1, zero, 2
; CHECK: addi a3, zero, 3
; CHECK: addi a4, zero, 4
; CHECK: addi a2, zero, 0
; CHECK: addi a5, zero, 0
; CHECK: jalr ra, a7, 0
  %1 = call i32 @callee_scalars(i32 1, i64 2, i32 3, i32 4, double 5.000000e+00)
  ret i32 %1
}

; Check that i128 and fp128 are passed indirectly

define i32 @callee_large_scalars(i128 %a, fp128 %b) {
; CHECK-LABEL: callee_large_scalars:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi  s0, sp, 16
; CHECK: lw a2, 12(a1)
; CHECK: lw a3, 12(a0)
; CHECK: xor a2, a3, a2
; CHECK: lw a3, 4(a1)
; CHECK: lw a4, 4(a0)
; CHECK: xor a3, a4, a3
; CHECK: or a2, a3, a2
; CHECK: lw a3, 8(a1)
; CHECK: lw a4, 8(a0)
; CHECK: xor a3, a4, a3
; CHECK: lw a1, 0(a1)
; CHECK: lw a0, 0(a0)
; CHECK: xor a0, a0, a1
; CHECK: or a0, a0, a3
; CHECK: or a0, a0, a2
; CHECK: xor a0, a0, zero
; CHECK: sltiu a0, a0, 1
  %b_bitcast = bitcast fp128 %b to i128
  %1 = icmp eq i128 %a, %b_bitcast
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @caller_large_scalars() {
; CHECK-LABEL: caller_large_scalars:
; CHECK: addi sp, sp, -48
; CHECK: sw ra, 44(sp)
; CHECK: sw s0, 40(sp)
; CHECK: addi  s0, sp, 48
; CHECK: sw zero, -40(s0)
; CHECK: sw zero, -44(s0)
; CHECK: sw zero, -48(s0)
; CHECK: sw zero, -12(s0)
; CHECK: sw zero, -16(s0)
; CHECK: sw zero, -20(s0)
; CHECK: addi a0, zero, 1
; CHECK: sw a0, -24(s0)
; CHECK: lui a0, 524272
; CHECK: addi a0, a0, 0
; CHECK: sw a0, -36(s0)
; CHECK: lui a0, %hi(callee_large_scalars)
; CHECK: addi a2, a0, %lo(callee_large_scalars)
; CHECK: addi a0, s0, -24
; CHECK: addi a1, s0, -48
; CHECK: jalr ra, a2, 0
  %1 = call i32 @callee_large_scalars(i128 1, fp128 0xL00000000000000007FFF000000000000)
  ret i32 %1
}

; Ensure that libcalls generated in the middle-end obey the calling convention

define i32 @caller_mixed_scalar_libcalls(i64 %a) {
; CHECK-LABEL: caller_mixed_scalar_libcalls:
; CHECK: addi sp, sp, -32
; CHECK: sw ra, 28(sp)
; CHECK: sw s0, 24(sp)
; CHECK: addi s0, sp, 32
; CHECK: addi a2, a1, 0
; CHECK: addi a1, a0, 0
; CHECK: lui a0, %hi(__floatditf)
; CHECK: addi a3, a0, %lo(__floatditf)
; CHECK: addi a0, s0, -24
; CHECK: jalr ra, a3, 0
; CHECK: lw a0, -24(s0)
; CHECK: lw s0, 24(sp)
; CHECK: lw ra, 28(sp)
; CHECK: addi sp, sp, 32
; CHECK: jalr zero, ra, 0
  %1 = sitofp i64 %a to fp128
  %2 = bitcast fp128 %1 to i128
  %3 = trunc i128 %2 to i32
  ret i32 %3
}

; Check that the stack is used once the GPRs are exhausted

define i32 @callee_many_scalars(i8 %a, i16 %b, i32 %c, i64 %d, i32 %e, i32 %f, i64 %g, i32 %h) {
; CHECK-LABEL: callee_many_scalars:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lw t0, 0(s0)
; CHECK: xor a4, a4, t0
; CHECK: xor a3, a3, a7
; CHECK: or a3, a3, a4
; CHECK: xor a3, a3, zero
; CHECK: lui a4, 16
; CHECK: addi a4, a4, -1
; CHECK: and a1, a1, a4
; CHECK: andi a0, a0, 255
; CHECK: add a0, a0, a1
; CHECK: add a0, a0, a2
; CHECK: sltiu a1, a3, 1
; CHECK: add a0, a1, a0
; CHECK: add a0, a0, a5
; CHECK: add a0, a0, a6
; CHECK: lw a1, 4(s0)
; CHECK: add a0, a0, a1
  %a_ext = zext i8 %a to i32
  %b_ext = zext i16 %b to i32
  %1 = add i32 %a_ext, %b_ext
  %2 = add i32 %1, %c
  %3 = icmp eq i64 %d, %g
  %4 = zext i1 %3 to i32
  %5 = add i32 %4, %2
  %6 = add i32 %5, %e
  %7 = add i32 %6, %f
  %8 = add i32 %7, %h
  ret i32 %8
}

define i32 @caller_many_scalars() {
; CHECK-LABEL: caller_many_scalars:
; CHECK: addi sp, sp, -32
; CHECK: sw ra, 28(sp)
; CHECK: sw s0, 24(sp)
; CHECK: addi s0, sp, 32
; CHECK: addi a0, zero, 8
; CHECK: sw a0, 4(sp)
; CHECK: sw zero, 0(sp)
; CHECK: lui a0, %hi(callee_many_scalars)
; CHECK: addi t0, a0, %lo(callee_many_scalars)
; CHECK: addi a0, zero, 1
; CHECK: addi a1, zero, 2
; CHECK: addi a2, zero, 3
; CHECK: addi a3, zero, 4
; CHECK: addi a5, zero, 5
; CHECK: addi a6, zero, 6
; CHECK: addi a7, zero, 7
; CHECK: addi a4, zero, 0
; CHECK: jalr ra, t0, 0
  %1 = call i32 @callee_many_scalars(i8 1, i16 2, i32 3, i64 4, i32 5, i32 6, i64 7, i32 8)
  ret i32 %1
}

; Check passing of coerced integer arrays

%struct.small = type { i32, i32* }

define i32 @callee_small_coerced_struct([2 x i32] %a.coerce) {
; CHECK-LABEL: callee_small_coerced_struct:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: xor a0, a0, a1
; CHECK: sltiu a0, a0, 1
  %1 = extractvalue [2 x i32] %a.coerce, 0
  %2 = extractvalue [2 x i32] %a.coerce, 1
  %3 = icmp eq i32 %1, %2
  %4 = zext i1 %3 to i32
  ret i32 %4
}

define i32 @caller_small_coerced_struct() {
; CHECK-LABEL: caller_small_coerced_struct:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lui a0, %hi(callee_small_coerced_struct)
; CHECK: addi a2, a0, %lo(callee_small_coerced_struct)
; CHECK: addi a0, zero, 1
; CHECK: addi a1, zero, 2
; CHECK: jalr ra, a2, 0
  %1 = call i32 @callee_small_coerced_struct([2 x i32] [i32 1, i32 2])
  ret i32 %1
}

; Check large struct arguments, which are passed byval

%struct.large = type { i32, i32, i32, i32 }

define i32 @callee_large_struct(%struct.large* byval align 4 %a) {
; CHECK-LABEL: callee_large_struct:
; CHECK: addi  sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lw a1, 12(a0)
; CHECK: lw a0, 0(a0)
; CHECK: add a0, a0, a1
  %1 = getelementptr inbounds %struct.large, %struct.large* %a, i32 0, i32 0
  %2 = getelementptr inbounds %struct.large, %struct.large* %a, i32 0, i32 3
  %3 = load i32, i32* %1
  %4 = load i32, i32* %2
  %5 = add i32 %3, %4
  ret i32 %5
}

define i32 @caller_large_struct() {
; CHECK-LABEL: caller_large_struct:
; CHECK: addi sp, sp, -48
; CHECK: sw ra, 44(sp)
; CHECK: sw s0, 40(sp)
; CHECK: addi s0, sp, 48
; CHECK: addi a0, zero, 1
; CHECK: sw a0, -24(s0)
; CHECK: sw a0, -40(s0)
; CHECK: addi a0, zero, 2
; CHECK: sw a0, -20(s0)
; CHECK: sw a0, -36(s0)
; CHECK: addi a0, zero, 3
; CHECK: sw a0, -16(s0)
; CHECK: sw a0, -32(s0)
; CHECK: addi a0, zero, 4
; CHECK: sw a0, -12(s0)
; CHECK: sw a0, -28(s0)
; CHECK: lui a0, %hi(callee_large_struct)
; CHECK: addi a1, a0, %lo(callee_large_struct)
; CHECK: addi a0, s0, -40
; CHECK: jalr ra, a1, 0
  %ls = alloca %struct.large, align 4
  %1 = bitcast %struct.large* %ls to i8*
  %a = getelementptr inbounds %struct.large, %struct.large* %ls, i32 0, i32 0
  store i32 1, i32* %a
  %b = getelementptr inbounds %struct.large, %struct.large* %ls, i32 0, i32 1
  store i32 2, i32* %b
  %c = getelementptr inbounds %struct.large, %struct.large* %ls, i32 0, i32 2
  store i32 3, i32* %c
  %d = getelementptr inbounds %struct.large, %struct.large* %ls, i32 0, i32 3
  store i32 4, i32* %d
  %2 = call i32 @callee_large_struct(%struct.large* byval align 4 %ls)
  ret i32 %2
}

; Check 2x*xlen values are aligned appropriately when passed on the stack
define i32 @callee_aligned_stack(i32 %a, i32 %b, fp128 %c, i32 %d, i32 %e,
    i64 %f, i32 %g, i32 %h, double %i, i32 %j, [2 x i32] %k) {
; The double should be 8-byte aligned on the stack, but the two-element array
; should only be 4-byte aligned
; CHECK-LABEL: callee_aligned_stack:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lw a0, 0(a2)
; CHECK: add a0, a0, a7
; CHECK: lw a1, 0(s0)
; CHECK: add a0, a0, a1
; CHECK: lw a1, 8(s0)
; CHECK: add a0, a0, a1
; CHECK: lw a1, 16(s0)
; CHECK: add a0, a0, a1
; CHECK: lw a1, 20(s0)
; CHECK: add a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = bitcast fp128 %c to i128
  %2 = trunc i128 %1 to i32
  %3 = add i32 %2, %g
  %4 = add i32 %3, %h
  %5 = bitcast double %i to i64
  %6 = trunc i64 %5 to i32
  %7 = add i32 %4, %6
  %8 = add i32 %7, %j
  %9 = extractvalue [2 x i32] %k, 0
  %10 = add i32 %8, %9
  ret i32 %10
}

define void @caller_aligned_stack() {
; The double should be 8-byte aligned on the stack, but the two-element array
; should only be 4-byte aligned
; CHECK-LABEL: caller_aligned_stack:
; CHECK: addi sp, sp, -64
; CHECK: sw ra, 60(sp)
; CHECK: sw s0, 56(sp)
; CHECK: addi s0, sp, 64
; CHECK: addi a0, zero, 18
; CHECK: sw a0, 24(sp)
; CHECK: addi a0, zero, 17
; CHECK: sw a0, 20(sp)
; CHECK: addi a0, zero, 16
; CHECK: sw a0, 16(sp)
; CHECK: lui a0, 262236
; CHECK: addi a0, a0, 655
; CHECK: sw a0, 12(sp)
; CHECK: lui a0, 377487
; CHECK: addi a0, a0, 1475
; CHECK: sw a0, 8(sp)
; CHECK: addi a0, zero, 15
; CHECK: sw a0, 0(sp)
  %1 = call i32 @callee_aligned_stack(i32 1, i32 11,
    fp128 0xLEB851EB851EB851F400091EB851EB851, i32 12, i32 13,
    i64 20000000000, i32 14, i32 15, double 2.720000e+00, i32 16,
    [2 x i32] [i32 17, i32 18])
  ret void
}

; Check return of 2x xlen scalars

define i64 @callee_small_scalar_ret() {
; CHECK-LABEL: callee_small_scalar_ret:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lui a0, 466866
; CHECK: addi a0, a0, 1677
; CHECK: addi a1, zero, 287
  ret i64 1234567898765
}

define i32 @caller_small_scalar_ret() {
; CHECK-LABEL: caller_small_scalar_ret:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lui a0, %hi(callee_small_scalar_ret)
; CHECK: addi a0, a0, %lo(callee_small_scalar_ret)
; CHECK: jalr ra, a0, 0
; CHECK: lui a2, 56
; CHECK: addi a2, a2, 580
; CHECK: xor a1, a1, a2
; CHECK: lui a2, 200614
; CHECK: addi a2, a2, 647
; CHECK: xor a0, a0, a2
; CHECK: or a0, a0, a1
; CHECK: xor a0, a0, zero
; CHECK: sltiu a0, a0, 1
  %1 = call i64 @callee_small_scalar_ret()
  %2 = icmp eq i64 987654321234567, %1
  %3 = zext i1 %2 to i32
  ret i32 %3
}

; Check return of 2x xlen structs

define %struct.small @callee_small_struct_ret() {
; CHECK-LABEL: callee_small_struct_ret:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: addi a0, zero, 1
; CHECK: addi a1, zero, 0
  ret %struct.small { i32 1, i32* null }
}

define i32 @caller_small_struct_ret() {
; CHECK-LABEL: caller_small_struct_ret:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lui a0, %hi(callee_small_struct_ret)
; CHECK: addi a0, a0, %lo(callee_small_struct_ret)
; CHECK: jalr ra, a0, 0
; CHECK: add a0, a0, a1
; CHECK: lw s0, 8(sp)
; CHECK: lw ra, 12(sp)
; CHECK: addi sp, sp, 16
; CHECK: jalr zero, ra, 0
  %1 = call %struct.small @callee_small_struct_ret()
  %2 = extractvalue %struct.small %1, 0
  %3 = extractvalue %struct.small %1, 1
  %4 = ptrtoint i32* %3 to i32
  %5 = add i32 %2, %4
  ret i32 %5
}

; Check return of >2x xlen scalars

define fp128 @callee_large_scalar_ret() {
; CHECK-LABEL: callee_large_scalar_ret:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: lui a1, 524272
; CHECK: addi a1, a1, 0
; CHECK: sw a1, 12(a0)
; CHECK: sw zero, 8(a0)
; CHECK: sw zero, 4(a0)
; CHECK: sw zero, 0(a0)
; CHECK: jalr zero, ra, 0
  ret fp128 0xL00000000000000007FFF000000000000
}

define void @caller_large_scalar_ret() {
; CHECK-LABEL: caller_large_scalar_ret:
; CHECK: addi sp, sp, -32
; CHECK: sw ra, 28(sp)
; CHECK: sw s0, 24(sp)
; CHECK: addi s0, sp, 32
; CHECK: lui a0, %hi(callee_large_scalar_ret)
; CHECK: addi a1, a0, %lo(callee_large_scalar_ret)
; CHECK: addi a0, s0, -32
; CHECK: jalr ra, a1, 0
  %1 = call fp128 @callee_large_scalar_ret()
  ret void
}

; Check return of >2x xlen structs

define void @callee_large_struct_ret(%struct.large* noalias sret %agg.result) {
; CHECK-LABEL: callee_large_struct_ret:
; CHECK: addi sp, sp, -16
; CHECK: sw ra, 12(sp)
; CHECK: sw s0, 8(sp)
; CHECK: addi s0, sp, 16
; CHECK: addi a1, zero, 2
; CHECK: sw a1, 4(a0)
; CHECK: addi a1, zero, 1
; CHECK: sw a1, 0(a0)
; CHECK: addi a1, zero, 3
; CHECK: sw a1, 8(a0)
; CHECK: addi a1, zero, 4
; CHECK: sw a1, 12(a0)
  %a = getelementptr inbounds %struct.large, %struct.large* %agg.result, i32 0, i32 0
  store i32 1, i32* %a, align 4
  %b = getelementptr inbounds %struct.large, %struct.large* %agg.result, i32 0, i32 1
  store i32 2, i32* %b, align 4
  %c = getelementptr inbounds %struct.large, %struct.large* %agg.result, i32 0, i32 2
  store i32 3, i32* %c, align 4
  %d = getelementptr inbounds %struct.large, %struct.large* %agg.result, i32 0, i32 3
  store i32 4, i32* %d, align 4
  ret void
}

define i32 @caller_large_struct_ret() {
; CHECK-LABEL: caller_large_struct_ret:
; CHECK: addi sp, sp, -32
; CHECK: sw ra, 28(sp)
; CHECK: sw s0, 24(sp)
; CHECK: addi s0, sp, 32
; CHECK: lui a0, %hi(callee_large_struct_ret)
; CHECK: addi a1, a0, %lo(callee_large_struct_ret)
; CHECK: addi a0, s0, -24
; CHECK: jalr ra, a1, 0
; CHECK: lw a0, -12(s0)
; CHECK: lw a1, -24(s0)
; CHECK: add a0, a1, a0
; CHECK: lw s0, 24(sp)
; CHECK: lw ra, 28(sp)
; CHECK: addi sp, sp, 32
; CHECK: jalr zero, ra, 0
  %1 = alloca %struct.large
  call void @callee_large_struct_ret(%struct.large* sret %1)
  %2 = getelementptr inbounds %struct.large, %struct.large* %1, i32 0, i32 0
  %3 = load i32, i32* %2
  %4 = getelementptr inbounds %struct.large, %struct.large* %1, i32 0, i32 3
  %5 = load i32, i32* %4
  %6 = add i32 %3, %5
  ret i32 %6
}
