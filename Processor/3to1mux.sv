module mux3 #(
    parameter int WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [WIDTH-1:0] c,
    input  logic [1:0]       ctrl,
    output logic [WIDTH-1:0] y
);
    always_comb begin
        case (ctrl)
            2'b00: y = a;
            2'b01: y = b;
            2'b10: y = c;
            default: y = a;
        endcase
    end
endmodule
