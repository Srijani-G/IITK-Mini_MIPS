# Floating Point Coprocessor-Integrated Mini MIPS Processor

This project implements a MIPS-like processor supporting integer and floating point arithmetic, based on the IITK-Mini-MIPS instruction set. It is built using Verilog and designed to run on the PYNQ-Z2 FPGA board.

The project features custom instruction and register memory implementations, as well as a full set of ALU operations, branching logic, and coprocessor interfacing.

This system was developed as part of the coursework for [CS220: Computer Organisation]
---

## Architecture Overview

The processor supports:

- 32-bit instruction and data word size
- 32 general-purpose registers
- A 32-register IEEE-754 compliant floating-point unit (FPU)
- Integer and floating-point arithmetic
- Full MIPS-style branching and jump support
- Harvard architecture (separate instruction and data memory)

---

## Core Components

### 1. Instruction Memory
- Dual-port distributed RAM initialized via `.coe`
- 32-bit word-aligned instructions starting from address `0x0`
- Access through the program counter

### 2. Register File
- 32 general-purpose 32-bit registers (`$0`–`$31`)
- `$0` is hardwired to zero
- Each register implemented as 32 D flip-flops
- Read and write logic based on instruction decoder signals

### 3. Arithmetic Logic Unit (ALU)
- Performs arithmetic (add, sub, etc.), logic (and, or, xor), shifts, and comparisons
- Supports signed and unsigned operations
- Handles immediate extension internally

### 4. Multiply Unit
- Separate from ALU
- Supports multiply and multiply-add operations
- Results go to special `hi` and `lo` registers
- `mfhi` and `mflo` used to move to GPRs

### 5. Program Counter
- 32-bit register holding address of next instruction
- Supports PC-relative branching and jumps
- Reset loads `0x0`

### 6. Instruction Decoder
- Decodes opcode and funct fields to set control signals
- Supports `jump`, `jump_reg`, `branch`, `store`, `load`, `link`, etc.
- Drives ALU sources, register file addresses, and control logic

### 7. Floating Point Coprocessor
- IEEE-754 single-precision float support
- 32 float registers
- Supports addition, subtraction, and comparisons
- Outputs 8-bit status flags
- Shares instruction and data path with CPU via `inst`, `in_data`, `out_data`

### 8. Data Memory
- Single-port distributed RAM
- 32-bit word-aligned accesses
- Controlled via decoder

---

## Usage Instructions

### 1. Build the Project

1. Open Vivado.
2. Create a new project and add all files from the `src/` and `ip/` folders.
3. If any IPs show up as "locked", right-click them in the *Sources* panel and choose **Upgrade IP**.

---

### 2. Load a Program into Instruction Memory

Use the provided `assembler.py` to convert an assembly file into a `.coe` memory initialization file:

```bash
python assembler.py your_program.asm -o program.coe -coe
