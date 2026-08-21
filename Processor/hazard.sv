module hazard(
    input  logic [4:0] rs1D,
    input  logic [4:0] rs2D,
    input  logic       usesRs1D,
    input  logic       usesRs2D,
    input  logic [4:0] rs1E,
    input  logic [4:0] rs2E,
    input  logic [4:0] rdE,
    input  logic [4:0] rdM,
    input  logic [4:0] rdW,
    input  logic       regWriteM,
    input  logic       regWriteW,
    input  logic       memReadE,
    input  logic       mispredictE,
    output logic       stallF,
    output logic       stallD,
    output logic       flushD,
    output logic       flushE,
    output logic [1:0] forwardAE,
    output logic [1:0] forwardBE
);
    logic loadUseStall;

    always_comb begin
        if ((rs1E != 5'd0) && regWriteM && (rdM != 5'd0) && (rdM == rs1E)) begin
            forwardAE = 2'b10;
        end else if ((rs1E != 5'd0) && regWriteW && (rdW != 5'd0) && (rdW == rs1E)) begin
            forwardAE = 2'b01;
        end else begin
            forwardAE = 2'b00;
        end

        if ((rs2E != 5'd0) && regWriteM && (rdM != 5'd0) && (rdM == rs2E)) begin
            forwardBE = 2'b10;
        end else if ((rs2E != 5'd0) && regWriteW && (rdW != 5'd0) && (rdW == rs2E)) begin
            forwardBE = 2'b01;
        end else begin
            forwardBE = 2'b00;
        end

        // This core uses combinational-read data memory and forwards load
        // results from MEM to EX, so immediate load-use dependencies do not
        // need a bubble. If DMEM is replaced with synchronous block RAM,
        // restore the classic load-use stall expression here.
        loadUseStall = 1'b0;

        stallF = loadUseStall;
        stallD = loadUseStall;
        flushD = mispredictE;
        flushE = mispredictE || loadUseStall;
    end
endmodule
