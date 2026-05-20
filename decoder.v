module decoder(
    /* Control Input */
    input  wire       enable, // Active high
    input  wire [7:0] instruction,

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
    output wire       mem_write_enable
);

    /* COND   CMD                 DST        SRC                COUNT */
    /* [Z|N]  MOV                 {A,B,PC},  {A,B,PC,#VALUE}  : 3x3x4 */
    /*        ADD/SUB/AND/OR/XOR  {A,B,PC},  {A,B,PC,#VALUE}  : 5x3x4 */
    /*        RD/WR               {A,B,PC},  #ADDRESS         : 2x3   */


    // 1. EXTRACT BITFIELDS
    wire       type_bit  = instruction[7];   
    wire [1:0] cond_code = instruction[6:5]; 
    wire       sub_op    = instruction[4];   
    wire [1:0] dest_sel  = instruction[3:2]; 
    wire [1:0] src_sel   = instruction[1:0]; 

    // 2. DECODE MAJOR GROUPS & CONDITIONS
    wire is_alu  =  type_bit;
    wire cmd_mov = ~type_bit & (cond_code != 2'b11);
    wire is_mem  = ~type_bit & (cond_code == 2'b11);

    wire cmd_rd  = is_mem & ~sub_op;
    wire cmd_wr  = is_mem &  sub_op;

    wire cond_al  = (cond_code == 2'b00);
    wire cond_z   = (cond_code == 2'b01) & alu_zero_flag;
    wire cond_n   = (cond_code == 2'b10) & alu_negative_flag;
    wire cond_met = cond_al | cond_z | cond_n;

    // 3. REGISTER LOAD (WRITE) CONTROLS
    wire reg_write_enable = is_alu | cmd_rd | (cmd_mov & cond_met);

    assign reg_a_load = enable & (reg_write_enable & (dest_sel == 2'b00));
    assign reg_b_load = enable & (reg_write_enable & (dest_sel == 2'b01));
    assign pc_load    = enable & (reg_write_enable & (dest_sel == 2'b10)); 

    // 4. REGISTER DATA OUTPUT CONTROLS
    wire [1:0] bus_driver_sel = cmd_wr ? dest_sel : src_sel;
    wire bus_drive_en = is_alu | cmd_mov | cmd_wr;

    assign reg_a_data_output_enable = enable & (bus_drive_en & (bus_driver_sel == 2'b00));
    assign reg_b_data_output_enable = enable & (bus_drive_en & (bus_driver_sel == 2'b01));
    assign pc_data_output_enable    = enable & (bus_drive_en & (bus_driver_sel == 2'b10));

    // 5. ALU CONTROLS & COMMANDS
    wire [2:0] alu_op = instruction[6:4];
    
    assign alu_enable  = enable & is_alu;
    assign alu_cmd_add = enable & (is_alu & (alu_op == 3'b000));
    assign alu_cmd_sub = enable & (is_alu & (alu_op == 3'b001));
    assign alu_cmd_and = enable & (is_alu & (alu_op == 3'b010));
    assign alu_cmd_or  = enable & (is_alu & (alu_op == 3'b011));
    assign alu_cmd_xor = enable & (is_alu & (alu_op == 3'b100));

    // 6. ADDRESS & PC CLOCK CONTROLS (Grounded here)
    wire is_immediate = (src_sel == 2'b11);
    
    assign pc_address_output_enable    = enable & is_immediate; 
    assign pc_increment                = enable & is_immediate; 
    
    assign reg_a_address_output_enable = 1'b0; 
    assign reg_b_address_output_enable = 1'b0;

    // 7. MEMORY CONTROL SIGNALS
    
    // Determine if the current instruction is trying to touch memory
    wire is_memory_active = cmd_rd | cmd_wr | ((is_alu | cmd_mov) & (src_sel == 2'b11));
    
    assign mem_enable             = enable & is_memory_active;
    assign mem_data_output_enable = enable & (cmd_rd | ((is_alu | cmd_mov) & (src_sel == 2'b11)));
    assign mem_write_enable       = enable & cmd_wr;

    // 8. ALU OPERAND SELECTORS
    assign alu_l_arg = dest_sel;
    assign alu_r_arg = src_sel;

endmodule