module control(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    output logic       regWrite,
    output logic [1:0] resultSrc,
    output logic       memRead,
    output logic       memWrite,
    output logic       jump,
    output logic       jalr,
    output logic       branch,
    output logic [3:0] aluControl,
    output logic [1:0] aluSrcA,
    output logic       aluSrcB,
    output logic [2:0] immSrc,
    output logic       usesRs1,
    output logic       usesRs2
);
    localparam logic [3:0] ALU_AND  = 4'b0000;
    localparam logic [3:0] ALU_OR   = 4'b0001;
    localparam logic [3:0] ALU_ADD  = 4'b0010;
    localparam logic [3:0] ALU_SLL  = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SRL  = 4'b0101;
    localparam logic [3:0] ALU_SUB  = 4'b0110;
    localparam logic [3:0] ALU_SLT  = 4'b0111;
    localparam logic [3:0] ALU_SLTU = 4'b1000;
    localparam logic [3:0] ALU_SRA  = 4'b1010;

    localparam logic [1:0] RESULT_ALU = 2'b00;
    localparam logic [1:0] RESULT_MEM = 2'b01;
    localparam logic [1:0] RESULT_PC4 = 2'b10;

    localparam logic [1:0] ALU_A_RS1  = 2'b00;
    localparam logic [1:0] ALU_A_PC   = 2'b01;
    localparam logic [1:0] ALU_A_ZERO = 2'b10;

    always_comb begin
        regWrite  = 1'b0;
        resultSrc = RESULT_ALU;
        memRead   = 1'b0;
        memWrite  = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;
        branch    = 1'b0;
        aluControl = ALU_ADD;
        aluSrcA   = ALU_A_RS1;
        aluSrcB   = 1'b0;
        immSrc    = 3'b000;
        usesRs1   = 1'b0;
        usesRs2   = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                regWrite = 1'b1;
                usesRs1  = 1'b1;
                usesRs2  = 1'b1;
                case (funct3)
                    3'b000: aluControl = funct7_5 ? ALU_SUB : ALU_ADD;
                    3'b001: aluControl = ALU_SLL;
                    3'b010: aluControl = ALU_SLT;
                    3'b011: aluControl = ALU_SLTU;
                    3'b100: aluControl = ALU_XOR;
                    3'b101: aluControl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: aluControl = ALU_OR;
                    3'b111: aluControl = ALU_AND;
                    default: aluControl = ALU_ADD;
                endcase
            end

            7'b0010011: begin // I-type ALU
                regWrite = 1'b1;
                aluSrcB  = 1'b1;
                immSrc   = 3'b001;
                usesRs1  = 1'b1;
                case (funct3)
                    3'b000: aluControl = ALU_ADD;  // ADDI
                    3'b001: aluControl = ALU_SLL;  // SLLI
                    3'b010: aluControl = ALU_SLT;  // SLTI
                    3'b011: aluControl = ALU_SLTU; // SLTIU
                    3'b100: aluControl = ALU_XOR;  // XORI
                    3'b101: aluControl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: aluControl = ALU_OR;   // ORI
                    3'b111: aluControl = ALU_AND;  // ANDI
                    default: aluControl = ALU_ADD;
                endcase
            end

            7'b0000011: begin // loads
                regWrite  = 1'b1;
                resultSrc = RESULT_MEM;
                memRead   = 1'b1;
                aluControl = ALU_ADD;
                aluSrcB   = 1'b1;
                immSrc    = 3'b001;
                usesRs1   = 1'b1;
            end

            7'b0100011: begin // stores
                memWrite  = 1'b1;
                aluControl = ALU_ADD;
                aluSrcB   = 1'b1;
                immSrc    = 3'b010;
                usesRs1   = 1'b1;
                usesRs2   = 1'b1;
            end

            7'b1100011: begin // conditional branches
                branch    = 1'b1;
                aluControl = ALU_SUB;
                immSrc    = 3'b011;
                usesRs1   = 1'b1;
                usesRs2   = 1'b1;
            end

            7'b1101111: begin // JAL
                regWrite  = 1'b1;
                resultSrc = RESULT_PC4;
                jump      = 1'b1;
                immSrc    = 3'b100;
            end

            7'b1100111: begin // JALR
                regWrite  = 1'b1;
                resultSrc = RESULT_PC4;
                jump      = 1'b1;
                jalr      = 1'b1;
                aluControl = ALU_ADD;
                aluSrcB   = 1'b1;
                immSrc    = 3'b001;
                usesRs1   = 1'b1;
            end

            7'b0110111: begin // LUI
                regWrite  = 1'b1;
                aluControl = ALU_ADD;
                aluSrcA   = ALU_A_ZERO;
                aluSrcB   = 1'b1;
                immSrc    = 3'b101;
            end

            7'b0010111: begin // AUIPC
                regWrite  = 1'b1;
                aluControl = ALU_ADD;
                aluSrcA   = ALU_A_PC;
                aluSrcB   = 1'b1;
                immSrc    = 3'b101;
            end

            7'b0001111: begin // FENCE: no-op in this simple in-order core
            end

            7'b1110011: begin // ECALL/EBREAK: treated as no-op; no trap unit is implemented
            end

            default: begin
            end
        endcase
    end
endmodule

module ControlUnit(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    output logic       regWrite,
    output logic [1:0] resultSrc,
    output logic       memRead,
    output logic       memWrite,
    output logic       jump,
    output logic       branch,
    output logic [3:0] aluControl,
    output logic       aluSrc,
    output logic [2:0] ImmSrc
);
    logic jalr_unused;
    logic [1:0] aluSrcA_unused;
    logic usesRs1_unused;
    logic usesRs2_unused;

    control wrapped_control(
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .regWrite(regWrite),
        .resultSrc(resultSrc),
        .memRead(memRead),
        .memWrite(memWrite),
        .jump(jump),
        .jalr(jalr_unused),
        .branch(branch),
        .aluControl(aluControl),
        .aluSrcA(aluSrcA_unused),
        .aluSrcB(aluSrc),
        .immSrc(ImmSrc),
        .usesRs1(usesRs1_unused),
        .usesRs2(usesRs2_unused)
    );
endmodule
