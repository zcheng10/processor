module IFID(
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        flush,
    input  logic [31:0] pc,
    input  logic [31:0] pc4,
    input  logic [31:0] predicted_pc,
    input  logic [31:0] instruction,
    output logic [31:0] pc_out,
    output logic [31:0] pc4_out,
    output logic [31:0] predicted_pc_out,
    output logic [31:0] instruction_out
);
    localparam logic [31:0] NOP = 32'h00000013; // addi x0, x0, 0

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            pc_out           <= 32'd0;
            pc4_out          <= 32'd4;
            predicted_pc_out <= 32'd4;
            instruction_out  <= NOP;
        end else if (!stall) begin
            pc_out           <= pc;
            pc4_out          <= pc4;
            predicted_pc_out <= predicted_pc;
            instruction_out  <= instruction;
        end
    end
endmodule
