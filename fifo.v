// Synchronous FIFO, first-word-fall-through read (dout always shows the head).
// DEPTH must be a power of two. Writes when full and reads when empty are ignored.
// A write on a full FIFO is dropped even if a read happens in the same cycle.
module fifo #(parameter WIDTH = 8, parameter DEPTH = 16) (
    input                        clk,
    input                        rst,
    input                        wr_en,
    input      [WIDTH-1:0]       din,
    input                        rd_en,
    output     [WIDTH-1:0]       dout,
    output                       full,
    output                       empty,
    output     [$clog2(DEPTH):0] count
);
    localparam AW = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0]      wptr, rptr;           // one extra bit distinguishes full from empty

    assign count = wptr - rptr;
    assign full  = (count == DEPTH);
    assign empty = (wptr == rptr);
    assign dout  = mem[rptr[AW-1:0]];

    always @(posedge clk) begin
        if (rst) begin
            wptr <= 0;
            rptr <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wptr[AW-1:0]] <= din;
                wptr <= wptr + 1'b1;
            end
            if (rd_en && !empty)
                rptr <= rptr + 1'b1;
        end
    end
endmodule
