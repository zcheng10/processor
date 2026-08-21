module immgen_tb();
    logic [31:0] instruction;
    logic [2:0]  immSrc;
    logic [31:0] immediate;

    ImmGen dut(
        .instruction(instruction[31:7]),
        .ImmSrc(immSrc),
        .immediate(immediate)
    );

    function automatic logic [31:0] encode_i(
        input int imm,
        input int rs1,
        input int funct3,
        input int rd,
        input int opcode
    );
        encode_i = (((imm & 12'hfff) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode);
    endfunction

    function automatic logic [31:0] encode_s(
        input int imm,
        input int rs2,
        input int rs1,
        input int funct3,
        input int opcode
    );
        encode_s = ((((imm >> 5) & 7'h7f) << 25) | (rs2 << 20) | (rs1 << 15) |
                    (funct3 << 12) | ((imm & 5'h1f) << 7) | opcode);
    endfunction

    function automatic logic [31:0] encode_b(
        input int imm,
        input int rs2,
        input int rs1,
        input int funct3,
        input int opcode
    );
        encode_b = ((((imm >> 12) & 1) << 31) | (((imm >> 5) & 6'h3f) << 25) |
                    (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
                    (((imm >> 1) & 4'hf) << 8) | (((imm >> 11) & 1) << 7) | opcode);
    endfunction

    function automatic logic [31:0] encode_u(
        input int imm20,
        input int rd,
        input int opcode
    );
        encode_u = ((imm20 & 20'hfffff) << 12) | (rd << 7) | opcode;
    endfunction

    function automatic logic [31:0] encode_j(
        input int imm,
        input int rd,
        input int opcode
    );
        encode_j = ((((imm >> 20) & 1) << 31) | (((imm >> 1) & 10'h3ff) << 21) |
                    (((imm >> 11) & 1) << 20) | (((imm >> 12) & 8'hff) << 12) |
                    (rd << 7) | opcode);
    endfunction

    task automatic check;
        input logic [31:0] inst;
        input logic [2:0]  src;
        input logic [31:0] expected;
        input integer      test_id;
        begin
            instruction = inst;
            immSrc = src;
            #1;
            if (immediate !== expected) begin
                $fatal(1, "ImmGen test %0d expected 0x%08h, got 0x%08h", test_id, expected, immediate);
            end
        end
    endtask

    initial begin
        check(encode_i(-1, 0, 3'b000, 1, 7'h13), 3'b001, 32'hffffffff, 1);
        check(encode_s(-4, 2, 1, 3'b010, 7'h23), 3'b010, 32'hfffffffc, 2);
        check(encode_b(16, 2, 1, 3'b000, 7'h63), 3'b011, 32'd16, 3);
        check(encode_b(-16, 2, 1, 3'b000, 7'h63), 3'b011, 32'hfffffff0, 4);
        check(encode_j(2048, 1, 7'h6f), 3'b100, 32'd2048, 5);
        check(encode_j(-2048, 1, 7'h6f), 3'b100, 32'hfffff800, 6);
        check(encode_u(20'h12345, 1, 7'h37), 3'b101, 32'h12345000, 7);

        $display("immgen_tb passed");
        $finish;
    end
endmodule
