`timescale 1ns/1ps

module PWM_tb;

  // === Testbench signals ===
  reg clk;                   // Clock signal
  reg reset;                 // Reset signal
  reg load;                  // Load signal
  reg shift_enable;          // Enable signal to shift bits into DUT
  reg S_in;                  // Serial data input
  reg [7:0] counter;         // PWM counter
  wire pwm_signal;           // Output PWM signal from DUT

  reg [7:0] byte_to_shift;   // Byte to shift into DUT
  integer i;                 // Loop index

  // === Instantiate Device Under Test (DUT) ===
  PWM dut (
    .clk(clk), 
    .reset(reset), 
    .load(load), 
    .shift_enable(shift_enable),  // Connect shift_enable
    .S_in(S_in), 
    .counter(counter), 
    .pwm_signal(pwm_signal)
  );

  // === Generate 100 MHz clock (10 ns period) ===
  always #5 clk = ~clk;

  // === Increment PWM counter ===
  // Counter counts from 0 to 255 to compare against duty_cycle
  always @(posedge clk or posedge reset) begin
    if (reset)
      counter <= 8'd0;                 // Reset counter
    else
      counter <= counter + 1;         // Increment counter
  end

  // === Task: Shift in one byte serially (MSB first) ===
  // Since RTL shifts left and inserts into LSB, feed MSB first
  task shift_in_byte;
  begin
    shift_enable = 1;                 // Enable shifting
    for (i = 7; i >= 0; i = i - 1) begin
      S_in = byte_to_shift[i];       // Send one bit (MSB first)
      @(posedge clk);                // Wait one clock cycle
    end
    shift_enable = 0;                // Disable shifting
    S_in = 0;                        // Clear S_in
  end
  endtask

  // === Initial block ===
  initial begin
    $dumpfile("PWM_tb.vcd");         // VCD waveform dump file
    $dumpvars(0, PWM_tb);            // Dump all variables

    // Initialize signals
    clk = 0;
    reset = 1;
    load = 0;
    shift_enable = 0;
    S_in = 0;
    counter = 0;

    // Hold reset for some cycles
    repeat (15) @(posedge clk);
    reset = 0;

    // === Test 1: 55% duty cycle (0x8C = 140) ===
    byte_to_shift = 8'h8C;           // Set byte to shift
    shift_in_byte();                 // Shift it in serially
    load = 1; @(posedge clk); load = 0;  // Latch into duty_cycle
    $display("Loaded duty cycle: 55%% (0x8C)");
    repeat (50) @(posedge clk);      // Wait for some cycles

    // === Test 2: 10% duty cycle (0x1A = 26) ===
    byte_to_shift = 8'h1A;
    shift_in_byte();
    load = 1; @(posedge clk); load = 0;
    $display("Loaded duty cycle: 10%% (0x1A)");
    repeat (200) @(posedge clk);

    // === Test 3: 90% duty cycle (0xE6 = 230) ===
    byte_to_shift = 8'hE6;
    shift_in_byte();
    load = 1; @(posedge clk); load = 0;
    $display("Loaded duty cycle: 90%% (0xE6)");
    repeat (200) @(posedge clk);

    // === Test 4: 85% duty cycle (0xD9 = 217) ===
    byte_to_shift = 8'hD9;
    shift_in_byte();
    load = 1; @(posedge clk); load = 0;
    $display("Loaded duty cycle: 85%% (0xD9)");
    repeat (200) @(posedge clk);

    $finish;                         // End simulation
  end

endmodule


//=============================
// Aha! Moments (Understanding):
//=============================
// - Aha! shift_reg shifts LEFT and 
