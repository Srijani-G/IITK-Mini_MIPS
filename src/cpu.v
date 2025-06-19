//module cpu (
//    input clock,
//    input reset
//);

//    wire [31:0] pipe1_data_in;
//    wire [31:0] pipe1_data_out;
//    wire [31:0] pipe1_instruction;
//    wire flag_overflow;
//    wire [7:0] status_flags;

//    processor core (
//        .clk(clock),
//        .rst(reset),
//        .data_from_cp1(pipe1_data_in),
//        .data_to_cp1(pipe1_data_out),
//        .inst(pipe1_instruction),
//        .overflow(flag_overflow)
//    );

//    fpu_coprocessor coproc1 (
//        .clk(clock),
//        .inst(pipe1_instruction),
//        .in_data(pipe1_data_out),
//        .out_data(pipe1_data_in),
//        .flags(status_flags)
//    );

//endmodule

module cpu (
    input clock,
    input reset
  
);

    wire [31:0] pipe1_data_in;
    wire [31:0] pipe1_data_out;
    wire [31:0] pipe1_instruction;
    wire flag_overflow;
    wire [7:0] status_flags;

  

    processor core (
        .clk(clock),
        .rst(reset),
        .data_from_cp1(pipe1_data_in),
        .data_to_cp1(pipe1_data_out),
        .inst(pipe1_instruction),
        .overflow(flag_overflow)
    );

    fpu_coprocessor coproc1 (
        .clk(clock),
        .inst(pipe1_instruction),
        .in_data(pipe1_data_out),
        .out_data(pipe1_data_in),
        .flags(status_flags)
    );

endmodule
