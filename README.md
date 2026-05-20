# Custom 8-Bit MCU - Verilog Implementation

A complete 8-bit Microcontroller Unit (MCU) implemented from scratch in Verilog, featuring a working CPU, ALU, registers, memory management, and I/O capabilities.

## Overview

This project implements a fully functional 8-bit microcontroller with:

- **8-bit Data Architecture**: All data paths operate on 8-bit values
- **Program Counter (PC)**: Manages instruction sequencing
- **2 General Purpose Registers**: Register A and Register B for data manipulation
- **ALU (Arithmetic Logic Unit)**: Supports ADD, SUB, AND, OR, XOR operations
- **Control Unit**: Decodes and executes instructions
- **Memory System**: 254 bytes of program/data RAM with memory-mapped I/O
- **I/O System**: Memory-mapped input (address 0xFE) and output (address 0xFF)
- **Instruction Decoder**: 8-bit instruction format with conditional execution support

## Architecture

### Core Components

```
┌─────────────────────────────────────────────┐
│              MCU Top Module                 │
├─────────────────────────────────────────────┤
│  CPU (Central Processing Unit)              │
│  ├─ Program Counter (PC)                    │
│  ├─ Register A (GPR)                        │
│  ├─ Register B (GPR)                        │
│  ├─ Arithmetic Logic Unit (ALU)             │
│  ├─ Control Unit (CU)                       │
│  └─ Instruction Decoder                     │
├─────────────────────────────────────────────┤
│  Memory System                              │
│  ├─ Program Memory (RAM): 0x00-0xFD         │
│  ├─ Memory-Mapped Output: 0xFF              │
│  └─ Memory-Mapped Input: 0xFE               │
└─────────────────────────────────────────────┘
```

### Module Descriptions

#### PC (Program Counter)
- Manages instruction address sequencing
- Supports increment and load operations
- Outputs address to memory bus
- Can be written to for jump operations

#### GPR (General Purpose Registers A & B)
- 8-bit storage for data
- Can read from or write to the data bus
- Can output address values to the address bus
- Used as ALU operands

#### ALU (Arithmetic Logic Unit)
- **Operations**: ADD, SUB, AND, OR, XOR
- Operates on 16-bit accumulation internally (for overflow detection)
- **Flags**: 
  - Zero Flag: Set when result is 0x00
  - Negative Flag: Set when result has sign bit (bit 7) = 1
- Inputs from PC, Register A, and Register B

#### Control Unit (CU)
- Coordinates all CPU operations
- Handles instruction sequencing and bus arbitration
- Manages register reads/writes and ALU operations
- Implements microcode for instruction execution

#### Decoder
- Converts 8-bit instructions into control signals
- Implements conditional execution logic
- Supports multiple addressing modes

### Memory Architecture

The MCU uses a unified memory space with special I/O addresses:

- **0x00-0xFD**: General purpose RAM (254 bytes)
- **0xFE**: Memory-Mapped Input Register (read-only)
  - Samples external input pins when addressed
  - Use for reading sensor data or external signals
- **0xFF**: Memory-Mapped Output Register (write-only)
  - Drives external output pins
  - Use for controlling actuators or signaling

## Instruction Set Architecture (ISA)

This architecture supports three primary registers: **`A`**, **`B`**, and the **`PC`** (Program Counter). Anywhere you see `dst` (destination) or `src` (source) in the command list below, you can use any of those three registers.

### 1. Data Movement (Register & Immediate)

These commands move data between registers, or load hardcoded values into a register.

| Command | Example | Description |
| :--- | :--- | :--- |
| **`MOV dst, src`** | `MOV A, B` | Copies the value from the source register into the destination register. |
| **`MOV dst, #IMM`** | `MOV B, #FF` | Loads a hardcoded 8-bit hex value (00-FF) into the destination register. |
| **`MOV dst, #LABEL`** | `MOV PC, #START` | Loads the memory address of a label into the destination register. |

### 2. Memory Access (RAM & I/O)

These commands read and write to your RAM array and your Memory-Mapped I/O ports (`FE` and `FF`).

| Command | Example | Description |
| :--- | :--- | :--- |
| **`RD [ptr], dst`** | `RD [B], A` | **Read:** Looks at the memory address currently held in `ptr`, and loads the data from that address into `dst`. |
| **`WR [ptr], src`** | `WR [B], A` | **Write:** Takes the data currently inside `src` and writes it into memory at the address held in `ptr`. |

### 3. Arithmetic & Logic (ALU)

These commands perform math and logic operations. The result is always stored back into the `dst` register. They also update the `Z` (Zero) and `N` (Negative) flags.

| Command | Example | Description |
| :--- | :--- | :--- |
| **`ADD dst, src`** | `ADD A, B` | Adds `src` to `dst`. |
| **`SUB dst, src`** | `SUB A, B` | Subtracts `src` from `dst`. |
| **`AND dst, src`** | `AND A, B` | Bitwise logical AND. |
| **`OR dst, src`** | `OR A, B` | Bitwise logical OR. |
| **`XOR dst, src`** | `XOR A, B` | Bitwise logical XOR. |

