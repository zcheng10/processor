module ImmGen(
    input  logic [31:7] instruction,
    input  logic [2:0]  ImmSrc,
    output logic [31:0] immediate
);
    always @* begin
        case (ImmSrc)
            3'b001: immediate = {{20{instruction[31]}}, instruction[31:20]}; // I-type
            3'b010: immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
            3'b011: immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
            3'b100: immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
            3'b101: immediate = {instruction[31:12], 12'b0}; // U-type
            default: immediate = 32'd0;
        endcase
    end
endmodule
