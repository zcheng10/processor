module IDEX(
    input  logic        clk,
    input  logic        reset,
    input  logic        flush,
    input  logic [31:0] pc_current,
    input  logic [31:0] pc4,
    input  logic [31:0] predicted_pc,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [2:0]  funct3,
    input  logic [31:0] read_data1,
    input  logic [31:0] read_data2,
    input  logic [31:0] immediate,
    input  logic        regWrite,
    input  logic        memRead,
    input  logic        memWrite,
    input  logic        jump,
    input  logic        jalr,
    input  logic        branch,
    input  logic [1:0]  aluSrcA,
    input  logic        aluSrcB,
    input  logic [1:0]  resultSrc,
    input  logic [3:0]  aluControl,
    output logic [31:0] pc_current_out,
    output logic [31:0] pc4_out,
    output logic [31:0] predicted_pc_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,
    output logic [2:0]  funct3_out,
    output logic [31:0] read_data1_out,
    output logic [31:0] read_data2_out,
    output logic [31:0] immediate_out,
    output logic        regWrite_out,
    output logic        memRead_out,
    output logic        memWrite_out,
    output logic        jump_out,
    output logic        jalr_out,
    output logic        branch_out,
    output logic [1:0]  aluSrcA_out,
    output logic        aluSrcB_out,
    output logic [1:0]  resultSrc_out,
    output logic [3:0]  aluControl_out
);
    always_ff @(posedge clk) begin
        if (reset || flush) begin
            pc_current_out  <= 32'd0;
            pc4_out         <= 32'd4;
            predicted_pc_out <= 32'd4;
            rs1_out         <= 5'd0;
            rs2_out         <= 5'd0;
            rd_out          <= 5'd0;
            funct3_out      <= 3'd0;
            read_data1_out  <= 32'd0;
            read_data2_out  <= 32'd0;
            immediate_out   <= 32'd0;
            regWrite_out    <= 1'b0;
            memRead_out     <= 1'b0;
            memWrite_out    <= 1'b0;
            jump_out        <= 1'b0;
            jalr_out        <= 1'b0;
            branch_out      <= 1'b0;
            aluSrcA_out     <= 2'b00;
            aluSrcB_out     <= 1'b0;
            resultSrc_out   <= 2'b00;
            aluControl_out  <= 4'b0010;
        end else begin
            pc_current_out  <= pc_current;
            pc4_out         <= pc4;
            predicted_pc_out <= predicted_pc;
            rs1_out         <= rs1;
            rs2_out         <= rs2;
            rd_out          <= rd;
            funct3_out      <= funct3;
            read_data1_out  <= read_data1;
            read_data2_out  <= read_data2;
            immediate_out   <= immediate;
            regWrite_out    <= regWrite;
            memRead_out     <= memRead;
            memWrite_out    <= memWrite;
            jump_out        <= jump;
            jalr_out        <= jalr;
            branch_out      <= branch;
            aluSrcA_out     <= aluSrcA;
            aluSrcB_out     <= aluSrcB;
            resultSrc_out   <= resultSrc;
            aluControl_out  <= aluControl;
        end
    end
endmodule
