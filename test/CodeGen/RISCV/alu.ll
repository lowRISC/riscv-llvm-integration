; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; Register-immediate instructions

define i32 @addi(i32 %a) nounwind {
; CHECK-LABEL: addi:
; CHECK: addi a0, a0, 1
; CHECK: jalr zero, ra, 0
; TODO: check support for materialising larger constants
  %1 = add i32 %a, 1
  ret i32 %1
}

define i32 @slti(i32 %a) nounwind {
; CHECK-LABEL: slti:
; CHECK: slti a0, a0, 2
; CHECK: jalr zero, ra, 0
  %1 = icmp slt i32 %a, 2
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @sltiu(i32 %a) nounwind {
; CHECK-LABEL: sltiu:
; CHECK: sltiu a0, a0, 3
; CHECK: jalr zero, ra, 0
  %1 = icmp ult i32 %a, 3
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @xori(i32 %a) nounwind {
; CHECK-LABEL: xori:
; CHECK: xori a0, a0, 4
; CHECK: jalr zero, ra, 0
  %1 = xor i32 %a, 4
  ret i32 %1
}

define i32 @ori(i32 %a) nounwind {
; CHECK-LABEL: ori:
; CHECK: ori a0, a0, 5
; CHECK: jalr zero, ra, 0
  %1 = or i32 %a, 5
  ret i32 %1
}

define i32 @andi(i32 %a) nounwind {
; CHECK-LABEL: andi:
; CHECK: andi a0, a0, 6
; CHECK: jalr zero, ra, 0
  %1 = and i32 %a, 6
  ret i32 %1
}

define i32 @slli(i32 %a) nounwind {
; CHECK-LABEL: slli:
; CHECK: slli a0, a0, 7
; CHECK: jalr zero, ra, 0
  %1 = shl i32 %a, 7
  ret i32 %1
}

define i32 @srli(i32 %a) nounwind {
; CHECK-LABEL: srli:
; CHECK: srli a0, a0, 8
; CHECK: jalr zero, ra, 0
  %1 = lshr i32 %a, 8
  ret i32 %1
}

define i32 @srai(i32 %a) nounwind {
; CHECK-LABEL: srai:
; CHECK: srai a0, a0, 9
; CHECK: jalr zero, ra, 0
  %1 = ashr i32 %a, 9
  ret i32 %1
}

; Register-register instructions

define i32 @add(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: add:
; CHECK: add a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = add i32 %a, %b
  ret i32 %1
}

define i32 @sub(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sub:
; CHECK: sub a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = sub i32 %a, %b
  ret i32 %1
}

define i32 @sll(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sll:
; CHECK: sll a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = shl i32 %a, %b
  ret i32 %1
}

define i32 @slt(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: slt:
; CHECK: slt a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = icmp slt i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @sltu(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sltu:
; CHECK: sltu a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = icmp ult i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @xor(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: xor:
; CHECK: xor a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = xor i32 %a, %b
  ret i32 %1
}

define i32 @srl(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: srl:
; CHECK: srl a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = lshr i32 %a, %b
  ret i32 %1
}

define i32 @sra(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sra:
; CHECK: sra a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = ashr i32 %a, %b
  ret i32 %1
}

define i32 @or(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: or:
; CHECK: or a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = or i32 %a, %b
  ret i32 %1
}

define i32 @and(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: and:
; CHECK: and a0, a0, a1
; CHECK: jalr zero, ra, 0
  %1 = and i32 %a, %b
  ret i32 %1
}

; Materialize constants

define i32 @zero() {
; CHECK-LABEL: zero:
; CHECK: addi a0, zero, 0
; CHECK: jalr zero, ra, 0
  ret i32 0
}

define i32 @pos_small() {
; CHECK-LABEL: pos_small:
; CHECK: addi a0, zero, 2047
; CHECK: jalr zero, ra, 0
  ret i32 2047
}

define i32 @neg_small() {
; CHECK-LABEL: neg_small:
; CHECK: addi a0, zero, -2048
; CHECK: jalr zero, ra, 0
  ret i32 -2048
}

define i32 @pos_i32() {
; CHECK-LABEL: pos_i32:
; CHECK: lui [[REG:[a-z0-9]+]], 423811
; CHECK: addi a0, [[REG]], -1297
; CHECK: jalr zero, ra, 0
  ret i32 1735928559
}

define i32 @neg_i32() {
; CHECK-LABEL: neg_i32:
; CHECK: lui [[REG:[a-z0-9]+]], 912092
; CHECK: addi a0, [[REG]], -273
; CHECK: jalr zero, ra, 0
  ret i32 -559038737
}
