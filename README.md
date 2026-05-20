## Running the tests

On debian install the followin commands:

```sh
sudo apt update
sudo apt install iverilog gtkwave
```

```sh
iverilog -g2012 -o pc.out pc.v pc.sv
vvp pc.out
```

```sh
iverilog -g2012 -o gpr.out gpr.v gpr.sv
vvp gpr.out
```

```sh
iverilog -g2012 -o decoder.out decoder.v decoder.sv
vvp decoder.out
gtkwave decoder.vcd
```

```sh
iverilog -g2012 -o cu.out cu.v decoder.v cu.sv
vvp cu.out
gtkwave cu.vcd
```

```sh
iverilog -g2012 -o alu.out alu.v alu.sv
vvp alu.out
gtkwave alu.vcd
```

```sh
iverilog -g2012 -o memory_mapped_output.out memory_mapped_output.v memory_mapped_output.sv
vvp memory_mapped_output.out
gtkwave memory_mapped_output.vcd
```

```sh
iverilog -g2012 -o memory_mapped_input.out memory_mapped_input.v memory_mapped_input.sv
vvp memory_mapped_input.out
gtkwave memory_mapped_input.vcd
```

```sh
iverilog -g2012 -o cpu.out cpu.v pc.v gpr.v decoder.v cu.v alu.v cpu.sv
vvp cpu.out
gtkwave cpu.vcd
```

```sh
iverilog -g2012 -o mcu.out cpu.v pc.v gpr.v decoder.v cu.v alu.v mcu.v memory_mapped_output.v memory_mapped_input.v mcu.sv
vvp mcu.out
gtkwave mcu.vcd
```

```sh
iverilog -g2012 -o mcu_execution.out cpu.v pc.v gpr.v decoder.v cu.v alu.v mcu.v memory_mapped_output.v memory_mapped_input.v mcu_execution.sv
vvp mcu_execution.out
gtkwave mcu_execution.vcd
```