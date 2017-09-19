; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

define void @jt(i32 %in, i32* %out) {
; CHECK-LABEL: jt:
entry:
  switch i32 %in, label %exit [
    i32 1, label %bb1
    i32 2, label %bb2
    i32 3, label %bb3
    i32 4, label %bb4
  ]
bb1:
  store i32 4, i32* %out
  br label %exit
bb2:
  store i32 3, i32* %out
  br label %exit
bb3:
  store i32 2, i32* %out
  br label %exit
bb4:
  store i32 1, i32* %out
  br label %exit
exit:
  ret void
}
