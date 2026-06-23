`timescale 1ns / 1ps

module tb_gpr;

    reg clk;
    reg reset;
    reg load;
    reg  [7:0] data_bus;
    wire [7:0] value;

    gpr dut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .data_bus(data_bus),
        .value(value)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("gpr.vcd");
        $dumpvars(0, tb_gpr);

        clk = 0;
        reset = 1;
        load = 0;
        data_bus = 8'h00;

        $display("--- Starting GPR Tests ---");

        // Test 1: Reset
        #15 reset = 0;
        #1;
        if (value == 8'h00)
            $display("[PASS] Test 1: Reset correctly initialized register to 00.");
        else
            $display("[FAIL] Test 1: Expected 00 after reset, got %h", value);

        // Test 2: Load from data bus
        @(posedge clk);
        data_bus = 8'h42;
        load = 1;
        @(posedge clk);
        load = 0;
        data_bus = 8'h00;
        #1;
        if (value == 8'h42)
            $display("[PASS] Test 2: Successfully loaded 42 from data_bus.");
        else
            $display("[FAIL] Test 2: Expected 42, got %h", value);

        $display("--- GPR Tests Complete ---");
        $finish;
    end

endmodule
