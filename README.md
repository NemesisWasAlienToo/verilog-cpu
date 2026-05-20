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

### Memory Architecture

The MCU uses a unified memory space with special I/O addresses:

- **0x00-0xFD**: General purpose RAM (254 bytes)
- **0xFE**: Memory-Mapped Input Register (read-only)
- **0xFF**: Memory-Mapped Output Register (write-only)

## Instruction Set Architecture (ISA)

| Command | Meaning |
| :--- | :--- |
| `MOV {A,B,PC}, {A,B,PC,#VALUE}` | move data or load an immediate value |
| `MOV Z {A,B,PC}, {A,B,PC,#VALUE}` | conditional move when Zero flag is set |
| `MOV N {A,B,PC}, {A,B,PC,#VALUE}` | conditional move when Negative flag is set |
| `ADD {A,B,PC}, {A,B,PC}` | add source to destination |
| `SUB {A,B,PC}, {A,B,PC}` | subtract source from destination |
| `AND {A,B,PC}, {A,B,PC}` | bitwise AND |
| `OR {A,B,PC}, {A,B,PC}` | bitwise OR |
| `XOR {A,B,PC}, {A,B,PC}` | bitwise XOR |
| `RD [{A,B,PC}], {A,B,PC}` | read memory at address in pointer |
| `WR [{A,B,PC}], {A,B,PC}` | write memory at address in pointer |

Notes:
- Jumping is done with `MOV PC, ...` (or `MOV Z PC, ...` / `MOV N PC, ...`).
- Only `MOV` supports condition codes.
- The compiler supports labels, `.DEFINE`, and `//` comments.

## Tools & Setup

### Prerequisites

On Debian/Ubuntu-based systems:

```bash
sudo apt update
sudo apt install iverilog gtkwave
```

- **iverilog**: Verilog compiler and simulator
- **gtkwave**: Waveform viewer for analyzing simulation results

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