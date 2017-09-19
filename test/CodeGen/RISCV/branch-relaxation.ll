; RUN: llc -mtriple=riscv32 -verify-machineinstrs -filetype=obj < %s \
; RUN:   -o /dev/null 2>&1 | FileCheck %s -check-prefix=MCCHECK -allow-empty
; RUN: llc -mtriple=riscv32 -verify-machineinstrs < %s | FileCheck %s

; MCCHECK-NOT: fixup value out of range

define void @relax_bcc(i1 %a) {
; CHECK-LABEL: relax_bcc:
  br i1 %a, label %iftrue, label %tail

iftrue:
  call void asm sideeffect ".space 4096", ""()
  br label %tail

tail:
  ret void
}

define i32 @relax_jal(i1 %a) {
; CHECK-LABEL: relax_jal:
  br i1 %a, label %iftrue, label %jmp

jmp:
  call void asm sideeffect "", ""()
  br label %tail

iftrue:
  call void asm sideeffect "", ""()
  br label %space

space:
  call void asm sideeffect ".space 1048576", ""()
  br label %tail

tail:
  ret i32 1
}
