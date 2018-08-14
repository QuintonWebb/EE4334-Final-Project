create_clock -name "CLOCK_50" -period 20.00ns [get_ports {clk}]
derive_pll_clocks
derive_clock_uncertainty
