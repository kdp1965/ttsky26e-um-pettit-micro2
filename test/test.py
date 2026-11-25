# SPDX-FileCopyrightText: © 2026 Ken Pettit
# SPDX-License-Identifier: Apache-2.0
"""Every clock of the first CLOCKS clocks (default 2.3 million: 560 samples,
past the pluck envelope's first three steps) against the cycle-exact model
(model.py), with ui_in changing every 5 samples: manual notes, sustain, and
the tune's own first notes (rests).  The whole tune is checked sample by
sample in test/tune, with a short prescaler."""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

from model import Model

UI_SEQ = [0x00, 0x41, 0x42, 0x45, 0x6A, 0x7F, 0xC3, 0xD5, 0xFF, 0x80, 0x2A, 0x40, 0x55]


@cocotb.test()
async def test_audio(dut):
    clocks = int(os.environ.get("CLOCKS", "2300000"))
    cocotb.start_soon(Clock(dut.clk, 32, unit="ns").start())   # 31.25 MHz

    dut.ui_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    model = Model()
    errors = high = 0
    seen = set()
    for n in range(clocks):
        if n % (5 * 4096) == 100:           # away from the sample boundary
            ui = UI_SEQ[(n // (5 * 4096)) % len(UI_SEQ)]
            dut.ui_in.value = ui
        elif n == 0:
            ui = 0
        await FallingEdge(dut.clk)          # ui_in is seen by the next rising edge
        expect = model.step(ui)
        got = dut.uo_out.value
        if not got.is_resolvable or int(got) != expect:
            errors += 1
            if errors <= 10:
                dut._log.error(f"clock {n} (sample {n >> 12}, ui {ui:#04x}): uo_out {got} expected {expect:08b}")
            continue
        high += int(got) >> 7
        seen.add(int(got) & 127)

    dut._log.info(f"{clocks} clocks, {errors} mismatches, PWM high {100 * high / clocks:.1f}%, {len(seen)} sample values")
    assert errors == 0
    assert len(seen) > 60
    assert 0.3 < high / clocks < 0.7
