module Impulse(
  input   clock,
  input   flip,
  output  impulse
);

reg current = 1'b0;
reg last = 1'b0;

initial begin
  current = flip;
end

assign impulse = ~current && last;

always @(posedge clock) begin
  current <= flip;
  last <= current;
end

endmodule