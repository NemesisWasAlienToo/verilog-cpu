module decoder(
    /* Instruction Input */
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
    output wire       alu_cmd_add,
    output wire       alu_cmd_sub,
    output wire       alu_cmd_and,
    output wire       alu_cmd_or,
    output wire       alu_cmd_xor,

    /* ALU Flags */
    input  wire       alu_zero_flag,
    input  wire       alu_negative_flag,

    /* Memory Controls */
    output wire       mem_data_output_enable, // Tells memory to output onto data bus
    output wire       mem_write_enable        // Tells memory to save from data bus
);

    /* COND   CMD                 DST        SRC                COUNT */
    /* [Z|N]  MOV                 {A,B,PC},  {A,B,PC,#VALUE}  : 3x3x4 */
    /*        ADD/SUB/AND/OR/XOR  {A,B,PC},  {A,B,PC,#VALUE}  : 5x3x4 */
    /*        RD/WR               {A,B,PC},  #ADDRESS         : 2x3   */

    /* ==============================================================================
    * 8-BIT CPU INSTRUCTION SET ARCHITECTURE (ISA)
    * ==============================================================================
    * 
    * INSTRUCTION FORMAT:  [7]  [6:5]  [4]  [3:2]  [1:0]
    *                       |     |     |     |      |
    *   Type (0=MOV/MEM) ---+     |     |     |      +--- Source (SS)
    *        (1=ALU)              |     |     |           00: A     10: PC
    *                             |     |     |           01: B     11: #VALUE (Next Byte)
    *   Cond/Escape (CC) ---------+     |     |           
    *   00: AL (Always)                 |     +---------- Dest (DD)
    *   01: Z  (If Zero)                |                 00: A     10: PC
    *   10: N  (If Negative)            |                 01: B     11: Unused
    *   11: Escape (RD/WR)              |                 
    *                                   +---------------- Sub-Op / Mem Dir
    *                                                     Mem: 0=RD, 1=WR
    *                                                     ALU: Lowest bit of opcode
    * 
    * ------------------------------------------------------------------------------
    * INSTRUCTION MAP
    * ------------------------------------------------------------------------------
    * TYPE | CMD | BIT 7 | BITS 6:5 | BIT 4 | BITS 3:2 | BITS 1:0 | FORMAT
    * -----|-----|-------|----------|-------|----------|----------|-----------------
    * MEM  | MOV |   0   |    CC    |   0   |    DD    |    SS    | 0 [CC] 0 [DD] [SS]
    * MEM  | RD  |   0   |    11    |   0   |    DD    |    00    | 0  11  0 [DD]  00
    * MEM  | WR  |   0   |    11    |   1   |    DD    |    00    | 0  11  1 [DD]  00
    * -----|-----|-------|----------|-------|----------|----------|-----------------
    * ALU  | ADD |   1   |    00    |   0   |    DD    |    SS    | 1  00  0 [DD] [SS]
    * ALU  | SUB |   1   |    00    |   1   |    DD    |    SS    | 1  00  1 [DD] [SS]
    * ALU  | AND |   1   |    01    |   0   |    DD    |    SS    | 1  01  0 [DD] [SS]
    * ALU  | OR  |   1   |    01    |   1   |    DD    |    SS    | 1  01  1 [DD] [SS]
    * ALU  | XOR |   1   |    10    |   0   |    DD    |    SS    | 1  10  0 [DD] [SS]
    * 
    * ------------------------------------------------------------------------------
    * IMPLICIT COMMANDS & NOTES
    * ------------------------------------------------------------------------------
    * NOP         -> MOV A, A            (00000000 / 0x00)
    * IMM OP (LD) -> Any instruction where SS=11 fetches the next byte as an operand.
    *                e.g., MOV A, #5  or  ADD B, #10
    * JMP         -> MOV PC, #VALUE      (00001011 / 0x0B)
    * JZ          -> MOV(Z) PC, #VALUE   (00011011 / 0x1B)
    * JN          -> MOV(N) PC, #VALUE   (00101011 / 0x2B)
    * ==============================================================================
    */

    // ====================================================================
    // 1. EXTRACT BITFIELDS
    // ====================================================================
    wire       type_bit  = instruction[7];   
    wire [1:0] cond_code = instruction[6:5]; 
    wire       sub_op    = instruction[4];   
    wire [1:0] dest_sel  = instruction[3:2]; 
    wire [1:0] src_sel   = instruction[1:0]; 

    // ====================================================================
    // 2. DECODE MAJOR GROUPS & CONDITIONS
    // ====================================================================
    wire is_alu  =  type_bit;
    wire cmd_mov = ~type_bit & (cond_code != 2'b11);
    wire is_mem  = ~type_bit & (cond_code == 2'b11);

    wire cmd_rd  = is_mem & ~sub_op;
    wire cmd_wr  = is_mem &  sub_op;

    wire cond_al  = (cond_code == 2'b00);
    wire cond_z   = (cond_code == 2'b01) & alu_zero_flag;
    wire cond_n   = (cond_code == 2'b10) & alu_negative_flag;
    wire cond_met = cond_al | cond_z | cond_n;

    // ====================================================================
    // 3. REGISTER LOAD (WRITE) CONTROLS
    // ====================================================================
    // A register is loaded if the ALU executes, RD executes, or a valid MOV executes.
    wire reg_write_enable = is_alu | cmd_rd | (cmd_mov & cond_met);

    assign reg_a_load = reg_write_enable & (dest_sel == 2'b00);
    assign reg_b_load = reg_write_enable & (dest_sel == 2'b01);
    assign pc_load    = reg_write_enable & (dest_sel == 2'b10); // Resolves Jump Commands automatically

    // ====================================================================
    // 4. REGISTER DATA OUTPUT CONTROLS (Driving the Data Bus)
    // ====================================================================
    // For ALU and MOV: Data is sourced from the SRC field (src_sel).
    // For WR (Write Memory): Data is sourced from the DST field (dest_sel) to be pushed to memory.
    wire [1:0] bus_driver_sel = cmd_wr ? dest_sel : src_sel;
    
    // We only enable register outputs during ALU, MOV, or WR. (RD reads from memory, not registers).
    wire bus_drive_en = is_alu | cmd_mov | cmd_wr;

    assign reg_a_data_output_enable = bus_drive_en & (bus_driver_sel == 2'b00);
    assign reg_b_data_output_enable = bus_drive_en & (bus_driver_sel == 2'b01);
    assign pc_data_output_enable    = bus_drive_en & (bus_driver_sel == 2'b10);
    // Note: If bus_driver_sel == 2'b11 (#VALUE), none of the registers output. Memory drives the bus!

    // ====================================================================
    // 5. ALU ONE-HOT COMMAND CONTROLS
    // ====================================================================
    // Maps the 3-bit ALU operation code directly to the one-hot wires
    wire [2:0] alu_op = instruction[6:4];
    
    assign alu_cmd_add = is_alu & (alu_op == 3'b000);
    assign alu_cmd_sub = is_alu & (alu_op == 3'b001);
    assign alu_cmd_and = is_alu & (alu_op == 3'b010);
    assign alu_cmd_or  = is_alu & (alu_op == 3'b011);
    assign alu_cmd_xor = is_alu & (alu_op == 3'b100);

    // ====================================================================
    // 6. ADDRESS & PC CLOCK CONTROLS (Context-Dependent)
    // ====================================================================
    // In a multi-cycle CPU, PC incrementing and Address driving must be tied to 
    // the current Clock State (Fetch vs Operand vs Execute). Because this is a 
    // pure combinational decoder without state context, we ground unused signals 
    // to prevent inferred latches. You will toggle these from your State Machine.
    
    assign pc_address_output_enable    = 1'b0; // Toggled high by State Machine during Fetch/Operand
    assign pc_increment                = 1'b0; // Toggled high by State Machine during Fetch/Operand
    
    // RD and WR instructions use #ADDRESS (Immediate), meaning the Memory outputs
    // the address onto the bus during the Execute phase, not a general register. 
    assign reg_a_address_output_enable = 1'b0; 
    assign reg_b_address_output_enable = 1'b0; 

    // ====================================================================
    // 7. MEMORY CONTROL SIGNALS (Execute Phase)
    // ====================================================================
    
    // Q: When should the memory chip drive the data bus?
    // A: 1. During a RD (Read) command.
    //    2. During any ALU or MOV command where the source is 11 (#VALUE).
    assign mem_data_output_enable = cmd_rd | ((is_alu | cmd_mov) & (src_sel == 2'b11));

    // Q: When should the memory chip capture data from the bus?
    // A: Only during a WR (Write) command.
    assign mem_write_enable = cmd_wr;

endmodule