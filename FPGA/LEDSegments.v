module LEDSegments(
  input         clock, reset,           // Clock and reset
  input   [3:0] in0, in1, in2, in3,     // The 4 inputs for four numbers.
  output  reg   a, b, c, d, e, f, g,    // Seven segments output to LED.
  output  [3:0] choice_n                // The choice of currently flashing number.
);

localparam N = 14;

reg [N-1:0] counter; // 14 bit counter which allows us to multiplex at 122Hz(1MHz/2^(14-1)=122.07Hz).

always @(posedge clock or posedge reset) begin
  counter <= reset ? 0 : counter + 1;
end

reg [3:0] choice;
reg [3:0] seg_data; // The 4 bit register to hold the number(0~9) to display.

always @(*) begin
  case(counter[N-1:N-2]) // Using only the 2 MSB's of the counter to achieve FDM
    2'b00 : begin // When the 2 MSB's are 00 enable the first_n display
      seg_data <= in0;
      choice <= 4'b0111;
    end

    2'b01 : begin // When the 2 MSB's are 01 enable the second display
      seg_data <= in1;
      choice <= 4'b1011;
    end

    2'b10 : begin // When the 2 MSB's are 10 enable the third display
      seg_data <= in2;
      choice <= 4'b1101;
    end

    2'b11 : begin // When the 2 MSB's are 11 enable the fourth display
      seg_data <= in3;
      choice <= 4'b1110;
    end
  endcase
end

always @(*) begin
  case(seg_data)
    4'd0    : {g, f, e, d, c, b, a} <= 7'b1000000; // display 0
    4'd1    : {g, f, e, d, c, b, a} <= 7'b1111001; // display 1
    4'd2    : {g, f, e, d, c, b, a} <= 7'b0100100; // display 2
    4'd3    : {g, f, e, d, c, b, a} <= 7'b0110000; // display 3
    4'd4    : {g, f, e, d, c, b, a} <= 7'b0011001; // display 4
    4'd5    : {g, f, e, d, c, b, a} <= 7'b0010010; // display 5
    4'd6    : {g, f, e, d, c, b, a} <= 7'b0000010; // display 6
    4'd7    : {g, f, e, d, c, b, a} <= 7'b1111000; // display 7
    4'd8    : {g, f, e, d, c, b, a} <= 7'b0000000; // display 8
    4'd9    : {g, f, e, d, c, b, a} <= 7'b0010000; // display 9
    4'bz    : {g, f, e, d, c, b, a} <= 7'b0010000; // display nothing
    4'b1111 : {g, f, e, d, c, b, a} <= 7'b0111111; // display dash
    default : {g, f, e, d, c, b, a} <= 7'b0000110; // display 'E' aka error
 endcase
end

endmodule