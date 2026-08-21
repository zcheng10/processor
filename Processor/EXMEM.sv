module EXMEM(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] aluResult,
    input  logic [31:0] writeData,
    input  logic [4:0]  rd,
    input  logic [31:0] pc4,
    input  logic [2:0]  funct3,
    input  logic        regWrite,
    input  logic        memRead,
    input  logic        memWrite,
    input  logic [1:0]  resultSrc,
    output logic [31:0] aluResult_out,
    output logic [31:0] writeData_out,
    output logic [4:0]  rd_out,
    output logic [31:0] pc4_out,
    output logic [2:0]  funct3_out,
    output logic        regWrite_out,
    output logic        memRead_out,
    output logic        memWrite_out,
    output logic [1:0]  resultSrc_out
);
    always_ff @(posedge clk) begin
        if (reset) begin
            aluResult_out <= 32'd0;
            writeData_out <= 32'd0;
            rd_out        <= 5'd0;
            pc4_out       <= 32'd4;
            funct3_out    <= 3'd0;
            regWrite_out  <= 1'b0;
            memRead_out   <= 1'b0;
            memWrite_out  <= 1'b0;
            resultSrc_out <= 2'b00;
        end else begin
            aluResult_out <= aluResult;
            writeData_out <= writeData;
            rd_out        <= rd;
            pc4_out       <= pc4;
            funct3_out    <= funct3;
            regWrite_out  <= regWrite;
            memRead_out   <= memRead;
            memWrite_out  <= memWrite;
            resultSrc_out <= resultSrc;
        end
    end
endmodule
