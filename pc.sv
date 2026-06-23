`timescale 1ns / 1ps

module tb_pc;

    reg clk;
    reg reset;
    reg increment;
    reg load;
    reg  [7:0] data_bus;
    wire [7:0] value;

    pc dut (
        .clk(clk),
        .reset(reset),
        .increment(increment),
        .load(load),
        .data_bus(data_bus),
        .value(value)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pc.vcd");
        $dumpvars(0, tb_pc);

        clk = 0;
        reset = 1;
        increment = 0;
        load = 0;
        data_bus = 8'h00;

        $display("--- Starting PC Tests ---");

        // Test 1: Reset
        #15 reset = 0;
        #1;
        if (value == 8'h00)
            $display("[PASS] Test 1: Reset initialized PC to 00.");
        else
            $display("[FAIL] Test 1: Expected 00 after reset, got %h", value);

        // Test 2: Increment
        @(posedge clk);
        increment = 1;
        @(posedge clk);
        increment = 0;
        #1;
        if (value == 8'h01)
            $display("[PASS] Test 2: Increment changed PC to 01.");
        else
            $display("[FAIL] Test 2: Expected 01, got %h", value);

        // Test 3: Load from data bus
        @(posedge clk);
        data_bus = 8'hA5;
        load = 1;
        @(posedge clk);
        load = 0;
        data_bus = 8'h00;
        #1;
        if (value == 8'hA5)
            $display("[PASS] Test 3: Load successfully grabbed A5 from data_bus.");
        else
            $display("[FAIL] Test 3: Expected A5, got %h", value);

        // Test 4: Load priority over increment
        @(posedge clk);
        data_bus = 8'hFF;
        load = 1;
        increment = 1;
        @(posedge clk);
        load = 0;
        increment = 0;
        data_bus = 8'h00;
        #1;
        if (value == 8'hFF)
            $display("[PASS] Test 4: Load correctly took priority over increment.");
        else
            $display("[FAIL] Test 4: Priority failed. Expected FF, got %h", value);

        $display("--- PC Tests Complete ---");
        $finish;
    end

endmodule
