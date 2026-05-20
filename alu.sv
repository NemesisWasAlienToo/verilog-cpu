`timescale 1ns / 1ps

module tb_alu;

    // Inputs
    reg       enable;
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
    wire [7:0] data_bus;
    wire       zero_flag;
    wire       negative_flag;

    // Instantiate DUT
    alu dut (
        .enable(enable),
        .a(a), .b(b), .c(c),
        .l_arg(l_arg), .r_arg(r_arg),
        .cmd_add(cmd_add), .cmd_sub(cmd_sub),
        .cmd_and(cmd_and), .cmd_or(cmd_or), .cmd_xor(cmd_xor),
        .data_bus(data_bus),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag)
    );

    initial begin
        // Generate VCD file for GTKWave visualization
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        // Initialize inputs
        enable = 0;
        a = 8'h00; b = 8'h00; c = 8'h00;
        l_arg = 2'b00; r_arg = 2'b00;
        cmd_add = 0; cmd_sub = 0; cmd_and = 0; cmd_or = 0; cmd_xor = 0;

        $display("--- Starting ALU Tests ---");

        // -----------------------------------------------------------
        // Test 1: Tri-state behavior
        // -----------------------------------------------------------
        #5;
        if (data_bus === 8'bz)
            $display("[PASS] Test 1: Data bus is High-Z when enable is 0.");
        else
            $display("[FAIL] Test 1: Data bus is driving when it shouldn't.");

        enable = 1;

        // -----------------------------------------------------------
        // Test 2: ADD A, B
        // -----------------------------------------------------------
        a = 8'h15;       // Decimal 21
        b = 8'h0A;       // Decimal 10
        l_arg = 2'b00;   // Left op = A
        r_arg = 2'b01;   // Right op = B
        cmd_add = 1;
        #5;
        if (data_bus == 8'h1F && !zero_flag && !negative_flag)
            $display("[PASS] Test 2: ADD A, B (15 + 0A = 1F).");
        else
            $display("[FAIL] Test 2: ADD A, B failed. Got %h", data_bus);
        cmd_add = 0;

        // -----------------------------------------------------------
        // Test 3: SUB B, C (Resulting in Negative Flag)
        // -----------------------------------------------------------
        b = 8'h05;       
        c = 8'h08;       
        l_arg = 2'b01;   // Left op = B
        r_arg = 2'b10;   // Right op = C
        cmd_sub = 1;
        #5;
        if (data_bus == 8'hFD && negative_flag && !zero_flag) // 5 - 8 = -3 (FD in 2s complement)
            $display("[PASS] Test 3: SUB B, C successfully triggered negative flag.");
        else
            $display("[FAIL] Test 3: SUB B, C negative check failed. Got %h", data_bus);
        cmd_sub = 0;

        // -----------------------------------------------------------
        // Test 4: XOR A, A (Resulting in Zero Flag)
        // -----------------------------------------------------------
        a = 8'hA5;
        l_arg = 2'b00;   // Left op = A
        r_arg = 2'b00;   // Right op = A
        cmd_xor = 1;
        #5;
        if (data_bus == 8'h00 && zero_flag && !negative_flag)
            $display("[PASS] Test 4: XOR A, A successfully triggered zero flag.");
        else
            $display("[FAIL] Test 4: XOR A, A zero check failed. Got %h", data_bus);
        cmd_xor = 0;
        
        // -----------------------------------------------------------
        // Test 5: Fallback to 0 check
        // -----------------------------------------------------------
        l_arg = 2'b11;   // Invalid operand
        r_arg = 2'b11;   // Invalid operand
        cmd_add = 1;
        #5;
        if (data_bus == 8'h00 && zero_flag)
            $display("[PASS] Test 5: ALU gracefully handled invalid arguments with 0s.");
        else
            $display("[FAIL] Test 5: Fallback to 0 failed. Got %h", data_bus);

        $display("--- ALU Tests Complete ---");
        $finish;
    end

endmodule