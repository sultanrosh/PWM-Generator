// ==============================
// Module: PWM
// Purpose: Shift in 8 bits serially to set a PWM duty cycle,
//          then generate a PWM signal by comparing with a counter
// ==============================

module PWM(
  input clk,                  // Clock signal (rising edge-triggered)
  input reset,                // Asynchronous reset to clear registers
  input load,                 // Load signal to latch the shift register into duty_cycle
  input shift_enable,         // Enable signal to shift bits into shift_reg
  input S_in,                 // Serial data input (1 bit per clock)
  input [7:0] counter,        // PWM counter (should count from 0 to 255)
  output reg pwm_signal       // Final PWM output signal
);

// === Internal registers ===
reg [2:0] bit_count;          // Counts number of bits shifted into shift_reg (0 to 7, only 3 bits needed)
reg [7:0] shift_reg;          // 8-bit shift register for serial loading of duty cycle
reg [7:0] duty_cycle;         // Latched duty cycle value used for PWM output

// === Serial shift register logic ===
// Shift register only shifts when shift_enable is HIGH
always @(posedge clk or posedge reset) begin
  if (reset) begin
    shift_reg <= 8'b00000000;  // Clear the shift register on reset
    bit_count <= 3'b000;       // Clear bit counter on reset
  end else if (shift_enable) begin
    shift_reg <= {shift_reg[6:0], S_in};  // Shift left and insert S_in into LSB
    bit_count <= bit_count + 1'b1;        // Increment bit counter each clock cycle
  end
end

// === Latch shift_reg into duty_cycle on load ===
// When load is HIGH, duty_cycle captures the current value of shift_reg
always @(posedge clk or posedge reset) begin
  if (reset)
    duty_cycle <= 8'b00000000;            // Clear duty_cycle on reset
  else if (load)
    duty_cycle <= shift_reg;             // Capture current shift_reg value into duty_cycle
end

// === PWM signal generation ===
// PWM signal is HIGH while counter is less than duty_cycle
always @(posedge clk or posedge reset) begin
  if (reset)
    pwm_signal <= 1'b0;                   // Clear output on reset
  else
    pwm_signal <= (counter < duty_cycle) ? 1'b1 : 1'b0;
end

endmodule


// ==============================
// Aha! Moments:
// ==============================
// - Aha! S_in is not "pushing" values into registers on its own — it's just a single bit input,
//        and the shift register logic decides when and how to store it.
// - Aha! bit_count is needed because Verilog hardware doesn’t "remember" how many bits you've shifted in.
// - Aha! load acts like a latch trigger — you don’t want duty_cycle updating mid-shift.
// - Aha! pwm_signal is based on comparing counter and duty_cycle to produce correct duty width.
// - Aha! shift_reg brings in bits from S_in one at a time — the 8-bit duty is built up over 8 clocks.
// - Aha! You only need 3 bits to count up to 8 (bit_count) since 2^3 = 8.
// - Aha! PWM needs stable duty_cycle values, so we only update them after full shifting is done.
// - Aha! pwm_signal <= (counter < duty_cycle) is the heart of PWM logic — HIGH while counter is under threshold.
// ==============================


  
  /*
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pwm_signal <= 0;
    end else begin
      pwm_signal <= duty_cycle
    end
  end
endmodule 
*/
  
  
/*
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      shift_reg <= 0;
      duty_cycle <= 0;
    end else begin
      shift_reg <= S_in;
      duty_cycle <= load;
 */   
      
