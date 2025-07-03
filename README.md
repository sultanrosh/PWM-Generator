# PWM-Generator

# Serial-Loaded Pulse Width Modulation (PWM) Generator – Verilog Design

This project implements a serially-loaded 8-bit Pulse Width Modulation (PWM) signal generator in Verilog. It features a shift register that accepts one serial bit per clock cycle and loads that value into a PWM generator that compares it with a continuously incrementing counter. The final output is a duty-controlled digital signal, making this a foundational building block for digital control systems and embedded interfaces.

This design is educational, waveform-driven, and debug-intensive — demonstrating bit-level accuracy, protocol correctness, and proper hardware/software interface understanding.

---

## Table of Contents

- [Project Description](#project-description)
- [Architecture Overview](#architecture-overview)
- [File Structure](#file-structure)
- [Module Descriptions](#module-descriptions)
- [Simulation Strategy](#simulation-strategy)
- [Aha! Moments – Key Learnings](#aha-moments--key-learnings)
- [Debugging Log and Design Evolution](#debugging-log-and-design-evolution)
- [Waveform Analysis](#waveform-analysis)
- [Future Improvements](#future-improvements)
- [Conclusion](#conclusion)

---

## Project Description

The purpose of this project is to simulate a hardware module that performs PWM signal generation based on an 8-bit serially shifted value. Instead of using a parallel bus to set the PWM duty cycle, this design shifts in one bit at a time through a 1-bit input port (`S_in`) and accumulates it in an internal shift register.

Once 8 bits are shifted in, a `load` signal latches the complete byte into a `duty_cycle` register. From there, a comparator evaluates whether the counter value is less than the duty cycle and outputs a high or low signal accordingly. The PWM signal can be used to modulate LEDs, motors, or digital controllers in embedded systems.

---

## Architecture Overview

The system consists of the following components:

1. **8-bit shift register**
   - Controlled by a `shift_enable` signal.
   - Shifts left and inserts the serial bit into the least significant position (`shift_reg <= {shift_reg[6:0], S_in};`).

2. **Load latch**
   - Captures the value in `shift_reg` into `duty_cycle` when `load` is high.

3. **PWM comparator**
   - Constantly compares a free-running 8-bit `counter` against the latched `duty_cycle` value.
   - Sets `pwm_signal` high when `counter < duty_cycle`.

4. **Testbench**
   - Drives all inputs.
   - Shifts in known test vectors (e.g., 0x8C, 0x1A, 0xE6).
   - Produces a `.vcd` waveform file.

---

## File Structure

.
├── PWM.v # Design module
├── PWM_tb.v # Testbench module
├── PWM_tb.vcd # Generated waveform file (can be viewed in GTKWave)
├── README.md # Documentation (this file)


---

## Module Descriptions

### PWM.v

This is the design under test. It contains:

- An 8-bit shift register (`shift_reg`)
- A `bit_count` register (optional for tracking shift progress)
- A `duty_cycle` latch
- A comparator that drives `pwm_signal`

Behavior:
- `reset` clears all state.
- On each rising clock edge:
  - If `shift_enable` is high, `S_in` is shifted into `shift_reg`.
  - If `load` is high, the current `shift_reg` is loaded into `duty_cycle`.
- PWM signal is high if `counter < duty_cycle`.

### PWM_tb.v

The testbench performs the following:
- Sets up a 100 MHz clock
- Applies reset and initialization
- Uses a `task` to shift in 8-bit values one bit at a time
- Controls `shift_enable` and `load` manually
- Displays status via `$display`
- Dumps waveform to VCD file

---

## Simulation Strategy

The testbench simulates several test cases:
- **0x8C (140)**: Expected to give ~55% duty cycle
- **0x1A (26)**: Expected to give ~10% duty cycle
- **0xE6 (230)**: Expected to give ~90% duty cycle
- **0xD9 (217)**: Expected to give ~85% duty cycle

Each byte is shifted in bit-by-bit using a for-loop that sends bits from **most significant to least significant** to match hardware logic.

Waveform inspection in GTKWave confirms the correctness of bit loading, `duty_cycle` capture, and PWM behavior.

---

## Aha! Moments – Key Learnings

### Aha 1: Bit Order Matters

The shift register shifts **left** and inserts into the **least significant bit**, so the first bit you send ends up in the **highest bit** of the register. Therefore, you must send **MSB first**.

**Incorrect (LSB first)**:


for (i = 0; i < 8; i++)
S_in = byte[i]; // LSB first


**Correct (MSB first)**:


for (i = 7; i >= 0; i--)
S_in = byte[i]; // MSB first


### Aha 2: shift_reg Builds Value Over Time

Each bit shifted in transforms the shift register. You can watch the register grow with each clock:

| Clock | S_in | shift_reg (binary) | Hex |
|-------|------|---------------------|-----|
| 1     | 1    | 00000001            | 0x01 |
| 2     | 0    | 00000010            | 0x02 |
| 3     | 0    | 00000100            | 0x04 |
| 4     | 0    | 00001000            | 0x08 |
| 5     | 1    | 00010001            | 0x11 |
| 6     | 1    | 00100011            | 0x23 |
| 7     | 0    | 01000110            | 0x46 |
| 8     | 0    | 10001100            | 0x8C ✅ |

### Aha 3: All State Changes Happen on posedge clk

In Verilog, an `always @(posedge clk)` block means:
- Changes happen **only at the moment the clock rises**
- If you miss a clock or load on the wrong edge, results are unstable

### Aha 4: You Only Have 8 Bits

The shift register is 8 bits wide:
- If you shift more than 8 times, early bits are lost
- If you shift fewer than 8 times and then load, the value is incomplete
- Therefore, timing is critical and must align with design expectations


### Aha 5: Bit Indexing in Verilog Is Not the Same as "Left to Right"
One of the key realizations during this project came from debugging why the PWM duty cycle was being incorrectly latched.

At first, the testbench was feeding in the serial data using the loop:

for (i = 0; i < 8; i = i + 1)
  S_in = byte_to_shift[i];
  
This loop fed i = 0 as the first bit, which was assumed to be the MSB — the "beginning" of the number. But in Verilog, byte_to_shift[0] is the least significant bit (LSB).

That meant the design was actually receiving the bits in reverse order from what it expected.

The hardware itself was functioning correctly: the shift register shifted left and inserted new bits at the LSB position — a process that requires the MSB to be fed first. But the testbench was feeding the LSB first, which led to the final value being reversed (e.g., expecting 0x8C but loading 0x31).

This uncovered a core concept of hardware design:

In Verilog, index 0 always refers to the LSB, not the leftmost bit. Bit index corresponds to bit significance — not sequence position.

Fix:
The testbench was corrected to feed MSB first by reversing the loop:

for (i = 7; i >= 0; i = i - 1)
  S_in = byte_to_shift[i];
  
This aligned the testbench logic with the design’s shifting behavior and resolved the mismatch between simulated input and hardware expectations.

---

## Debugging Log and Design Evolution

### Original Bug

Initially, the testbench used LSB-first shifting, which led to incorrect values being latched into `duty_cycle`.

For example:
- Attempted to shift `0x8C = 10001100`
- Resulting register was `0x31 = 00110001`

This confused the waveform and resulted in wrong PWM output.

### Root Cause

The shift register logic was shifting **left**, and assumed **MSB-first** bit ordering. Feeding LSB-first reversed the byte and broke the design.

### Fix

Modified the testbench to feed bits from **MSB to LSB**, matching the shifting direction and ensuring the first bit landed in bit 7.

### Validation

After the fix:
- Shifted value correctly landed as `0x8C`
- PWM signal showed approximately 55% duty cycle
- Other test vectors matched expected behavior
- Waveforms confirmed correct signal transitions

---

## Waveform Analysis

Waveforms (viewed in GTKWave) clearly show:
- `S_in` pulses HIGH only when feeding a '1' bit
- `shift_reg` values building up correctly from 0 to 8C
- `duty_cycle` capturing correct value immediately after `load`
- `pwm_signal` pulsing HIGH whenever `counter < duty_cycle`

These validate every step of the design.

---

## Future Improvements

Several features could be added to improve robustness:

- **Make shift width parameterizable**  
  Use `parameter WIDTH = 8;` to allow reuse of the module for different sizes

- **Guard shift logic with bit counter**  
  Prevent overshifting by:
  ```verilog
  if (bit_count < 8)
    shift_reg <= {shift_reg[6:0], S_in};

---

## Author
**Kourosh Rashidiyan**  
**July 3rd, 2025**


