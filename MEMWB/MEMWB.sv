module MEMWB(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] aluResult,
    input  logic [31:0] readData,
    input  logic [31:0] pc4,
    input  logic [4:0]  rd,
    input  logic [1:0]  resultSrc,
    input  logic        regWrite,
    output logic [31:0] aluResult_out,
    output logic [31:0] readData_out,
    output logic [31:0] pc4_out,
    output logic [4:0]  rd_out,
    output logic [1:0]  resultSrc_out,
    output logic        regWrite_out
);
    always_ff @(posedge clk) begin
        if (reset) begin
            aluResult_out <= 32'd0;
            readData_out  <= 32'd0;
            pc4_out       <= 32'd4;
            rd_out        <= 5'd0;
            regWrite_out  <= 1'b0;
            resultSrc_out <= 2'b00;
        end else begin
            aluResult_out <= aluResult;
            readData_out  <= readData;
            pc4_out       <= pc4;
            rd_out        <= rd;
            regWrite_out  <= regWrite;
            resultSrc_out <= resultSrc;
        end
    end
endmodule