### 4. Control Flow (Branching / Jumping)

To jump to a different part of your code, you simply `MOV` a new address into the `PC`. You can do this unconditionally, or conditionally based on the ALU flags from the *last executed ALU command*.

| Command | Example | Description |
| :--- | :--- | :--- |
| **`MOV PC, src`** | `MOV PC, B` | **Unconditional Jump:** Immediately jumps to the address held in the source register. |
| **`MOV Z PC, src`** | `MOV Z PC, B` | **Jump if Zero:** Jumps *only* if the Zero flag is 1 (meaning the last ALU result was 00). |
| **`MOV N PC, src`** | `MOV N PC, B` | **Jump if Negative:** Jumps *only* if the Negative flag is 1 (meaning the last ALU result caused an underflow below 00). |

*(Note: You can also conditionally move data between regular registers, like `MOV Z A, B`, which only overwrites A if the zero flag is set!)*

### 5. Assembler Directives (Syntax)

These aren't instructions for the CPU; they are helpers for the compiler to make your code easier to write.

| Syntax | Example | Description |
| :--- | :--- | :--- |
| **`LABEL:`** | `LOOP:` | Marks a specific line of code with a name so you can jump to it later without counting memory addresses. |
| **`.DEFINE`** | `.DEFINE OUT FF` | Tells the compiler to search-and-replace all instances of `OUT` with `FF` before compiling. |
| **`//`** | `// Read port` | Anything after two slashes is a comment and is ignored by the compiler. |

### Flag Behavior

After each ALU operation, two flags are set:
- **Zero Flag (Z)**: Set if result == 0x00
- **Negative Flag (N)**: Set if result bit 7 == 1 (two's complement sign)

These flags control conditional execution of MOV instructions.

## Tools & Setup

### Prerequisites

On Debian/Ubuntu-based systems:

```bash
sudo apt update
sudo apt install iverilog gtkwave
```

- **iverilog**: Verilog compiler and simulator
- **gtkwave**: Waveform viewer for analyzing simulation results

### Simulation Files

- `*.v` files: Module interface definitions
- `*.sv` files: Module implementations (SystemVerilog)
- `*.out` files: Compiled simulation executables (generated)
- `*.vcd` files: Waveform dump files (generated)

## Using the Compiler

The `compiler.html` file is an interactive web-based assembler:

1. **Open** `compiler.html` in a web browser
2. **Write** assembly code for your MCU program
3. **Compile** to generate machine code
4. **Export** the machine code to `program.mem`
5. **Simulate** with `make mcu-exec`


## Workflow: From Code to Execution

### Step 1: Write Assembly

Open `compiler.html` in your browser and write your program:

```assembly
MOV A, #0xAA
MOV B, #0x55
ADD A, B
MOV #0xFF, A
```

### Step 2: Compile & Generate program.mem

The compiler exports machine code. Save it to `program.mem`:

```
AA
55
81
... (hex values)
```

### Step 3: Simulate

```bash
make mcu-exec
```

### Step 4: Analyze Results

Open the generated waveform:

```bash
gtkwave mcu_execution.vcd
```

In GTKWave, you can inspect:
- Clock cycles
- Register values (A, B, PC)
- ALU outputs and flags
- Data and address bus values
- Memory reads/writes
- I/O pin activity

## Example: Complete Program

This example demonstrates a counting program that outputs values to the output port:

```assembly
.DEFINE OUT_PORT FF
.DEFINE IN_PORT FE

    MOV A, #05          // Initialize counter to 5
    
LOOP:
    MOV B, #OUT_PORT    // Point B to output port
    WR [B], A           // Write current counter value to output
    
    MOV B, #01          // Put 1 in B for subtraction
    SUB A, B            // Decrement: A = A - 1 (updates flags)
    
    MOV B, #LOOP        // Load loop label address into B
    MOV Z PC, #HALT     // If A is now zero, jump to HALT
    MOV PC, B           // Otherwise, unconditional jump back to LOOP

HALT:
    MOV PC, #HALT       // Infinite loop to halt execution
```

**Program Explanation**:
1. Initialize counter to 5
2. Write counter value to output port (address FF)
3. Decrement counter by 1
4. If counter reaches 0 (Zero flag set), jump to HALT
5. Otherwise, loop back to LOOP
6. When done, enter infinite loop at HALT

## Architecture Design Decisions

- **8-bit design**: Simple, educational, easy to understand
- **Memory-mapped I/O**: Treats I/O as memory addresses (0xFE, 0xFF)
- **Condition codes**: Zero and Negative flags for flow control
- **ALU operations**: Essential arithmetic and logic operations
- **Unified addressing**: Single memory space for program and data

## References

- [Verilog-2001-2005 Standard](https://en.wikipedia.org/wiki/Verilog)
- [GTKWave Documentation](https://gtkwave.sourceforge.io/)
- [iVerilog Documentation](http://bleyer.org/icarus/)

## License

Educational project - freely available for learning and modification.