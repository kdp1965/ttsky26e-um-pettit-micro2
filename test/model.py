# SPDX-License-Identifier: Apache-2.0
"""Model of tt_um_pettit_micro2.

sample(t, ui)   the 7-bit sample at sample time t (16 bits) for ui_in
Model(pre)      cycle-exact: step(ui) is one rising clock edge with rst_n high
                and returns the uo_out the chip shows after it

    python3 model.py out.wav [K] [seconds] [sustain]     the tune as a WAV file
"""


def sample(t, ui):
    k, manual, sustain = ui & 63, ui >> 6 & 1, ui >> 7 & 1
    m = k if manual else (k ^ 42) & (t >> 10) & 63
    if m == 0:
        return 64
    u = ((t & 127) * m & 127) - 64              # the sawtooth about its centre
    age = 0 if sustain else (t >> 8) & 3
    return (u >> age) + 64                      # arithmetic shift


class Model:
    def __init__(self, pre=12):
        self.pre = pre
        self.c = self.acc = self.carry = self.pwm = 0

    def step(self, ui):
        ramp, t = self.c & 31, (self.c >> self.pre) & 0xFFFF
        s = sample(t, ui)
        pwm = 1 if ramp < (s >> 2) + self.carry else 0
        if ramp == 31:
            a = self.acc + (s & 3)
            self.carry, self.acc = a >> 2, a & 3
        self.c = (self.c + 1) & ((1 << (self.pre + 16)) - 1)
        self.pwm = pwm
        # uo_out after the edge: the registered PWM, and the sample of the new time
        return pwm << 7 | sample((self.c >> self.pre) & 0xFFFF, ui)


if __name__ == "__main__":
    import struct
    import sys
    import wave
    out = sys.argv[1]
    k = int(sys.argv[2], 0) if len(sys.argv) > 2 else 0
    secs = float(sys.argv[3]) if len(sys.argv) > 3 else 16.8
    ui = k & 63 | (0x80 if len(sys.argv) > 4 else 0)
    rate = 32_000_000 / 4096
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(int(rate))
        w.writeframes(b"".join(struct.pack("<h", (sample(t & 0xFFFF, ui) - 64) * 256) for t in range(int(secs * rate))))
    print("%s: K = %d, %.1f s at %d Hz" % (out, k, secs, rate))
