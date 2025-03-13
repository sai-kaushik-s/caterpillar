module top (a, b, c, d);
    input a, b, c;
    output d;
    wire temp1, temp2, temp3;
    assign temp1 = a & b;
    assign temp2 = b & c;
    assign temp3 = temp1 ^ temp2;
    assign d = temp3 & c;
endmodule