#!/usr/bin/env python3
"""Create a temporary STA ROM from the existing integration-test program."""

import re
import sys
from pathlib import Path


testbench, output, depth_text = sys.argv[1:4]
depth = int(depth_text)
source = Path(testbench).read_text()
instructions = {
    int(index): int(word, 16)
    for index, word in re.findall(
        r"dut\.u_instruction_memory\.mem\[(\d+)\]\s*=\s*32'h([0-9a-fA-F]{8})",
        source,
    )
}
if len(instructions) != 20:
    raise SystemExit(f"expected 20 existing regression instructions, found {len(instructions)}")
if max(instructions) >= depth:
    raise SystemExit("STA instruction-memory depth is too small for the regression image")

rom = [0x00000013] * depth
for address, instruction in instructions.items():
    rom[address] = instruction
Path(output).write_text("".join(f"{word:08x}\n" for word in rom))
print(f"Generated temporary {depth}-word ROM from {len(instructions)} existing regression instructions")
