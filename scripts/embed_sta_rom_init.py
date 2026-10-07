#!/usr/bin/env python3
"""Embed the existing regression ROM into an ignored STA-only RTL copy."""

import re
import sys
from pathlib import Path


rtl_path, image_path = map(Path, sys.argv[1:3])
rtl = rtl_path.read_text()
image = [int(line, 16) for line in image_path.read_text().splitlines() if line.strip()]
assignments = [
    f"mem[{index}] = 32'h{word:08x};"
    for index, word in enumerate(image)
    if word != 0x00000013
]
if not assignments:
    raise SystemExit("STA ROM image has no non-NOP words")
rtl, replacements = re.subn(
    r'\$readmemh\("instructions\.hex",\s*mem\);',
    "\n        ".join(assignments),
    rtl,
    count=1,
)
if replacements != 1:
    raise SystemExit("could not locate instruction_memory $readmemh call")
rtl_path.write_text(rtl)
print(f"Embedded {len(assignments)} non-NOP words into the ignored STA RTL copy")
