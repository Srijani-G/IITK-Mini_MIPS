module processor(
    input [31:0] data_from_cp1,
    input clk,
    input rst,
    output [31:0] inst,
    output [31:0] data_to_cp1,
    output overflow
);

    wire [31:0] pc_now, pc_next, pc_plus4;
    wire [31:0] fetched;
    wire [31:0] reg_a, reg_b, alu_res, mul_res, dmem_out;
    wire alu_ovf;

    // Instruction field extraction
    wire [5:0] op    = fetched[31:26];
    wire [4:0] r1    = fetched[25:21];
    wire [4:0] r2    = fetched[20:16];
    wire [4:0] r3    = fetched[15:11];
    wire [4:0] shft  = fetched[10:6];
    wire [5:0] func  = fetched[5:0];
    wire [15:0] imm  = fetched[15:0];
    wire [25:0] jaddr = fetched[25:0];

    assign inst = fetched;
    assign data_to_cp1 = reg_b;

    // Control signals
    wire reg3, jmp, jreg, ld, st, lnk, aimm, simm, lui;
    wire brnch, regwr, hload, cp1sel, ovfchk;
    wire [4:0] alu_sel;
    wire [2:0] mul_sel;

    // Program Counter
    pc_reg pc_unit (
        .next_pc(pc_next),
        .reset(rst),
        .clk(clk),
        .current_pc(pc_now)
    );

    // Instruction Memory
    mem_instruction imem (
        .addr_fetch(pc_now),
        .addr_store(32'b0),         // unused
        .insn_input(32'b0),         // unused
        .write_enable(1'b0),
        .clk_i(clk),
        .insn_output(fetched)
    );

    // Data Memory
    mem_data dmem (
        .access_addr(alu_res),
        .write_data(reg_b),
        .enable_write(st),
        .clk_i(clk),
        .read_data(dmem_out)
    );

    // Decoder
    inst_decoder decoder (
        .opcode(op),
        .funct(func),
        .needs_three_regs(reg3),
        .jump(jmp),
        .jump_reg(jreg),
        .load(ld),
        .store(st),
        .link(lnk),
        .alu_op(alu_sel),
        .alu_imm(aimm),
        .shift_imm(simm),
        .load_upper(lui),
        .branch(brnch),
        .write_to_register(regwr),
        .load_from_hi_lo(hload),
        .mul_op(mul_sel),
        .from_cp1(cp1sel),
        .has_overflow(ovfchk)
    );

    // Register File
    register_file regs (
        .src1(r1),
        .src2(r2),
        .dest(reg3 ? r3 : (lnk ? 5'd31 : r2)),
        .wr_data(ld ? dmem_out : (lnk ? pc_plus4 : (cp1sel ? data_from_cp1 : alu_res))),
        .wr_en(regwr),
        .clk(clk),
        .rd_data1(reg_a),
        .rd_data2(reg_b)
    );

    // ALU
    alu core_alu (
        .a(simm ? {27'b0, shft} : (lui ? 32'd16 : reg_a)),
        .b(hload ? mul_res : (aimm ? {{16{imm[15]}}, imm} : reg_b)),
        .op_code(alu_sel),
        .use_imm(aimm),
        .result(alu_res),
        .has_overflow(alu_ovf)
    );

    assign overflow = ovfchk ? alu_ovf : 1'b0;

    // Multiplier
    multiplier mcore (
        .in1(reg_a),
        .in2(reg_b),
        .mul_op(mul_sel),
        .clk(clk),
        .out(mul_res)
    );

    // PC + 4
    assign pc_plus4 = pc_now + 32'd4;

    // Branch/Jump Logic
    assign pc_next = jmp ? (jreg ? reg_a : {pc_plus4[31:28], jaddr, 2'b00}) :
                      (brnch && alu_res[0]) ? (pc_plus4 + {{14{imm[15]}}, imm, 2'b00}) :
                      pc_plus4;

endmodule
