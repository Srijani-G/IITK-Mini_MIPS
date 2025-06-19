module register_file #(
    parameter REG_COUNT = 32,
    parameter WIDTH = 32,
    parameter IDX_WIDTH = 5  // log2(REG_COUNT) = 5 for 32 registers
)(
    input  [IDX_WIDTH-1:0] src1,
    input  [IDX_WIDTH-1:0] src2,
    input  [IDX_WIDTH-1:0] dest,
    input  [WIDTH-1:0]     wr_data,
    input  wr_en,
    input  clk,
    output [WIDTH-1:0]     rd_data1,
    output [WIDTH-1:0]     rd_data2
);

    // Register file: reg[0] is hardwired to zero
    reg [WIDTH-1:0] regs [0:REG_COUNT-1];

    // Read ports
    assign rd_data1 = (src1 == 0) ? {WIDTH{1'b0}} : regs[src1];
    assign rd_data2 = (src2 == 0) ? {WIDTH{1'b0}} : regs[src2];

    // Write port
    always @(posedge clk) begin
        if (wr_en && dest != 0)
            regs[dest] <= wr_data;
    end

endmodule
