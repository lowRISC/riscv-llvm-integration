; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; TODO: check the generated instructions for the equivalent of seqz, snez, sltz, sgtz map to something simple

define i32 @eq(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: eq:
; CHECK: xor a0, a0, a1
; CHECK: sltiu a0, a0, 1
  %1 = icmp eq i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @ne(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: ne:
; CHECK: xor a0, a0, a1
; CHECK: sltu a0, zero, a0
  %1 = icmp ne i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @ugt(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: ugt:
; CHECK: sltu a0, a1, a0
  %1 = icmp ugt i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @uge(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: uge:
; CHECK: sltu a0, a0, a1
; CHECK: xori a0, a0, 1
  %1 = icmp uge i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @ult(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: ult:
; CHECK: sltu a0, a0, a1
  %1 = icmp ult i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @ule(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: ule:
; CHECK: sltu a0, a1, a0
; CHECK: xori a0, a0, 1
  %1 = icmp ule i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @sgt(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sgt:
; CHECK: slt a0, a1, a0
  %1 = icmp sgt i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @sge(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sge:
; CHECK: slt a0, a0, a1
; CHECK: xori a0, a0, 1
  %1 = icmp sge i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @slt(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: slt:
; CHECK: slt a0, a0, a1
  %1 = icmp slt i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

define i32 @sle(i32 %a, i32 %b) nounwind {
; CHECK-LABEL: sle:
; CHECK: slt a0, a1, a0
; CHECK: xori a0, a0, 1
  %1 = icmp sle i32 %a, %b
  %2 = zext i1 %1 to i32
  ret i32 %2
}

; TODO: check variants with an immediate?
