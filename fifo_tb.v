`timescale 1ns/1ps
module fifo_tb;
    localparam DEPTH = 16;
    reg        clk = 0, rst = 1, wr_en = 0, rd_en = 0;
    reg  [7:0] din = 0;
    wire [7:0] dout;
    wire       full, empty;
    wire [4:0] count;

    fifo #(8, DEPTH) dut (.clk(clk), .rst(rst), .wr_en(wr_en), .din(din), .rd_en(rd_en),
                          .dout(dout), .full(full), .empty(empty), .count(count));

    always #5 clk = ~clk;

    integer errors = 0, checks = 0, i, n, occ;
    reg [7:0] model [0:1023];     // reference queue
    integer head = 0, tail = 0;

    task assert_that(input cond, input [255:0] msg);
        begin
            checks = checks + 1;
            if (!cond) begin errors = errors + 1; $display("FAIL: %0s (t=%0t)", msg, $time); end
        end
    endtask

    task push(input [7:0] v);
        begin
            @(posedge clk); #1 wr_en = 1; din = v;
            if (count < DEPTH) begin model[tail] = v; tail = tail + 1; end
            @(posedge clk); #1 wr_en = 0;
        end
    endtask

    task pop;
        begin
            @(posedge clk); #1 rd_en = 1;
            if (head != tail) begin
                assert_that(dout === model[head], "dout matches reference");
                head = head + 1;
            end
            @(posedge clk); #1 rd_en = 0;
        end
    endtask

    initial begin
        $dumpfile("build/fifo.vcd");
        $dumpvars(0, fifo_tb);
        repeat (3) @(posedge clk);
        #1 rst = 0;
        assert_that(empty && !full && count == 0, "empty after reset");

        for (i = 0; i < DEPTH; i = i + 1) push(8'hA0 + i);
        assert_that(full && !empty && count == DEPTH, "full after DEPTH pushes");

        push(8'hFF);                                   // overflow attempt
        assert_that(count == DEPTH, "write on full is ignored");

        for (i = 0; i < DEPTH; i = i + 1) pop;
        assert_that(empty && count == 0, "empty after draining");

        pop;                                           // underflow attempt
        assert_that(empty && count == 0, "read on empty is ignored");

        // Randomised simultaneous push/pop traffic against the reference queue
        for (i = 0; i < 6; i = i + 1) push($random);
        for (n = 0; n < 500; n = n + 1) begin
            @(posedge clk); #1;
            // DUT has applied last cycle's stimulus; the model was updated at the same time
            assert_that(count == tail - head, "count matches reference");
            assert_that(empty == (head == tail), "empty flag matches reference");
            assert_that(full == ((tail - head) == DEPTH), "full flag matches reference");
            // Choose the next cycle's stimulus and predict its effect
            wr_en = $random; rd_en = $random; din = $random;
            occ = tail - head;                         // occupancy before this cycle's read
            if (rd_en && head != tail) begin
                assert_that(dout === model[head], "random traffic: dout matches");
                head = head + 1;
            end
            if (wr_en && occ < DEPTH) begin model[tail] = din; tail = tail + 1; end
        end
        wr_en = 0; rd_en = 0;

        $display("FIFO: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("FAILED");
        $finish;
    end
endmodule
