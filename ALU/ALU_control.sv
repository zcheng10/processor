module ALU_control(
    input  logic [1:0] aluOp,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    output logic [3:0] aluControl
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

    always_comb begin
        case (aluOp)
            2'b00: aluControl = ALU_ADD; // address/add-immediate path
            2'b01: aluControl = ALU_SUB; // branch equality path
            default: begin
                case (funct3)
                    3'b000: aluControl = funct7_5 ? ALU_SUB : ALU_ADD;
                    3'b001: aluControl = ALU_SLL;
                    3'b010: aluControl = ALU_SLT;
                    3'b011: aluControl = ALU_SLTU;
                    3'b100: aluControl = ALU_XOR;
                    3'b101: aluControl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: aluControl = ALU_OR;
                    3'b111: aluControl = ALU_AND;
                    default: aluControl = ALU_ADD;
                endcase
            end
        endcase
    end
endmodule
