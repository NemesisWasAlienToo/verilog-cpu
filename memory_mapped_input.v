module memory_mapped_input #(
    parameter ADDRESS = 0
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] address,
    input  wire [7:0] data_in,
    output wire [7:0] data_bus,
    input  wire       mem_enable,
    input  wire       mem_data_output_enable
);

    assign data_bus = (mem_enable && mem_data_output_enable && address == ADDRESS) ?
                      data_in : 8'bz;

endmodule