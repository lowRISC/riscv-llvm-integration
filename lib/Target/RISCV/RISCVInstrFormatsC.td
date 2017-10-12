//===-- RISCVInstrFormatsC.td - RISCV C Instruction Formats --*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//  This file describes the RISC-V C extension instruction formats.
//
//===----------------------------------------------------------------------===//

class RV16Inst<dag outs, dag ins, string asmstr, list<dag> pattern,
                  InstFormat format>
    : Instruction {
  field bits<16> Inst;
  // SoftFail is a field the disassembler can use to provide a way for
  // instructions to not match without killing the whole decode process. It is
  // mainly used for ARM, but Tablegen expects this field to exist or it fails
  // to build the decode table.
  field bits<16> SoftFail = 0;
  let Size = 2;

  bits<2> Opcode = 0;

  let Namespace = "RISCV";

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;

  let TSFlags{3-0} = format.Value;
}

class CR<bits<4> funct4, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatC> {
  bits<5> rs1;
  bits<5> rs2;

  let Inst{15-12} = funct4;
  let Inst{11-7} = rs1;
  let Inst{6-2} = rs2;
  let Inst{1-0} = opcode;
}

class CI<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatC> {
  bits<10> imm;
  bits<5> rd;
  bits<5> rs1;

  let Inst{15-13} = funct3;
  let Inst{12} = imm{5};
  let Inst{11-7} = rd;
  let Inst{1-0} = opcode;
}

class CSS<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
          string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatC> {
  bits<10> imm;
  bits<5> rs2;
  bits<5> rs1;

  let Inst{15-13} = funct3;
  let Inst{6-2} = rs2;
  let Inst{1-0} = opcode;
}

class CIW<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatC> {
  bits<10> imm;
  bits<3> rd;

  let Inst{15-13} = funct3;
  let Inst{4-2} = rd;
  let Inst{1-0} = opcode;
}

class CL<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatC> {
  bits<3> rd;
  bits<3> rs1;

  let Inst{15-13} = funct3;
  let Inst{9-7} = rs1;
  let Inst{4-2} = rd;
  let Inst{1-0} = opcode;
}

class CS<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatC> {
  bits<3> rs2;
  bits<3> rs1;

  let Inst{15-13} = funct3;
  let Inst{9-7} = rs1;
  let Inst{4-2} = rs2;
  let Inst{1-0} = opcode;
}

class CB<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatCB> {
  bits<9> imm;
  bits<3> rs1;

  let Inst{15-13} = funct3;
  let Inst{9-7} = rs1;
  let Inst{1-0} = opcode;
}

class CJ<bits<3> funct3, bits<2> opcode, dag outs, dag ins,
         string asmstr>
    : RV16Inst<outs, ins, asmstr, [], InstFormatCJ> {
  bits<12> offset;

  let Inst{15-13} = funct3;
  let Inst{12} = offset{11};
  let Inst{11} = offset{4};
  let Inst{10-9} = offset{9-8};
  let Inst{8} = offset{10};
  let Inst{7} = offset{6};
  let Inst{6} = offset{7};
  let Inst{5-3} = offset{3-1};
  let Inst{2} = offset{5};
  let Inst{1-0} = opcode;
}
