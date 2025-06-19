module ir_latch #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] in_data,
    input clk,
    output reg [WIDTH-1:0] out_data
);

    always @(posedge clk)
        out_data <= in_data;

endmodule
