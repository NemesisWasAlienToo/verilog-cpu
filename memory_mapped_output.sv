`timescale 1ns / 1ps

module tb_memory_mapped_output;

    // Define a test parameter for the address
    localparam [7:0] TB_ADDRESS = 8'hFF;

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] address;
    reg [7:0] data_in;
    reg mem_enable;
    reg mem_write_enable;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the Device Under Test (DUT)
    memory_mapped_output #(
        .ADDRESS(TB_ADDRESS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable)
    );

    // Clock Generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        // Generate VCD file for visualization
        $dumpfile("memory_mapped_output.vcd");
        $dumpvars(0, tb_memory_mapped_output);

        // Initialize Inputs
        clk = 0;
        reset = 1;
        address = 8'h00;
        data_in = 8'h00;
        mem_enable = 0;
        mem_write_enable = 0;

        $display("--- Starting Memory Mapped Output Tests ---");

        // -----------------------------------------------------------
        // Test 1: Asynchronous Reset Behavior
        // -----------------------------------------------------------
        #15 reset = 0; // Release reset
        #1;
        if (data_out == 8'h00) 
            $display("[PASS] Test 1: Reset successfully cleared the output to 00.");
        else 
            $display("[FAIL] Test 1: Reset failed. Expected 00, got %h", data_out);

        // -----------------------------------------------------------
        // Test 2: Valid Write
        // -----------------------------------------------------------
        @(posedge clk);
        address = TB_ADDRESS;
        data_in = 8'hAA;
        mem_enable = 1;
        mem_write_enable = 1;
        
        @(posedge clk);             // Wait for falling edge to latch
        mem_enable = 0;             // Disable write
        mem_write_enable = 0;
        
        #1;
        if (data_out == 8'hAA) 
            $display("[PASS] Test 2: Valid write to Address %h successfully latched data AA.", TB_ADDRESS);
        else 
            $display("[FAIL] Test 2: Valid write failed. Expected AA, got %h", data_out);

        // -----------------------------------------------------------
        // Test 3: Invalid Address (Should ignore write)
        // -----------------------------------------------------------
        @(posedge clk);
        address = 8'hFE;            // Wrong address!
        data_in = 8'hBB;            // Data we DO NOT want to write
        mem_enable = 1;
        mem_write_enable = 1;
        
        @(posedge clk);
        mem_enable = 0;
        mem_write_enable = 0;
        
        #1;
        if (data_out == 8'hAA) 
            $display("[PASS] Test 3: Safely ignored write because address did not match.");
        else 
            $display("[FAIL] Test 3: Address isolation failed. Expected AA, got %h", data_out);

        // -----------------------------------------------------------
        // Test 4: Disabled mem_enable (Should ignore write)
        // -----------------------------------------------------------
        @(posedge clk);
        address = TB_ADDRESS;
        data_in = 8'hCC;
        mem_enable = 0;             // Disabled!
        mem_write_enable = 1;
        
        @(posedge clk);
        mem_write_enable = 0;
        
        #1;
        if (data_out == 8'hAA) 
            $display("[PASS] Test 4: Safely ignored write when mem_enable was low.");
        else 
            $display("[FAIL] Test 4: mem_enable isolation failed. Expected AA, got %h", data_out);

        // -----------------------------------------------------------
        // Test 5: Disabled mem_write_enable (Should ignore write)
        // -----------------------------------------------------------
        @(posedge clk);
        address = TB_ADDRESS;
        data_in = 8'hDD;
        mem_enable = 1;             
        mem_write_enable = 0;       // Disabled!
        
        @(posedge clk);
        mem_enable = 0;
        
        #1;
        if (data_out == 8'hAA) 
            $display("[PASS] Test 5: Safely ignored write when mem_write_enable was low.");
        else 
            $display("[FAIL] Test 5: mem_write_enable isolation failed. Expected AA, got %h", data_out);

        $display("--- Tests Complete ---");
        $finish;
    end

endmodule