# RISC-V bubble-sort demonstration

This demo runs the actual 32-bit pipelined SystemVerilog CPU on 17 RISC-V machine instructions. The program sorts five words in data memory in place.

Initial values: `8, 3, 10, 1, 6`  
Expected final values: `1, 3, 6, 8, 10`

## Files

- [`sort_demo.s`](sort_demo.s): human-readable assembly (labels and comments are not instructions).
- [`instructions.hex`](instructions.hex): the exact 17-word instruction image loaded by the testbench.
- [`data.hex`](data.hex): byte-addressed, little-endian initial RAM image; each word is stored least-significant byte first.
- [`demo_tb.sv`](demo_tb.sv): dedicated testbench that loads the demo images, runs the CPU, checks the final words, and writes the VCD.
- [`run.sh`](run.sh): compiles the existing RTL with Icarus Verilog and runs the testbench.
- [`sort_demo.gtkw`](sort_demo.gtkw): GTKWave signal layout for the demo.

## Run

From the repository root:

```sh
./demo/run.sh
gtkwave build/demo_sort.vcd demo/sort_demo.gtkw
```

The simulation prints the final values by byte address and reports `RESULT: SORT DEMO PASS` when all five memory checks pass. It also confirms that execution reaches the program's `jal x0,0` halt loop. The waveform includes PC/instruction execution, memory write activity, forwarding and load-stall behavior, and register writeback. The RAM array itself is checked by the testbench and printed in the simulation log; Icarus does not include its unpacked memory array in this VCD.

The runner and testbench use demo-local instruction and data images. The regression, synthesis, STA, and CPU RTL flows are not part of this demo command.
