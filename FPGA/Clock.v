module Clock(
  input clock,
  /** PC104 **/
  input         write_n,
  input         read_n,
  input   [9:0] address,
  input         aen,
  input   [7:0] data_bus_in,
  output  [7:0] data_bus_out,
  /** Interrupt **/
  output irq11,
  /** Buttons **/
  input button0_signal,
  input button1_signal,
  input button1_signal_long,
  input button2_signal,
  input button2_signal_long,
  /** LEDs **/
  output [5:0]  led_num0, led_num1,
  output        led_dot
);

/** Modes **/
localparam MODE_NORMAL  = 1'b0;
localparam MODE_TIMESET = 1'b1;

reg mode = MODE_NORMAL;

/** Switch between normal/time-set modes **/
always @(posedge button1_signal_long) begin
  mode <= ~mode;
end

/** CounterCore module **/
reg         modify_flip;
wire        modify_signal;

Impulse modify_impluse(
  .clock  (clock),
  .flip   (modify_flip),
  .impulse(modify_signal)
);

reg   [4:0] hr_in;
reg   [5:0] min_in, sec_in;
wire  [5:0] hr_out, min_out, sec_out;

CounterCore #(
  .L0_LIMIT(60),
  .L1_LIMIT(60), 
  .L2_LIMIT(24)) 
core (
  .clock(clock),
  .reset(reset),
  .enabled(mode == MODE_NORMAL),
  .modify_signal(modify_signal),
  .l0_in(sec_in),
  .l1_in(min_in),
  .l2_in({1'b0, hr_in}),
  .l0_out(sec_out),
  .l1_out(min_out),
  .l2_out(hr_out)
);

/** ClockSync module **/
wire sync_done;
wire [4:0] sync_hr;
wire [5:0] sync_min, sync_sec;

ClockSync sync(
  .clock       (clock),
  .write_n     (write_n),
  .read_n      (read_n),
  .address     (address),
  .aen         (aen),
  .data_bus_in (data_bus_in),
  .data_bus_out(data_bus_out),
  .hr_in       (hr_out[4:0]),
  .min_in      (min_out),
  .sec_in      (sec_out),
  .hr_out      (sync_hr),
  .min_out     (sync_min),
  .sec_out     (sync_sec),
  .request     (mode == MODE_NORMAL ? button2_signal : 1'b0),
  .done        (sync_done),
  .irq11       (irq11)
);

/** Switch between HH:MM/MM:SS **/
localparam POS_HHMM = 1'b0;
localparam POS_MMSS = 1'b1;

reg display_position = POS_MMSS;

always @(posedge button0_signal) begin
  display_position <= ~display_position;
end

/** LED display **/
assign led_num0 = display_position == POS_HHMM ? hr_out : min_out;
assign led_num1 = display_position == POS_HHMM ? min_out : sec_out;
assign led_dot  = mode == MODE_NORMAL ? sec_out : 1'b0;

/** Time modification **/
always @( posedge sync_done or posedge button1_signal or posedge button2_signal) begin
  if(sync_done) begin
    if(mode == MODE_NORMAL) begin
      {hr_in, min_in, sec_in} <= {sync_hr, sync_min, sync_sec};
      modify_flip <= ~modify_flip;
    end
  end else if(mode == MODE_TIMESET) begin
    case({button1_signal, display_position})
      {1'b1, POS_HHMM} : hr_in  <= hr_out  == 23 ? 4'b0 : hr_out  + 1;
      {1'b0, POS_HHMM} ,
      {1'b1, POS_MMSS} : min_in <= min_out == 59 ? 5'b0 : min_out + 1;
      {1'b0, POS_MMSS} : sec_in <= sec_out == 59 ? 5'b0 : sec_out + 1;
    endcase
  end
end

endmodule