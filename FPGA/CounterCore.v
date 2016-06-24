module CounterCore(
  input         clock, reset,           // Clock and reset.
  input         enabled,                // Enable.
  input         modify_signal,          // The 1 bit input represents the signal of modifying the counters' value.
  input   [5:0] l0_in, l1_in, l2_in,    // The 6 bits each inputs for digits of tl0ee level counters.
  output  [5:0] l0_out, l1_out, l2_out  // The 6 bits each outputs for digits of tl0ee level counters.
);

parameter CLK_FREQ = 1000000;

parameter L0_LIMIT = 60;
parameter L1_LIMIT = 60;
parameter L2_LIMIT = 60;

parameter L0_COUNTER_N      = 19;
parameter L0_COUNTER_LIMIT  = 499999;

reg [L0_COUNTER_N - 1:0] counter = 0;

reg clock_l0 = 0;

reg [5:0] l0, l1, l2;

assign {l0_out, l1_out, l2_out} = {l0, l1, l2};

always @(posedge clock or posedge reset) begin
  if(reset | modify_signal) begin
    counter <= 0;
    clock_l0 <= 0;
  end else if(enabled) begin
     if(counter >= L0_COUNTER_LIMIT - 1) begin
       clock_l0 <= ~clock_l0;
       counter <= 0;
     end else
       counter <= counter + 1;
  end
end

always @(posedge clock_l0 or posedge reset) begin
  if(reset)
    {l0, l1, l2} <= 0;
  else if(modify_signal) begin
    l0 <= l0_in >= L0_LIMIT ? 0 : l0_in;
    l1 <= l1_in >= L1_LIMIT ? 0 : l1_in;
    l2 <= l2_in >= L2_LIMIT ? 0 : l2_in;
  end else begin
    if(l0 >= L0_LIMIT - 1) begin
      l0 <= 0;
      l1 <= l1 + 1;
    end else
      l0 <= l0 + 1;

    if(l1 >= L1_LIMIT - 1) begin
      l1 <= 0;
      l2 <= l2 + 1;
    end else
      l1 <= l1 + 1;

    if(l2 >= L2_LIMIT - 1)
      l2 <= 0;
    else
      l2 <= l2 + 1;
  end
end

endmodule