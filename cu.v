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
    output wire       alu_cmd_add,
    output wire       alu_cmd_sub,
    output wire       alu_cmd_and,
    output wire       alu_cmd_or,
    output wire       alu_cmd_xor,

    /* ALU Flags */
    input  wire       alu_zero_flag,
    input  wire       alu_negative_flag,

    /* Memory Controls */
    output wire       mem_data_output_enable,
    output wire       mem_write_enable,

    /* Data bus input */
    input  wire [7:0] data_bus
);

    // ====================================================================
    // 1. PIPELINE STAGE TRACKER (0 = Fetch, 1 = Execute)
    // ====================================================================
    wire stage;
    
    // Assuming you have a toggle_register module that flips its state every cycle
    toggle_register pipeline_stage(
        .clk(clk), 
        .reset(reset), 
        .q(stage)
    );

    // ====================================================================
    // 2. INSTRUCTION REGISTER (IR)
    // ====================================================================
    reg [7:0] ir;
    
    // As requested: On the rising edge of the fetch step, capture the data bus.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ir <= 8'h00;
        end else if (stage == 1'b0) begin
            ir <= data_bus; 
        end
    end




    ////////

    wire stage;
    reg [7:0] ir = 0;
    stage pipeline_stage(.clk(clk), .reset(reset), q(stage));

    always @(posedge clk) begin
        if (stage == 1'b0) begin
            /* Fetch step: fetch the instruction into IR (Instruction Register) */
            pc_address_output_enable = 1'b1;
            mem_data_output_enable = 1'b1;
            ir <= data_bus;
        end else begin
            pc_address_output_enable = 1'bz;
            mem_data_output_enable = 1'bz;
        end
    end

    always @(negedge clk) begin
        if (stage == 1'b0) begin
            pc_increment = 1'b1
        end else begin
            pc_increment = 1'bz;
            /* Execution step: Execute the instruction */
        end
    end

    // ====================================================================
    // 3. INTERNAL DECODER INSTANTIATION
    // ====================================================================
    // These wires carry the "raw" logic from your combinational decoder
    wire dec_pc_load, dec_pc_data_oe, dec_pc_addr_oe;
    wire dec_reg_a_load, dec_reg_a_data_oe, dec_reg_a_addr_oe;
    wire dec_reg_b_load, dec_reg_b_data_oe, dec_reg_b_addr_oe;
    wire dec_mem_data_oe, dec_mem_write;
    
    decoder cpu_decoder(
        .instruction(ir), // Feed the internal IR directly to the decoder
        
        .alu_zero_flag(alu_zero_flag),
        .alu_negative_flag(alu_negative_flag),

        // Map outputs to internal wires
        .pc_increment(), // Ignored here, CU handles incrementing during fetch manually
        .pc_load(dec_pc_load),
        .pc_data_output_enable(dec_pc_data_oe),
        .pc_address_output_enable(dec_pc_addr_oe),
        
        .reg_a_load(dec_reg_a_load),
        .reg_a_data_output_enable(dec_reg_a_data_oe),
        .reg_a_address_output_enable(dec_reg_a_addr_oe),
        
        .reg_b_load(dec_reg_b_load),
        .reg_b_data_output_enable(dec_reg_b_data_oe),
        .reg_b_address_output_enable(dec_reg_b_addr_oe),
        
        // ALU logic flows straight through, we will gate it below
        .alu_cmd_add(alu_cmd_add),
        .alu_cmd_sub(alu_cmd_sub),
        .alu_cmd_and(alu_cmd_and),
        .alu_cmd_or(alu_cmd_or),
        .alu_cmd_xor(alu_cmd_xor),
        
        .mem_data_output_enable(dec_mem_data_oe),
        .mem_write_enable(dec_mem_write)
    );

    // ====================================================================
    // 4. STAGE MULTIPLEXING LOGIC
    // ====================================================================
    
    // --- FETCH STAGE OVERRIDES (stage == 0) ---
    // During fetch, we must force the PC to drive the address bus, and 
    // memory to drive the data bus so the IR can catch it. 
    // Otherwise (stage == 1), we let the decoder decide.
    assign pc_address_output_enable = (stage == 1'b0) ? 1'b1 : dec_pc_addr_oe;
    assign mem_data_output_enable   = (stage == 1'b0) ? 1'b1 : dec_mem_data_oe;
    
    // PC Increment is only active during the fetch stage. 
    // Because your PC module updates on the negedge of the clock, holding this 
    // high during stage 0 means the PC will increment perfectly on the falling edge!
    assign pc_increment = (stage == 1'b0) ? 1'b1 : 1'b0;

    // --- EXECUTE STAGE GATEKEEPING (stage == 1) ---
    // We must ensure that registers are NOT loaded and do NOT output to the bus
    // while we are fetching. They are only allowed to turn on if stage == 1.
    
    assign pc_load               = (stage == 1'b1) ? dec_pc_load : 1'b0;
    assign pc_data_output_enable = (stage == 1'b1) ? dec_pc_data_oe : 1'b0;

    assign reg_a_load                  = (stage == 1'b1) ? dec_reg_a_load : 1'b0;
    assign reg_a_data_output_enable    = (stage == 1'b1) ? dec_reg_a_data_oe : 1'b0;
    assign reg_a_address_output_enable = (stage == 1'b1) ? dec_reg_a_addr_oe : 1'b0;

    assign reg_b_load                  = (stage == 1'b1) ? dec_reg_b_load : 1'b0;
    assign reg_b_data_output_enable    = (stage == 1'b1) ? dec_reg_b_data_oe : 1'b0;
    assign reg_b_address_output_enable = (stage == 1'b1) ? dec_reg_b_addr_oe : 1'b0;

    assign mem_write_enable      = (stage == 1'b1) ? dec_mem_write : 1'b0;

endmodule