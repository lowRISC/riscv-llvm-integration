; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define void @foo(i32 %a, i32 *%b, i1 %c) {
; CHECK-LABEL: foo:

  %val1 = load volatile i32, i32* %b
  %tst1 = icmp eq i32 %val1, %a
  br i1 %tst1, label %end, label %test2
; CHECK: beq {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test2:
  %val2 = load volatile i32, i32* %b
  %tst2 = icmp ne i32 %val2, %a
  br i1 %tst2, label %end, label %test3
; CHECK: bne {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test3:
  %val3 = load volatile i32, i32* %b
  %tst3 = icmp slt i32 %val3, %a
  br i1 %tst3, label %end, label %test4
; CHECK: blt {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test4:
  %val4 = load volatile i32, i32* %b
  %tst4 = icmp sge i32 %val4, %a
  br i1 %tst4, label %end, label %test5
; CHECK: bge {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test5:
  %val5 = load volatile i32, i32* %b
  %tst5 = icmp ult i32 %val5, %a
  br i1 %tst5, label %end, label %test6
; CHECK: bltu {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test6:
  %val6 = load volatile i32, i32* %b
  %tst6 = icmp uge i32 %val6, %a
  br i1 %tst6, label %end, label %test7
; CHECK: bgeu {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

; Check for condition codes that don't have a matching instruction

test7:
  %val7 = load volatile i32, i32* %b
  %tst7 = icmp sgt i32 %val7, %a
  br i1 %tst7, label %end, label %test8
; CHECK: blt {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test8:
  %val8 = load volatile i32, i32* %b
  %tst8 = icmp sle i32 %val8, %a
  br i1 %tst8, label %end, label %test9
; CHECK: bge {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test9:
  %val9 = load volatile i32, i32* %b
  %tst9 = icmp ugt i32 %val9, %a
  br i1 %tst9, label %end, label %test10
; CHECK: bltu {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

test10:
  %val10 = load volatile i32, i32* %b
  %tst10 = icmp ule i32 %val10, %a
  br i1 %tst10, label %end, label %test11
; CHECK: bgeu {{[a-z0-9]+}}, {{[a-z0-9]+}}, .LBB

; Check the case of a branch where the condition was generated in another
; function

test11:
; CHECK: andi {{[a-z0-9]+}}, {{[a-z0-9]+}}, 1
; CHECK: bne {{[a-z0-9]+}}, zero, .LBB
  %val11 = load volatile i32, i32* %b
  br i1 %c, label %end, label %test12

test12:
  %val12 = load volatile i32, i32* %b
; CHECK: jalr zero, ra, 0
  br label %end

end:
  ret void
}
