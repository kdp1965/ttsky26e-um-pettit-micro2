# Harden log

Local LibreLane 3.0.2 runs (`harden/`, sky130A open_pdks 8afc834) of tt_um_pettit_micro2 on the
micro tile. The recipe is `src/config.json`, the same as ttsky26e-um-pettit-micro's (drive
strength 1 cells allowed in synthesis, hold margins 0.04 / 0.03, a one-cluster clock tree) with
the clock period at 31 ns.

## Sizing the design (2026-11-25, synthesis only)

| RTL | synth um2 |
|-----|-----------|
| 8-bit tone (8 x 6 multiplier), 4-step envelope, 3-bit sigma-delta with an equality comparator | 2335 |
| of which: multiplier about 650, counter increment 480, sigma-delta 240, envelope 210 | |
| 7-bit tone (7 x 6), 2-bit sigma-delta folded into the PWM comparator's subtraction | 2021 |

## Runs

| run | synth um2 | result |
|-----|-----------|--------|
| rc1 | 2021 | clean, 78.3% utilization, router 7 iterations |

rc1: standard cells 2347 um2, clock buffers 38, repair buffers 225, wire 5031 um; route DRC,
Magic DRC, LVS and antenna 0, no slew violations; setup +11.5 ns at max_ss against the 31 ns
period (the multiplier to the PWM flop: 64 MHz would not close); hold +0.053 ns at min_ff
(+0.23 at tt), on top of LibreLane's 0.25 ns clock uncertainty. Gate-level simulation of rc1's
netlist: 2,300,000 clocks, 0 mismatches. tt-support-tools precheck (main, micro rules): pass.

Not promoted: `gds/` is not in the repository; the GitHub gds action builds its own.
