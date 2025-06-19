module alu #(
    parameter WIDTH = 32,
    parameter OP_ADD  = 5'd0,
    parameter OP_SUB  = 5'd16,
    parameter OP_AND  = 5'd1,
    parameter OP_OR   = 5'd2,
    parameter OP_NOT  = 5'd3,
    parameter OP_XOR  = 5'd4,
    parameter OP_SLL  = 5'd5,
    parameter OP_SRL  = 5'd6,
    parameter OP_SRA  = 5'd7,
    parameter OP_EQ   = 5'd8,
    parameter OP_NE   = 5'd9,
    parameter OP_LT   = 5'd10,
    parameter OP_GT   = 5'd11,
    parameter OP_LE   = 5'd12,
    parameter OP_GE   = 5'd13,
    parameter OP_LTU  = 5'd14,
    parameter OP_GTU  = 5'd15
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [4:0] op_code,
    input  use_imm,
    output reg [WIDTH-1:0] result,
    output reg has_overflow
);

    wire [WIDTH-1:0] imm_signed  = $signed(b[WIDTH/2-1:0]);
    wire [WIDTH-1:0] imm_unsigned = { {(WIDTH/2){1'b0}}, b[WIDTH/2-1:0] };

    wire [WIDTH-1:0] lhs = a;
    reg  [WIDTH-1:0] rhs;

    always @* begin
        if (use_imm) begin
            case (op_code)
                OP_ADD, OP_SUB, OP_EQ, OP_NE, OP_LT, OP_GT, OP_LE, OP_GE:
                    rhs = imm_signed;
                default:
                    rhs = imm_unsigned;
            endcase
        end else begin
            rhs = b;
        end
    end

    wire [WIDTH:0] arith_out;
    wire carry_flag = arith_out[WIDTH];

    int_addsub_0 calc_unit (
        .A(lhs),
        .B(rhs),
        .ADD((op_code == OP_ADD) ? 1'b1 :
             (op_code == OP_SUB) ? 1'b0 : 1'bx),
        .S(arith_out)
    );

    wire overflow_flag = carry_flag ^ arith_out[WIDTH-1];
    wire signed_lt = $signed(lhs) < $signed(rhs);
    wire is_equal  = lhs == rhs;
    wire unsigned_lt = $unsigned(lhs) < $unsigned(rhs);

    always @* begin
        case (op_code)
            OP_ADD, OP_SUB: result = arith_out[WIDTH-1:0];
            OP_AND: result = lhs & rhs;
            OP_OR:  result = lhs | rhs;
            OP_NOT: result = ~rhs;
            OP_XOR: result = lhs ^ rhs;
            OP_SLL: result = rhs << lhs[4:0];
            OP_SRL: result = rhs >> lhs[4:0];
            OP_SRA: result = $signed(rhs) >>> lhs[4:0];
            OP_EQ:  result = is_equal;
            OP_NE:  result = ~is_equal;
            OP_LT:  result = signed_lt;
            OP_GT:  result = ~(signed_lt | is_equal);
            OP_LE:  result = signed_lt | is_equal;
            OP_GE:  result = ~signed_lt;
            OP_LTU: result = unsigned_lt;
            OP_GTU: result = ~(unsigned_lt | is_equal);
            default: result = {WIDTH{1'bx}};
        endcase

        case (op_code)
            OP_ADD, OP_SUB: has_overflow = overflow_flag;
            default: has_overflow = 1'bx;
        endcase
    end
endmodule
