`include "ALU.sv"
`include "adder.sv"

module processor(
    input logic clk,
    input logic reset,
    output logic        halted,
    output logic [31:0] cycle_count,
    output logic [31:0] instruction_retired_count,
    output logic [31:0] load_use_stall_count,
    output logic [31:0] redirect_flush_count,
    output logic [31:0] branch_count,
    output logic [31:0] branch_taken_count,
    output logic [31:0] branch_mispredict_count,
    output logic [31:0] jump_count,
    output logic [31:0] jump_mispredict_count
);
    localparam logic [31:0] NOP_INSTRUCTION   = 32'h00000013;
    localparam logic [31:0] ECALL_INSTRUCTION = 32'h00000073;

    localparam logic [1:0] RESULT_ALU = 2'b00;
    localparam logic [1:0] RESULT_MEM = 2'b01;
    localparam logic [1:0] RESULT_PC4 = 2'b10;

    localparam logic [1:0] ALU_A_RS1  = 2'b00;
    localparam logic [1:0] ALU_A_PC   = 2'b01;
    localparam logic [1:0] ALU_A_ZERO = 2'b10;

    logic        stallF;
    logic        stallD;
    logic        flushD;
    logic        flushE;

    // Fetch stage
    logic [31:0] PCF;
    logic [31:0] PCNextF;
    logic [31:0] PC4F;
    logic [31:0] instructionF;
    logic [31:0] predictedPCF;
    logic        predictedTakenF;

    // Decode stage
    logic [31:0] PCD;
    logic [31:0] PC4D;
    logic [31:0] predictedPCD;
    logic [31:0] instructionD;
    logic [6:0]  opcodeD;
    logic [4:0]  rs1D;
    logic [4:0]  rs2D;
    logic [4:0]  rdD;
    logic [2:0]  funct3D;
    logic        funct7_5D;
    logic [31:0] RD1D;
    logic [31:0] RD2D;
    logic [31:0] immediateD;
    logic        regWriteD;
    logic [1:0]  resultSrcD;
    logic        memReadD;
    logic        memWriteD;
    logic        jumpD;
    logic        jalrD;
    logic        branchD;
    logic [3:0]  aluControlD;
    logic [1:0]  aluSrcAD;
    logic        aluSrcBD;
    logic [2:0]  immSrcD;
    logic        usesRs1D;
    logic        usesRs2D;

    // Execute stage
    logic [31:0] PCE;
    logic [31:0] PC4E;
    logic [31:0] predictedPCE;
    logic [4:0]  rs1E;
    logic [4:0]  rs2E;
    logic [4:0]  rdE;
    logic [2:0]  funct3E;
    logic [31:0] RD1E;
    logic [31:0] RD2E;
    logic [31:0] immediateE;
    logic        regWriteE;
    logic [1:0]  resultSrcE;
    logic        memReadE;
    logic        memWriteE;
    logic        jumpE;
    logic        jalrE;
    logic        branchE;
    logic [3:0]  aluControlE;
    logic [1:0]  aluSrcAE;
    logic        aluSrcBE;
    logic [1:0]  forwardAE;
    logic [1:0]  forwardBE;
    logic [31:0] forwardedAE;
    logic [31:0] forwardedBE;
    logic [31:0] srcAE;
    logic [31:0] srcBE;
    logic [31:0] aluResultE;
    logic        zeroFlagE;
    logic [31:0] branchTargetE;
    logic [31:0] jalrTargetE;
    logic [31:0] actualNextPCE;
    logic        branchTakenE;
    logic        mispredictE;

    // Memory stage
    logic [31:0] aluResultM;
    logic [31:0] writeDataM;
    logic [4:0]  rdM;
    logic [31:0] PC4M;
    logic [2:0]  funct3M;
    logic        regWriteM;
    logic [1:0]  resultSrcM;
    logic        memReadM;
    logic        memWriteM;
    logic [31:0] readDataM;
    logic [31:0] resultM;

    // Writeback stage
    logic [31:0] aluResultW;
    logic [31:0] readDataW;
    logic [4:0]  rdW;
    logic [31:0] PC4W;
    logic        regWriteW;
    logic [1:0]  resultSrcW;
    logic [31:0] resultW;
    logic        retireValidD;
    logic        retireValidE;
    logic        retireValidM;
    logic        retireValidW;
    logic        ecallD;
    logic        ecallE;
    logic        ecallM;
    logic        ecallW;

    function automatic logic branch_condition(
        input logic [2:0]  funct3,
        input logic [31:0] a,
        input logic [31:0] b
    );
        begin
            case (funct3)
                3'b000: branch_condition = (a == b); // BEQ
                3'b001: branch_condition = (a != b); // BNE
                3'b100: branch_condition = ($signed(a) < $signed(b)); // BLT
                3'b101: branch_condition = ($signed(a) >= $signed(b)); // BGE
                3'b110: branch_condition = (a < b); // BLTU
                3'b111: branch_condition = (a >= b); // BGEU
                default: branch_condition = 1'b0;
            endcase
        end
    endfunction

    assign PCNextF = mispredictE ? actualNextPCE : predictedPCF;
    assign retireValidD = (instructionD != NOP_INSTRUCTION) && (instructionD != ECALL_INSTRUCTION);
    assign ecallD = (instructionD == ECALL_INSTRUCTION);

    PC pc(
        .clk(clk),
        .reset(reset),
        .stall(stallF),
        .PC_next(PCNextF),
        .PC_current(PCF)
    );

    IMEM #(.MEM_WORDS(1024)) imem(
        .read_address(PCF),
        .instruction(instructionF)
    );

    adder pc_adder(
        .a(PCF),
        .b(32'd4),
        .sum(PC4F)
    );

    branchPredictor branchPred(
        .clk(clk),
        .reset(reset),
        .pc(PCF),
        .instruction(instructionF),
        .updateValid(branchE),
        .pcUpdate(PCE),
        .branchTaken(branchTakenE),
        .pcPredicted(predictedPCF),
        .predictedTaken(predictedTakenF)
    );

    IFID ifid(
        .clk(clk),
        .reset(reset),
        .stall(stallD),
        .flush(flushD),
        .pc(PCF),
        .pc4(PC4F),
        .predicted_pc(predictedPCF),
        .instruction(instructionF),
        .pc_out(PCD),
        .pc4_out(PC4D),
        .predicted_pc_out(predictedPCD),
        .instruction_out(instructionD)
    );

    assign opcodeD   = instructionD[6:0];
    assign rdD       = instructionD[11:7];
    assign funct3D   = instructionD[14:12];
    assign rs1D      = instructionD[19:15];
    assign rs2D      = instructionD[24:20];
    assign funct7_5D = instructionD[30];

    register regs(
        .clk(clk),
        .reset(reset),
        .regWrite(regWriteW),
        .rs1(rs1D),
        .rs2(rs2D),
        .rd(rdW),
        .result(resultW),
        .rs1_data(RD1D),
        .rs2_data(RD2D)
    );

    ImmGen immgen(
        .instruction(instructionD[31:7]),
        .ImmSrc(immSrcD),
        .immediate(immediateD)
    );

    control controlUnit(
        .opcode(opcodeD),
        .funct3(funct3D),
        .funct7_5(funct7_5D),
        .regWrite(regWriteD),
        .resultSrc(resultSrcD),
        .memRead(memReadD),
        .memWrite(memWriteD),
        .jump(jumpD),
        .jalr(jalrD),
        .branch(branchD),
        .aluControl(aluControlD),
        .aluSrcA(aluSrcAD),
        .aluSrcB(aluSrcBD),
        .immSrc(immSrcD),
        .usesRs1(usesRs1D),
        .usesRs2(usesRs2D)
    );

    IDEX idex(
        .clk(clk),
        .reset(reset),
        .flush(flushE),
        .pc_current(PCD),
        .pc4(PC4D),
        .predicted_pc(predictedPCD),
        .rs1(rs1D),
        .rs2(rs2D),
        .rd(rdD),
        .funct3(funct3D),
        .read_data1(RD1D),
        .read_data2(RD2D),
        .immediate(immediateD),
        .regWrite(regWriteD),
        .memRead(memReadD),
        .memWrite(memWriteD),
        .jump(jumpD),
        .jalr(jalrD),
        .branch(branchD),
        .aluSrcA(aluSrcAD),
        .aluSrcB(aluSrcBD),
        .resultSrc(resultSrcD),
        .aluControl(aluControlD),
        .pc_current_out(PCE),
        .pc4_out(PC4E),
        .predicted_pc_out(predictedPCE),
        .rs1_out(rs1E),
        .rs2_out(rs2E),
        .rd_out(rdE),
        .funct3_out(funct3E),
        .read_data1_out(RD1E),
        .read_data2_out(RD2E),
        .immediate_out(immediateE),
        .regWrite_out(regWriteE),
        .memRead_out(memReadE),
        .memWrite_out(memWriteE),
        .jump_out(jumpE),
        .jalr_out(jalrE),
        .branch_out(branchE),
        .aluSrcA_out(aluSrcAE),
        .aluSrcB_out(aluSrcBE),
        .resultSrc_out(resultSrcE),
        .aluControl_out(aluControlE)
    );

    mux3 #(.WIDTH(32)) forwardA(
        .a(RD1E),
        .b(resultW),
        .c(resultM),
        .ctrl(forwardAE),
        .y(forwardedAE)
    );

    mux3 #(.WIDTH(32)) forwardB(
        .a(RD2E),
        .b(resultW),
        .c(resultM),
        .ctrl(forwardBE),
        .y(forwardedBE)
    );

    always_comb begin
        case (aluSrcAE)
            ALU_A_RS1:  srcAE = forwardedAE;
            ALU_A_PC:   srcAE = PCE;
            ALU_A_ZERO: srcAE = 32'd0;
            default:    srcAE = forwardedAE;
        endcase

        srcBE = aluSrcBE ? immediateE : forwardedBE;
    end

    ALU alu(
        .A(srcAE),
        .B(srcBE),
        .aluControl(aluControlE),
        .res(aluResultE),
        .zeroFlag(zeroFlagE)
    );

    adder branchAdder(
        .a(PCE),
        .b(immediateE),
        .sum(branchTargetE)
    );

    assign jalrTargetE  = {aluResultE[31:1], 1'b0};
    assign branchTakenE = branchE && branch_condition(funct3E, forwardedAE, forwardedBE);

    always_comb begin
        actualNextPCE = PC4E;
        if (jumpE) begin
            actualNextPCE = jalrE ? jalrTargetE : branchTargetE;
        end else if (branchTakenE) begin
            actualNextPCE = branchTargetE;
        end
    end

    assign mispredictE = (branchE || jumpE) && (predictedPCE != actualNextPCE);

    always_ff @(posedge clk) begin
        if (reset) begin
            retireValidE <= 1'b0;
            retireValidM <= 1'b0;
            retireValidW <= 1'b0;
            ecallE       <= 1'b0;
            ecallM       <= 1'b0;
            ecallW       <= 1'b0;
        end else begin
            retireValidM <= retireValidE;
            retireValidW <= retireValidM;
            ecallM       <= ecallE;
            ecallW       <= ecallM;

            if (flushE) begin
                retireValidE <= 1'b0;
                ecallE       <= 1'b0;
            end else begin
                retireValidE <= retireValidD;
                ecallE       <= ecallD;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            halted                    <= 1'b0;
            cycle_count               <= 32'd0;
            instruction_retired_count <= 32'd0;
            load_use_stall_count      <= 32'd0;
            redirect_flush_count      <= 32'd0;
            branch_count              <= 32'd0;
            branch_taken_count        <= 32'd0;
            branch_mispredict_count   <= 32'd0;
            jump_count                <= 32'd0;
            jump_mispredict_count     <= 32'd0;
        end else if (!halted) begin
            cycle_count <= cycle_count + 32'd1;

            if (retireValidW) begin
                instruction_retired_count <= instruction_retired_count + 32'd1;
            end

            if (stallF) begin
                load_use_stall_count <= load_use_stall_count + 32'd1;
            end

            if (mispredictE) begin
                redirect_flush_count <= redirect_flush_count + 32'd1;
            end

            if (branchE) begin
                branch_count <= branch_count + 32'd1;
                if (branchTakenE) begin
                    branch_taken_count <= branch_taken_count + 32'd1;
                end
                if (mispredictE) begin
                    branch_mispredict_count <= branch_mispredict_count + 32'd1;
                end
            end

            if (jumpE) begin
                jump_count <= jump_count + 32'd1;
                if (mispredictE) begin
                    jump_mispredict_count <= jump_mispredict_count + 32'd1;
                end
            end

            if (ecallW) begin
                halted <= 1'b1;
            end
        end
    end

    EXMEM exmem(
        .clk(clk),
        .reset(reset),
        .pc4(PC4E),
        .aluResult(aluResultE),
        .writeData(forwardedBE),
        .rd(rdE),
        .funct3(funct3E),
        .regWrite(regWriteE),
        .memRead(memReadE),
        .memWrite(memWriteE),
        .resultSrc(resultSrcE),
        .pc4_out(PC4M),
        .aluResult_out(aluResultM),
        .writeData_out(writeDataM),
        .rd_out(rdM),
        .funct3_out(funct3M),
        .regWrite_out(regWriteM),
        .memRead_out(memReadM),
        .memWrite_out(memWriteM),
        .resultSrc_out(resultSrcM)
    );

    DMEM #(.MEM_BYTES(4096)) dmem(
        .clk(clk),
        .reset(reset),
        .memWrite(memWriteM),
        .memRead(memReadM),
        .funct3(funct3M),
        .aluResult(aluResultM),
        .writeData(writeDataM),
        .readData(readDataM)
    );

    always_comb begin
        case (resultSrcM)
            RESULT_ALU: resultM = aluResultM;
            RESULT_MEM: resultM = readDataM;
            RESULT_PC4: resultM = PC4M;
            default:    resultM = aluResultM;
        endcase
    end

    MEMWB memwb(
        .clk(clk),
        .reset(reset),
        .pc4(PC4M),
        .aluResult(aluResultM),
        .readData(readDataM),
        .rd(rdM),
        .regWrite(regWriteM),
        .resultSrc(resultSrcM),
        .pc4_out(PC4W),
        .aluResult_out(aluResultW),
        .readData_out(readDataW),
        .rd_out(rdW),
        .regWrite_out(regWriteW),
        .resultSrc_out(resultSrcW)
    );

    always_comb begin
        case (resultSrcW)
            RESULT_ALU: resultW = aluResultW;
            RESULT_MEM: resultW = readDataW;
            RESULT_PC4: resultW = PC4W;
            default:    resultW = aluResultW;
        endcase
    end

    hazard hazardUnit(
        .rs1D(rs1D),
        .rs2D(rs2D),
        .usesRs1D(usesRs1D),
        .usesRs2D(usesRs2D),
        .rs1E(rs1E),
        .rs2E(rs2E),
        .rdE(rdE),
        .rdM(rdM),
        .rdW(rdW),
        .regWriteM(regWriteM),
        .regWriteW(regWriteW),
        .memReadE(memReadE),
        .mispredictE(mispredictE),
        .stallF(stallF),
        .stallD(stallD),
        .flushD(flushD),
        .flushE(flushE),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE)
    );
endmodule
