#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build
RTL=(rtl/ALU.sv rtl/alu_control.sv rtl/control_unit.sv rtl/cpu_top.sv rtl/data_memory.sv rtl/ex_mem.sv rtl/forwarding_unit.sv rtl/hazard_detection_unit.sv rtl/id_ex.sv rtl/if_id.sv rtl/immediate_generator.sv rtl/instruction_memory.sv rtl/mem_wb.sv rtl/register_file.sv)
echo "[program] Compiling CPU runner; loading root instructions.hex"
iverilog -g2012 -s user_program_tb -o build/user_program.vvp "${RTL[@]}" tb/user_program_tb.sv
vvp build/user_program.vvp "$@"
