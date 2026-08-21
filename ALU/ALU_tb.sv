module ALU_tb();
    logic [31:0] A, B; 
    logic [3:0] aluControl;
    logic [31:0] res;
    logic zeroFlag;

    ALU alu_inst(
        .A(A),
        .B(B),
        .aluControl(aluControl),
        .res(res),
        .zeroFlag(zeroFlag)
    );

    task automatic check_alu;
        input logic [3:0]  ctrl;
        input logic [31:0] a;
        input logic [31:0] b;
        input logic [31:0] expected;
        input integer      test_id;
        begin
            A = a;
            B = b;
            aluControl = ctrl;
            #1;
            if (res !== expected) begin
                $fatal(1, "ALU test %0d failed: expected 0x%08h, got 0x%08h", test_id, expected, res);
            end
        end
    endtask

    initial begin
        check_alu(4'b0010, 32'd10, 32'd5, 32'd15, 1);
        check_alu(4'b0110, 32'd10, 32'd5, 32'd5, 2);
        check_alu(4'b0000, 32'h0000000c, 32'h0000000a, 32'h00000008, 3);
        check_alu(4'b0001, 32'h0000000c, 32'h0000000a, 32'h0000000e, 4);
        check_alu(4'b0100, 32'h0000000c, 32'h0000000a, 32'h00000006, 5);
        check_alu(4'b0011, 32'h00000001, 32'h00000021, 32'h00000002, 6);
        check_alu(4'b0101, 32'h80000000, 32'h0000001f, 32'h00000001, 7);
        check_alu(4'b1010, 32'h80000000, 32'h0000001f, 32'hffffffff, 8);
        check_alu(4'b0111, 32'hffffffff, 32'h00000001, 32'h00000001, 9);
        check_alu(4'b1000, 32'hffffffff, 32'h00000001, 32'h00000000, 10);
        check_alu(4'b0110, 32'd5, 32'd5, 32'd0, 11);
        if (zeroFlag !== 1'b1) $fatal(1, "zeroFlag expected high");

        $display("ALU_tb passed");
        $finish;
    end
endmodule
