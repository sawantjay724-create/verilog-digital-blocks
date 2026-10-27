`timescale 1ns/1ps
// Self-checking testbench: exhaustive over all 8-bit (a, b) pairs for every op.
module alu_tb;
    reg  [7:0] a, b;
    reg  [2:0] op;
    wire [7:0] y;
    wire       zero, carry, overflow;

    alu #(8) dut (.a(a), .b(b), .op(op), .y(y), .zero(zero), .carry(carry), .overflow(overflow));

    integer errors = 0, checks = 0;
    integer i, j, k, sa, sb, s;
    reg [7:0] ey;
    reg       ec, ev;

    task check;
        begin
            sa = a[7] ? a - 256 : a;
            sb = b[7] ? b - 256 : b;
            ec = 0; ev = 0;
            case (op)
                0: begin ey = a + b; ec = (a + b) > 255; s = sa + sb; ev = (s > 127) || (s < -128); end
                1: begin ey = a - b; ec = (a >= b);      s = sa - sb; ev = (s > 127) || (s < -128); end
                2: ey = a & b;
                3: ey = a | b;
                4: ey = a ^ b;
                5: ey = a << b[2:0];
                6: ey = a >> b[2:0];
                7: ey = (sa < sb) ? 8'd1 : 8'd0;
            endcase
            #1;
            checks = checks + 1;
            if (y !== ey || carry !== ec || overflow !== ev || zero !== (ey == 0)) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("FAIL op=%0d a=%0d b=%0d: y=%0d (exp %0d) c=%b/%b v=%b/%b z=%b",
                             op, a, b, y, ey, carry, ec, overflow, ev, zero);
            end
        end
    endtask

    initial begin
        $dumpfile("build/alu.vcd");
        $dumpvars(0, alu_tb);
        // Directed cases first (recorded in the waveform)
        a = 8'd100; b = 8'd100; op = 0; #5; check;   // signed overflow on add
        a = 8'd255; b = 8'd1;   op = 0; #5; check;   // carry out, zero result
        a = 8'd5;   b = 8'd9;   op = 1; #5; check;   // borrow
        a = 8'h80;  b = 8'd1;   op = 1; #5; check;   // signed overflow on sub
        a = 8'hF0;  b = 8'h3C;  op = 2; #5; check;
        a = 8'h81;  b = 8'd1;   op = 5; #5; check;
        a = 8'hFE;  b = 8'd0;   op = 7; #5; check;
        $dumpoff;
        // Exhaustive sweep
        for (k = 0; k < 8; k = k + 1)
            for (i = 0; i < 256; i = i + 1)
                for (j = 0; j < 256; j = j + 1) begin
                    op = k; a = i; b = j; check;
                end
        $display("ALU: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("FAILED");
        $finish;
    end
endmodule
