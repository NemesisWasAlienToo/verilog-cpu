module mcu(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] in_pins,
    output wire [7:0] out_pins
);

    // wire clk, clk_fb;
    // PLLE2_BASE #(.CLKIN1_PERIOD(8.0), .CLKFBOUT_MULT(8), .CLKOUT0_DIVIDE(127))
    // PLLE2_BASE_inst(.CLKIN1(clk125), .CLKFBOUT(clk_fb), .CLKFBIN(clk_fb), .CLKOUT0(clk));


    // Global bus lines
    wire [7:0] data_bus;
    wire [7:0] address_bus;
    wire       mem_enable;
    wire       mem_write_enable;
    wire       mem_data_output_enable;

    // Processor
    wire [7:0] cpu_data_out;
    wire       cpu_data_drive;
    cpu cpu_inst(
        .clk(clk),
        .reset(reset),
        .data_bus_in(data_bus),
        .data_bus_out(cpu_data_out),
        .data_bus_drive(cpu_data_drive),
        .address_pins(address_bus),
        .mem_enable(mem_enable),
        .mem_write_enable(mem_write_enable),
        .mem_data_output_enable(mem_data_output_enable)
    );

    // Memory unit
    reg [7:0] program_mem[0:253];
    initial $readmemh("program.mem", program_mem);

    wire ram_enable = (address_bus < 8'hFE) && mem_enable;
    wire ram_drive  = ram_enable && mem_data_output_enable;
    wire [7:0] ram_value  = program_mem[address_bus];

    always @(negedge clk) begin
        if (ram_enable && mem_write_enable) begin
            program_mem[address_bus] <= data_bus;
        end
    end

    wire [7:0] mmio_out_value;
    wire       mmio_out_drive;
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
        .mem_data_output_enable(mem_data_output_enable),
        .bus_value(mmio_out_value),
        .bus_drive(mmio_out_drive)
    );

    // Memory-mapped input register (0xFE)
    wire [7:0] mmio_in_value;
    wire       mmio_in_drive;
    memory_mapped_input #(
        .ADDRESS(8'hFE)
    ) memory_mapped_in_reg_b (
        .address(address_bus),
        .data_in(in_pins),
        .mem_enable(mem_enable),
        .mem_data_output_enable(mem_data_output_enable),
        .bus_value(mmio_in_value),
        .bus_drive(mmio_in_drive)
    );

    assign data_bus =
        cpu_data_drive ? cpu_data_out   :
        ram_drive      ? ram_value      :
        mmio_in_drive  ? mmio_in_value  :
        mmio_out_drive ? mmio_out_value :
        8'h00;

endmodule
