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
    /*        ADD/SUB/AND/OR/XOR  {A,B,PC},  {A,B,PC}         : 5x3x3 */
    /*        RD/WR               [A,B,PC],  {A,B,PC}         : 2x3   */

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
    wire [1:0] load_sel = cmd_rd ? src_sel : dest_sel;

    assign reg_a_load = enable & (reg_write_enable & (load_sel == 2'b00));
    assign reg_b_load = enable & (reg_write_enable & (load_sel == 2'b01));
    assign pc_load    = enable & (reg_write_enable & (load_sel == 2'b10)); 

    // 4. REGISTER DATA OUTPUT CONTROLS
    wire is_immediate = cmd_mov & (src_sel == 2'b11);
    
    // FIX: Apply cond_met ONLY to cmd_mov. Memory Writes (cmd_wr) are always unconditional!
    wire bus_drive_en = ((cmd_mov & cond_met) | cmd_wr) & ~is_immediate;

    assign reg_a_data_output_enable = enable & (bus_drive_en & (src_sel == 2'b00));
    assign reg_b_data_output_enable = enable & (bus_drive_en & (src_sel == 2'b01));
    assign pc_data_output_enable    = enable & (bus_drive_en & (src_sel == 2'b10));

    // 5. ALU CONTROLS & COMMANDS
    wire [2:0] alu_op = instruction[6:4];
    
    assign alu_enable  = enable & is_alu;
    assign alu_cmd_add = enable & (is_alu & (alu_op == 3'b000));
    assign alu_cmd_sub = enable & (is_alu & (alu_op == 3'b001));
    assign alu_cmd_and = enable & (is_alu & (alu_op == 3'b010));
    assign alu_cmd_or  = enable & (is_alu & (alu_op == 3'b011));
    assign alu_cmd_xor = enable & (is_alu & (alu_op == 3'b100));

    // 6. ADDRESS & PC CLOCK CONTROLS
    wire addr_drive_en = is_mem | is_immediate;
    wire [1:0] addr_sel = is_mem ? dest_sel : 2'b10;
    
    assign reg_a_address_output_enable = enable & (addr_drive_en & (addr_sel == 2'b00));
    assign reg_b_address_output_enable = enable & (addr_drive_en & (addr_sel == 2'b01));
    assign pc_address_output_enable    = enable & (addr_drive_en & (addr_sel == 2'b10));
    
    assign pc_increment                = enable & is_immediate; 

    // 7. MEMORY CONTROL SIGNALS
    wire is_memory_active = is_mem | is_immediate;
    
    assign mem_enable             = enable & is_memory_active;
    assign mem_data_output_enable = enable & (cmd_rd | is_immediate);
    assign mem_write_enable       = enable & cmd_wr;

    // 8. ALU OPERAND SELECTORS
    assign alu_l_arg = dest_sel;
    assign alu_r_arg = src_sel;

endmodule