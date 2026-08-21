module branchPredictor #(
    parameter int ENTRIES = 1024
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc,
    input  logic [31:0] instruction,
    input  logic        updateValid,
    input  logic [31:0] pcUpdate,
    input  logic        branchTaken,
    output logic [31:0] pcPredicted,
    output logic        predictedTaken
);
    logic [1:0] branchHistory [0:ENTRIES-1];
    logic [31:0] pcBranch;
    logic [31:0] branchImmediate;
    logic [$clog2(ENTRIES)-1:0] predictIndex;
    logic [$clog2(ENTRIES)-1:0] updateIndex;
    logic isBranchInstruction;

    integer i;

    function automatic logic [$clog2(ENTRIES)-1:0] fnv_index(input logic [31:0] value);
        logic [31:0] hash_value;
        begin
            hash_value = 32'h811C9DC5 ^ value;
            hash_value = hash_value * 32'h01000193;
            fnv_index = hash_value[$clog2(ENTRIES)-1:0];
        end
    endfunction

    assign branchImmediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign pcBranch = pc + branchImmediate;
    assign isBranchInstruction = (instruction[6:0] == 7'b1100011);
    assign predictIndex = fnv_index(pc);
    assign updateIndex = fnv_index(pcUpdate);
    assign predictedTaken = isBranchInstruction && (branchHistory[predictIndex] >= 2'b10);
    assign pcPredicted = predictedTaken ? pcBranch : (pc + 32'd4);

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                branchHistory[i] <= 2'b00; // strongly not taken
            end
        end else if (updateValid) begin
            if (branchTaken) begin
                if (branchHistory[updateIndex] != 2'b11) begin
                    branchHistory[updateIndex] <= branchHistory[updateIndex] + 2'b01;
                end
            end else begin
                if (branchHistory[updateIndex] != 2'b00) begin
                    branchHistory[updateIndex] <= branchHistory[updateIndex] - 2'b01;
                end
            end
        end
    end
endmodule
