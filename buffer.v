module buffer #(
    parameter RISING_EDGE = 1, // 1 = Trigger on posedge, 0 = Trigger on negedge
    parameter WIDTH = 8        // Default to 8-bit register
)(
    input  wire             clk,
    input  wire             reset,
    input  wire             load,    // Write control: 1 = capture data on 'd'
    input  wire             read_en, // Read control: 1 = output data to 'q'
    input  wire [WIDTH-1:0] d,       // Data Input
    output wire [WIDTH-1:0] q        // Data Output (Notice this is now a wire)
);

    // Internal storage (the actual physical flip-flops)
    reg [WIDTH-1:0] internal_data;

    generate
        if (RISING_EDGE == 1) begin : gen_posedge
            always @(posedge clk or posedge reset) begin
                if (reset)
                    internal_data <= {WIDTH{1'b0}}; // Reset to 0
                else if (load)
                    internal_data <= d;             // Capture new data
            end
        end 
        else begin : gen_negedge
            always @(negedge clk or posedge reset) begin
                if (reset)
                    internal_data <= {WIDTH{1'b0}};
                else if (load)
                    internal_data <= d;
            end
        end
    endgenerate

    // Tri-state output logic
    // If read_en is 1, drive the bus with internal_data.
    // If read_en is 0, output 'z' (High-Impedance / disconnected).
    assign q = (read_en) ? internal_data : {WIDTH{1'bz}};

endmodule