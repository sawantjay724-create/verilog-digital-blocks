IVERILOG ?= iverilog
VVP      ?= vvp

SRC_alu  := rtl/alu.v tb/alu_tb.v
SRC_fifo := rtl/fifo.v tb/fifo_tb.v
SRC_uart := rtl/uart_tx.v rtl/uart_rx.v tb/uart_tb.v
TESTS    := alu fifo uart

.PHONY: all test clean

all: test

test: $(TESTS:%=sim-%)

sim-%: | build
	$(IVERILOG) -g2012 -o build/$*.vvp $(SRC_$*)
	$(VVP) build/$*.vvp | tee build/$*.log
	@grep -q "ALL TESTS PASSED" build/$*.log

# Open a waveform in GTKWave, e.g. `make wave-uart`
wave-%: sim-%
	gtkwave build/$*.vcd &

build:
	mkdir -p build

clean:
	rm -rf build/*
