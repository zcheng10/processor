module branchpredictor_tb();
    logic        clk;
    logic        reset;
    logic [31:0] pc;
    logic [31:0] instruction;
    logic        updateValid;
    logic [31:0] pcUpdate;
    logic        branchTaken;
    logic [31:0] pcPredicted;
    logic        predictedTaken;

    branchPredictor dut(
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction),
        .updateValid(updateValid),
        .pcUpdate(pcUpdate),
        .branchTaken(branchTaken),
        .pcPredicted(pcPredicted),
        .predictedTaken(predictedTaken)
    );

    always #5 clk = ~clk;

    function automatic logic [31:0] encode_b(
        input int imm,
        input int rs2,
        input int rs1,
        input int funct3,
        input int opcode
    );
        encode_b = ((((imm >> 12) & 1) << 31) | (((imm >> 5) & 6'h3f) << 25) |
                    (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
                    (((imm >> 1) & 4'hf) << 8) | (((imm >> 11) & 1) << 7) | opcode);
    endfunction

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        pc = 32'd0;
        instruction = encode_b(8, 0, 0, 3'b000, 7'h63);
        updateValid = 1'b0;
        pcUpdate = 32'd0;
        branchTaken = 1'b0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;
        if (predictedTaken || pcPredicted !== 32'd4) $fatal(1, "initial prediction should be not-taken");

        @(negedge clk);
        updateValid = 1'b1;
        branchTaken = 1'b1;
        pcUpdate = 32'd0;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (!predictedTaken || pcPredicted !== 32'd8) $fatal(1, "predictor should become taken after two taken updates");

        @(negedge clk);
        branchTaken = 1'b0;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (predictedTaken || pcPredicted !== 32'd4) $fatal(1, "predictor should return to not-taken after two not-taken updates");

        @(negedge clk);
        instruction = 32'h00000013;
        updateValid = 1'b0;
        #1;
        if (predictedTaken || pcPredicted !== 32'd4) $fatal(1, "non-branch instruction should predict PC+4");

        $display("branchpredictor_tb passed");
        $finish;
    end
endmodule
