module mem_instruction #(
    parameter MEM_SIZE = 512,
    parameter WIDTH = 32,
    parameter IDX_WIDTH = 9  // $clog2(512) = 9
)(
    input [IDX_WIDTH + 1 : 0] addr_fetch,
    input [IDX_WIDTH + 1 : 0] addr_store,
    input [WIDTH - 1 : 0] insn_input,
    input write_enable,
    input clk_i,
    output [WIDTH - 1 : 0] insn_output
);

    simple_dual_port_distributed_ram_0 rom_ram_block (
        .d(insn_input),
        .a(addr_store[IDX_WIDTH + 1 : 2]),  // word-aligned write address
        .dpra(addr_fetch[IDX_WIDTH + 1 : 2]),  // word-aligned read address
        .dpo(insn_output),
        .clk(clk_i),
        .we(write_enable)
    );

endmodule
