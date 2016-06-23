module BCD7(
  input       [6:0] binary,     // Input binary(0~99).
  output reg  [3:0] ones, tens  // Output two digits(ones and tens).
);

integer i;
always @(binary) begin
  ones = 4'd0;
  tens = 4'd0;

  for (i = 7; i >= 0; i = i -1) begin
    // Add 3 to columns >= 5
    if(tens >= 5)
      tens = tens + 3;
    if(ones >= 5)
      ones = ones + 3;

    // Shift left one
    tens = tens << 1;
    tens[0] = ones[3];
    ones = ones << 1;
    ones[0] = binary[i];
  end
end

endmodule