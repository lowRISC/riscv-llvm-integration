; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefix=RV32I %s

@gi = external global i32

define i32 @constraint_r(i32 %a) {
; RV32I-LABEL: constraint_r:
; RV32I:       # BB#0:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw ra, 12(sp)
; RV32I-NEXT:    sw s0, 8(sp)
; RV32I-NEXT:    addi s0, sp, 16
; RV32I-NEXT:    lui a1, %hi(gi)
; RV32I-NEXT:    addi a1, a1, %lo(gi)
; RV32I-NEXT:    lw a1, 0(a1)
; RV32I-NEXT:    #APP
; RV32I-NEXT:    add a0, a0, a1
; RV32I-NEXT:    #NO_APP
; RV32I-NEXT:    lw s0, 8(sp)
; RV32I-NEXT:    lw ra, 12(sp)
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    jalr zero, ra, 0
  %1 = load i32, i32* @gi
  %2 = tail call i32 asm "add $0, $1, $2", "=r,r,r"(i32 %a, i32 %1)
  ret i32 %2
}

define i32 @constraint_i(i32 %a) {
; RV32I-LABEL: constraint_i:
; RV32I:       # BB#0:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw ra, 12(sp)
; RV32I-NEXT:    sw s0, 8(sp)
; RV32I-NEXT:    addi s0, sp, 16
; RV32I-NEXT:    #APP
; RV32I-NEXT:    addi a0, a0, 113
; RV32I-NEXT:    #NO_APP
; RV32I-NEXT:    lw s0, 8(sp)
; RV32I-NEXT:    lw ra, 12(sp)
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    jalr zero, ra, 0
  %1 = load i32, i32* @gi
  %2 = tail call i32 asm "addi $0, $1, $2", "=r,r,i"(i32 %a, i32 113)
  ret i32 %2
}

define void @constraint_m(i32* %a) {
; RV32I-LABEL: constraint_m:
; RV32I:       # BB#0:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw ra, 12(sp)
; RV32I-NEXT:    sw s0, 8(sp)
; RV32I-NEXT:    addi s0, sp, 16
; RV32I-NEXT:    #APP
; RV32I-NEXT:    #NO_APP
; RV32I-NEXT:    lw s0, 8(sp)
; RV32I-NEXT:    lw ra, 12(sp)
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    jalr zero, ra, 0
  call void asm sideeffect "", "=*m"(i32* %a)
  ret void
}

define i32 @constraint_m2(i32* %a) {
; RV32I-LABEL: constraint_m2:
; RV32I:       # BB#0:
; RV32I-NEXT:    addi sp, sp, -16
; RV32I-NEXT:    sw ra, 12(sp)
; RV32I-NEXT:    sw s0, 8(sp)
; RV32I-NEXT:    addi s0, sp, 16
; RV32I-NEXT:    #APP
; RV32I-NEXT:    lw a0, 0(a0)
; RV32I-NEXT:    #NO_APP
; RV32I-NEXT:    lw s0, 8(sp)
; RV32I-NEXT:    lw ra, 12(sp)
; RV32I-NEXT:    addi sp, sp, 16
; RV32I-NEXT:    jalr zero, ra, 0
  %1 = tail call i32 asm "lw $0, $1", "=r,*m"(i32* %a) nounwind
  ret i32 %1
}

; TODO: expend tests for more complex constraints, out of range immediates etc
