module hazard_tb();
    logic [4:0] rs1D;
    logic [4:0] rs2D;
    logic       usesRs1D;
    logic       usesRs2D;
    logic [4:0] rs1E;
    logic [4:0] rs2E;
    logic [4:0] rdE;
    logic [4:0] rdM;
    logic [4:0] rdW;
    logic       regWriteM;
    logic       regWriteW;
    logic       memReadE;
    logic       mispredictE;
    logic       stallF;
    logic       stallD;
    logic       flushD;
    logic       flushE;
    logic [1:0] forwardAE;
    logic [1:0] forwardBE;

    hazard dut(
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

    initial begin
        rs1D = 5'd0; rs2D = 5'd0; usesRs1D = 1'b0; usesRs2D = 1'b0;
        rs1E = 5'd0; rs2E = 5'd0; rdE = 5'd0; rdM = 5'd0; rdW = 5'd0;
        regWriteM = 1'b0; regWriteW = 1'b0; memReadE = 1'b0; mispredictE = 1'b0;
        #1;
        if (stallF || stallD || flushD || flushE || forwardAE !== 2'b00 || forwardBE !== 2'b00) $fatal(1, "default hazard outputs failed");

        rs1E = 5'd5; rdM = 5'd5; regWriteM = 1'b1;
        rs2E = 5'd6; rdW = 5'd6; regWriteW = 1'b1;
        #1;
        if (forwardAE !== 2'b10 || forwardBE !== 2'b01) $fatal(1, "forwarding failed");

        rs1D = 5'd7; rs2D = 5'd8; usesRs1D = 1'b1; usesRs2D = 1'b0; rdE = 5'd8; memReadE = 1'b1;
        #1;
        if (stallF || stallD || flushE) $fatal(1, "unused rs2 should not cause load-use stall");

        usesRs2D = 1'b1;
        #1;
        if (!stallF || !stallD || !flushE) $fatal(1, "load-use stall failed");

        memReadE = 1'b0; mispredictE = 1'b1;
        #1;
        if (stallF || stallD || !flushD || !flushE) $fatal(1, "misprediction flush failed");

        $display("hazard_tb passed");
        $finish;
    end
endmodule
