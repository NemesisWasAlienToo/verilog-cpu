`timescale 1ns / 1ps

module tb_alu;

    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] c;
    reg [1:0] l_arg;
    reg [1:0] r_arg;
    reg       cmd_add;
    reg       cmd_sub;
    reg       cmd_and;
    reg       cmd_or;
    reg       cmd_xor;

    // Outputs
    wire [7:0] result;
    wire       zero_flag;
    wire       negative_flag;

    alu dut (
        .a(a), .b(b), .c(c),
        .l_arg(l_arg), .r_arg(r_arg),
        .cmd_add(cmd_add), .cmd_sub(cmd_sub),
        .cmd_and(cmd_and), .cmd_or(cmd_or), .cmd_xor(cmd_xor),
        .result(result),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        a = 8'h00; b = 8'h00; c = 8'h00;
        l_arg = 2'b00; r_arg = 2'b00;
        cmd_add = 0; cmd_sub = 0; cmd_and = 0; cmd_or = 0; cmd_xor = 0;

        $display("--- Starting ALU Tests ---");

        // Test 1: ADD A, B
        a = 8'h15; b = 8'h0A;
        l_arg = 2'b00; r_arg = 2'b01;
        cmd_add = 1;
        #5;
        if (result == 8'h1F && !zero_flag && !negative_flag)
            $display("[PASS] Test 1: ADD A, B (15 + 0A = 1F).");
        else
            $display("[FAIL] Test 1: ADD A, B failed. Got %h", result);
        cmd_add = 0;

        // Test 2: SUB B, C (negative flag)
        b = 8'h05; c = 8'h08;
        l_arg = 2'b01; r_arg = 2'b10;
        cmd_sub = 1;
        #5;
        if (result == 8'hFD && negative_flag && !zero_flag)
            $display("[PASS] Test 2: SUB B, C successfully triggered negative flag.");
        else
            $display("[FAIL] Test 2: SUB B, C negative check failed. Got %h", result);
        cmd_sub = 0;

        // Test 3: XOR A, A (zero flag)
        a = 8'hA5;
        l_arg = 2'b00; r_arg = 2'b00;
        cmd_xor = 1;
        #5;
        if (result == 8'h00 && zero_flag && !negative_flag)
            $display("[PASS] Test 3: XOR A, A successfully triggered zero flag.");
        else
            $display("[FAIL] Test 3: XOR A, A zero check failed. Got %h", result);
        cmd_xor = 0;

        // Test 4: Invalid operands fall back to 0
        l_arg = 2'b11; r_arg = 2'b11;
        cmd_add = 1;
        #5;
        if (result == 8'h00 && zero_flag)
            $display("[PASS] Test 4: ALU gracefully handled invalid arguments with 0s.");
        else
            $display("[FAIL] Test 4: Fallback to 0 failed. Got %h", result);

        $display("--- ALU Tests Complete ---");
        $finish;
    end

endmodule
