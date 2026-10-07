#!/usr/bin/env python3
"""Check mapped cell coverage and timing arcs against the selected Liberty."""

import re
import sys
from pathlib import Path


netlist = Path(sys.argv[1]).read_text()
liberty = Path(sys.argv[2]).read_text()
instance_re = re.compile(r"^\s*(sky130_fd_sc_hd__[A-Za-z0-9_]+)\s+[^\s(]+\s*\(", re.MULTILINE)
instances = set(instance_re.findall(netlist))
lib_cells = re.compile(r'^\s*cell\s*\(\s*"([^"]+)"\s*\)\s*\{', re.MULTILINE)
cell_ranges = {}

for match in lib_cells.finditer(liberty):
    depth = 0
    quoted = False
    escaped = False
    index = liberty.find("{", match.start(), match.end())
    end = None
    while index < len(liberty):
        char = liberty[index]
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
        index += 1
    if end is None:
        raise SystemExit(f"unterminated Liberty cell {match.group(1)}")
    cell_ranges[match.group(1)] = liberty[match.start():end]

missing = sorted(instances - cell_ranges.keys())
without_timing = sorted(name for name in instances & cell_ranges.keys() if "timing (" not in cell_ranges[name])
if not instances:
    raise SystemExit("no SKY130 cell instances found in mapped netlist")
if missing or without_timing:
    if missing:
        print("Cells absent from Liberty:", ", ".join(missing), file=sys.stderr)
    if without_timing:
        print("Cells without timing groups:", ", ".join(without_timing), file=sys.stderr)
    raise SystemExit("mapped cell coverage validation failed")

print(f"Validated {len(instances)} unique mapped SKY130 cells; all have Liberty timing groups")
