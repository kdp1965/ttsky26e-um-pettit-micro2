## How it works

Micro Music Box is a bytebeat synthesizer that fits a Tiny Tapeout **micro tile**: 70.38 x 51.68 um
of sky130, a quarter of a 1x1 tile, with only `clk`, `rst_n`, `ui_in` and `uo_out`. It uses 32
flip-flops and about 250 gates.

One free-running 28-bit counter is the whole machine. With a 32 MHz clock:

- its low 5 bits are the PWM ramp: 1 MHz PWM;
- the 16 bits above the 12-bit prescaler are the sample time `t`: 7812.5 samples a second.

The sample is

    tone = t * m                  7 bits: a sawtooth of m * 61 Hz
    m    = (K XOR 42) AND (t >> 10)

`t >> 10` changes every 131 ms, so `m` is a tune: with K = 0 it is the well-known "42 melody",
`t * (42 & t >> 10)`, 64 notes that repeat every 8.4 seconds. The six bits of K choose which
bits of the time make the tune, so the host has 64 tunes to pick from, and can change K while
it plays. In manual mode `m = K`: the host plays the notes itself, harmonics 1 to 63 of 61 Hz
(8, 9, 10, 12, 15, 16 make a major scale without its fourth and sixth).

A pluck envelope halves the tone's amplitude about its centre every quarter of a note, which
is what makes it sound like a music box rather than an organ; a rest (`m = 0`) is the centre
value. The 7-bit sample drives a 5-bit PWM whose last two bits come from a first-order
sigma-delta: one extra clock of high time in some periods, 7 bits of resolution over 4 periods.

## How to test

Connect the Tiny Tapeout audio Pmod so that its input is `uo[7]`, set the clock to 32 MHz and
reset. With all inputs low the 42 melody plays.

| Input | Function |
|-------|----------|
| `ui[5:0]` | K: the tune (0 is the 42 melody; 42 is silence), or the note in manual mode |
| `ui[6]`   | MANUAL: the note is K, a sawtooth of K * 61 Hz; K = 0 is a rest |
| `ui[7]`   | SUSTAIN: no pluck envelope |

Things for the host (the RP2350 on the demo board) to do with the inputs:

- step K every few seconds for a medley, or flip one bit of K on the beat for a variation;
- MANUAL with its own note sequence: any melody on the harmonic scale, with the envelope
  retriggering every 131 ms (a mandolin) or SUSTAIN for held notes;
- toggle SUSTAIN for an accent.

`uo[6:0]` is the 7-bit sample itself, for a resistor DAC, a logic analyser, or for the host to
read back. Other clock frequencies work and scale everything: at 16 MHz the PWM is 500 kHz and
the tune an octave lower and half as fast.

`test/model.py` writes any tune as a WAV file (`python3 model.py out.wav 0`), so it can be heard
without the chip.

## External hardware

[Tiny Tapeout audio Pmod](https://github.com/MichaelBell/tt-audio-pmod) (or any low-pass filter
and amplifier) on `uo[7]`.
