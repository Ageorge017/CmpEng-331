`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2018 04:44:26 PM
// Design Name: 
// Module Name: ProgramCounter
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

module ProgramCounter(clock, PC_IN, PC_OUT);
    input clock;
    input [31:0]PC_IN;
    reg[31:0] PCMEM;
    output reg [31:0]PC_OUT;
     
     initial begin
        PC_OUT = 0;
        PCMEM = 100;
     end
    always @ (posedge clock) begin
        PCMEM <= PC_IN;
    end
    
    always @ (negedge clock) begin
        PC_OUT <= PCMEM;
    end    
endmodule

module PC_adder(PC, PC_Plus); 
    input [31:0]PC;
    output reg [31:0]PC_Plus;
    initial begin
        PC_Plus <= 0;
    end
    
    always @(PC) begin
        PC_Plus <= PC + 4;
    end
endmodule

module instructionMemory(instructionAddress, instruction);
    input [31:0]instructionAddress;
    output reg [31:0]instruction;
    reg [31:0] IM[0:511];
    
    initial begin
        IM[32'd100] = 32'h8c220000;
        IM[32'd104] = 32'h8c230004;
        IM[32'd108] = 32'h8c240008;
        IM[32'd112] = 32'h8c25000C;
    end
    always @ (instructionAddress) begin
        instruction <= IM[instructionAddress];
    end   
endmodule

module IF_ID(clock, INSTRUCTION_in, INSTRUCTION_out);
    input clock;
    input [31:0]INSTRUCTION_in;
    reg [31:0]IF;
    output reg [31:0]INSTRUCTION_out;
    
    always @ (posedge clock) begin
        IF <= INSTRUCTION_in;
    end
    always @(negedge clock)begin
        INSTRUCTION_out <= IF;
    end
endmodule

module ControlUnit(instruction_CU, wreg, mem2reg,wmem, aluc, aluImm, regRt);
    input [31:0]instruction_CU;
    wire [5:0]op, func;
    output reg wreg, mem2reg,wmem, aluImm, regRt;
    output reg [3:0]aluc;
    
    assign op = instruction_CU[31:26];
    
    always @ (op)begin
        case(op) 
            6'b100011: begin
                wreg <= 1'b1;
                mem2reg <= 1'b1;
                wmem <= 1'b0;
                aluc <= 4'b0010;
                aluImm <= 1'b1;
                regRt <= 1'b1;
            end
              
        endcase
    end   
endmodule


module MuxRegRt(instruction_MUX, RegRT, RTRD);
    input [31:0]instruction_MUX;
    input RegRT;
    output reg [4:0]RTRD;
    wire [4:0]rd, rt;
    
    assign rd = instruction_MUX[15:11];
    assign rt = instruction_MUX[20:16];
    
    always @ (rd,rt) begin
        case(RegRT) 
            1'b1: RTRD = rt;
    
            1'b0: RTRD = rd;
        endcase
    end
endmodule

module RegisterFile(instruction_RF, RS_OUT, RT_OUT);
    input [31:0]instruction_RF;
    reg [31:0]registers[31:0]; 
    integer i;
    wire [4:0]Rs, Rt;
    output reg [31:0]RS_OUT, RT_OUT;
    
    assign Rs = instruction_RF[25:21];
    assign Rt = instruction_RF[20:16];
    
   initial for(i = 0; i < 32; i=i+1) begin
       registers[i] = 32'h00000000;
   end 

    always @(Rs , Rt)begin
        RS_OUT <= registers[Rs];
        RT_OUT <= registers[Rt];
    end 
endmodule

module ImmediateField(instruction_IF, Extended);
    input [31:0] instruction_IF;
    output reg [31:0]Extended;
    wire [15:0]imm;
    
    assign imm = instruction_IF[15:0];
    
    always @(imm)begin
        Extended = {{16{imm[15]}}, imm};
    end
    
endmodule

module ID_EXE(clock, WREG, M2REG, WMEM, ALUC, ALUIMM, MUX, QA, QB, IMMEXT, WREG_OUT, M2REG_OUT,WMEM_OUT, ALUC_OUT,ALUIMM_OUT, MUX_OUT, QA_OUT, QB_OUT, IMMEXT_OUT);
    input clock;
    input WREG, M2REG, WMEM, ALUIMM;
    input [4:0] MUX;
    input  [3:0] ALUC;
    input [31:0]IMMEXT, QA, QB;
    
    reg Wreg, M2reg, Wmem, Aluimm;
    reg[4:0] Mux;
    reg[3:0] Aluc;
    reg [31:0] Qa, Qb, Immext;

    output reg WREG_OUT, M2REG_OUT, WMEM_OUT, ALUIMM_OUT;
    output reg [3:0]ALUC_OUT;
    output reg [4:0]MUX_OUT;
    output reg [31:0] IMMEXT_OUT, QA_OUT, QB_OUT;
    
    always @ (posedge clock) begin
        Wreg <= WREG;
        M2reg <= M2REG;
        Wmem <= WMEM;
        Aluimm <= ALUIMM;
        Mux <= MUX;
        Aluc <= ALUC;
        Qa <= QA;
        Qb <= QB;
        Immext <= IMMEXT;
        
    end

    always @ (negedge clock) begin
        WREG_OUT <= Wreg;
        M2REG_OUT <= M2reg;
        WMEM_OUT <= Wmem;
        ALUC_OUT <= Aluc;
        ALUIMM_OUT <= Aluimm;
        QA_OUT <= Qa;
        QB_OUT <= Qb;
        IMMEXT_OUT <= Immext;
    end
endmodule

module AluMux(aluImm_out,qb, immExt, alu_b);
    input aluImm_out;
    input [31:0] qb, immExt;

    output reg [31:0] alu_b;

    always @(qb, immExt) begin
        case (aluImm_out)
            1'b0: alu_b = qb;
            1'b1: alu_b = immExt;
        endcase
    end
endmodule

module ALU (ALUcontrol,a , b, ALU_OUT);
    input [31:0] a, b;
    input [3:0]ALUcontrol; //4bit number
    output reg [31:0] ALU_OUT;

    always @ (a,b) begin
        case (ALUcontrol)
            4'b0010: ALU_OUT <= a + b;
        endcase
    end
endmodule

module EXE_MEM (clock, eWREG, eM2REG, eWMEM, eMUX, eALU_OUT, eQB, eWREG_out, eM2REG_out, eWMEM_out, eMUX_out, eALU_out, eQB_out);
    input clock, eWREG, eM2REG, eWMEM;
    input [4:0] eMUX;
    input [31:0] eQB, eALU_OUT;
    
    reg ewreg, em2reg, ewmem;
    reg [4:0] emux;
    reg [31:0] ealu_out, eqb;
    
    output reg eWREG_out, eM2REG_out, eWMEM_out;
    output reg [4:0] eMUX_out;
    output reg [31:0] eALU_out, eQB_out;

    always @ (posedge clock) begin
        ewreg <= eWREG;
        em2reg <= eM2REG;
        ewmem <= eWMEM;
        emux <= eMUX;
        ealu_out <= eALU_OUT;
        eqb <= eQB;
    end

    always @ (negedge clock) begin
        eWREG_out <= ewreg;
        eM2REG_out <= em2reg;
        eWMEM_out <= ewmem;
        eMUX_out <= emux;
        eALU_out <= ealu_out;
        eQB_out <= eqb;
    end
endmodule

module DataMemory (MEMWRITE, ALUDATA_IN ,QBDATA_IN, DMDATA_OUT);
    input MEMWRITE;
    input [31:0] ALUDATA_IN, QBDATA_IN;

    reg [31:0] DM [0:36];

    output reg [31:0] DMDATA_OUT;

    initial begin
        DM[32'd0] = 32'hA00000AA;
        DM[32'd4] = 32'h10000011;
        DM[32'd8] = 32'h20000022;
        DM[32'd12] = 32'h30000033;
        DM[32'd16] = 32'h40000044;
        DM[32'd20] = 32'h50000055;
        DM[32'd24] = 32'h60000066;
        DM[32'd28] = 32'h70000077;
        DM[32'd32] = 32'h80000088;
        DM[32'd36] = 32'h90000099;
    end


    always @ (ALUDATA_IN, QBDATA_IN) begin
        case (MEMWRITE)
            1'b0: DMDATA_OUT <= DM[ALUDATA_IN];
            1'b1: DMDATA_OUT <= DM[QBDATA_IN];  
        endcase
    end
endmodule

module MEM_WB(clock, mWREG, mM2REG, mMUX, mALU,mDM );
    input clock, mWREG, mM2REG;
    input [4:0] mMUX;
    input [31:0] mALU, mDM;

    reg mwreg,mm2reg;
    reg [4:0] mmux;
    reg [31:0] malu,mdm;

    always @(posedge clock) begin
        mwreg <= mWREG;
        mm2reg <= mM2REG;
        mmux <= mMUX;
        malu <= mALU;
        mdm <= mDM;
    end

endmodule