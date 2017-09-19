; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; FIXME: an unncessary register is allocated just to store 0. X0 should be
; used instead

define i8 @sext_i1_to_i8(i1 %a) {
; TODO: the addi that stores 0 in t1 is unnecessary
; CHECK-LABEL: sext_i1_to_i8
; CHECK: andi a0, a0, 1
; CHECK: addi a1, zero, 0
; CHECK: sub a0, a1, a0
  %1 = sext i1 %a to i8
  ret i8 %1
}

define i16 @sext_i1_to_i16(i1 %a) {
; TODO: the addi that stores 0 in t1 is unnecessary
; CHECK-LABEL: sext_i1_to_i16
; CHECK: andi a0, a0, 1
; CHECK: addi a1, zero, 0
; CHECK: sub a0, a1, a0
  %1 = sext i1 %a to i16
  ret i16 %1
}

define i32 @sext_i1_to_i32(i1 %a) {
; TODO: the addi that stores 0 in t1 is unnecessary
; CHECK-LABEL: sext_i1_to_i32
; CHECK: andi a0, a0, 1
; CHECK: addi a1, zero, 0
; CHECK: sub a0, a1, a0
  %1 = sext i1 %a to i32
  ret i32 %1
}

define i64 @sext_i1_to_i64(i1 %a) {
; TODO: the addi that stores 0 in t1 is unnecessary
; CHECK-LABEL: sext_i1_to_i64
; CHECK: andi a0, a0, 1
; CHECK: addi a1, zero, 0
; CHECK: sub a0, a1, a0
  %1 = sext i1 %a to i64
  ret i64 %1
}

define i16 @sext_i8_to_i16(i8 %a) {
; CHECK-LABEL: sext_i8_to_i16
; CHECK: slli a0, a0, 24
; CHECK: srai a0, a0, 24
  %1 = sext i8 %a to i16
  ret i16 %1
}

define i32 @sext_i8_to_i32(i8 %a) {
; CHECK-LABEL: sext_i8_to_i32
; CHECK: slli a0, a0, 24
; CHECK: srai a0, a0, 24
  %1 = sext i8 %a to i32
  ret i32 %1
}

define i64 @sext_i8_to_i64(i8 %a) {
; CHECK-LABEL: sext_i8_to_i64
; CHECK: slli a1, a0, 24
; CHECK: srai a0, a1, 24
; CHECK: srai a1, a1, 31
  %1 = sext i8 %a to i64
  ret i64 %1
}

define i32 @sext_i16_to_i32(i16 %a) {
; CHECK-LABEL: sext_i16_to_i32
; CHECK: slli a0, a0, 16
; CHECK: srai a0, a0, 16
  %1 = sext i16 %a to i32
  ret i32 %1
}

define i64 @sext_i16_to_i64(i16 %a) {
; CHECK-LABEL: sext_i16_to_i64
; CHECK: slli a1, a0, 16
; CHECK: srai a0, a1, 16
; CHECK: srai a1, a1, 31
  %1 = sext i16 %a to i64
  ret i64 %1
}

define i64 @sext_i32_to_i64(i32 %a) {
; CHECK-LABEL: sext_i32_to_i64
; CHECK: srai a1, a0, 31
  %1 = sext i32 %a to i64
  ret i64 %1
}

define i8 @zext_i1_to_i8(i1 %a) {
; CHECK-LABEL: zext_i1_to_i8
; CHECK: andi a0, a0, 1
  %1 = zext i1 %a to i8
  ret i8 %1
}

define i16 @zext_i1_to_i16(i1 %a) {
; CHECK-LABEL: zext_i1_to_i16
; CHECK: andi a0, a0, 1
  %1 = zext i1 %a to i16
  ret i16 %1
}

define i32 @zext_i1_to_i32(i1 %a) {
; CHECK-LABEL: zext_i1_to_i32
; CHECK: andi a0, a0, 1
  %1 = zext i1 %a to i32
  ret i32 %1
}

