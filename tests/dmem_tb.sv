module dmem_tb();
    logic        clk;
    logic        reset;
    logic        memWrite;
    logic        memRead;
    logic [2:0]  funct3;
    logic [31:0] aluResult;
    logic [31:0] writeData;
    logic [31:0] readData;

    DMEM #(.MEM_BYTES(64)) dut(
        .clk(clk),
        .reset(reset),
        .memWrite(memWrite),
        .memRead(memRead),
        .funct3(funct3),
        .aluResult(aluResult),
        .writeData(writeData),
        .readData(readData)
    );

    always #5 clk = ~clk;

    task automatic write_mem;
        input logic [2:0]  f3;
        input logic [31:0] addr;
        input logic [31:0] data;
        begin
            @(negedge clk);
            memWrite = 1'b1;
            memRead = 1'b0;
            funct3 = f3;
            aluResult = addr;
            writeData = data;
            @(posedge clk);
            #1;
            memWrite = 1'b0;
        end
    endtask

    task automatic read_mem;
        input logic [2:0]  f3;
        input logic [31:0] addr;
        input logic [31:0] expected;
        input integer      test_id;
        begin
            @(negedge clk);
            memWrite = 1'b0;
            memRead = 1'b1;
            funct3 = f3;
            aluResult = addr;
            #1;
            if (readData !== expected) begin
                $fatal(1, "DMEM test %0d expected 0x%08h, got 0x%08h", test_id, expected, readData);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        memWrite = 1'b0;
        memRead = 1'b0;
        funct3 = 3'b000;
        aluResult = 32'd0;
        writeData = 32'd0;
        repeat (2) @(posedge clk);
        reset = 1'b0;

        write_mem(3'b010, 32'd4, 32'haabbccdd); // SW
        read_mem(3'b010, 32'd4, 32'haabbccdd, 1);
        read_mem(3'b000, 32'd4, 32'hffffffdd, 2);
        read_mem(3'b100, 32'd4, 32'h000000dd, 3);
        read_mem(3'b001, 32'd4, 32'hffffccdd, 4);
        read_mem(3'b101, 32'd4, 32'h0000ccdd, 5);

        write_mem(3'b000, 32'd12, 32'h00000080); // SB
        read_mem(3'b000, 32'd12, 32'hffffff80, 6);

        write_mem(3'b001, 32'd14, 32'h00008001); // SH
        read_mem(3'b001, 32'd14, 32'hffff8001, 7);

        $display("dmem_tb passed");
        $finish;
    end
endmodule
