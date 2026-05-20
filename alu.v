module alu (
    input  wire enable,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] c,
    input  wire [1:0] l_arg,
    input  wire [1:0] r_arg,
    input  wire cmd_add,
    input  wire cmd_sub,
    input  wire cmd_and,
    input  wire cmd_or,
    input  wire cmd_xor,
    
    output wire [7:0] data_bus,
    output wire       zero_flag,
    output wire       negative_flag
);

    wire [7:0] op_l;
    wire [7:0] op_r;
    wire [7:0] result;
    
    assign op_l = (l_arg == 2'b00) ? a :
                  (l_arg == 2'b01) ? b :
                  (l_arg == 2'b10) ? c :
                                     8'b00000000;

    assign op_r = (r_arg == 2'b00) ? a :
                  (r_arg == 2'b01) ? b :
                  (r_arg == 2'b10) ? c :
                                     8'b00000000;

    assign result = cmd_add ? (op_l + op_r) :
                             cmd_sub ? (op_l - op_r) :
                             cmd_and ? (op_l & op_r) :
                             cmd_or  ? (op_l | op_r) :
                             cmd_xor ? (op_l ^ op_r) :
                             8'b00000000;

    assign data_bus = enable ? result : 8'bz;
    assign zero_flag = (result == 8'b00000000);
    assign negative_flag = result[7];

endmodule