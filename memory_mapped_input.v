module memory_mapped_input #(
    parameter ADDRESS = 0
)(
    input  wire [7:0] address,
    input  wire [7:0] data_in,

    input  wire       mem_enable,
    input  wire       mem_data_output_enable,

    // Bus-mux contribution (replaces the old internal tri-state driver)
    output wire [7:0] bus_value,
    output wire       bus_drive
);

    assign bus_value = data_in;
    assign bus_drive = (mem_enable && mem_data_output_enable && address == ADDRESS);

endmodule
