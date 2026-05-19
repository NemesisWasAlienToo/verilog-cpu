module alu_wire_version (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire cmd_add,
    input  wire cmd_sub,
    input  wire cmd_and,
    input  wire cmd_or,
    input  wire cmd_xor,
    
    output wire [7:0] result,
    output wire       zero_flag,
    output wire       negative_flag
);

    // Continuous assignment using nested ternary operators
    assign result = cmd_add ? (a + b) :
                    cmd_sub ? (a - b) :
                    cmd_and ? (a & b) :
                    cmd_or  ? (a | b) :
                    cmd_xor ? (a ^ b) :
                    8'b00000000; // Default state

    assign zero_flag = (result == 8'b00000000);
    assign negative_flag = result[7];

endmodule