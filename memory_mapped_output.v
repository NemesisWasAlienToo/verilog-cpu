module memory_mapped_output #(
    parameter ADDRESS = 0
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] address,
    input  wire [7:0] data_in,
    output wire [7:0] data_out,
    input  wire       mem_enable,
    input  wire       mem_write_enable
);

    reg [7:0] data = 8'h00;
    assign data_out = data;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            data <= 8'h00;
        end else begin
            if (mem_enable && mem_write_enable && address == ADDRESS) begin
                data <= data_in;
            end
        end
    end

endmodule