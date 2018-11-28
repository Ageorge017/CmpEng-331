`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2018 04:48:42 PM
// Design Name: 
// Module Name: Lab4_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ConnectWires(clk, IFETCH, IDECODE, IEXECUTE, IMEMORY);
  input clk;
  output reg [31:0] IFETCH, IDECODE, IEXECUTE, IMEMORY;
  wire [31:0] pc_in, pc_out, im_out, ifid_out, qa_out, qb_out, extend_out, eqa_out, eqb_out, eimmext_out, alumux_out,alu_out, e2mALU, QB2DM, DM_OUT;
  wire [3:0]aluc_out, ealuc_out;
  wire wreg_out, m2reg_out, wmem_out, aluImm_out, regRt_out, ewreg_out, em2reg_out, ewmem_out, ealuimm_out,e2mWREG, e2mM2REG, wMemDM;
  wire [4:0] regMux_out, eregmux_out, e2mMUX;

  ProgramCounter PC (.clock(clk), .PC_IN(pc_in), .PC_OUT(pc_out)); //ProgramCounter (clock, PC_IN, PC_OUT);
  PC_adder PCadder(.PC(pc_out), .PC_Plus(pc_in)); //PC_adder(PC, PC_Plus); 
  instructionMemory IM(.instructionAddress(pc_out), .instruction(im_out)); //instructionMemory(instructionAddress, instruction)

  IF_ID fetchDecode (.clock(clk), .INSTRUCTION_in(im_out), .INSTRUCTION_out(ifid_out)); //IF_ID(clock, INSTRUCTION_in, INSTRUCTION_out);

  ControlUnit CU(.instruction_CU(ifid_out), .wreg(wreg_out), .mem2reg(m2reg_out), .wmem(wmem_out), .aluc(aluc_out), .aluImm(aluImm_out), .regRt(regRt_out) ); //ControlUnit(instruction_CU, wreg, mem2reg,wmem, aluc, aluImm, regRt);
  MuxRegRt regMux (.instruction_MUX(ifid_out), .RegRT(regRt_out), .RTRD(regMux_out) ); //MuxRegRt(instruction_MUX, RegRT, RTRD);
  RegisterFile RegFile(.instruction_RF(ifid_out), .RS_OUT(qa_out), .RT_OUT(qb_out)); //RegisterFile(instruction_RF, RS_OUT, RT_OUT);
  ImmediateField ImmF(.instruction_IF(ifid_out), .Extended(extend_out)); //ImmediateField(instruction_IF, Extended);
 
  ID_EXE decodeExec(.clock(clk), 
   .WREG(wreg_out), .M2REG(m2reg_out), .WMEM(wmem_out), .ALUC(aluc_out), .ALUIMM(aluImm_out), .MUX(regMux_out), .QA(qa_out), .QB(qb_out), .IMMEXT(extend_out), 
   .WREG_OUT(ewreg_out), .M2REG_OUT(em2reg_out), .WMEM_OUT(ewmem_out), .ALUC_OUT(ealuc_out), .ALUIMM_OUT(ealuimm_out), .MUX_OUT(eregmux_out), .QA_OUT(eqa_out), .QB_OUT(eqb_out), .IMMEXT_OUT(eimmext_out)); 
                    //clock, WREG, M2REG, WMEM, ALUC, ALUIMM, MUX, QA, QB, IMMEXT, /////////////////////////WREG_OUT, M2REG_OUT,WMEM_OUT, ALUC_OUT,ALUIMM_OUT, MUX_OUT, QA_OUT, QB_OUT, IMMEXT_OUT
  
  AluMux aluMultiplexor(.aluImm_out(ealuimm_out), .qb(eqb_out), .immExt(eimmext_out), .alu_b(alumux_out)); //aluImm_out,qb, immExt, alu_b
  ALU aluDevice(.ALUcontrol(ealuc_out), .a(eqa_out), .b(alumux_out), .ALU_OUT(alu_out)); //ALUcontrol,a , b, ALU_OUT)
 
  EXE_MEM executeMemory (.clock(clk), 
  .eWREG(ewreg_out), .eM2REG(em2reg_out), .eWMEM(ewmem_out), .eMUX(eregmux_out), .eALU_OUT(alu_out), .eQB(eqb_out), 
  .eWREG_out(e2mWREG), .eM2REG_out(e2mM2REG), .eWMEM_out(wMemDM), .eMUX_out(e2mMUX), .eALU_out(e2mALU), .eQB_out(QB2DM) );
  //clock, eWREG, eM2REG, eWMEM, eMUX, eALU_OUT, eQB, eWREG_out, eM2REG_out, eWMEM_out, eMUX_out, eALU_out, eQB_out
  

  DataMemory DM( .MEMWRITE(wMemDM), .ALUDATA_IN(e2mALU), .QBDATA_IN(QB2DM), .DMDATA_OUT(DM_OUT) ); //MEMWRITE, ALUDATA_IN ,QBDATA_IN, DMDATA_OUT

  MEM_WB memoryWriteback ( .clock(clk), .mWREG(e2mWREG), .mM2REG(e2mM2REG), .mMUX(e2mMUX), .mALU(e2mALU), .mDM(DM_OUT) );// clock, mWREG, mM2REG, mMUX, mALU,mDM 

  always @ (posedge clk) begin
    IFETCH <= im_out;
    IDECODE <= IFETCH;
    IEXECUTE <= IDECODE;
    IMEMORY <= IEXECUTE;
  end
endmodule


module Lab4_tb();
  reg clock;
  wire [31:0] ifetch_tb, idecode_tb, iexecute_tb, imemory_tb;

  always
  begin
   #5 clock = ~clock;
  end
  
  ConnectWires connectwires_tb(.clk(clock), .IFETCH(ifetch_tb), .IDECODE(idecode_tb), .IEXECUTE(iexecute_tb), .IMEMORY(imemory_tb));
  initial begin
    clock = 0;
  end
  
endmodule

