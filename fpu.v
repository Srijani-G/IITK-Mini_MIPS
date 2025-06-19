module fpu #(
    parameter OP_ADD = 3'h0,
    parameter OP_SUB = 3'h1,
    parameter OP_EQ  = 3'h2,
    parameter OP_LT  = 3'h3,
    parameter OP_GT  = 3'h4,
    parameter OP_LE  = 3'h5,
    parameter OP_GE  = 3'h6,
    parameter OP_MOV = 3'h7
)(
    input  [31:0] a,
    input  [31:0] b,
    input  [2:0]  op,
    output reg [31:0] result
);

    wire [31:0] addsub_res;
    wire lt, eq, gt;

    fp_addsub_0 adder_unit (
        .s_axis_a_tdata(a),
        .s_axis_b_tdata(b),
        .s_axis_operation_tdata((op == OP_ADD) ? 8'd0 :
                                 (op == OP_SUB) ? 8'd1 : 8'dx),
        .m_axis_result_tdata(addsub_res)
    );

    fp_compare_0 cmp_unit (
        .s_axis_a_tdata(a),
        .s_axis_b_tdata(b),
        .m_axis_result_tdata({gt, lt, eq})
    );

    always @(*) begin
        case (op)
            OP_ADD, OP_SUB: result = addsub_res;
            OP_EQ:  result = {31'b0, eq};
            OP_LT:  result = {31'b0, lt};
            OP_GT:  result = {31'b0, gt};
            OP_LE:  result = {31'b0, lt | eq};
            OP_GE:  result = {31'b0, gt | eq};
            OP_MOV: result = a;
            default: result = 32'hxxxx_xxxx;
        endcase
    end

endmodule
