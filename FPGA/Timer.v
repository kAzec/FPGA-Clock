module Timer (
  input         clock,
  /** Buttons **/
  input button0_signal,
  input button1_signal,
  input button2_debounced,
  /** LEDs **/
  output [5:0]  led_num0, led_num1,
  output        led_dot
);

/** Reset **/
wire reset;
assign reset = button2_debounced;

/** Pause/Resume control **/
reg running = 0;

always @(posedge button1_signal) begin
  running <= ~running;
end

/** Counter core **/
wire [5:0] min_out, sec_out, cs_out;

CounterCore #(
  .L0_LIMIT(60),
  .L1_LIMIT(60),
  .L2_LIMIT(60),
  .L0_COUNTER_N(13), 
  .L0_COUNTER_LIMIT(4999)) 
core (
  .clock(clock),
  .reset(reset),
  .enabled(running),
  .modify_n(1'b0),
  .l0_in(6'b0),
  .l1_in(6'b0),
  .l2_in(6'b0),
  .l0_out(cs_out),
  .l1_out(sec_out),
  .l2_out(min_out)
);

/** SS:CC/MM:SS switch/auto-switch **/
localparam POS_SSCC = 0;
localparam POS_MMSS = 1;

reg position = POS_SSCC;
reg auto_switch = 0;

always @(posedge button0_signal or posedge auto_switch) begin
  position <= auto_switch ? POS_MMSS : ~position;
end

always @(min_out[0] or posedge reset) begin
  if(reset)
    auto_switch <= 0;
  else if(min_out > 0)
    auto_switch <= 1;
end

/** LED display **/
assign led_num0 = position == 0 ? min_out : sec_out;
assign led_num1 = position == 0 ? sec_out : cs_out;
assign led_dot  = min_out > 0 ? 1 : 0;

endmodule