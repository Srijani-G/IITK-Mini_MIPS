module mem_data #(
    parameter MEM_SIZE = 512,
    parameter WIDTH = 32,
    parameter IDX_WIDTH = 9  
)(
    input [IDX_WIDTH + 1 : 0] access_addr,
    input [WIDTH - 1 : 0] write_data,
    input enable_write,
    input clk_i,
    output [WIDTH - 1 : 0] read_data
);

    single_port_distributed_ram_0 mem_core (
        .d(write_data),
        .a(access_addr[IDX_WIDTH + 1 : 2]),  // word-aligned
        .spo(read_data),
        .clk(clk_i),
        .we(enable_write)
    );

endmodule
