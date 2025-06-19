module fpu_inst_decoder #(
    parameter OP_MFC1   = 5'h0,
    parameter OP_MTC1   = 5'h4,
    parameter OP_COP1_S = 5'h10,

    parameter FN_ADD = 6'h0,
    parameter FN_SUB = 6'h1,
    parameter FN_CEQ = 6'd50,
    parameter FN_CLE = 6'd62,
    parameter FN_CLT = 6'd60,
    parameter FN_CGE = 6'd40,
    parameter FN_CGT = 6'd42,
    parameter FN_MOV = 6'h6,

    parameter FPU_OP_ADD = 3'h0,
    parameter FPU_OP_SUB = 3'h1,
    parameter FPU_OP_EQ  = 3'h2,
    parameter FPU_OP_LT  = 3'h3,
    parameter FPU_OP_GT  = 3'h4,
    parameter FPU_OP_LE  = 3'h5,
    parameter FPU_OP_GE  = 3'h6,
    parameter FPU_OP_MOV = 3'h7
)(
    input  [4:0] op,
    input  [5:0] fn,
    output reg        write_en,
    output reg        flag_en,
    output reg [2:0]  op_code,
    output reg        from_cpu
);

    always @(*) begin
        case (op)
            OP_MTC1: write_en = 1'b1;
            OP_COP1_S: write_en = (fn < 6'd40) ? 1'b1 : 1'b0;
            default: write_en = 1'b0;
        endcase

        flag_en = (op == OP_COP1_S && fn >= 6'd40) ? 1'b1 : 1'b0;

        case (fn)
            FN_ADD: op_code = FPU_OP_ADD;
            FN_SUB: op_code = FPU_OP_SUB;
            FN_CEQ: op_code = FPU_OP_EQ;
            FN_CLT: op_code = FPU_OP_LT;
            FN_CGT: op_code = FPU_OP_GT;
            FN_CLE: op_code = FPU_OP_LE;
            FN_CGE: op_code = FPU_OP_GE;
            FN_MOV: op_code = FPU_OP_MOV;
            default: op_code = 3'bxxx;
        endcase

        case (op)
            OP_MFC1:   from_cpu = 1'b1;
            OP_COP1_S: from_cpu = 1'b0;
            default:   from_cpu = 1'bx;
        endcase
    end

endmodule
