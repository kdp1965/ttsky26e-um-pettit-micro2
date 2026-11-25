/*
 * Copyright (c) 2026 Ken Pettit
 * SPDX-License-Identifier: Apache-2.0
 *
 * tt_um_pettit_micro2 - a bytebeat music box for the Tiny Tapeout micro tile
 * (70.38 x 51.68 um of sky130; clk, rst_n, ui_in and uo_out only).
 *
 * One free-running counter is everything: its low 5 bits are the PWM ramp
 * (32 MHz / 32 = 1 MHz PWM), the bits above the prescaler are the sample
 * time t (32 MHz / 4096 = 7812.5 samples a second), and the sample is
 *
 *     tone = t * m                  (7 bits: a sawtooth of m * 61 Hz)
 *     m    = (K ^ 42) & (t >> 10)   the tune: a new note every 131 ms
 *
 * which with K = 0 is the "42 melody" (t * (42 & t >> 10)).  The six bits of
 * K choose which bits of the time make the tune, so the host has 64 tunes;
 * in manual mode m = K and the host plays the notes itself (harmonics 1 to
 * 63 of 61 Hz).  A pluck envelope halves the amplitude about its centre
 * every quarter of a note (the music box), and a 2-bit first-order
 * sigma-delta dithers the 5-bit PWM to the 7 bits of the sample.
 */

`default_nettype none

module tt_um_pettit_micro2 #(
    parameter PRE = 12          // prescaler bits: a sample is 2**PRE clocks (simulation may use 5)
) (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [5:0] k       = ui_in[5:0];  // tune number / note
  wire       manual  = ui_in[6];    // m = K: the host plays
  wire       sustain = ui_in[7];    // no pluck envelope

  // ----------------------------------------------------------------- time
  reg [PRE+15:0] c;
  always @(posedge clk) c <= rst_n ? c + 1'b1 : {(PRE + 16) {1'b0}};

  wire [4:0]  ramp = c[4:0];
  wire [15:0] t    = c[PRE+15:PRE];

  // ----------------------------------------------------------------- tone
  wire [5:0] m    = manual ? k : ((k ^ 6'd42) & t[15:10]);
  wire [6:0] tone = t[6:0] * m;

  // pluck: the tone about its centre, shifted down as the note ages; a rest
  // (m = 0) is the centre itself, so that the envelope does not thump
  wire [1:0]        age = sustain ? 2'd0 : t[9:8];
  wire signed [6:0] u   = (m == 6'd0) ? 7'sd0 : {~tone[6], tone[5:0]};
  wire signed [6:0] v   = u >>> age;
  wire [6:0]        s   = {~v[6], v[5:0]};

  // ------------------------------------------------------------------ PWM
  // high for s[6:2] of the 32 clocks, and one more when the sigma-delta of
  // s[1:0] carried: 7 bits of resolution over 4 periods.  One subtraction:
  // ramp - duty - carry is negative while the output is high
  reg [1:0] acc;
  reg       carry;
  reg       pwm;
  wire [5:0] diff = {1'b0, ramp} - {1'b0, s[6:2]} - {5'd0, carry};
  always @(posedge clk) begin
    if (!rst_n)     {carry, acc} <= 3'd0;
    else if (&ramp) {carry, acc} <= {1'b0, acc} + {1'b0, s[1:0]};
    pwm <= diff[5];
  end

  // uo[7]: the audio Pmod's PWM pin; uo[6:0]: the sample for a resistor DAC or the host
  assign uo_out = {pwm, s};

endmodule
