; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

%struct.Foo = type { i32, i32, i32, i16, i8 }
@foo = global %struct.Foo { i32 1, i32 2, i32 3, i16 4, i8 5 }, align 4

define i32 @callee(%struct.Foo* byval %f) nounwind {
entry:
; CHECK-LABEL: callee:
; CHECK: lw a0, 0(a0)
  %0 = getelementptr inbounds %struct.Foo, %struct.Foo* %f, i32 0, i32 0
  %1 = load i32, i32* %0, align 4
  ret i32 %1
}


define void @caller() nounwind {
entry:
; CHECK-LABEL: caller:
; CHECK: lui a0, %hi(foo)
; CHECK: addi a0, a0, %lo(foo)
; CHECK: lw a0, 0(a0)
; CHECK: sw a0, -24(s0)
; CHECK: addi a0, s0, -24
; CHECK-NEXT: jalr
  %call = call i32 @callee(%struct.Foo* byval @foo)
  ret void
}
