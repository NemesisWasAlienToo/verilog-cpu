module machine(
    input wire       clk,
    input wire       reset,
    output reg  [7:0] gpio_pins
);

    wire [7:0] data_bus;
    wire [7:0] address_bus;
    wire       mem_enable;
    wire       mem_write_enable;
    wire       mem_data_output_enable;

    reg [7:0] program_mem[0:255];
    initial $readmemh("program.mem", program_mem);

    cpu cpu_inst(
        .clk(clk),
        .reset(reset),
        .data_pins(data_bus),
        .address_pins(address_bus),
        .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable),
        .mem_data_output_enable(mem_data_output_enable)
    );

    reg [7:0] mem_data_out;
    assign data_bus = (mem_enable && mem_data_output_enable && !mem_write_enable) ? mem_data_out : 8'bz;

    always @(negedge clk) begin
        if (mem_enable) begin
            if (mem_write_enable) begin
                program_mem[address_bus] <= data_bus;
            end else if (mem_data_output_enable) begin
                mem_data_out <= program_mem[address_bus];
            end
        end
    end

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            gpio_pins <= 8'h00;
        end else begin
            gpio_pins <= program_mem[255];
        end
    end

endmodule