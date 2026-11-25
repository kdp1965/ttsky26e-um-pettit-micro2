# Testbench

A [cocotb](https://docs.cocotb.org/en/stable/) bench that compares every clock of `uo_out` (the PWM and the sample) with a cycle-exact model (`model.py`) for 2.3 million clocks, with `ui_in` changing on the way. `tune/` checks the whole tune sample by sample with a short prescaler, and `model.py` writes a tune as a WAV file.

## How to run

To run the RTL simulation:

```sh
make -B
```

To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```
