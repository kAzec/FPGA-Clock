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
  input button0_signal_long,
  input button1_signal,
  input button1_signal_long,
  input button2_signal,
  input button2_signal_long,
  /** LEDs **/
  output [5:0]  led_num0, led_num1,
  output        led_dot
);

/** Modes **/
localparam MODE_NORMAL = 0;
localparam MODE_TIMESET = 1;

reg mode = MODE_NORMAL;

/** Switch between normal/time-set modes **/
always @(posedge button0_signal_long) begin
  mode <= ~mode;
end

/** CounterCore module **/
reg         modify_flip;
wire        modify_n;

Impulse modify_impluse(
  .clock  (clock),
  .flip   (modify_flip),
  .impulse(modify_n)
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
  .modify_n(modify_n),
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
localparam POS_HHMM = 0;
localparam POS_MMSS = 1;

reg position = POS_MMSS;

always @(posedge button0_signal) begin
  position <= ~position;
end

/** LED display **/
assign led_num0 = position == POS_HHMM ? hr_out : min_out;
assign led_num1 = position == POS_HHMM ? min_out : sec_out;
assign led_dot  = mode == MODE_NORMAL ? sec_out : 1'b0;

/** Time modification **/
reg add_digit1 = 1;
reg add_digit2 = 1;

task ADD_HOUR(input add); begin
  if(add)
    hr_in <= hr_out == 23 ? 00 : hr_out + 1;
  else
    hr_in <= hr_out == 00 ? 23 : hr_out - 1;
end
endtask

task ADD_MINUTE(input add); begin
  if(add)
    min_in <= min_out == 59 ? 00 : min_out + 1;
  else
    min_in <= min_out == 00 ? 59 : min_out - 1;
end
endtask

task ADD_SECOND(input add); begin
  if(add)
    sec_in <= sec_out == 59 ? 00 : sec_out + 1;
  else
    sec_in <= sec_out == 00 ? 59 : sec_out - 1;
end
endtask

always @( posedge sync_done or 
          posedge button1_signal or 
          posedge button1_signal_long or 
          posedge button2_signal or 
          posedge button2_signal_long) begin
  if(sync_done) begin
    if(mode == MODE_NORMAL) begin
      if(sync_done) begin
        {hr_in, min_in, sec_in} <= {sync_hr, sync_min, sync_sec};
        modify_flip <= ~modify_flip;
      end
    end
  end else if(mode == MODE_TIMESET) begin
    if(button1_signal || button1_signal_long) begin
      if(position == POS_HHMM)
        ADD_HOUR(add_digit1);
      else
        ADD_MINUTE(add_digit1);

      if(button1_signal_long)
        add_digit1 <= ~add_digit1;
    end else begin
      if(position == POS_HHMM)
        ADD_MINUTE(add_digit2);
      else
        ADD_SECOND(add_digit2);

      if(button2_signal_long)
        add_digit2 <= ~add_digit2;
    end
  end
end

endmodule