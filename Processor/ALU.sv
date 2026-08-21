module ALU(
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [3:0]  aluControl,
    output logic [31:0] res,
    output logic        zeroFlag
);
    localparam logic [3:0] ALU_AND  = 4'b0000;
    localparam logic [3:0] ALU_OR   = 4'b0001;
    localparam logic [3:0] ALU_ADD  = 4'b0010;
    localparam logic [3:0] ALU_SLL  = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SRL  = 4'b0101;
    localparam logic [3:0] ALU_SUB  = 4'b0110;
    localparam logic [3:0] ALU_SLT  = 4'b0111;
    localparam logic [3:0] ALU_SLTU = 4'b1000;
    localparam logic [3:0] ALU_SRA  = 4'b1010;

    always @* begin
        case (aluControl)
            ALU_AND:  res = A & B;
            ALU_OR:   res = A | B;
            ALU_ADD:  res = A + B;
            ALU_SLL:  res = A << B[4:0];
            ALU_XOR:  res = A ^ B;
            ALU_SRL:  res = A >> B[4:0];
            ALU_SUB:  res = A - B;
            ALU_SLT:  res = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            ALU_SLTU: res = (A < B) ? 32'd1 : 32'd0;
            ALU_SRA:  res = $signed(A) >>> B[4:0];
            default:  res = 32'd0;
        endcase

        zeroFlag = (res == 32'd0);
    end
endmodule
