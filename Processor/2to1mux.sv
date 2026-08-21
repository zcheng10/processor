module mux2 #(
    parameter int WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic             ctrl,
    output logic [WIDTH-1:0] y
);
    always_comb begin
        y = ctrl ? b : a;
    end
endmodule
