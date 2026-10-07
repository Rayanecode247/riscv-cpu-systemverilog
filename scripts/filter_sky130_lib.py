#!/usr/bin/env python3
"""Write a SKY130 mapping Liberty without cells forbidden by the ORFS platform."""

import re
import sys
from pathlib import Path


source, destination = map(Path, sys.argv[1:3])
text = source.read_text()
cell_start = re.compile(r'(?m)^\s*cell\s*\(\s*"([^"]+)"\s*\)\s*\{')
excluded = ("sky130_fd_sc_hd__lpflow_", "sky130_fd_sc_hd__probe", "sky130_fd_sc_hd__probec")
output = []
last = 0
removed = []

for match in cell_start.finditer(text):
    if match.start() < last:
        continue
    brace = text.find("{", match.start(), match.end())
    depth = 0
    quoted = False
    escaped = False
    line_comment = False
    block_comment = False
    end = None
    index = brace

    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
        elif block_comment:
            if char == "*" and next_char == "/":
                block_comment = False
                index += 1
        elif quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
        elif char == "/" and next_char == "/":
            line_comment = True
            index += 1
        elif char == "/" and next_char == "*":
            block_comment = True
            index += 1
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
        raise RuntimeError(f"unterminated Liberty cell {match.group(1)}")
    name = match.group(1)
    if name.startswith(excluded):
        output.append(text[last:match.start()])
        removed.append(name)
        last = end

output.append(text[last:])
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text("".join(output))
print(f"Removed {len(removed)} ORFS DONT_USE cells from ABC/DFF mapping Liberty")
