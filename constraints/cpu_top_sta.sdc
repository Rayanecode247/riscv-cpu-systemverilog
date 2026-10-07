# Nominal 10 ns analysis clock. This is a timing-analysis reference, not Fmax.
create_clock -name core_clk -period 10.000 [get_ports clk]
set_clock_transition 0.100 [get_clocks core_clk]

# reset is the only non-clock input. It is used synchronously by the RTL.
set_input_delay -clock core_clk -max 0.500 [get_ports reset]
set_input_transition 0.100 [get_ports reset]

# Debug outputs are treated as clocked interface outputs with a 1 ns external
# budget and a 10 fF load. These assumptions are not physical board constraints.
set_output_delay -clock core_clk -max 1.000 [all_outputs]
set_load 0.010 [all_outputs]
