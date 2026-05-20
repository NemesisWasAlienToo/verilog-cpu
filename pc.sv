`timescale 1ns / 1ps

module tb_pc;

    // Control Inputs
    reg clk;
    reg reset;
    reg increment;
    reg load;
    reg data_output_enable;
    reg address_output_enable;

    // Bidirectional Bus setup
    wire [7:0] data_bus;
    reg  [7:0] tb_data_bus_driver;
    assign data_bus = tb_data_bus_driver; // Drives the bus when not 8'bz

    // Outputs
    wire [7:0] data_alu;
    wire [7:0] address_out;

    // Instantiate DUT
    pc dut (
        .clk(clk),
        .reset(reset),
        .increment(increment),
        .load(load),
        .data_output_enable(data_output_enable),
        .address_output_enable(address_output_enable),
        .data_bus(data_bus),
        .data_alu(data_alu),
        .address_out(address_out)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("pc.vcd");
        $dumpvars(0, tb_pc);
        // -----------------------------------------------------------
        // Initialization
        // -----------------------------------------------------------
        clk = 0;
        reset = 1;
        increment = 0;
        load = 0;
        data_output_enable = 0;
        address_output_enable = 0;
        tb_data_bus_driver = 8'bz; // Testbench releases the bus by default

        $display("--- Starting PC Tests ---");

        // -----------------------------------------------------------
        // Test 1: Reset behavior
        // -----------------------------------------------------------
        #15 reset = 0;
        #1; 
        if (data_alu == 8'h00)
            $display("[PASS] Test 1: Reset initialized PC to 00.");
        else
            $display("[FAIL] Test 1: Expected 00 after reset, got %h", data_alu);

        // -----------------------------------------------------------
        // Test 2: Increment
        // -----------------------------------------------------------
        @(posedge clk);
        increment = 1;
        @(posedge clk);
        increment = 0;
        
        #1; // Wait for falling edge to register
        if (data_alu == 8'h01)
            $display("[PASS] Test 2: Increment changed PC to 01.");
        else
            $display("[FAIL] Test 2: Expected 01, got %h", data_alu);

        // -----------------------------------------------------------
        // Test 3: Output Enables (High-Z checks)
        // -----------------------------------------------------------
        if (data_bus === 8'bz && address_out === 8'bz)
            $display("[PASS] Test 3a: Outputs are properly high-Z when disabled.");
        else
            $display("[FAIL] Test 3a: Outputs not floating. data_bus=%b, address_out=%b", data_bus, address_out);

        data_output_enable = 1;
        address_output_enable = 1;
        #1;
        if (data_bus === 8'h01 && address_out === 8'h01)
            $display("[PASS] Test 3b: Output enables successfully drove the buses.");
        else
            $display("[FAIL] Test 3b: Output enables failed. data_bus=%h, address_out=%h", data_bus, address_out);
        
        data_output_enable = 0;
        address_output_enable = 0;

        // -----------------------------------------------------------
        // Test 4: Load from Data Bus (Jump instruction behavior)
        // -----------------------------------------------------------
        @(posedge clk);
        tb_data_bus_driver = 8'hA5; // Testbench puts data on the bus
        load = 1;
        
        @(posedge clk);
        load = 0;
        tb_data_bus_driver = 8'bz;  // Testbench releases the bus
        
        #1;
        if (data_alu == 8'hA5)
            $display("[PASS] Test 4: Load successfully grabbed A5 from data_bus.");
        else
            $display("[FAIL] Test 4: Expected A5, got %h", data_alu);

        // -----------------------------------------------------------
        // Test 5: Priority Check (Load vs Increment)
        // -----------------------------------------------------------
        @(posedge clk);
        tb_data_bus_driver = 8'hFF;
        load = 1;
        increment = 1; // Assert both!
        
        @(posedge clk);
        load = 0;
        increment = 0;
        tb_data_bus_driver = 8'bz;
        
        #1;
        if (data_alu == 8'hFF)
            $display("[PASS] Test 5: Load correctly took priority over increment.");
        else
            $display("[FAIL] Test 5: Priority failed. Expected FF, got %h", data_alu);

        $display("--- PC Tests Complete ---");
        $finish;
    end

endmodule
