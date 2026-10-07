# SystemVerilog RV32I Pipeline CPU

This repository contains a small five-stage, in-order RISC-V CPU implemented in SystemVerilog. The RTL is under [`rtl/`](rtl/); reproducible simulation and synthesis entry points are under [`scripts/`](scripts/). See [`docs/README.md`](docs/README.md) for architecture, instruction coverage, limits, and verification details.

## Quick start

On Ubuntu/Codespaces, install the tools with `sudo apt-get update && sudo apt-get install -y iverilog yosys gtkwave`, then run:

```sh
./scripts/sim.sh
./scripts/synth.sh
```

Simulation prints a PASS/FAIL result and writes `build/cpu_top_tb.vcd`. Synthesis writes a generic netlist and statistics under `build/`. Neither flow invokes a RISC-V assembler; the regression machine words are directly encoded in the testbench.

The root `instructions.hex` is the runtime instruction-memory image. Replace its contents with your own manually prepared words when ready. Use one 32-bit hexadecimal instruction per line, with the lowest-address instruction first. See the documentation for loading programs, examining state, and the manual demonstration handoff.

Run your own manually encoded image with `./scripts/run_program.sh`. This runner loads the root image, waits for repeated `jal x0,0` as the program's halt convention, prints all registers and nonzero RAM words, and writes `build/user_program.vcd`.
