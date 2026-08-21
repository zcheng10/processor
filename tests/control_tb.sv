module control_tb();
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;
    logic       regWrite;
    logic [1:0] resultSrc;
    logic       memRead;
    logic       memWrite;
    logic       jump;
    logic       jalr;
    logic       branch;
    logic [3:0] aluControl;
    logic [1:0] aluSrcA;
    logic       aluSrcB;
    logic [2:0] immSrc;
    logic       usesRs1;
    logic       usesRs2;

    control dut(
        .opcode(opcode),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .regWrite(regWrite),
        .resultSrc(resultSrc),
        .memRead(memRead),
        .memWrite(memWrite),
        .jump(jump),
        .jalr(jalr),
        .branch(branch),
        .aluControl(aluControl),
        .aluSrcA(aluSrcA),
        .aluSrcB(aluSrcB),
        .immSrc(immSrc),
        .usesRs1(usesRs1),
        .usesRs2(usesRs2)
    );

    task automatic drive;
        input logic [6:0] op;
        input logic [2:0] f3;
        input logic       f7_5;
        begin
            opcode = op;
            funct3 = f3;
            funct7_5 = f7_5;
            #1;
        end
    endtask

    initial begin
        drive(7'b0110011, 3'b000, 1'b1); // SUB
        if (!regWrite || !usesRs1 || !usesRs2 || aluControl !== 4'b0110) $fatal(1, "R-type SUB decode failed");

        drive(7'b0010011, 3'b011, 1'b0); // SLTIU
        if (!regWrite || !usesRs1 || usesRs2 || !aluSrcB || immSrc !== 3'b001 || aluControl !== 4'b1000) $fatal(1, "SLTIU decode failed");

        drive(7'b0000011, 3'b010, 1'b0); // LW
        if (!regWrite || !memRead || memWrite || resultSrc !== 2'b01 || !aluSrcB || !usesRs1) $fatal(1, "LW decode failed");

        drive(7'b0100011, 3'b010, 1'b0); // SW
        if (regWrite || memRead || !memWrite || !usesRs1 || !usesRs2 || immSrc !== 3'b010) $fatal(1, "SW decode failed");

        drive(7'b1100011, 3'b000, 1'b0); // BEQ
        if (regWrite || !branch || jump || !usesRs1 || !usesRs2 || immSrc !== 3'b011) $fatal(1, "BEQ decode failed");

        drive(7'b1100111, 3'b000, 1'b0); // JALR
        if (!regWrite || !jump || !jalr || resultSrc !== 2'b10 || !usesRs1 || immSrc !== 3'b001) $fatal(1, "JALR decode failed");

        drive(7'b0110111, 3'b000, 1'b0); // LUI
        if (!regWrite || aluSrcA !== 2'b10 || !aluSrcB || immSrc !== 3'b101) $fatal(1, "LUI decode failed");

        drive(7'b0010111, 3'b000, 1'b0); // AUIPC
        if (!regWrite || aluSrcA !== 2'b01 || !aluSrcB || immSrc !== 3'b101) $fatal(1, "AUIPC decode failed");

        $display("control_tb passed");
        $finish;
    end
endmodule
