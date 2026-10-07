# SKY130 static timing flow

Run `./scripts/sta.sh` from the repository root. The flow is separate from `scripts/synth.sh`; its generated RTL copies, mapped netlist, JSON netlist, and reports live under ignored `build/sta/`.

## Technology and timing library

- Technology/library: SkyWater SKY130 FD SC High Density (`sky130_fd_sc_hd`).
- Liberty: `sky130_fd_sc_hd__tt_025C_1v80.lib`, fetched from the `sky130hd` platform in [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts/tree/9b26ff8ff651fc0b696f7ef20a356865ca6068bb/flow/platforms/sky130hd) at commit `9b26ff8ff651fc0b696f7ef20a356865ca6068bb`.
- Corner: typical process, 25 °C, 1.80 V. The file declares 1 ns time units, 25 °C nominal temperature, 1.8 V nominal voltage, table-lookup delay modeling, and cell timing tables. SHA-256 is `ec0e1067a35c8bf20b11e58d1e8ac53326067e4dac84a125cc1b917a3518d0d9` (12,800,135 bytes).
- Mapping uses a generated Liberty copy without the `lpflow_*` and `probe*` cells listed as `DONT_USE_CELLS` by that pinned platform. OpenSTA loads the unmodified, checksum-verified library. A validator checks every mapped cell against the full library and requires timing groups; the last run checked 84 unique cell types.
- Yosys maps from Liberty sequential/function data with `dfflibmap` and ABC. Separate cell Verilog models are not needed for technology mapping or OpenSTA linking; this flow does not perform gate-level simulation.

OpenSTA 3.1.0 was built from upstream Parallax OpenSTA revision `b7d866ff69e618c025510423ffb65a202796b4f9`, installed under ignored `build/opensta-install/`. CUDD 3.0.0 and build dependencies are also installed in ignored/local build paths or through the Codespace package manager. This is pre-layout cell timing: there is no placement, routing, extracted interconnect, clock tree, or on-chip variation analysis.

## Clock and assumptions

The RTL top is `cpu_top`, with `clk` and synchronous `reset` ports. The SDC uses a 10 ns reference clock, 100 ps clock/input transition, 500 ps reset input delay, 1 ns output delay, and 10 fF debug-output loads. These interface assumptions are not board-level specifications. The clock period is an STA reference, not a claimed Fmax. ABC's 1 ns delay target is an optimization setting, not a timing result.

By default, the flow maps the CPU with `IMEM_DEPTH=64` and `DMEM_DEPTH=64`. It creates an ignored temporary ROM image from the 20 instruction words already in `tb/cpu_top_tb.sv`, with NOPs in the remaining words. Since Yosys did not reliably consume the simulation `$readmemh` in this build, `embed_sta_rom_init.py` inserts the same image as explicit initialization assignments into an ignored copy of `instruction_memory.sv`. The repository ROM and demo files are not modified. The data memory remains the RTL byte array, not a replacement timing model or SRAM macro. Thus results apply only to this 64-word ROM / 256-byte RAM configuration and that fixed regression image; the full default memory depths were attempted but did not finish in this Codespace run.

## Verified run

The last `./scripts/sta.sh` run technology-mapped the design, validated 84 unique mapped SKY130 cell types against timing groups in the selected Liberty, loaded the mapped Verilog and constraints in OpenSTA, recognized `core_clk`, and reported a register-to-register maximum setup path. The electrical check report contained no max-slew, max-capacitance, or max-fanout violations.

- Startpoint: mapped register instance `_57094_/Q` (`sky130_fd_sc_hd__dfxtp_1`), which is `u_mem_wb.rd_out[2]` in the mapped Verilog.
- Endpoint: mapped register instance `_56181_/D` (`sky130_fd_sc_hd__dfxtp_1`). The Yosys Verilog output does not preserve an RTL signal name for this endpoint; the named instance and pin are present in the netlist and reported by OpenSTA.
- OpenSTA data arrival (including launch clock-to-Q and combinational cell delays): 11.4561 ns.
- Endpoint setup requirement: 0.1068 ns.
- Setup slack at the 10.0000 ns reference period: -1.5629 ns.
- Setup-derived minimum period for this reported path: 11.5629 ns (data arrival plus setup requirement, with ideal clock network and zero skew).
- Setup-based Fmax for this mapped configuration and corner: 86.483 MHz (`1000 / 11.5629 ns`). This is a cell-only, pre-layout result for this specific parameterization and fixed ROM image; it is not a universal or post-layout CPU frequency.

The complete path appears in `build/sta/opensta.log`. Timing is reported by OpenSTA, not inferred from Yosys statistics. The result assumes ideal clocks and has no extracted wire parasitics, so physical implementation can change the delay.

## Reproduction and generated reports

```sh
./scripts/sta.sh
```

Useful artifacts include `build/sta/cpu_top_sky130.v`, `build/sta/cpu_top_sky130.json`, `build/sta/sky130_stat.txt`, `build/sta/yosys_sky130.log`, `build/sta/run_sta.tcl`, `build/sta/opensta.log`, and `build/sta/electrical_violations.log`. To try the RTL default memory depths, set `STA_IMEM_DEPTH=1024 STA_DMEM_DEPTH=1024`; that larger mapping did not complete during this run.
