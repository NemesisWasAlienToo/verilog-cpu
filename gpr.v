module gpr (
    input  wire       clk,
    input  wire       reset,
    input  wire       load,
    input  wire       data_output_enable,
    input  wire       address_output_enable,
    input  wire [7:0] data_in,
    output wire [7:0] data_out,
    output wire [7:0] address_out
);

    reg [7:0] q;

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 8'h00;
        else if (load)
            q <= data_in;
    end

    assign data_out = (data_output_enable) ? q : 8'bz;
    assign address_out = (address_output_enable) ? q : 8'bz;

endmodule