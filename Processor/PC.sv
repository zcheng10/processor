module PC(
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic [31:0] PC_next,
    output logic [31:0] PC_current
);
    always_ff @(posedge clk) begin
        if (reset) begin
            PC_current <= 32'd0;
        end else if (!stall) begin
            PC_current <= PC_next;
        end
    end
endmodule
