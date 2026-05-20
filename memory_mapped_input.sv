`timescale 1ns / 1ps

module tb_memory_mapped_input;

    // Define a test parameter for the address
    localparam [7:0] TB_ADDRESS = 8'hFE;

    // Inputs
    reg       clk;
    reg       reset;
    reg [7:0] address;
    reg [7:0] data_in;
    reg       mem_enable;
    reg       mem_data_output_enable;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the Device Under Test (DUT)
    memory_mapped_input #(
        .ADDRESS(TB_ADDRESS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .mem_enable(mem_enable),
        .mem_data_output_enable(mem_data_output_enable)
    );

    // Dummy clock for waveform visual reference (even though module doesn't use it)
    always #5 clk = ~clk;

    initial begin
        // Generate VCD file for visualization
        $dumpfile("memory_mapped_input.vcd");
        $dumpvars(0, tb_memory_mapped_input);

        // Initialize Inputs
        clk = 0;
        reset = 1;
        address = 8'h00;
        data_in = 8'h00;
        mem_enable = 0;
        mem_data_output_enable = 0;

        $display("--- Starting Memory Mapped Input Tests ---");

        // -----------------------------------------------------------
        // Test 1: Default State (Should be High-Z)
        // -----------------------------------------------------------
        #10 reset = 0;
        data_in = 8'h55; // Put some data on the physical input pins
        #1;
        if (data_out === 8'bz) 
            $display("[PASS] Test 1: Outputs are safely High-Z when control signals are low.");
        else 
            $display("[FAIL] Test 1: Bus contention risk! Output is not floating. Got %b", data_out);

        // -----------------------------------------------------------
        // Test 2: Valid Read Operation
        // -----------------------------------------------------------
        #10;
        address = TB_ADDRESS;
        mem_enable = 1;
        mem_data_output_enable = 1;
        #1; // Allow combinational logic to propagate
        if (data_out === 8'h55) 
            $display("[PASS] Test 2: Valid read successfully drove data_in (55) onto data_out.");
        else 
            $display("[FAIL] Test 2: Read failed. Expected 55, got %h", data_out);

        // -----------------------------------------------------------
        // Test 3: Continuous Data Propagation
        // -----------------------------------------------------------
        #10;
        data_in = 8'hAA; // Change input data while still reading
        #1;
        if (data_out === 8'hAA) 
            $display("[PASS] Test 3: Data continuously propagates while read is active.");
        else 
            $display("[FAIL] Test 3: Data propagation failed. Expected AA, got %h", data_out);

        // -----------------------------------------------------------
        // Test 4: Invalid Address Isolation
        // -----------------------------------------------------------
        #10;
        address = 8'h00; // CPU switches to reading a different address
        #1;
        if (data_out === 8'bz) 
            $display("[PASS] Test 4: Safely released the bus (High-Z) when address changed.");
        else 
            $display("[FAIL] Test 4: Address isolation failed. Output is not floating.");

        // Restore correct address for next tests
        address = TB_ADDRESS;

        // -----------------------------------------------------------
        // Test 5: Disabled mem_enable Isolation
        // -----------------------------------------------------------
        #10;
        mem_enable = 0;
        #1;
        if (data_out === 8'bz) 
            $display("[PASS] Test 5: Safely released the bus when mem_enable went low.");
        else 
            $display("[FAIL] Test 5: mem_enable isolation failed. Output is not floating.");
        mem_enable = 1;

        // -----------------------------------------------------------
        // Test 6: Disabled mem_data_output_enable Isolation
        // -----------------------------------------------------------
        #10;
        mem_data_output_enable = 0; // CPU is writing to this address, not reading
        #1;
        if (data_out === 8'bz) 
            $display("[PASS] Test 6: Safely released the bus when mem_data_output_enable went low.");
        else 
            $display("[FAIL] Test 6: mem_data_output_enable isolation failed. Output is not floating.");

        $display("--- Tests Complete ---");
        $finish;
    end

endmodule