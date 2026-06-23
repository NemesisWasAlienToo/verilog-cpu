`timescale 1ns / 1ps

module tb_memory_mapped_output;

    localparam [7:0] TB_ADDRESS = 8'hFF;

    reg clk;
    reg reset;
    reg [7:0] address;
    reg [7:0] data_bus;
    reg mem_enable;
    reg mem_write_enable;
    reg mem_data_output_enable;

    wire [7:0] data_out;
    wire [7:0] bus_value;
    wire       bus_drive;

    memory_mapped_output #(
        .ADDRESS(TB_ADDRESS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .address(address),
        .data_bus(data_bus),
        .data_out(data_out),
        .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable),
        .mem_data_output_enable(mem_data_output_enable),
        .bus_value(bus_value),
        .bus_drive(bus_drive)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("memory_mapped_output.vcd");
        $dumpvars(0, tb_memory_mapped_output);

        clk = 0;
        reset = 1;
        address = 8'h00;
        data_bus = 8'h00;
        mem_enable = 0;
        mem_write_enable = 0;
        mem_data_output_enable = 0;

        $display("--- Starting Memory Mapped Output Tests ---");

        // Test 1: Reset
        #15 reset = 0;
        #1;
        if (data_out == 8'h00)
            $display("[PASS] Test 1: Reset successfully cleared the output to 00.");
        else
            $display("[FAIL] Test 1: Reset failed. Expected 00, got %h", data_out);

        // Test 2: Valid write
        @(posedge clk);
        address = TB_ADDRESS;
        data_bus = 8'hAA;
        mem_enable = 1;
        mem_write_enable = 1;
        @(posedge clk);
        mem_enable = 0;
        mem_write_enable = 0;
        #1;
        if (data_out == 8'hAA)
            $display("[PASS] Test 2: Valid write to Address %h latched data AA.", TB_ADDRESS);
        else
            $display("[FAIL] Test 2: Valid write failed. Expected AA, got %h", data_out);

        // Test 3: Wrong address ignored
        @(posedge clk);
        address = 8'hFE;
        data_bus = 8'hBB;
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

        // Test 4: Readback requests the bus with q
        address = TB_ADDRESS;
        mem_enable = 1;
        mem_data_output_enable = 1;
        #1;
        if (bus_drive && bus_value == 8'hAA)
            $display("[PASS] Test 4: Readback drives bus with AA.");
        else
            $display("[FAIL] Test 4: Readback failed. drive=%b value=%h", bus_drive, bus_value);

        // Test 5: Releases the bus when not addressed/enabled
        mem_enable = 0;
        mem_data_output_enable = 0;
        #1;
        if (!bus_drive)
            $display("[PASS] Test 5: Releases the bus when disabled.");
        else
            $display("[FAIL] Test 5: Still requesting the bus when disabled.");

        $display("--- Tests Complete ---");
        $finish;
    end

endmodule
