// Parameterised combinational ALU with zero / carry / overflow flags.
//   op: 0 ADD  1 SUB  2 AND  3 OR  4 XOR  5 SLL  6 SRL  7 SLT (signed)
// For SUB, carry = 1 means "no borrow" (a >= b unsigned), as in ARM.
module alu #(parameter W = 8) (
    input      [W-1:0] a,
    input      [W-1:0] b,
    input      [2:0]   op,
    output reg [W-1:0] y,
    output             zero,
    output reg         carry,
    output reg         overflow
);
    localparam ADD = 3'd0, SUB = 3'd1, AND_ = 3'd2, OR_ = 3'd3,
               XOR_ = 3'd4, SLL = 3'd5, SRL = 3'd6, SLT = 3'd7;

    reg [W:0] sum;

    always @* begin
        carry    = 1'b0;
        overflow = 1'b0;
        sum      = {(W+1){1'b0}};
        case (op)
            ADD: begin
                sum      = {1'b0, a} + {1'b0, b};
                y        = sum[W-1:0];
                carry    = sum[W];
                overflow = (a[W-1] == b[W-1]) && (y[W-1] != a[W-1]);
            end
            SUB: begin
                sum      = {1'b0, a} + {1'b0, ~b} + {{W{1'b0}}, 1'b1};
                y        = sum[W-1:0];
                carry    = sum[W];
                overflow = (a[W-1] != b[W-1]) && (y[W-1] != a[W-1]);
            end
            AND_: y = a & b;
            OR_:  y = a | b;
            XOR_: y = a ^ b;
            SLL:  y = a << b[$clog2(W)-1:0];
            SRL:  y = a >> b[$clog2(W)-1:0];
            SLT:  y = ($signed(a) < $signed(b)) ? {{(W-1){1'b0}}, 1'b1} : {W{1'b0}};
            default: y = {W{1'b0}};
        endcase
    end

    assign zero = (y == {W{1'b0}});
endmodule
