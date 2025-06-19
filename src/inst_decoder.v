module inst_decoder #(
    // Opcodes
    parameter OP_RTYPE = 6'h0,
    parameter OP_MADD  = 6'h1c,
    parameter OP_MADDU = 6'h1c,
    parameter OP_ADDI  = 6'h8,
    parameter OP_ADDIU = 6'h9,
    parameter OP_ANDI  = 6'hc,
    parameter OP_ORI   = 6'hd,
    parameter OP_XORI  = 6'he,
    parameter OP_LW    = 6'h23,
    parameter OP_SW    = 6'h2b,
    parameter OP_LUI   = 6'hf,
    parameter OP_BEQ   = 6'h4,
    parameter OP_BNE   = 6'h5,
    parameter OP_BGT   = 6'h7,
    parameter OP_BGTE  = 6'h1,
    parameter OP_BLE   = 6'h1,
    parameter OP_BLEQ  = 6'h7,
    parameter OP_BLEU  = 6'h16,
    parameter OP_BGTU  = 6'h17,
    parameter OP_SLTI  = 6'ha,
    parameter OP_SEQ   = 6'h18,
    parameter OP_J     = 6'h2,
    parameter OP_JAL   = 6'h3,
    parameter OP_CP1   = 6'h11,

    // Func codes
    parameter FUNC_ADD   = 6'h20,
    parameter FUNC_SUB   = 6'h22,
    parameter FUNC_ADDU  = 6'h21,
    parameter FUNC_SUBU  = 6'h23,
    parameter FUNC_MADD  = 6'h0,
    parameter FUNC_MADDU = 6'h1,
    parameter FUNC_MUL   = 6'h18,
    parameter FUNC_AND   = 6'h24,
    parameter FUNC_OR    = 6'h25,
    parameter FUNC_NOT   = 6'h27,
    parameter FUNC_XOR   = 6'h26,
    parameter FUNC_SLL   = 6'h0,
    parameter FUNC_SRL   = 6'h2,
    parameter FUNC_SLA   = 6'h0,
    parameter FUNC_SRA   = 6'h3,
    parameter FUNC_SLT   = 6'h2a,
    parameter FUNC_JR    = 6'h8,
    parameter FUNC_MFHI  = 6'h10,
    parameter FUNC_MFLO  = 6'h12,

    // ALU ops
    parameter ALU_ADD = 5'h0,
    parameter ALU_SUB = 5'h10,
    parameter ALU_AND = 5'h1,
    parameter ALU_OR  = 5'h2,
    parameter ALU_NOT = 5'h3,
    parameter ALU_XOR = 5'h4,
    parameter ALU_SLL = 5'h5,
    parameter ALU_SRL = 5'h6,
    parameter ALU_SRA = 5'h7,
    parameter ALU_EQ  = 5'h8,
    parameter ALU_NE  = 5'h9,
    parameter ALU_LT  = 5'ha,
    parameter ALU_GT  = 5'hb,
    parameter ALU_LE  = 5'hc,
    parameter ALU_GE  = 5'hd,
    parameter ALU_LTU = 5'he,
    parameter ALU_GTU = 5'hf,

    // MUL ops
    parameter MUL_MADD  = 3'b000,
    parameter MUL_MADDU = 3'b001,
    parameter MUL_MUL   = 3'b010,
    parameter MUL_MFHI  = 3'b101,
    parameter MUL_MFLO  = 3'b100
)(
    input [5:0] opcode,
    input [5:0] funct,
    output reg needs_three_regs,
    output reg jump,
    output reg jump_reg,
    output reg load,
    output reg store,
    output reg link,
    output reg [5:0] alu_op,
    output reg alu_imm,
    output reg shift_imm,
    output reg load_upper,
    output reg branch,
    output reg write_to_register,
    output reg load_from_hi_lo,
    output reg [2:0] mul_op,
    output reg from_cp1,
    output reg has_overflow
);

    always @(*) begin
        // Default values
        needs_three_regs = 0;
        jump = 0;
        jump_reg = 0;
        load = 0;
        store = 0;
        link = 0;
        alu_op = 5'bxxxxx;
        alu_imm = 0;
        shift_imm = 0;
        load_upper = 0;
        branch = 0;
        write_to_register = 0;
        load_from_hi_lo = 0;
        mul_op = MUL_MFLO;
        from_cp1 = 0;
        has_overflow = 0;

        // Needs three registers
        if (opcode == OP_RTYPE) needs_three_regs = 1;

        // Jumps
        if (opcode == OP_J || opcode == OP_JAL || (opcode == OP_RTYPE && funct == FUNC_JR))
            jump = 1;

        jump_reg = (opcode == OP_RTYPE && funct == FUNC_JR);

        // Memory
        load = (opcode == OP_LW);
        store = (opcode == OP_SW);

        // Link (JAL)
        link = (opcode == OP_JAL);

        // Branch
        branch = (opcode == OP_BEQ || opcode == OP_BNE || opcode == OP_BGT || opcode == OP_BGTE ||
                  opcode == OP_BLE || opcode == OP_BLEQ || opcode == OP_BLEU || opcode == OP_BGTU);

        // ALU ops
        case (opcode)
            OP_ADDI, OP_ADDIU, OP_LW, OP_SW: alu_op = ALU_ADD;
            OP_ANDI: alu_op = ALU_AND;
            OP_ORI:  alu_op = ALU_OR;
            OP_XORI: alu_op = ALU_XOR;
            OP_LUI:  alu_op = ALU_SLL;
            OP_SEQ, OP_BEQ: alu_op = ALU_EQ;
            OP_BNE:  alu_op = ALU_NE;
            OP_BGT:  alu_op = ALU_GT;
            OP_BGTE: alu_op = ALU_GE;
            OP_SLTI, OP_BLE: alu_op = ALU_LT;
            OP_BLEQ: alu_op = ALU_LE;
            OP_BLEU: alu_op = ALU_LTU;
            OP_BGTU: alu_op = ALU_GTU;
            OP_RTYPE: begin
                case (funct)
                    FUNC_ADD, FUNC_ADDU: alu_op = ALU_ADD;
                    FUNC_SUB, FUNC_SUBU: alu_op = ALU_SUB;
                    FUNC_AND: alu_op = ALU_AND;
                    FUNC_OR:  alu_op = ALU_OR;
                    FUNC_NOT: alu_op = ALU_NOT;
                    FUNC_XOR: alu_op = ALU_XOR;
                    FUNC_SLL, FUNC_SLA: alu_op = ALU_SLL;
                    FUNC_SRL: alu_op = ALU_SRL;
                    FUNC_SRA: alu_op = ALU_SRA;
                    FUNC_SLT: alu_op = ALU_LT;
                    FUNC_MFHI, FUNC_MFLO: alu_op = ALU_OR;
                    default: alu_op = 5'bxxxxx;
                endcase
            end
        endcase

        // Immediate ALU
        alu_imm = (opcode != OP_RTYPE) && !branch;

        // Shift Immediate
        shift_imm = (opcode == OP_RTYPE &&
                    (funct == FUNC_SLL || funct == FUNC_SLA || funct == FUNC_SRL || funct == FUNC_SRA));

        // Load upper immediate
        load_upper = (opcode == OP_LUI);

        // Write to reg
        write_to_register = !(branch || store || (jump && !jump_reg));

        // Load from hi/lo
        load_from_hi_lo = (opcode == OP_RTYPE && 
                          (funct == FUNC_MFHI || funct == FUNC_MFLO));

        // Multiplier ops
        if (opcode == OP_MADD || opcode == OP_MADDU) begin
            case (funct)
                FUNC_MADD:  mul_op = MUL_MADD;
                FUNC_MADDU: mul_op = MUL_MADDU;
                default:    mul_op = MUL_MFLO;
            endcase
        end else if (opcode == OP_RTYPE) begin
            case (funct)
                FUNC_MUL:  mul_op = MUL_MUL;
                FUNC_MFHI: mul_op = MUL_MFHI;
                FUNC_MFLO: mul_op = MUL_MFLO;
                default:   mul_op = MUL_MFLO;
            endcase
        end

        // Coprocessor
        from_cp1 = (opcode == OP_CP1);

        // Overflow
        if ((opcode == OP_RTYPE && (funct == FUNC_ADD || funct == FUNC_SUB)) || opcode == OP_ADDI)
            has_overflow = 1;
    end

endmodule
