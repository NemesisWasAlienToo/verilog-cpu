`timescale 1ns / 1ps

module tb_mcu_runner;
    reg clk;
    reg reset;
    reg [7:0] in_pins;
    wire [7:0] out_pins;

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

        $display("Executing program.mem");

        clk = 0;
        reset = 0;

        // Start with a distinct input pattern
        in_pins = 8'hAA; 

        // Hardware Reset Sequence
        #2 reset = 1;
        #15 reset = 0;

        // Let the MCU run for a while
        repeat(200) @(negedge clk);
        $finish;
    end
    
    always @(out_pins) begin
        $display("Time=%0t | MCU out_pins updated to: %h", $time, out_pins);
    end

endmodule