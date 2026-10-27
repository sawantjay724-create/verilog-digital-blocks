# verilog-digital-blocks
It has an ALU, a FIFO, and a UART transmitter and receiver, each with a self-checking testbench. I ran all three in Icarus Verilog and they pass:  The ALU test is exhaustive, covering every 8-bit input pair for all 8 operations (524,295 checks). The FIFO test checks full, empty and overflow cases, plus 500 cycles of random reads 
