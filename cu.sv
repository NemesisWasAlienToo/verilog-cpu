`timescale 1ns / 1ps

module tb_cu_sync;

    // Inputs
    reg       clk;
    reg       reset;
    reg       alu_zero_flag;
    reg       alu_negative_flag;
    reg [7:0] data_bus;

    // Outputs
    wire       pc_increment, pc_load, pc_data_output_enable, pc_address_output_enable;
    wire       reg_a_load, reg_a_data_output_enable, reg_a_address_output_enable;
    wire       reg_b_load, reg_b_data_output_enable, reg_b_address_output_enable;
    wire       alu_enable, alu_cmd_add, alu_cmd_sub, alu_cmd_and, alu_cmd_or, alu_cmd_xor;
    wire [1:0] alu_l_arg, alu_r_arg;
    wire       mem_enable, mem_data_output_enable, mem_write_enable;

    // Instantiate DUT
    cu dut (
        .clk(clk), .reset(reset),
        .pc_increment(pc_increment), .pc_load(pc_load), 
        .pc_data_output_enable(pc_data_output_enable), .pc_address_output_enable(pc_address_output_enable),
        .reg_a_load(reg_a_load), .reg_a_data_output_enable(reg_a_data_output_enable), .reg_a_address_output_enable(reg_a_address_output_enable),
        .reg_b_load(reg_b_load), .reg_b_data_output_enable(reg_b_data_output_enable), .reg_b_address_output_enable(reg_b_address_output_enable),
        .alu_enable(alu_enable), .alu_cmd_add(alu_cmd_add), .alu_cmd_sub(alu_cmd_sub), .alu_cmd_and(alu_cmd_and), .alu_cmd_or(alu_cmd_or), .alu_cmd_xor(alu_cmd_xor),
        .alu_l_arg(alu_l_arg), .alu_r_arg(alu_r_arg), .alu_zero_flag(alu_zero_flag), .alu_negative_flag(alu_negative_flag),
        .mem_enable(mem_enable), .mem_data_output_enable(mem_data_output_enable), .mem_write_enable(mem_write_enable),
        .data_bus(data_bus)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("cu.vcd");
        $dumpvars(0, tb_cu_sync);

        // ===========================================================
        // THE FIX: Explicit Reset Toggle
        // ===========================================================
        clk = 0;
        reset = 0; // START LOW
        alu_zero_flag = 0;
        alu_negative_flag = 0;
        data_bus = 8'h00;

        $display("--- Starting Multi-Cycle Control Unit Tests ---");

        #2; 
        reset = 1; // Explicit posedge reset! Forces stage to 001.
        #10;
        reset = 0; // Release reset.

        // Sync up: Let the CPU do a dummy Decode and Execute cycle 
        // so we start our tests cleanly on a brand new Fetch edge.
        @(posedge clk); // Shifts 001 -> 010 (Decode)
        @(posedge clk); // Shifts 010 -> 100 (Execute)

        // ===========================================================
        // INSTRUCTION 1: ALU ADD A, B 
        // ===========================================================
        
        // --- STAGE 1: FETCH ---
        @(posedge clk); // Shifts 100 -> 001 (Fetch)
        #1; // Settle time
        if (pc_address_output_enable && mem_enable && mem_data_output_enable && !alu_enable)
            $display("[PASS] Inst 1 (Fetch Phase): CU correctly seized the bus.");
        else $display("[FAIL] Inst 1 (Fetch Phase): Bus seizure failed. FSM Stage: %b", dut.stage);
        
        data_bus = 8'b1_000_00_01; // Put 'ADD A, B' on the data bus 
        
        // --- STAGE 2: DECODE / PC INC ---
        // (The Instruction Register latches on the falling edge between Fetch and Decode)
        @(posedge clk); // Shifts 001 -> 010 (Decode)
        #1;
        if (pc_increment && !mem_enable && !alu_enable)
            $display("[PASS] Inst 1 (Decode Phase): CU successfully incremented PC in isolation.");
        else $display("[FAIL] Inst 1 (Decode Phase): PC Increment failed. FSM Stage: %b", dut.stage);

        // --- STAGE 3: EXECUTE ---
        @(posedge clk); // Shifts 010 -> 100 (Execute)
        #1;
        if (alu_enable && alu_cmd_add && reg_a_load && !pc_address_output_enable)
            $display("[PASS] Inst 1 (Execute Phase): CU fired the decoder logic perfectly.");
        else $display("[FAIL] Inst 1 (Execute Phase): Execution logic failed. FSM Stage: %b", dut.stage);


        // ===========================================================
        // INSTRUCTION 2: IMMEDIATE FETCH (MOV A, #IMM)
        // ===========================================================
        
        // --- STAGE 1: FETCH ---
        @(posedge clk); // Shifts back to 001
        #1;
        data_bus = 8'b0_00_0_00_11; // 'MOV A, #IMM'
        
        // --- STAGE 2: DECODE / PC INC ---
        @(posedge clk); 
        #1;
        if (pc_increment) $display("[PASS] Inst 2 (Decode Phase): PC incremented past the instruction byte.");
        else $display("[FAIL] Inst 2 (Decode Phase).");

        // --- STAGE 3: EXECUTE (Double Increment Check) ---
        @(posedge clk);
        #1;
        if (pc_increment && pc_address_output_enable && mem_enable && mem_data_output_enable && reg_a_load)
            $display("[PASS] Inst 2 (Execute Phase): CU elegantly fetched immediate and double-incremented the PC!");
        else $display("[FAIL] Inst 2 (Execute Phase): Immediate fetch failed.");


        // ===========================================================
        // INSTRUCTION 3: CONDITIONAL JUMP (MOV N PC, A)
        // ===========================================================
        
        // --- STAGE 1: FETCH ---
        @(posedge clk);
        #1;
        data_bus = 8'b0_10_0_10_00; 

        // --- STAGE 2: DECODE ---
        @(posedge clk);
        #1;

        // --- STAGE 3: EXECUTE (Flag = 0) ---
        @(posedge clk);
        alu_negative_flag = 0; 
        #1;
        if (!pc_load && !reg_a_data_output_enable)
            $display("[PASS] Inst 3 (Execute Phase - False): Ignored jump because Negative Flag was 0.");
        else $display("[FAIL] Inst 3 (Execute Phase - False).");

        // Fast forward a full cycle back to Execute
        @(posedge clk); @(posedge clk); @(posedge clk); 
        alu_negative_flag = 1; 
        #1;
        if (pc_load && reg_a_data_output_enable)
            $display("[PASS] Inst 3 (Execute Phase - True): Executed jump because Negative Flag was 1.");
        else $display("[FAIL] Inst 3 (Execute Phase - True).");

        $display("--- Complete ---");
        $finish;
    end

endmodule