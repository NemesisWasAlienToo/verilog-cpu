module toggle_register (
    input  wire clk,
    input  wire reset,
    output reg  q
);
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            q <= 1'b0;
        end else begin
            q <= ~q; // Toggle the bit
        end
    end
endmodule