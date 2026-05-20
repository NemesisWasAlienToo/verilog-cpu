module pc (
    input  wire       clk,
    input  wire       reset,
    input  wire       increment,
    input  wire       load,
    input  wire       data_output_enable,
    input  wire       address_output_enable,
    
    inout  wire [7:0] data_bus,
    output wire [7:0] data_alu,
    output wire [7:0] address_out
);

    reg [7:0] q = 8'h00;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            q <= 8'b00000000;
        end else if (load) begin
            q <= data_bus;
        end else if (increment) begin
            q <= q + 1;
        end
    end

    assign data_bus    = (data_output_enable) ? q : 8'bz;
    assign address_out = (address_output_enable) ? q : 8'bz;
    assign data_alu = q;

endmodule