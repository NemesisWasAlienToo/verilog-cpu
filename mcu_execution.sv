`timescale 1ns / 1ps

module tb_mcu_runner;
    reg clk;
    reg reset;
    reg [7:0] in_pins;
    wire [7:0] out_pins;

    // Instantiate the Microcontroller
    // It will automatically load "program.mem" via its own $readmemh block!
    mcu uut (
        .clk(clk),
        .reset(reset),
        .in_pins(in_pins),
        .out_pins(out_pins)
    );

    // 10ns Clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mcu_execution.vcd");
        $dumpvars(0, tb_mcu_runner);

        $display("--- Booting MCU from program.mem ---");

        // Initial states
        clk = 0;
        reset = 0;
        in_pins = 8'hAA; // Start with a distinct input pattern

        // Hardware Reset Sequence
        #2 reset = 1;
        #15 reset = 0;

        $display("MCU Running... (Simulating 100 clock cycles)");

        // Let the MCU run for a while
        repeat(30) @(negedge clk);
        
        // Change the physical input pin environment 
        $display("Time=%0t | Changing in_pins to 8'h55", $time);
        in_pins = 8'h55; 

        // Let it run some more to process the new input
        repeat(30) @(negedge clk);

        $display("Time=%0t | Changing in_pins to 8'hFF", $time);
        in_pins = 8'hFF;

        repeat(40) @(negedge clk);

        $display("--- Execution Complete. Check mcu_execution.vcd ---");
        $finish;
    end
    
    // Optional: A simple monitor to print out_pins whenever they change
    always @(out_pins) begin
        $display("Time=%0t | MCU out_pins updated to: %h", $time, out_pins);
    end

endmodule