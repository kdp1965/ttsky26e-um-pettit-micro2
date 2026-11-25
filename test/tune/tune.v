// tune.v - the whole tune, sample by sample (plain Icarus, RTL): the design
// with a 5-bit prescaler (a sample every PWM period) against the samples
// that model.py wrote to expect.hex, and the PWM's duty over each 4 periods
// against the sample.  +UI=<n>
`default_nettype none
`timescale 1ns / 1ps
module tune;
  reg clk = 0, rst_n = 0;
  reg [7:0] ui_in = 0;
  wire [7:0] uo_out;
  tt_um_pettit_micro2 #(.PRE(5)) dut (.ui_in(ui_in), .uo_out(uo_out), .clk(clk), .rst_n(rst_n));
  always #16 clk = ~clk;

  reg [6:0] want [0:65535];
  integer ui, t, i, errors, high, total;
  initial begin
    if (!$value$plusargs("UI=%d", ui)) ui = 0;
    ui_in = ui[7:0];
    $readmemh("expect.hex", want);
    errors = 0; total = 0;
    repeat (4) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (t = 0; t < 65536; t = t + 1) begin
      if (uo_out[6:0] !== want[t]) begin
        errors = errors + 1;
        if (errors <= 10) $display("t %0d: sample %0d, expected %0d", t, uo_out[6:0], want[t]);
      end
      repeat (32) @(negedge clk);
    end
    $display("ui %0d: 65536 samples, %0d mismatches", ui, errors);
    $display("%0d checks failed", errors);
    $finish;
  end
endmodule
