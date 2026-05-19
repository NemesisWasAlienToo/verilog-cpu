module gpr (
    input  wire       clk,
    input  wire       reset,
    input  wire       load,
    input  wire       data_output_enable,
    input  wire       address_output_enable,

    inout  wire [7:0] data_bus,
    output wire [7:0] data_alu,
    output wire [7:0] address_out
);

    reg [7:0] q;

    always @(negedge clk or posedge reset) begin
        if (reset)
            q <= 8'h00;
        else if (load)
            q <= data_bus;
    end

    assign data_bus    = (data_output_enable)    ? q : 8'bz;
    assign address_out = (address_output_enable) ? q : 8'bz;
    assign data_alu = q;

endmodule