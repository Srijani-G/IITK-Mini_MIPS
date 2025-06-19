module fpu_coprocessor #(
    parameter NREG = 32,
    parameter NFLAGS = 8
)(
    input  [31:0] inst,
    input  [31:0] in_data,
    input         clk,
    output [31:0] out_data,
    output [NFLAGS-1:0] flags
);

    reg [31:0] rf [0:NREG-1];
    reg [NFLAGS-1:0] flag_reg;

    // Instruction decoding
    wire [5:0] opc;
    wire [4:0] fop, ft, fs, fd;
    wire [2:0] cond;
    wire [5:0] fn;

    assign {opc, fop, ft, fs, fd, fn} = inst;
    assign cond = fd[4:2];
    assign out_data = rf[fs];
    assign flags = flag_reg;

    // Control signals
    wire we_reg, we_flag, from_cpu;
    wire [2:0] op_sel;
    wire [31:0] alu_out;

    fpu_inst_decoder decoder (
        .op(fop),
        .fn(fn),
        .write_en(we_reg),
        .flag_en(we_flag),
        .op_code(op_sel),
        .from_cpu(from_cpu)
    );

    fpu fpu_core (
        .a(rf[fs]),
        .b(rf[ft]),
        .op(op_sel),
        .result(alu_out)
    );

    always @(posedge clk) begin
        if (opc == 6'h11) begin
            if (we_reg)
                rf[fd] <= from_cpu ? in_data : alu_out;
            if (we_flag)
                flag_reg[cond] <= alu_out[0];
        end
    end

endmodule
