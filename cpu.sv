`timescale 1ns / 1ps

module tb_cpu_full;

    reg clk;
    reg reset;
    wire [7:0] data_pins;
    wire [7:0] address_pins;
    wire mem_enable, mem_write_enable, mem_data_output_enable;

    reg [7:0] memory [0:255];

    // Read Logic: If CPU wants to read, output the memory at address_pins
    assign data_pins = (mem_enable && mem_data_output_enable && !mem_write_enable) ? memory[address_pins] : 8'bz;

    // Write Logic: If CPU wants to write, capture data_pins into memory
    always @(negedge clk) begin
        if (mem_enable && mem_write_enable) begin
            memory[address_pins] <= data_pins;
        end
    end

    // Instantiate CPU
    cpu uut (
        .clk(clk), .reset(reset), .data_pins(data_pins),
        .address_pins(address_pins), .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable), .mem_data_output_enable(mem_data_output_enable)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, tb_cpu_full);

        memory[8'h00] = 8'b0_00_0_01_11; // MOV B, #IMM  (Hex 07)
        memory[8'h01] = 8'h05;           // Immediate data: 05
        
        memory[8'h02] = 8'b0_00_0_00_11; // MOV A, #IMM  (Hex 03)
        memory[8'h03] = 8'hAA;           // Immediate data: AA
        
        memory[8'h04] = 8'b1_000_00_01;  // ADD A, B     (Hex 81)
        
        memory[8'h05] = 8'b0_11_1_00_01; // WR [A], B    (Hex 71)

        clk = 0;
        reset = 0;

        $display("--- Starting CPU System Execution ---");

        #2 reset = 1;
        #10 reset = 0;

        // 1. MOV B, #05
        repeat(3) @(negedge clk);
        #1;
        if (uut.register_b.q == 8'h05) $display("[PASS] Executed: MOV B, #05");
        else $display("[FAIL] MOV B, #05. Got: %h", uut.register_b.q);

        // 2. MOV A, #AA
        repeat(3) @(negedge clk);
        #1;
        if (uut.register_a.q == 8'hAA) $display("[PASS] Executed: MOV A, #AA");
        else $display("[FAIL] MOV A, #AA. Got: %h", uut.register_a.q);

        // 3. ADD A, B
        repeat(3) @(negedge clk);
        #1;
        if (uut.register_a.q == 8'hAF) $display("[PASS] Executed: ADD A, B (Result: AF)");
        else $display("[FAIL] ADD A, B. Got: %h", uut.register_a.q);

        // 4. WR [A], B
        repeat(3) @(negedge clk);
        @(posedge clk);
        if (memory[8'hAF] == 8'h05) $display("[PASS] Executed: WR [A], B (Wrote 05 to Address AF)");
        else $display("[FAIL] WR [A], B. Memory at AF is: %h", memory[8'hAF]);

        $display("--- System Test Complete ---");
        $finish;
    end
endmodule