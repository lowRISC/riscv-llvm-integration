; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define i32 @foo(i32 %a, i32 *%b) {
; CHECK-LABEL: foo:
; CHECK: beq a0, a2, .LBB{{.+}}
  %val1 = load volatile i32, i32* %b
  %tst1 = icmp eq i32 %a, %val1
  %val2 = select i1 %tst1, i32 %a, i32 %val1

; CHECK: bne a0, a2, .LBB{{.+}}
  %val3 = load volatile i32, i32* %b
  %tst2 = icmp ne i32 %val2, %val3
  %val4 = select i1 %tst2, i32 %val2, i32 %val3

; CHECK: bltu a2, a0, .LBB{{.+}}
  %val5 = load volatile i32, i32* %b
  %tst3 = icmp ugt i32 %val4, %val5
  %val6 = select i1 %tst3, i32 %val4, i32 %val5

; CHECK: bgeu a0, a2, .LBB{{.+}}
  %val7 = load volatile i32, i32* %b
  %tst4 = icmp uge i32 %val6, %val7
  %val8 = select i1 %tst4, i32 %val6, i32 %val7

; CHECK: bltu a0, a2, .LBB{{.+}}
  %val9 = load volatile i32, i32* %b
  %tst5 = icmp ult i32 %val8, %val9
  %val10 = select i1 %tst5, i32 %val8, i32 %val9

; CHECK: bgeu a2, a0, .LBB{{.+}}
  %val11 = load volatile i32, i32* %b
  %tst6 = icmp ule i32 %val10, %val11
  %val12 = select i1 %tst6, i32 %val10, i32 %val11

; CHECK: blt a2, a0, .LBB{{.+}}
  %val13 = load volatile i32, i32* %b
  %tst7 = icmp sgt i32 %val12, %val13
  %val14 = select i1 %tst7, i32 %val12, i32 %val13

; CHECK: bge a0, a2, .LBB{{.+}}
  %val15 = load volatile i32, i32* %b
  %tst8 = icmp sge i32 %val14, %val15
  %val16 = select i1 %tst8, i32 %val14, i32 %val15

; CHECK: blt a0, a2, .LBB{{.+}}
  %val17 = load volatile i32, i32* %b
  %tst9 = icmp slt i32 %val16, %val17
  %val18 = select i1 %tst9, i32 %val16, i32 %val17

; CHECK: bge a1, a0, .LBB{{.+}}
  %val19 = load volatile i32, i32* %b
  %tst10 = icmp sle i32 %val18, %val19
  %val20 = select i1 %tst10, i32 %val18, i32 %val19

  ret i32 %val20
}
