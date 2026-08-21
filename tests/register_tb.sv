module register_tb();
    logic        clk;
    logic        reset;
    logic        regWrite;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [31:0] result;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    register dut(
        .clk(clk),
        .reset(reset),
        .regWrite(regWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .result(result),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        regWrite = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd1;
        rd = 5'd0;
        result = 32'd0;
        repeat (2) @(posedge clk);
        reset = 1'b0;

        @(negedge clk);
        regWrite = 1'b1;
        rd = 5'd1;
        result = 32'hdeadbeef;
        rs1 = 5'd1;
        #1;
        if (rs1_data !== 32'hdeadbeef) $fatal(1, "same-cycle write/read bypass failed");

        @(posedge clk);
        #1;
        if (dut.registers[1] !== 32'hdeadbeef) $fatal(1, "register write failed");

        @(negedge clk);
        rd = 5'd0;
        result = 32'hffffffff;
        rs1 = 5'd0;
        @(posedge clk);
        #1;
        if (rs1_data !== 32'd0 || dut.registers[0] !== 32'd0) $fatal(1, "x0 write protection failed");

        $display("register_tb passed");
        $finish;
    end
endmodule
