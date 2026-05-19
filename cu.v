module cu (
    input  wire       clk,
    input  wire       reset,

    /* PC Control */
    output wire       pc_increment,
    output wire       pc_load,
    output wire       pc_data_output_enable,
    output wire       pc_address_output_enable,

    /* Register A Controls */
    output wire       reg_a_load,
    output wire       reg_a_data_output_enable,
    output wire       reg_a_address_output_enable,

    /* Register B Controls */
    output wire       reg_b_load,
    output wire       reg_b_data_output_enable,
    output wire       reg_b_address_output_enable,

    /* ALU Controls */
    output wire       alu_enable,
    output wire [1:0] alu_l_arg,
    output wire [1:0] alu_r_arg,
    output wire       alu_cmd_add,
    output wire       alu_cmd_sub,
    output wire       alu_cmd_and,
    output wire       alu_cmd_or,
    output wire       alu_cmd_xor,

    /* ALU Flags */
    input  wire       alu_zero_flag,
    input  wire       alu_negative_flag,

    /* Memory Controls */
    output wire       mem_enable,
    output wire       mem_data_output_enable,
    output wire       mem_write_enable,

    /* Data bus input */
    input  wire [7:0] data_bus
);

    reg [7:0] ir = 8'b00000000;
    
    /* 3-Stage pipeline */
    reg [2:0] stage = 3'b100;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage <= 3'b001; // Start at Fetch
        end else begin
            stage <= {stage[1:0], stage[2]}; 
        end
    end

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            ir <= 8'h00;
        end else if (stage[0]) begin
            ir <= data_bus;
        end
    end

    wire dec_mem_enable;
    wire dec_mem_data_oe;
    wire dec_pc_addr_oe;
    wire dec_pc_increment;

    decoder isa_decoder(
        .enable(stage[2]),
        
        .instruction(ir),
        .alu_zero_flag(alu_zero_flag),
        .alu_negative_flag(alu_negative_flag),

        .pc_address_output_enable(dec_pc_addr_oe),
        .mem_enable(dec_mem_enable),
        .mem_data_output_enable(dec_mem_data_oe),
        
        .pc_increment(dec_pc_increment),
        .pc_load(pc_load),
        .pc_data_output_enable(pc_data_output_enable),
        
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
        
        .mem_write_enable(mem_write_enable)
    );

    assign pc_address_output_enable = stage[0] ? 1'b1 : dec_pc_addr_oe;
    assign mem_enable               = stage[0] ? 1'b1 : dec_mem_enable;
    assign mem_data_output_enable   = stage[0] ? 1'b1 : dec_mem_data_oe;
    assign pc_increment             = stage[1] ? 1'b1 : dec_pc_increment;

endmodule