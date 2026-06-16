module memory_mapped_output #(
    parameter ADDRESS = 0
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] address,
    inout  wire [7:0] data_bus,
    output wire [7:0] data_out,
    input  wire       mem_enable,
    input  wire       mem_write_enable,
    input  wire       mem_data_output_enable
);

    reg [7:0] q = 8'h00;
    assign data_out = q;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            q <= 8'h00;
        end else begin
            if (mem_enable && mem_write_enable && address == ADDRESS) begin
                q <= data_bus;
            end
        end
    end

    assign data_bus = (mem_enable && mem_data_output_enable && address == ADDRESS) ?
                      q : 8'bz;

endmodule