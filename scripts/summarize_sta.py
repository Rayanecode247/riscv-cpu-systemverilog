#!/usr/bin/env python3
"""Summarize the reported worst setup path without estimating missing data."""

import re
import sys
from pathlib import Path


report = Path(sys.argv[1]).read_text()
sdc = Path(sys.argv[2]).read_text()
electrical = Path(sys.argv[3]).read_text()
if "(VIOLATED)" in electrical:
    raise SystemExit(
        "[sta] NO DEFENSIBLE TIMING RESULT: mapped design violates SKY130 "
        "max-slew/max-capacitance/max-fanout checks; see electrical_violations.log"
    )
start = re.search(r"^Startpoint: (.+)$", report, re.MULTILINE)
end = re.search(r"^Endpoint: (.+)$", report, re.MULTILINE)
arrival = re.search(r"^\s*([0-9]+(?:\.[0-9]+)?)\s+data arrival time$", report, re.MULTILINE)
setup = re.search(r"^\s*(-?[0-9]+(?:\.[0-9]+)?)\s+-?[0-9]+(?:\.[0-9]+)?\s+library setup time$", report, re.MULTILINE)
slack = re.search(r"^\s*(-?[0-9]+(?:\.[0-9]+)?)\s+slack \((?:VIOLATED|MET)\)$", report, re.MULTILINE)
period = re.search(r"create_clock\s+-name\s+\S+\s+-period\s+([0-9]+(?:\.[0-9]+)?)", sdc)

if not all((start, end, arrival, setup, slack, period)):
    raise SystemExit("[sta] ERROR: could not extract complete setup-path data from OpenSTA")

arrival_ns = float(arrival.group(1))
setup_ns = abs(float(setup.group(1)))
slack_ns = float(slack.group(1))
clock_ns = float(period.group(1))
required_period_ns = clock_ns - slack_ns
if required_period_ns <= 0:
    raise SystemExit("[sta] ERROR: invalid setup-derived minimum period")
fmax_mhz = 1000.0 / required_period_ns

print(f"[sta] Startpoint: {start.group(1)}")
print(f"[sta] Endpoint: {end.group(1)}")
print(f"[sta] Data arrival: {arrival_ns:.4f} ns")
print(f"[sta] Setup requirement: {setup_ns:.4f} ns")
print(f"[sta] Setup slack at {clock_ns:.4f} ns reference period: {slack_ns:.4f} ns")
print(f"[sta] Setup-derived minimum period: {required_period_ns:.4f} ns")
print(f"[sta] Fmax for this mapped configuration/corner: {fmax_mhz:.3f} MHz")
