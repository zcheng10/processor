module IMEM #(
    parameter int MEM_WORDS = 1024,
    parameter string INIT_FILE = "program.hex"
)(
    input  logic [31:0] read_address,
    output logic [31:0] instruction
);
    logic [31:0] memory [0:MEM_WORDS-1];
    logic [29:0] word_address;
    integer file_handle;
    integer scan_count;
    integer load_index;
    integer skipped_char;
    logic [31:0] loaded_word;

    initial begin
        for (int i = 0; i < MEM_WORDS; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP
        end
        if (INIT_FILE != "") begin
            file_handle = $fopen(INIT_FILE, "r");
            if (file_handle != 0) begin
                load_index = 0;
                while (!$feof(file_handle) && (load_index < MEM_WORDS)) begin
                    scan_count = $fscanf(file_handle, "%h\n", loaded_word);
                    if (scan_count == 1) begin
                        memory[load_index] = loaded_word;
                        load_index = load_index + 1;
                    end else begin
                        skipped_char = $fgetc(file_handle);
                    end
                end
                $fclose(file_handle);
            end else begin
                $display("WARNING: could not open instruction memory init file '%s'; using NOPs", INIT_FILE);
            end
        end
    end

    assign word_address = read_address[31:2];

    always_comb begin
        if (word_address < MEM_WORDS) begin
            instruction = memory[word_address];
        end else begin
            instruction = 32'h00000013;
        end
    end
endmodule
