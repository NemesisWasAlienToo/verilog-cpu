`timescale 1ns / 1ps

module tb_gpr;

    // Control Inputs
    reg clk;
    reg reset;
    reg load;
    reg data_output_enable;
    reg address_output_enable;

    // Bidirectional Bus setup
    wire [7:0] data_bus;
    reg  [7:0] tb_data_bus_driver;
    assign data_bus = tb_data_bus_driver; // Testbench drives bus when not 8'bz

    // Outputs
    wire [7:0] data_alu;
    wire [7:0] address_out;

    // Instantiate the Device Under Test (DUT)
    gpr dut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .data_output_enable(data_output_enable),
        .address_output_enable(address_output_enable),
        .data_bus(data_bus),
        .data_alu(data_alu),
        .address_out(address_out)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("gpr.vcd");
        $dumpvars(0, tb_gpr);
        // -----------------------------------------------------------
        // Initialization
        // -----------------------------------------------------------
        clk = 0;
        reset = 1;
        load = 0;
        data_output_enable = 0;
        address_output_enable = 0;
        tb_data_bus_driver = 8'bz; // Testbench releases the bus initially

        $display("--- Starting GPR Tests ---");

        // -----------------------------------------------------------
        // Test 1: Asynchronous Reset Check
        // -----------------------------------------------------------
        #15 reset = 0; // Release reset after a clock cycle
        #1; 
        if (data_alu == 8'h00)
            $display("[PASS] Test 1: Reset correctly initialized register to 00.");
        else
            $display("[FAIL] Test 1: Expected 00 after reset, got %h", data_alu);

        // -----------------------------------------------------------
        // Test 2: Load Data from Bus
        // -----------------------------------------------------------
        @(posedge clk);
        tb_data_bus_driver = 8'h42; // Put hex 42 on the data bus
        load = 1;                   // Tell GPR to load it
        
        @(posedge clk);             // Wait for falling edge to do the work
        load = 0;                   // Disable load
        tb_data_bus_driver = 8'bz;  // Stop driving the bus
        
        #1; // Brief delay to let assignments settle
        if (data_alu == 8'h42)
            $display("[PASS] Test 2: Successfully loaded 42 from data_bus.");
        else
            $display("[FAIL] Test 2: Expected 42, got %h", data_alu);

        // -----------------------------------------------------------
        // Test 3: High-Z (Floating) Check
        // -----------------------------------------------------------
        if (data_bus === 8'bz && address_out === 8'bz)
            $display("[PASS] Test 3a: Outputs are safely High-Z when disabled.");
        else
            $display("[FAIL] Test 3a: Outputs are not floating. data_bus=%b, address_out=%b", data_bus, address_out);

        // -----------------------------------------------------------
        // Test 4: Output Enable Check
        // -----------------------------------------------------------
        data_output_enable = 1;
        address_output_enable = 1;
        
        #1;
        if (data_bus === 8'h42 && address_out === 8'h42)
            $display("[PASS] Test 3b: Output enables successfully drove data onto buses.");
        else
            $display("[FAIL] Test 3b: Output enables failed. data_bus=%h, address_out=%h", data_bus, address_out);
        
        // Cleanup for any future tests
        data_output_enable = 0;
        address_output_enable = 0;

        $display("--- GPR Tests Complete ---");
        $finish;
    end

endmodule