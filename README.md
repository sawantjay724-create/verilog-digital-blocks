# verilog-digital-blocks

[![Simulate](https://github.com/YOUR-USERNAME/verilog-digital-blocks/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR-USERNAME/verilog-digital-blocks/actions)

Three small, reusable digital design blocks written in Verilog. Each has a
**self-checking testbench**, runs on the open-source Icarus Verilog simulator,
and writes a waveform you can open in GTKWave.

| Module | What it does | How it is tested |
|---|---|---|
| `rtl/alu.v` | Parameterised ALU: add, subtract, AND, OR, XOR, shift left/right, signed compare. Zero, carry and overflow flags. | Exhaustive: every 8-bit `a`, `b` pair for all 8 operations (524,295 checks). |
| `rtl/fifo.v` | Synchronous FIFO with full / empty / count flags and first-word-fall-through output. | Fill to full, overflow and underflow attempts, then 500 cycles of random simultaneous push/pop against a reference queue. |
| `rtl/uart_tx.v`, `rtl/uart_rx.v` | UART 8N1 transmitter and receiver with a two-flop input synchroniser and mid-bit sampling. | Loopback of 8 byte patterns, plus a hand-driven frame with a bad stop bit to check framing-error detection. |

## Requirements

- [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`sudo apt install iverilog`)
- Optional: [GTKWave](https://gtkwave.sourceforge.net/) for viewing waveforms

## Run

```bash
make test          # run all three testbenches
make sim-uart      # run just one (alu, fifo or uart)
make wave-uart     # simulate, then open build/uart.vcd in GTKWave
```

Expected output:

```
ALU: 524295 checks, 0 errors
ALL TESTS PASSED
FIFO: 1767 checks, 0 errors
ALL TESTS PASSED
UART: 9 checks, 0 errors
ALL TESTS PASSED
```

## Design notes

- **ALU:** for `SUB`, `carry = 1` means *no borrow* (a >= b unsigned), the ARM convention. Shift amounts use the low `log2(W)` bits of `b`.
- **FIFO:** pointers have one extra bit so full and empty can be told apart without a separate counter. A write to a full FIFO is dropped even if a read happens in the same cycle (a simple, safe choice).
- **UART:** `CLKS_PER_BIT = clock_frequency / baud_rate` (for example 50 MHz / 115200 = 434). The testbench uses 16 to keep simulations short. `valid` pulses once per received frame and `frame_err` marks a bad stop bit, so the consumer decides what to do with bad frames.

## Project layout

```
rtl/    synthesizable design files
tb/     self-checking testbenches
build/  simulation output (ignored by git)
```

## Ideas to extend

SPI master, parity and baud-rate generator for the UART, an asynchronous FIFO with Gray-code pointers, or a small CPU built around the ALU.

## License

MIT
