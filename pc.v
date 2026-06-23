module pc (
    input  wire       clk,
    input  wire       reset,
    input  wire       increment,
    input  wire       load,

    input  wire [7:0] data_bus,
    output wire [7:0] value
);

    reg [7:0] q = 8'b00000000;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            q <= 8'b00000000;
        end else if (load) begin
            q <= data_bus;
        end else if (increment) begin
            q <= q + 1;
        end
    end

    assign value = q;

endmodule
