module processor_tb();
    logic clk;
    logic reset;
    logic halted;
    logic [31:0] cycle_count;
    logic [31:0] instruction_retired_count;
    logic [31:0] load_use_stall_count;
    logic [31:0] redirect_flush_count;
    logic [31:0] branch_count;
    logic [31:0] branch_taken_count;
    logic [31:0] branch_mispredict_count;
    logic [31:0] jump_count;
    logic [31:0] jump_mispredict_count;
    integer timeout_cycles;
    real ipc;
    real cpi;
    real branch_accuracy;
    real branch_mispredict_rate;

    processor proc(
        .clk(clk),
        .reset(reset),
        .halted(halted),
        .cycle_count(cycle_count),
        .instruction_retired_count(instruction_retired_count),
        .load_use_stall_count(load_use_stall_count),
        .redirect_flush_count(redirect_flush_count),
        .branch_count(branch_count),
        .branch_taken_count(branch_taken_count),
        .branch_mispredict_count(branch_mispredict_count),
        .jump_count(jump_count),
        .jump_mispredict_count(jump_mispredict_count)
    );

    task automatic write_word;
        input integer word_index;
        input logic [31:0] value;
        integer byte_addr;
        begin
            byte_addr = word_index * 4;
            proc.dmem.memory[byte_addr]     = value[7:0];
            proc.dmem.memory[byte_addr + 1] = value[15:8];
            proc.dmem.memory[byte_addr + 2] = value[23:16];
            proc.dmem.memory[byte_addr + 3] = value[31:24];
        end
    endtask

    task automatic check_word;
        input integer word_index;
        input logic [31:0] expected;
        integer byte_addr;
        logic [31:0] actual;
        begin
            byte_addr = word_index * 4;
            actual = {
                proc.dmem.memory[byte_addr + 3],
                proc.dmem.memory[byte_addr + 2],
                proc.dmem.memory[byte_addr + 1],
                proc.dmem.memory[byte_addr]
            };
            if (actual !== expected) begin
                $fatal(1, "array[%0d] expected %0d, got %0d (0x%08h)", word_index, expected, actual, actual);
            end
        end
    endtask

    initial begin
        $dumpfile("bubble_sort.vcd");
        $dumpvars(0, processor_tb);

        clk = 1'b0;
        reset = 1'b1;
        repeat (3) @(posedge clk);
        reset = 1'b0;

        write_word(0, 32'd9);
        write_word(1, 32'd3);
        write_word(2, 32'd7);
        write_word(3, 32'd1);
        write_word(4, 32'd5);
        write_word(5, 32'd8);
        write_word(6, 32'd2);
        write_word(7, 32'd4);
        write_word(8, 32'd6);

        timeout_cycles = 0;
        while (!halted && timeout_cycles < 5000) begin
            @(posedge clk);
            timeout_cycles = timeout_cycles + 1;
        end

        if (!halted) begin
            $fatal(1, "bubble sort benchmark timed out before ECALL retired");
        end

        check_word(0, 32'd1);
        check_word(1, 32'd2);
        check_word(2, 32'd3);
        check_word(3, 32'd4);
        check_word(4, 32'd5);
        check_word(5, 32'd6);
        check_word(6, 32'd7);
        check_word(7, 32'd8);
        check_word(8, 32'd9);

        ipc = instruction_retired_count;
        ipc = ipc / cycle_count;
        cpi = cycle_count;
        cpi = cpi / instruction_retired_count;

        if (ipc < 0.9) begin
            $fatal(1, "IPC target failed: expected >= 0.900000, got %0.6f", ipc);
        end

        if (branch_count != 0) begin
            branch_accuracy = branch_count - branch_mispredict_count;
            branch_accuracy = branch_accuracy / branch_count;
            branch_mispredict_rate = branch_mispredict_count;
            branch_mispredict_rate = branch_mispredict_rate / branch_count;
        end else begin
            branch_accuracy = 0.0;
            branch_mispredict_rate = 0.0;
        end

        $display("bubble_sort benchmark passed");
        $display("cycles=%0d", cycle_count);
        $display("retired_instructions=%0d", instruction_retired_count);
        $display("ipc=%0.6f", ipc);
        $display("cpi=%0.6f", cpi);
        $display("load_use_stalls=%0d", load_use_stall_count);
        $display("redirect_flushes=%0d", redirect_flush_count);
        $display("branches=%0d", branch_count);
        $display("branches_taken=%0d", branch_taken_count);
        $display("branch_mispredicts=%0d", branch_mispredict_count);
        $display("branch_accuracy=%0.6f", branch_accuracy);
        $display("branch_mispredict_rate=%0.6f", branch_mispredict_rate);
        $display("jumps=%0d", jump_count);
        $display("jump_mispredicts=%0d", jump_mispredict_count);
        $finish;
    end
  
    always begin
        #5
        clk = ~clk;
    end
endmodule
