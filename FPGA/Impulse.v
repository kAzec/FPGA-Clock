module Impulse(
  input   clock,
  input   flip,
  output  impulse
);

reg current = 0;
reg last = 0;

assign impulse = ~current && last;

always @(posedge clock) begin
  current <= flip;
  last <= current;
end

endmodule