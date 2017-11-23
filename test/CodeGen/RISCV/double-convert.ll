; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -mattr=+d -verify-machineinstrs < %s \
; RUN:   | FileCheck -check-prefix=RV32IFD %s

define float @fcvt_s_d(double %a) nounwind {
; RV32IFD-LABEL: fcvt_s_d:
; RV32IFD:       # BB#0:
; RV32IFD-NEXT:    addi sp, sp, -16
; RV32IFD-NEXT:    sw a1, 12(sp)
; RV32IFD-NEXT:    sw a0, 8(sp)
; RV32IFD-NEXT:    fld ft0, 8(sp)
; RV32IFD-NEXT:    fcvt.s.d ft0, ft0
; RV32IFD-NEXT:    fmv.x.w a0, ft0
; RV32IFD-NEXT:    addi sp, sp, 16
; RV32IFD-NEXT:    jalr zero, ra, 0
  %1 = fptrunc double %a to float
  ret float %1
}

define double @fcvt_d_s(float %a) nounwind {
; RV32IFD-LABEL: fcvt_d_s:
; RV32IFD:       # BB#0:
; RV32IFD-NEXT:    addi sp, sp, -16
; RV32IFD-NEXT:    fmv.w.x ft0, a0
; RV32IFD-NEXT:    fcvt.d.s ft0, ft0
; RV32IFD-NEXT:    fsd ft0, 8(sp)
; RV32IFD-NEXT:    lw a0, 8(sp)
; RV32IFD-NEXT:    lw a1, 12(sp)
; RV32IFD-NEXT:    addi sp, sp, 16
; RV32IFD-NEXT:    jalr zero, ra, 0
  %1 = fpext float %a to double
  ret double %1
}

define i32 @fcvt_w_d(double %a) nounwind {
; RV32IFD-LABEL: fcvt_w_d:
; RV32IFD:       # BB#0:
; RV32IFD-NEXT:    addi sp, sp, -16
; RV32IFD-NEXT:    sw a1, 12(sp)
; RV32IFD-NEXT:    sw a0, 8(sp)
; RV32IFD-NEXT:    fld ft0, 8(sp)
; RV32IFD-NEXT:    fcvt.w.d a0, ft0, rtz
; RV32IFD-NEXT:    addi sp, sp, 16
; RV32IFD-NEXT:    jalr zero, ra, 0
  %1 = fptosi double %a to i32
  ret i32 %1
}

define i32 @fcvt_wu_d(double %a) nounwind {
; RV32IFD-LABEL: fcvt_wu_d:
; RV32IFD:       # BB#0:
; RV32IFD-NEXT:    addi sp, sp, -16
; RV32IFD-NEXT:    sw a1, 12(sp)
; RV32IFD-NEXT:    sw a0, 8(sp)
; RV32IFD-NEXT:    fld ft0, 8(sp)
; RV32IFD-NEXT:    fcvt.wu.d a0, ft0, rtz
; RV32IFD-NEXT:    addi sp, sp, 16
; RV32IFD-NEXT:    jalr zero, ra, 0
  %1 = fptoui double %a to i32
  ret i32 %1
}

define double @fcvt_d_w(i32 %a) nounwind {
; RV32IFD-LABEL: fcvt_d_w:
; RV32IFD:       # BB#0:
; RV32IFD-NEXT:    addi sp, sp, -16
; RV32IFD-NEXT:    fcvt.d.w ft0, a0
; RV32IFD-NEXT:    fsd ft0, 8(sp)
; RV32IFD-NEXT:    lw a0, 8(sp)
; RV32IFD-NEXT:    lw a1, 12(sp)
; RV32IFD-NEXT:    addi sp, sp, 16
; RV32IFD-NEXT:    jalr zero, ra, 0
  %1 = sitofp i32 %a to double
  ret double %1
}

define double @fcvt_d_wu(i32 %a) nounwind {
; RV32IFD-LABEL: fcvt_d_wu:
; RV32IFD:       # BB#0:
; RV32IFD-NEXT:    addi sp, sp, -16
; RV32IFD-NEXT:    fcvt.d.wu ft0, a0
; RV32IFD-NEXT:    fsd ft0, 8(sp)
; RV32IFD-NEXT:    lw a0, 8(sp)
; RV32IFD-NEXT:    lw a1, 12(sp)
; RV32IFD-NEXT:    addi sp, sp, 16
; RV32IFD-NEXT:    jalr zero, ra, 0
  %1 = uitofp i32 %a to double
  ret double %1
}
