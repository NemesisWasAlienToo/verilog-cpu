.PHONY: all clean test pc gpr decoder cu alu mio cpu mcu mcu-exec help

# Compiler and simulator
IVERILOG = iverilog
VERILOG_STD = -g2012
GTKWAVE = gtkwave
SIMULATOR = vvp

# Output files
PC_OUT = pc.out
GPR_OUT = gpr.out
DECODER_OUT = decoder.out
CU_OUT = cu.out
ALU_OUT = alu.out
MIO_OUT = memory_mapped_io.out
CPU_OUT = cpu.out
MCU_OUT = mcu.out
MCU_EXEC_OUT = mcu_execution.out

help:
	@echo "MCU Verilog Simulation - Available Commands:"
	@echo ""
	@echo "  make test              - Run all unit tests"
	@echo "  make pc                - Test Program Counter"
	@echo "  make gpr               - Test General Purpose Registers"
	@echo "  make decoder           - Test Instruction Decoder (with waveform)"
	@echo "  make cu                - Test Control Unit (with waveform)"
	@echo "  make alu               - Test ALU (with waveform)"
	@echo "  make mio               - Test Memory-Mapped I/O"
	@echo "  make cpu               - Test CPU (with waveform)"
	@echo "  make mcu               - Test MCU (with waveform)"
	@echo "  make mcu-exec          - Run MCU execution simulation (with waveform)"
	@echo "  make wave <vcd_file>   - View waveform (e.g., make wave decoder.vcd)"
	@echo "  make clean             - Remove all compiled outputs and VCD files"
	@echo ""

# Test Program Counter
pc: $(PC_OUT)
	$(SIMULATOR) $(PC_OUT)

$(PC_OUT): pc.v pc.sv
	$(IVERILOG) $(VERILOG_STD) -o $(PC_OUT) pc.v pc.sv

# Test General Purpose Registers
gpr: $(GPR_OUT)
	$(SIMULATOR) $(GPR_OUT)

$(GPR_OUT): gpr.v gpr.sv
	$(IVERILOG) $(VERILOG_STD) -o $(GPR_OUT) gpr.v gpr.sv

# Test Decoder (with waveform)
decoder: $(DECODER_OUT)
	$(SIMULATOR) $(DECODER_OUT)
# 	@echo "Opening decoder.vcd in GTKWave..."
# 	$(GTKWAVE) decoder.vcd

$(DECODER_OUT): decoder.v decoder.sv
	$(IVERILOG) $(VERILOG_STD) -o $(DECODER_OUT) decoder.v decoder.sv

# Test Control Unit (with waveform)
cu: $(CU_OUT)
	$(SIMULATOR) $(CU_OUT)
# 	@echo "Opening cu.vcd in GTKWave..."
# 	$(GTKWAVE) cu.vcd

$(CU_OUT): cu.v cu.sv decoder.v
	$(IVERILOG) $(VERILOG_STD) -o $(CU_OUT) cu.v decoder.v cu.sv

# Test ALU (with waveform)
alu: $(ALU_OUT)
	$(SIMULATOR) $(ALU_OUT)
# 	@echo "Opening alu.vcd in GTKWave..."
# 	$(GTKWAVE) alu.vcd

$(ALU_OUT): alu.v alu.sv
	$(IVERILOG) $(VERILOG_STD) -o $(ALU_OUT) alu.v alu.sv

# Test Memory-Mapped I/O
mio: memory_mapped_output memory_mapped_input

memory_mapped_output:
	$(IVERILOG) $(VERILOG_STD) -o memory_mapped_output.out memory_mapped_output.v memory_mapped_output.sv
	$(SIMULATOR) memory_mapped_output.out
	@echo "Opening memory_mapped_output.vcd in GTKWave..."
# 	$(GTKWAVE) memory_mapped_output.vcd

memory_mapped_input:
	$(IVERILOG) $(VERILOG_STD) -o memory_mapped_input.out memory_mapped_input.v memory_mapped_input.sv
	$(SIMULATOR) memory_mapped_input.out
	@echo "Opening memory_mapped_input.vcd in GTKWave..."
# 	$(GTKWAVE) memory_mapped_input.vcd

# Test CPU (with waveform)
cpu: $(CPU_OUT)
	$(SIMULATOR) $(CPU_OUT)
	@echo "Opening cpu.vcd in GTKWave..."
# 	$(GTKWAVE) cpu.vcd

$(CPU_OUT): cpu.v cpu.sv pc.v gpr.v decoder.v cu.v alu.v
	$(IVERILOG) $(VERILOG_STD) -o $(CPU_OUT) cpu.v pc.v gpr.v decoder.v cu.v alu.v cpu.sv

# Test MCU (with waveform)
mcu: $(MCU_OUT)
	$(SIMULATOR) $(MCU_OUT)
	@echo "Opening mcu.vcd in GTKWave..."
# 	$(GTKWAVE) mcu.vcd

$(MCU_OUT): mcu.v mcu.sv cpu.v pc.v gpr.v decoder.v cu.v alu.v memory_mapped_output.v memory_mapped_input.v
	$(IVERILOG) $(VERILOG_STD) -o $(MCU_OUT) cpu.v pc.v gpr.v decoder.v cu.v alu.v mcu.v memory_mapped_output.v memory_mapped_input.v mcu.sv

# Run MCU Execution (full program simulation)
mcu-exec: $(MCU_EXEC_OUT)
	$(SIMULATOR) $(MCU_EXEC_OUT)

$(MCU_EXEC_OUT): mcu_execution.sv mcu.v cpu.v pc.v gpr.v decoder.v cu.v alu.v memory_mapped_output.v memory_mapped_input.v
	$(IVERILOG) $(VERILOG_STD) -o $(MCU_EXEC_OUT) cpu.v pc.v gpr.v decoder.v cu.v alu.v mcu.v memory_mapped_output.v memory_mapped_input.v mcu_execution.sv

# View waveform (usage: make wave decoder.vcd)
wave:
	@if [ -z "$(VCD_FILE)" ]; then echo "Usage: make wave VCD_FILE=<filename.vcd>"; exit 1; fi
	$(GTKWAVE) $(VCD_FILE)

# Run all tests
test: pc gpr decoder cu alu mio cpu mcu

# Clean up
clean:
	rm -f *.out *.vcd
	@echo "Cleaned up compiled files and waveforms"

