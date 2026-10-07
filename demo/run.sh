#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 -c 'import pathlib,re,sys
p=pathlib.Path(sys.argv[1]); words=[]
for n,line in enumerate(p.read_text().splitlines(),1):
    text=line.split("//",1)[0].strip()
    if not text: continue
    word=text[2:] if text.lower().startswith("0x") else text
    if not re.fullmatch(r"[0-9a-fA-F]{8}",word):
        raise SystemExit(f"{p}:{n}: expected one 32-bit hexadecimal instruction word")
    words.append(word.lower())
if len(words)!=17:
    raise SystemExit(f"{p}: expected exactly 17 manually supplied words, found {len(words)}")
print(f"Validated {len(words)} manually supplied instruction words")' demo/instructions.hex

mkdir -p build
RTL=(rtl/ALU.sv rtl/alu_control.sv rtl/control_unit.sv rtl/cpu_top.sv
     rtl/data_memory.sv rtl/ex_mem.sv rtl/forwarding_unit.sv
     rtl/hazard_detection_unit.sv rtl/id_ex.sv rtl/if_id.sv
     rtl/immediate_generator.sv rtl/instruction_memory.sv rtl/mem_wb.sv
     rtl/register_file.sv)

echo "[demo] Compiling dedicated sort demonstration testbench"
iverilog -g2012 -s demo_tb -o build/demo_tb.vvp "${RTL[@]}" demo/demo_tb.sv
echo "[demo] Running; waveform will be build/demo_sort.vcd"
vvp build/demo_tb.vvp