define i64 @zext_i1_to_i64(i1 %a) {
; CHECK-LABEL: zext_i1_to_i64
; CHECK: andi a0, a0, 1
; CHECK: addi a1, zero, 0
  %1 = zext i1 %a to i64
  ret i64 %1
}

define i16 @zext_i8_to_i16(i8 %a) {
; CHECK-LABEL: zext_i8_to_i16
; CHECK: andi a0, a0, 255
  %1 = zext i8 %a to i16
  ret i16 %1
}

define i32 @zext_i8_to_i32(i8 %a) {
; CHECK-LABEL: zext_i8_to_i32
; CHECK: andi a0, a0, 255
  %1 = zext i8 %a to i32
  ret i32 %1
}

define i64 @zext_i8_to_i64(i8 %a) {
; CHECK-LABEL: zext_i8_to_i64
; CHECK: andi a0, a0, 255
; CHECK: addi a1, zero, 0
  %1 = zext i8 %a to i64
  ret i64 %1
}

define i32 @zext_i16_to_i32(i16 %a) {
; CHECK-LABEL: zext_i16_to_i32
; CHECK: lui a1, 16
; CHECK: addi a1, a1, -1
; CHECK: and a0, a0, a1
  %1 = zext i16 %a to i32
  ret i32 %1
}

define i64 @zext_i16_to_i64(i16 %a) {
; CHECK-LABEL: zext_i16_to_i64
; CHECK: lui a1, 16
; CHECK: addi a1, a1, -1
; CHECK: and a0, a0, a1
; CHECK: addi a1, zero, 0
  %1 = zext i16 %a to i64
  ret i64 %1
}

define i64 @zext_i32_to_i64(i32 %a) {
; CHECK-LABEL: zext_i32_to_i64
; CHECK: addi a1, zero, 0
  %1 = zext i32 %a to i64
  ret i64 %1
}

; TODO: should the trunc tests explicitly ensure no code is generated before
; jalr?

define i1 @trunc_i8_to_i1(i8 %a) {
; CHECK-LABEL: trunc_i8_to_i1
  %1 = trunc i8 %a to i1
  ret i1 %1
}

define i1 @trunc_i16_to_i1(i16 %a) {
; CHECK-LABEL: trunc_i16_to_i1
  %1 = trunc i16 %a to i1
  ret i1 %1
}

define i1 @trunc_i32_to_i1(i32 %a) {
; CHECK-LABEL: trunc_i32_to_i1
  %1 = trunc i32 %a to i1
  ret i1 %1
}

define i1 @trunc_i64_to_i1(i64 %a) {
; CHECK-LABEL: trunc_i64_to_i1
  %1 = trunc i64 %a to i1
  ret i1 %1
}

define i8 @trunc_i16_to_i8(i16 %a) {
; CHECK-LABEL: trunc_i16_to_i8
  %1 = trunc i16 %a to i8
  ret i8 %1
}

define i8 @trunc_i32_to_i8(i32 %a) {
; CHECK-LABEL: trunc_i32_to_i8
  %1 = trunc i32 %a to i8
  ret i8 %1
}

define i8 @trunc_i64_to_i8(i64 %a) {
; CHECK-LABEL: trunc_i64_to_i8
  %1 = trunc i64 %a to i8
  ret i8 %1
}

define i16 @trunc_i32_to_i16(i32 %a) {
; CHECK-LABEL: trunc_i32_to_i16
  %1 = trunc i32 %a to i16
  ret i16 %1
}

define i16 @trunc_i64_to_i16(i64 %a) {
; CHECK-LABEL: trunc_i64_to_i16
  %1 = trunc i64 %a to i16
  ret i16 %1
}

define i32 @trunc_i64_to_i32(i64 %a) {
; CHECK-LABEL: trunc_i64_to_i32
  %1 = trunc i64 %a to i32
  ret i32 %1
}
