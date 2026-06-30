`timescale 1ns / 1ps

module tb_mcu;
    reg clk;
    reg reset;
    reg [7:0] in_pins;
    wire [7:0] out_pins;

    // Instantiate the Microcontroller
    mcu uut (
        .clk(clk),
        .reset(reset),
        .in_pins(in_pins),
        .out_pins(out_pins)
    );

    always #5 clk = ~clk;

    initial begin
        // Trick to suppress the $readmemh warning: Create an empty file
        integer fd;
        fd = $fopen("program.mem", "w");
        $fclose(fd);
        
        $dumpfile("mcu.vcd");
        $dumpvars(0, tb_mcu);

        clk = 0;
        reset = 0;
        in_pins = 8'h42; 

        // Inject the "I/O Echo Loop" program into the MCU's RAM
        uut.program_mem[8'h00] = 8'h07; // MOV B, #FE (Load Input Address)
        uut.program_mem[8'h01] = 8'hFE;
        uut.program_mem[8'h02] = 8'h64; // RD [B], A  (Read from Input to A)
        uut.program_mem[8'h03] = 8'h07; // MOV B, #FF (Load Output Address)
        uut.program_mem[8'h04] = 8'hFF;
        uut.program_mem[8'h05] = 8'h74; // WR [B], A  (Write A to Output) <-- FIXED OPCODE!
        uut.program_mem[8'h06] = 8'h07; // MOV B, #00 (Load Jump Target)
        uut.program_mem[8'h07] = 8'h00;
        uut.program_mem[8'h08] = 8'h09; // MOV PC, B  (Jump to 00)

        $display("--- Starting MCU Integration Test ---");

        // Perfectly aligned reset: Hold long enough to clear, 
        // release cleanly before the first negedge fetch cycle.
        #2 reset = 1;
        #15 reset = 0;

        // The program takes 6 instructions to complete one loop.
        // 6 instructions * 3 FSM cycles = 18 clock cycles.
        // Let's wait 20 cycles to give it plenty of time to latch the output.
        repeat(20) @(negedge clk);
        
        if (out_pins == 8'h42) 
            $display("[PASS] Cycle 1: Read '42' from Input, Wrote '42' to Output!");
        else 
            $display("[FAIL] Cycle 1: Expected Output '42', Got '%h'", out_pins);

        // Now, change the input pin value on the fly. 
        in_pins = 8'h99;

        // Give it another 20 clocks to complete the jump and run the loop again
        repeat(20) @(negedge clk);

        if (out_pins == 8'h99) 
            $display("[PASS] Cycle 2: Program successfully looped and echoed '99'!");
        else 
            $display("[FAIL] Cycle 2: Expected Output '99', Got '%h'", out_pins);

        $display("--- MCU Test Complete ---");
        $finish;
    end
endmodule