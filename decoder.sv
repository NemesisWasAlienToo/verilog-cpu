`timescale 1ns / 1ps

module tb_decoder_complete;

    // Inputs
    reg       enable;
    reg [7:0] instruction;
    reg       alu_zero_flag;
    reg       alu_negative_flag;

    // Outputs
    wire       pc_increment, pc_load, pc_data_output_enable, pc_address_output_enable;
    wire       reg_a_load, reg_a_data_output_enable, reg_a_address_output_enable;
    wire       reg_b_load, reg_b_data_output_enable, reg_b_address_output_enable;
    wire       alu_enable, alu_cmd_add, alu_cmd_sub, alu_cmd_and, alu_cmd_or, alu_cmd_xor;
    wire [1:0] alu_l_arg, alu_r_arg;
    wire       mem_enable, mem_data_output_enable, mem_write_enable;

    // Instantiate DUT
    decoder dut (
        .enable(enable), .instruction(instruction),
        .pc_increment(pc_increment), .pc_load(pc_load),
        .pc_data_output_enable(pc_data_output_enable), .pc_address_output_enable(pc_address_output_enable),
        .reg_a_load(reg_a_load), .reg_a_data_output_enable(reg_a_data_output_enable), .reg_a_address_output_enable(reg_a_address_output_enable),
        .reg_b_load(reg_b_load), .reg_b_data_output_enable(reg_b_data_output_enable), .reg_b_address_output_enable(reg_b_address_output_enable),
        .alu_enable(alu_enable), .alu_cmd_add(alu_cmd_add), .alu_cmd_sub(alu_cmd_sub), .alu_cmd_and(alu_cmd_and), .alu_cmd_or(alu_cmd_or), .alu_cmd_xor(alu_cmd_xor),
        .alu_l_arg(alu_l_arg), .alu_r_arg(alu_r_arg), .alu_zero_flag(alu_zero_flag), .alu_negative_flag(alu_negative_flag),
        .mem_enable(mem_enable), .mem_data_output_enable(mem_data_output_enable), .mem_write_enable(mem_write_enable)
    );

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, tb_decoder_complete);

        // Initialize
        enable = 0;
        instruction = 8'h00;
        alu_zero_flag = 0;
        alu_negative_flag = 0;

        $display("--- Starting Complete Decoder Tests ---");

        // -----------------------------------------------------------
        // Test 1: Disable Pin Safety
        // -----------------------------------------------------------
        enable = 0;
        instruction = 8'b1_000_00_01; // ADD A, B
        #5;
        if (!alu_enable && !reg_a_load && !mem_enable && !pc_increment)
            $display("[PASS] Test 1: Disable safety (All outputs 0)");
        else $display("[FAIL] Test 1: Disable safety");

        enable = 1;

        // -----------------------------------------------------------
        // Test 2: ALU ADD A, B
        // Format: [1][000][00][01] -> Hex 81
        // -----------------------------------------------------------
        instruction = 8'b1_000_00_01;
        #5;
        if (alu_enable && alu_cmd_add && reg_a_load && alu_l_arg==2'b00 && alu_r_arg==2'b01 && !reg_a_data_output_enable && !mem_enable)
            $display("[PASS] Test 2: ALU ADD A, B");
        else $display("[FAIL] Test 2: ALU ADD A, B");

        // -----------------------------------------------------------
        // Test 3: ALU SUB B, A
        // Format: [1][001][01][00] -> Hex 94
        // -----------------------------------------------------------
        instruction = 8'b1_001_01_00;
        #5;
        if (alu_enable && alu_cmd_sub && reg_b_load && alu_l_arg==2'b01 && alu_r_arg==2'b00)
            $display("[PASS] Test 3: ALU SUB B, A");
        else $display("[FAIL] Test 3: ALU SUB B, A");

        // -----------------------------------------------------------
        // Test 4: Unconditional MOV B, A
        // Format: [0][00][0][01][00] -> Hex 04
        // -----------------------------------------------------------
        instruction = 8'b0_00_0_01_00;
        #5;
        if (reg_b_load && reg_a_data_output_enable && !alu_enable && !mem_enable)
            $display("[PASS] Test 4: MOV B, A (Unconditional)");
        else $display("[FAIL] Test 4: MOV B, A (Unconditional)");

        // -----------------------------------------------------------
        // Test 5: Conditional MOV Z A, B (Zero Flag = 0)
        // Format: [0][01][0][00][01] -> Hex 21
        // -----------------------------------------------------------
        instruction = 8'b0_01_0_00_01;
        alu_zero_flag = 0;
        #5;
        if (!reg_a_load && !reg_b_data_output_enable)
            $display("[PASS] Test 5: MOV Z A, B (Ignored when Z=0)");
        else $display("[FAIL] Test 5: MOV Z A, B (Ignored when Z=0)");

        // -----------------------------------------------------------
        // Test 6: Conditional MOV Z A, B (Zero Flag = 1)
        // Format: [0][01][0][00][01] -> Hex 21
        // -----------------------------------------------------------
        instruction = 8'b0_01_0_00_01;
        alu_zero_flag = 1;
        #5;
        if (reg_a_load && reg_b_data_output_enable)
            $display("[PASS] Test 6: MOV Z A, B (Executed when Z=1)");
        else $display("[FAIL] Test 6: MOV Z A, B (Executed when Z=1)");
        alu_zero_flag = 0;

        // -----------------------------------------------------------
        // Test 7a: Conditional MOV N PC, A (Negative Flag = 1) -> Branching!
        // Format: [0][10][0][10][00] -> Hex 48
        // -----------------------------------------------------------
        instruction = 8'b0_10_0_10_00;
        alu_negative_flag = 1;
        #5;
        if (pc_load && reg_a_data_output_enable)
            $display("[PASS] Test 7a: MOV N PC, A (Executed when N=1)");
        else $display("[FAIL] Test 7a: MOV N PC, A (Executed when N=1)");
        
        // -----------------------------------------------------------
        // Test 7b: Conditional MOV N PC, A (Negative Flag = 0) -> Ignored Branch!
        // Format: [0][10][0][10][00] -> Hex 48
        // -----------------------------------------------------------
        alu_negative_flag = 0;
        #5;
        if (!pc_load && !reg_a_data_output_enable)
            $display("[PASS] Test 7b: MOV N PC, A (Ignored when N=0)");
        else $display("[FAIL] Test 7b: MOV N PC, A (Ignored when N=0)");

        // -----------------------------------------------------------
        // Test 8: Immediate Fetch: MOV A, #IMM
        // Format: [0][00][0][00][11] -> Hex 03
        // -----------------------------------------------------------
        instruction = 8'b0_00_0_00_11;
        #5;
        if (pc_address_output_enable && pc_increment && mem_enable && mem_data_output_enable && reg_a_load && !alu_enable)
            $display("[PASS] Test 8: MOV A, #IMM (Immediate Fetch)");
        else $display("[FAIL] Test 8: MOV A, #IMM (Immediate Fetch)");

        // -----------------------------------------------------------
        // Test 9: Memory Write: WR [A], B
        // Format: [0][11][1][00][01] -> Hex 71
        // -----------------------------------------------------------
        instruction = 8'b0_11_1_00_01;
        #5;
        if (mem_enable && mem_write_enable && reg_a_address_output_enable && reg_b_data_output_enable && !pc_address_output_enable)
            $display("[PASS] Test 9: WR [A], B (Memory Write)");
        else $display("[FAIL] Test 9: WR [A], B (Memory Write)");

        // -----------------------------------------------------------
        // Test 10: Memory Read: RD [B], A
        // Format: [0][11][0][01][00] -> Hex 64
        // -----------------------------------------------------------
        instruction = 8'b0_11_0_01_00;
        #5;
        if (mem_enable && mem_data_output_enable && reg_b_address_output_enable && reg_a_load && !pc_address_output_enable)
            $display("[PASS] Test 10: RD [B], A (Memory Read)");
        else $display("[FAIL] Test 10: RD [B], A (Memory Read)");

        $display("--- Tests Complete ---");
        $finish;
    end

endmodule