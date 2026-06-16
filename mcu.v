module mcu(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] in_pins,
    output wire [7:0] out_pins
);

    // Global bus lines
    wire [7:0] data_bus;
    wire [7:0] address_bus;
    wire       mem_enable;
    wire       mem_write_enable;
    wire       mem_data_output_enable;


    // Memory unit
    reg [7:0] program_mem[0:253];
    initial $readmemh("program.mem", program_mem);

    wire ram_enable = (address_bus < 8'hFE && mem_enable);
    wire [7:0] memory_data_out = (ram_enable && mem_data_output_enable) ? program_mem[address_bus] : 8'bz;

    always @(negedge clk) begin
        if (ram_enable && mem_write_enable) begin
            program_mem[address_bus] <= data_bus;
        end
    end

    assign data_bus = memory_data_out;

    memory_mapped_output #(
        .ADDRESS(8'hFF)
    ) memory_mapped_out_reg_a (
        .clk(clk),
        .reset(reset),
        .address(address_bus),
        .data_bus(data_bus),
        .data_out(out_pins),
        .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable),
        .mem_data_output_enable(mem_data_output_enable)
    );

    memory_mapped_input #(
        .ADDRESS(8'hFE)
    ) memory_mapped_in_reg_b (
        .clk(clk),
        .reset(reset),
        .address(address_bus),
        .data_in(in_pins),
        .data_bus(data_bus),
        .mem_enable(mem_enable),
        .mem_data_output_enable(mem_data_output_enable)
    );


    // Processor
    cpu cpu_inst(
        .clk(clk),
        .reset(reset),
        .data_pins(data_bus),
        .address_pins(address_bus),
        .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable),
        .mem_data_output_enable(mem_data_output_enable)
    );

endmodule