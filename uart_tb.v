`timescale 1ns/1ps
// Loopback test (tx -> rx) plus a hand-driven bad-stop-bit frame.
module uart_tb;
    localparam CPB = 16;
    reg        clk = 0, rst = 1, start = 0, inject = 0, inj_line = 1;
    reg  [7:0] tx_data = 0;
    wire       tx_line, busy, valid, frame_err;
    wire [7:0] rx_data;
    wire       line = inject ? inj_line : tx_line;

    uart_tx #(CPB) u_tx (.clk(clk), .rst(rst), .start(start), .data(tx_data), .tx(tx_line), .busy(busy));
    uart_rx #(CPB) u_rx (.clk(clk), .rst(rst), .rx(line), .data(rx_data), .valid(valid), .frame_err(frame_err));

    always #5 clk = ~clk;

    integer errors = 0, checks = 0, i;
    reg [7:0] vectors [0:7];
    reg [7:0] got;
    reg       got_err, seen;

    // Capture the receiver output whenever `valid` pulses
    always @(posedge clk) if (valid) begin got <= rx_data; got_err <= frame_err; seen <= 1'b1; end

    task send(input [7:0] v);
        begin
            @(posedge clk); #1 tx_data = v; start = 1;
            @(posedge clk); #1 start = 0;
            seen = 0;
            wait (seen); @(posedge clk);
            checks = checks + 1;
            if (got !== v || got_err) begin
                errors = errors + 1;
                $display("FAIL: sent %h received %h frame_err=%b", v, got, got_err);
            end
            wait (!busy);
        end
    endtask

    initial begin
        $dumpfile("build/uart.vcd");
        $dumpvars(0, uart_tb);
        vectors[0] = 8'h00; vectors[1] = 8'hFF; vectors[2] = 8'hA5; vectors[3] = 8'h3C;
        vectors[4] = 8'h55; vectors[5] = 8'h01; vectors[6] = 8'h80; vectors[7] = 8'h7E;
        repeat (4) @(posedge clk);
        #1 rst = 0;
        repeat (4) @(posedge clk);

        for (i = 0; i < 8; i = i + 1) send(vectors[i]);

        // Bad frame: start bit, 8 zero data bits, stop bit forced to 0
        #1 inject = 1; inj_line = 0; seen = 0;
        repeat (CPB * 10) @(posedge clk);
        #1 inj_line = 1;
        repeat (CPB * 2) @(posedge clk);
        checks = checks + 1;
        if (!seen || !got_err) begin errors = errors + 1; $display("FAIL: framing error not flagged"); end
        inject = 0;

        $display("UART: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("FAILED");
        $finish;
    end

    initial begin #2000000; $display("FAIL: timeout"); $finish; end
endmodule
