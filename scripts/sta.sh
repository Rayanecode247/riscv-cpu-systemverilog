#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build/sta/lib

LIB="build/sta/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
MAP_LIB="build/sta/lib/sky130_fd_sc_hd__tt_025C_1v80_map.lib"
LIB_URL="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/9b26ff8ff651fc0b696f7ef20a356865ca6068bb/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
LIB_SHA256="ec0e1067a35c8bf20b11e58d1e8ac53326067e4dac84a125cc1b917a3518d0d9"
STA_BIN="${OPENSTA:-$ROOT/build/opensta-install/bin/sta}"
STA_IMEM_DEPTH="${STA_IMEM_DEPTH:-64}"
STA_DMEM_DEPTH="${STA_DMEM_DEPTH:-64}"

if [[ ! -f "$LIB" ]]; then
    echo "[sta] Fetching the pinned SKY130 HD TT Liberty from OpenROAD-flow-scripts"
    curl -fL "$LIB_URL" -o "$LIB"
fi
echo "$LIB_SHA256  $LIB" | sha256sum --check --status || {
    echo "[sta] ERROR: SKY130 Liberty SHA-256 mismatch" >&2
    exit 1
}
python3 scripts/filter_sky130_lib.py "$LIB" "$MAP_LIB"

if [[ ! -x "$STA_BIN" ]]; then
    if command -v sta >/dev/null 2>&1; then
        STA_BIN="$(command -v sta)"
    else
        echo "[sta] ERROR: OpenSTA not found. See docs/sta.md for the pinned source build." >&2
        exit 1
    fi
fi

RTL=(rtl/ALU.sv rtl/alu_control.sv rtl/control_unit.sv rtl/cpu_top.sv
     rtl/data_memory.sv rtl/ex_mem.sv rtl/forwarding_unit.sv
     rtl/hazard_detection_unit.sv rtl/id_ex.sv rtl/if_id.sv
     rtl/immediate_generator.sv rtl/instruction_memory.sv rtl/mem_wb.sv
     rtl/register_file.sv)
python3 scripts/make_sta_rom.py tb/cpu_top_tb.sv build/sta/instructions.hex "$STA_IMEM_DEPTH"
mkdir -p build/sta/rtl
cp rtl/*.sv build/sta/rtl/
cp build/sta/instructions.hex build/sta/rtl/instructions.hex
python3 scripts/embed_sta_rom_init.py build/sta/rtl/instruction_memory.sv build/sta/instructions.hex
RTL_ABS=()
for source in "${RTL[@]}"; do RTL_ABS+=("$ROOT/build/sta/$source"); done
LIB_ABS="$ROOT/$LIB"
MAP_LIB_ABS="$ROOT/$MAP_LIB"
ABC_CONSTR_ABS="$ROOT/constraints/cpu_top_abc.constr"

echo "[sta] Mapping cpu_top to SKY130 FD SC HD cells (IMEM_DEPTH=$STA_IMEM_DEPTH, DMEM_DEPTH=$STA_DMEM_DEPTH)"
(cd build/sta && yosys -Q -T -p "read_verilog -sv ${RTL_ABS[*]}; chparam -set IMEM_DEPTH $STA_IMEM_DEPTH -set DMEM_DEPTH $STA_DMEM_DEPTH cpu_top; hierarchy -check -top cpu_top; synth -top cpu_top -flatten -noabc; dfflibmap -liberty $MAP_LIB_ABS; abc -liberty $MAP_LIB_ABS -constr $ABC_CONSTR_ABS -D 1000; clean; tee -o $ROOT/build/sta/sky130_stat.txt stat -liberty $LIB_ABS; write_verilog -noattr -noexpr $ROOT/build/sta/cpu_top_sky130.v; write_json $ROOT/build/sta/cpu_top_sky130.json") > build/sta/yosys_sky130.log

if ! grep -Eq 'sky130_fd_sc_hd__[[:alnum:]_]+[[:space:]]+[[:alnum:]_]+[[:space:]]*\(' build/sta/cpu_top_sky130.v; then
    echo "[sta] ERROR: mapped netlist contains no SKY130 cell instances" >&2
    exit 1
fi
if grep -Eq '\$_(AND|DFF|MUX|OR|NOT|XOR|NAND|NOR)' build/sta/cpu_top_sky130.v; then
    echo "[sta] ERROR: generic Yosys cells remain in mapped netlist" >&2
    exit 1
fi
if grep -Eq 'sky130_fd_sc_hd__(lpflow_|probe)' build/sta/cpu_top_sky130.v; then
    echo "[sta] ERROR: mapped netlist contains an ORFS DONT_USE cell" >&2
    exit 1
fi
python3 scripts/validate_sky130_netlist.py build/sta/cpu_top_sky130.v "$LIB"
echo "[sta] SKY130 cells in mapped netlist: $(grep -oE 'sky130_fd_sc_hd__[[:alnum:]_]+' build/sta/cpu_top_sky130.v | sort -u | wc -l | tr -d ' ') unique types"

cat > build/sta/run_sta.tcl <<EOF
read_liberty $LIB
read_verilog build/sta/cpu_top_sky130.v
link_design cpu_top
read_sdc constraints/cpu_top_sta.sdc
check_setup -verbose
report_checks -path_delay max -from [all_registers] -to [all_registers] -group_path_count 1 -format full_clock_expanded -fields {slew cap fanout input_pin} -digits 4
report_worst_slack -max -digits 4
report_check_types -violators -max_slew -max_capacitance -max_fanout > build/sta/electrical_violations.log
exit
EOF

echo "[sta] Running OpenSTA with constraints/cpu_top_sta.sdc"
"$STA_BIN" -no_splash -exit build/sta/run_sta.tcl > build/sta/opensta.log 2>&1
if ! grep -q 'Startpoint:' build/sta/opensta.log; then
    cat build/sta/opensta.log >&2
    echo "[sta] ERROR: OpenSTA did not report a register-to-register setup path" >&2
    exit 1
fi
cat build/sta/opensta.log
cat build/sta/electrical_violations.log
python3 scripts/summarize_sta.py build/sta/opensta.log constraints/cpu_top_sta.sdc build/sta/electrical_violations.log
echo "[sta] Reports: build/sta/yosys_sky130.log, build/sta/opensta.log"
