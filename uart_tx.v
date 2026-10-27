// UART transmitter, 8N1. Pulse `start` for one clock while `busy` is low.
module uart_tx #(parameter CLKS_PER_BIT = 16) (
    input        clk,
    input        rst,
    input        start,
    input  [7:0] data,
    output       tx,
    output       busy
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0]  state;
    reg [15:0] cnt;
    reg [2:0]  idx;
    reg [7:0]  sh;

    assign busy = (state != IDLE);
    assign tx   = (state == START) ? 1'b0 :
                  (state == DATA)  ? sh[0] : 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; cnt <= 0; idx <= 0; sh <= 0;
        end else begin
            case (state)
                IDLE:  if (start) begin sh <= data; cnt <= 0; state <= START; end
                START: if (cnt == CLKS_PER_BIT-1) begin cnt <= 0; idx <= 0; state <= DATA; end
                       else cnt <= cnt + 1'b1;
                DATA:  if (cnt == CLKS_PER_BIT-1) begin
                           cnt <= 0;
                           sh  <= {1'b0, sh[7:1]};
                           if (idx == 3'd7) state <= STOP; else idx <= idx + 1'b1;
                       end else cnt <= cnt + 1'b1;
                STOP:  if (cnt == CLKS_PER_BIT-1) begin cnt <= 0; state <= IDLE; end
                       else cnt <= cnt + 1'b1;
            endcase
        end
    end
endmodule
