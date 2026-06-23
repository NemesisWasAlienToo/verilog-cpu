module gpr (
    input  wire       clk,
    input  wire       reset,
    input  wire       load,

    input  wire [7:0] data_bus,
    output wire [7:0] value
);

    reg [7:0] q = 8'h00;

    always @(negedge clk or posedge reset) begin
        if (reset)
            q <= 8'h00;
        else if (load)
            q <= data_bus;
    end

    assign value = q;

endmodule
