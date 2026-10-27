// UART receiver, 8N1, samples each bit at its centre. `valid` pulses for one
// clock when a frame is complete; `frame_err` is high alongside it if the stop bit was 0.
module uart_rx #(parameter CLKS_PER_BIT = 16) (
    input            clk,
    input            rst,
    input            rx,
    output reg [7:0] data,
    output reg       valid,
    output reg       frame_err
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg        s1, s2;                  // two-flop synchroniser
    reg [1:0]  state;
    reg [15:0] cnt;
    reg [2:0]  idx;
    reg [7:0]  sh;

    always @(posedge clk) begin
        valid <= 1'b0;
        if (rst) begin
            s1 <= 1'b1; s2 <= 1'b1;
            state <= IDLE; cnt <= 0; idx <= 0; sh <= 0; data <= 0; frame_err <= 1'b0;
        end else begin
            s1 <= rx; s2 <= s1;
            case (state)
                IDLE:  if (!s2) begin cnt <= 0; state <= START; end
                START: if (cnt == CLKS_PER_BIT/2 - 1) begin
                           cnt <= 0;
                           if (!s2) begin idx <= 0; state <= DATA; end   // still low: real start bit
                           else state <= IDLE;                           // glitch
                       end else cnt <= cnt + 1'b1;
                DATA:  if (cnt == CLKS_PER_BIT-1) begin
                           cnt <= 0;
                           sh[idx] <= s2;                                 // LSB first
                           if (idx == 3'd7) state <= STOP; else idx <= idx + 1'b1;
                       end else cnt <= cnt + 1'b1;
                STOP:  if (cnt == CLKS_PER_BIT-1) begin
                           cnt <= 0; state <= IDLE;
                           data <= sh; valid <= 1'b1; frame_err <= !s2;
                       end else cnt <= cnt + 1'b1;
            endcase
        end
    end
endmodule
