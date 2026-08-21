module DMEM #(
    parameter int MEM_BYTES = 4096
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        memWrite,
    input  logic        memRead,
    input  logic [2:0]  funct3,
    input  logic [31:0] aluResult,
    input  logic [31:0] writeData,
    output logic [31:0] readData
);
    logic [7:0] memory [0:MEM_BYTES-1];

    integer i;
    logic [31:0] addr;
    logic [7:0]  byte0;
    logic [7:0]  byte1;
    logic [7:0]  byte2;
    logic [7:0]  byte3;
    logic [15:0] halfword;
    logic [31:0] word;

    assign addr = aluResult;
    assign byte0 = in_range(addr)     ? memory[addr]     : 8'd0;
    assign byte1 = in_range(addr + 1) ? memory[addr + 1] : 8'd0;
    assign byte2 = in_range(addr + 2) ? memory[addr + 2] : 8'd0;
    assign byte3 = in_range(addr + 3) ? memory[addr + 3] : 8'd0;
    assign halfword = {byte1, byte0};
    assign word = {byte3, byte2, byte1, byte0};

    function automatic logic in_range(input logic [31:0] address);
        in_range = (address < MEM_BYTES);
    endfunction

    always @* begin
        if (!memRead) begin
            readData = 32'd0;
        end else begin
            case (funct3)
                3'b000: readData = {{24{byte0[7]}}, byte0};       // LB
                3'b001: readData = {{16{halfword[15]}}, halfword}; // LH
                3'b010: readData = word;                           // LW
                3'b100: readData = {24'd0, byte0};                 // LBU
                3'b101: readData = {16'd0, halfword};              // LHU
                default: readData = 32'd0;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < MEM_BYTES; i = i + 1) begin
                memory[i] <= 8'd0;
            end
        end else if (memWrite) begin
            case (funct3)
                3'b000: begin // SB
                    if (in_range(addr)) memory[addr] <= writeData[7:0];
                end
                3'b001: begin // SH
                    if (in_range(addr))     memory[addr]     <= writeData[7:0];
                    if (in_range(addr + 1)) memory[addr + 1] <= writeData[15:8];
                end
                3'b010: begin // SW
                    if (in_range(addr))     memory[addr]     <= writeData[7:0];
                    if (in_range(addr + 1)) memory[addr + 1] <= writeData[15:8];
                    if (in_range(addr + 2)) memory[addr + 2] <= writeData[23:16];
                    if (in_range(addr + 3)) memory[addr + 3] <= writeData[31:24];
                end
                default: begin
                end
            endcase
        end
    end
endmodule
