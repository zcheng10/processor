module register(
    input  logic        clk,
    input  logic        reset,
    input  logic        regWrite,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] result,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);
    logic [31:0] registers [31:0];

    integer i;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (regWrite && (rd != 5'd0)) begin
            registers[rd] <= result;
        end
    end

    always_comb begin
        if (rs1 == 5'd0) begin
            rs1_data = 32'd0;
        end else if (regWrite && (rd == rs1) && (rd != 5'd0)) begin
            rs1_data = result;
        end else begin
            rs1_data = registers[rs1];
        end

        if (rs2 == 5'd0) begin
            rs2_data = 32'd0;
        end else if (regWrite && (rd == rs2) && (rd != 5'd0)) begin
            rs2_data = result;
        end else begin
            rs2_data = registers[rs2];
        end
    end
endmodule
