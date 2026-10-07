#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build
RTL="rtl/ALU.sv rtl/alu_control.sv rtl/control_unit.sv rtl/cpu_top.sv rtl/data_memory.sv rtl/ex_mem.sv rtl/forwarding_unit.sv rtl/hazard_detection_unit.sv rtl/id_ex.sv rtl/if_id.sv rtl/immediate_generator.sv rtl/instruction_memory.sv rtl/mem_wb.sv rtl/register_file.sv"
echo "[synth] Running generic Yosys synthesis for cpu_top"
yosys -Q -T -p "read_verilog -sv $RTL; chparam -set IMEM_DEPTH 64 -set DMEM_DEPTH 64 cpu_top; hierarchy -check -top cpu_top; synth -top cpu_top; tee -o build/synth_stat.txt stat; tee -o build/synth_top_stat.txt stat -top cpu_top; write_verilog -noattr build/cpu_top_synth.v" > build/synth.log
tail -n 45 build/synth.log
echo "[synth] PASS; statistics: build/synth_stat.txt; netlist: build/cpu_top_synth.v"
