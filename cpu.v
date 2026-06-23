module cpu(
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] data_bus_in,
    output wire [7:0] data_bus_out,
    output wire       data_bus_drive,

    output wire [7:0] address_pins,
    output wire       mem_enable,
    output wire       mem_write_enable,
    output wire       mem_data_output_enable
);

    wire pc_increment, pc_load, pc_data_output_enable, pc_address_output_enable;
    wire [7:0] pc_value;
    pc program_counter(
        .clk(clk),
        .reset(reset),
        .increment(pc_increment),
        .load(pc_load),
        .data_bus(data_bus_in),
        .value(pc_value)
    );

    wire reg_a_load, reg_a_data_output_enable, reg_a_address_output_enable;
    wire [7:0] reg_a_value;
    gpr register_a(
        .clk(clk),
        .reset(reset),
        .load(reg_a_load),
        .data_bus(data_bus_in),
        .value(reg_a_value)
    );

    wire reg_b_load, reg_b_data_output_enable, reg_b_address_output_enable;
    wire [7:0] reg_b_value;
    gpr register_b(
        .clk(clk),
        .reset(reset),
        .load(reg_b_load),
        .data_bus(data_bus_in),
        .value(reg_b_value)
    );

    wire alu_enable, alu_cmd_add, alu_cmd_sub, alu_cmd_and, alu_cmd_or, alu_cmd_xor;
    wire [1:0] alu_l_arg, alu_r_arg;
    wire alu_zero_flag, alu_negative_flag;
    wire [7:0] alu_result;
    reg  [1:0] alu_flags = 2'b00;
    alu alu_unit(
        .a(reg_a_value),
        .b(reg_b_value),
        .c(pc_value),
        .l_arg(alu_l_arg),
        .r_arg(alu_r_arg),
        .cmd_add(alu_cmd_add),
        .cmd_sub(alu_cmd_sub),
        .cmd_and(alu_cmd_and),
        .cmd_or(alu_cmd_or),
        .cmd_xor(alu_cmd_xor),
        .result(alu_result),
        .zero_flag(alu_zero_flag),
        .negative_flag(alu_negative_flag)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_flags <= 2'b00;
        end else if (alu_enable) begin // ONLY update flags when ALU is active!
            alu_flags <= {alu_zero_flag, alu_negative_flag};
        end
    end

    cu control_unit(
        .clk(clk),
        .reset(reset),

        .pc_increment(pc_increment),
        .pc_load(pc_load),
        .pc_data_output_enable(pc_data_output_enable),
        .pc_address_output_enable(pc_address_output_enable),

        .reg_a_load(reg_a_load),
        .reg_a_data_output_enable(reg_a_data_output_enable),
        .reg_a_address_output_enable(reg_a_address_output_enable),

        .reg_b_load(reg_b_load),
        .reg_b_data_output_enable(reg_b_data_output_enable),
        .reg_b_address_output_enable(reg_b_address_output_enable),

        .alu_enable(alu_enable),
        .alu_l_arg(alu_l_arg),
        .alu_r_arg(alu_r_arg),
        .alu_cmd_add(alu_cmd_add),
        .alu_cmd_sub(alu_cmd_sub),
        .alu_cmd_and(alu_cmd_and),
        .alu_cmd_or(alu_cmd_or),
        .alu_cmd_xor(alu_cmd_xor),

        .alu_zero_flag(alu_flags[0]),
        .alu_negative_flag(alu_flags[1]),
        
        .mem_enable(mem_enable),
        .mem_data_output_enable(mem_data_output_enable),
        .mem_write_enable(mem_write_enable),

        .data_bus(data_bus_in)
    );

    assign address_pins =
        pc_address_output_enable    ? pc_value    :
        reg_a_address_output_enable ? reg_a_value :
        reg_b_address_output_enable ? reg_b_value :
        8'h00;

    assign data_bus_drive =
          pc_data_output_enable
        | reg_a_data_output_enable
        | reg_b_data_output_enable 
        | alu_enable;

    assign data_bus_out =
        pc_data_output_enable    ? pc_value    :
        reg_a_data_output_enable ? reg_a_value :
        reg_b_data_output_enable ? reg_b_value :
        alu_enable               ? alu_result  :
        8'h00;

endmodule
