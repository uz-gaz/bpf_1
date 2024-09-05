# eBPF Core

 - [**misc**](./misc): Contains some useful files like [Xilinx IP configurations](./misc/xilinx_ips/), [C files used in proof of concept](./misc/app/), a [testbench for simulating in Vivado](./misc/top_mb.vhd) and [gtkwave layouts](./misc/gtkwave_layouts/) to make debugging more comfortable.
  - [**programs**](./programs): Contains test programs. 
 - [**scripts**](./scripts): Contains scripts for compilation and simulation of `.vhd` files. 
 - [**src**](./src): Contains source code of the eBPF core inside an AXI Lite peripheral.
 - [**test**](./test): Contains testbenchs for unit and integration tests (only [peripheral tests](./test/peripheral_test/) do work with current source files).
 - [**Work in Windows**](./doc/work-in-windows-ghdl.md) 


##### Example of simulation
```bash
./scripts/launch-peripheral-testbench.sh --imem test_alu --tb program_test
gtkwave waves/test.ghw -a ./misc/gtkwave_layouts/peripheral_layout.gtkw
```
