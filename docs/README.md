# CPU architecture and reproducible workflows

## Repository inventory

- Top module: `cpu_top` in `rtl/cpu_top.sv`.
- RTL source list, compiled by both scripts: `ALU.sv`, `alu_control.sv`, `control_unit.sv`, `cpu_top.sv`, `data_memory.sv`, `ex_mem.sv`, `forwarding_unit.sv`, `hazard_detection_unit.sv`, `id_ex.sv`, `if_id.sv`, `immediate_generator.sv`, `instruction_memory.sv`, `mem_wb.sv`, and `register_file.sv`.
- Integration test: `tb/cpu_top_tb.sv`.
- Instruction image: root `instructions.hex`, loaded by `$readmemh` from `rtl/instruction_memory.sv`. Unspecified words default to `addi x0,x0,0` (NOP).
- Data RAM: `rtl/data_memory.sv`, 1024 words (4096 bytes) by default, initialized to zero in RTL. No separate RAM initialization file is used.
- No Makefile, project configuration, synthesis constraints, or prior simulation/synthesis scripts existed. The original testbench had no image or expected-value data, so it did not provide a runnable integration check.

## Pipeline and datapath

`cpu_top` implements IF, ID, EX, MEM, and WB stages with IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers. Instruction fetch, register-file reads, and data RAM reads are combinational. Stores update RAM bytes on the rising edge. The core is in-order and has no cache, privilege modes, exceptions, interrupts, or external bus.

- EX/MEM forwarding has priority over MEM/WB forwarding for both ALU operands, branch operands, and store data. The register file also bypasses a simultaneous WB write to its combinational read ports.
- The hazard unit stalls PC and IF/ID and injects a bubble into ID/EX for one cycle when an EX-stage load destination matches either decoded source field. It compares both fields for every opcode, so an I-type immediate that coincides with a load destination can cause an unnecessary stall.
- Branches and jumps redirect in EX and flush IF/ID and ID/EX. JAL and JALR write PC+4. JALR currently computes `rs1 + imm` without clearing target bit 0.
- x0 reads as zero and writes to x0 are suppressed.
- Data addresses are byte addresses. RAM is little-endian and implements signed LB/LH, LW, unsigned LBU/LHU, and SB/SH/SW. Unaligned accesses are not trapped. Out-of-range reads return zero and out-of-range store bytes are ignored.
- Top-level debug outputs expose fetch PC/instruction, load stall, forwarding selects, WB write activity, and data-memory store activity. These make internal CPU activity observable and preserve meaningful logic in generic synthesis.

## Instruction support and caveats

The control/decode recognizes these opcode families:

- R-type: ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA.
- I-type ALU: ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI.
- Loads: LB, LH, LW, LBU, LHU. Stores: SB, SH, SW.
- Branches: BEQ and BNE are supported. BLT, BGE, BLTU, and BGEU are not implemented and currently behave incorrectly; do not use them.
- Jumps: JAL and JALR. Upper-immediate operations: LUI and AUIPC.

The ALU decoder does not validate all reserved `funct7` encodings, so unsupported encodings can alias a supported ALU operation. There is no illegal-instruction trap. This is partial RV32I coverage, not a complete compliant ISA implementation. Compressed instructions and M-extension operations are unsupported.

## Simulation and waveform

Run from any directory with:

```sh
./scripts/sim.sh
```

The script compiles every RTL source with Icarus Verilog (`iverilog -g2012`) and runs the result with `vvp`. It returns nonzero on compile errors, failed checks, or timeout. The regression checks arithmetic, AND, dependent ALU results, EX/MEM and MEM/WB forwarding, a load-use stall, SW/LW, BEQ, JAL, JALR, x0, flushed-path suppression, registers, and RAM contents. This focused test is not an exhaustive ISA compliance suite.

The verified run passed 19 checks in 32 cycles with Icarus Verilog 12.0. Icarus emits non-fatal messages about `always_*` constant selects and ignored `unique case` qualities. The waveform is `build/cpu_top_tb.vcd`; it includes the testbench hierarchy and CPU pipeline, register-file, RAM, forwarding, hazard, memory, and writeback signals. Open it with:

```sh
gtkwave build/cpu_top_tb.vcd
```

GTKWave is optional; the VCD can be copied to a machine with a GUI.

## Synthesis and timing

Run:

```sh
./scripts/synth.sh
```

Yosys reads every RTL source, checks `cpu_top`, synthesizes it, writes `build/cpu_top_synth.v`, and records logs and cell statistics in `build/synth.log`, `build/synth_stat.txt`, and the top-level-only `build/synth_top_stat.txt`. The script uses IMEM_DEPTH=64 and DMEM_DEPTH=64 so generic logic mapping remains tractable. RTL defaults are 1024 words for each memory, so these statistics use a reduced-memory configuration. The verified Yosys 0.33 run mapped to 27,689 generic logic cells, including 3,072 enabled D flip-flops and 14,873 muxes. These counts are specific to this flow and reduced memory configuration. Synthesis reads the current `instructions.hex`; the checked-in all-NOP image may let synthesis simplify instruction-dependent logic, so these counts do not represent an arbitrary replacement program image. No technology library is selected.

There is no standard-cell library, clock constraint, IO constraint, or physical design setup here. No defensible technology-specific critical-path delay or Fmax is available. Likely long paths include EX forwarding through ALU/branch resolution to the PC redirect mux and asynchronous data-memory read through WB selection. A meaningful Fmax requires selecting a library, adding timing constraints, mapping the design, and running static timing analysis. Generic cell counts are not physical area or timing measurements.

## Reproducible user-program workflow

The runtime image format is one eight-digit hexadecimal instruction per line in `instructions.hex`, starting at byte address zero. Each unspecified word defaults to NOP. The regression image is embedded in `tb/cpu_top_tb.sv`; simulation does not overwrite the runtime image.

For your later manual demonstration, choose an algorithm, write its assembly yourself, translate it manually to machine words, and place those words in `instructions.hex`. Do not use the regression as the demonstration. Run `./scripts/run_program.sh`; it loads the root image without replacing it, waits for repeated `jal x0,0` as the halt convention, prints all registers and nonzero RAM words, and writes `build/user_program.vcd`. You can pass `+MAX_CYCLES=20000` to adjust its timeout. Open the VCD with GTKWave and run `./scripts/synth.sh` for the generic synthesis result. This repository intentionally includes no final demonstration assembly or machine code.

The program runner was smoke-checked with a temporary one-instruction self-loop image; it correctly detected termination, printed the all-zero register/RAM state, and generated its VCD. The repository image was restored to its all-NOP template afterward. This checks the runner plumbing only, not a meaningful user program.

## Verified status and known issues

- Simulation passed as described above.
- Generic Yosys synthesis has been run; see the generated statistics and log. It does not establish timing, physical area, or silicon behavior.
- RTL correction: instruction memory previously left unspecified words uninitialized when the hex file was shorter than memory. It now fills all words with NOP before loading the image. Simulation passed after this correction.
- The top module now has explicit debug/activity outputs for PC, fetch instruction, stall/forwarding, WB, and store activity. The previous top interface exposed no outputs, so synthesis legally pruned all logic; these outputs provide useful observability and keep operating logic in the synthesized design.
- Remaining functional limits: only BEQ/BNE branch conditions; JALR does not clear bit 0; no alignment exceptions or illegal-instruction handling; unsupported function encodings may alias; load-use detection may insert avoidable stalls; partial RV32I coverage only.
