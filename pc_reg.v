module pc_reg #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] next_pc,
    input reset,
    input clk,
    output reg [WIDTH-1:0] current_pc
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            current_pc <= {WIDTH{1'b0}};
        else
            current_pc <= next_pc;
    end

endmodule
