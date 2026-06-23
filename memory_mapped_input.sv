`timescale 1ns / 1ps

module tb_memory_mapped_input;

    localparam [7:0] TB_ADDRESS = 8'hFE;

    reg [7:0] address;
    reg [7:0] data_in;
    reg       mem_enable;
    reg       mem_data_output_enable;

    wire [7:0] bus_value;
    wire       bus_drive;

    memory_mapped_input #(
        .ADDRESS(TB_ADDRESS)
    ) dut (
        .address(address),
        .data_in(data_in),
        .mem_enable(mem_enable),
        .mem_data_output_enable(mem_data_output_enable),
        .bus_value(bus_value),
        .bus_drive(bus_drive)
    );

    initial begin
        $dumpfile("memory_mapped_input.vcd");
        $dumpvars(0, tb_memory_mapped_input);

        address = 8'h00;
        data_in = 8'h00;
        mem_enable = 0;
        mem_data_output_enable = 0;

        $display("--- Starting Memory Mapped Input Tests ---");

        // Test 1: Not driving when disabled
        #10;
        data_in = 8'h55;
        #1;
        if (!bus_drive)
            $display("[PASS] Test 1: Not requesting the bus when control signals are low.");
        else
            $display("[FAIL] Test 1: Requesting bus unexpectedly.");

        // Test 2: Valid read
        address = TB_ADDRESS;
        mem_enable = 1;
        mem_data_output_enable = 1;
        #1;
        if (bus_drive && bus_value == 8'h55)
            $display("[PASS] Test 2: Valid read drove data_in (55) onto the bus.");
        else
            $display("[FAIL] Test 2: Read failed. drive=%b value=%h", bus_drive, bus_value);

        // Test 3: Continuous propagation
        data_in = 8'hAA;
        #1;
        if (bus_drive && bus_value == 8'hAA)
            $display("[PASS] Test 3: Data continuously propagates while read is active.");
        else
            $display("[FAIL] Test 3: Propagation failed. value=%h", bus_value);

        // Test 4: Wrong address isolation
        address = 8'h00;
        #1;
        if (!bus_drive)
            $display("[PASS] Test 4: Safely released the bus when address changed.");
        else
            $display("[FAIL] Test 4: Address isolation failed.");

        $display("--- Tests Complete ---");
        $finish;
    end

endmodule
