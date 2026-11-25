![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# Micro Music Box: bytebeat in a Tiny Tapeout micro tile

`t * (42 & t >> 10)` and 63 relatives of it, with a pluck envelope and 1 MHz dithered PWM, from
32 flip-flops in the experimental sky130 **micro tile** (70.38 x 51.68 um; `tiles: "micro"`).
The host picks the tune or plays the notes itself through `ui_in`.

- [The datasheet](docs/info.md): how it works, the inputs, what the host can do
- [src/tt_um_pettit_micro2.v](src/tt_um_pettit_micro2.v): the design, one file
- [HARDEN.md](HARDEN.md): the local LibreLane runs

## Hear it

```sh
cd test
python3 model.py tune.wav 0          # the 42 melody, 16.8 s; the second argument is K
python3 model.py tune.wav 21 8.4 s   # K = 21, 8.4 s, a fourth argument = sustain
```

## Simulation

```sh
cd test
make                       # RTL: 2.3 million clocks against the cycle-exact model (test/model.py)
make GATES=yes             # the same on gate_level_netlist.v (needs PDK_ROOT)
cd tune && make            # the whole 65536-sample tune for ten ui_in values, short prescaler
```

## Hardening locally

```sh
cd harden
make harden TAG=rc2        # runs/rc2/final/{gds,lef,pnl,...}; python3 metrics.py runs/rc2
make synth TAG=s1          # synthesis only (seconds): the area
```

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that makes it easier and cheaper than ever to get your
digital and analog designs manufactured on a real chip. See https://tinytapeout.com.
