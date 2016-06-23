module Top(
  /**PC104**/
  input   [9:0]   ab,
  input           aen,
  input   [7:0]   db_in,
  output  [7:0]   db_out,
  input           ior_n,
  input           iow_n,
  input           oe_n,
  
  /** 7 Segments LED **/
  output time_ml,
  output time_ll,
  output time_mh,
  output time_hh,
  output led_a,
  output led_b,
  output led_c,
  output led_d,
  output led_e,
  output led_f,
  output led_g,
  output led_dp,
  
  /** Buttons **/
  input btn_l,
  input btn_m,
  input btn_h,
  
  /** Clock **/
  input   clk,
  
  /**RS232C**/
  input   fpga_rxd,
  output  fpga_txd,
  
  /** Interrupt **/
  output irq11
);

/** Reset **/
assign rst = 0;

/** Buttons **/
wire [2:0] debounced;
wire [2:0] pressed;
wire [2:0] long_pressed;

Button button0(
  .clock      (clk),
  .reset      (rst),
  .in         (btn_h),
  .debounced  (debounced[0]),
  .signal     (pressed[0]),
  .signal_long(long_pressed[0])
);

Button button1(
  .clock      (clk),
  .reset      (rst),
  .in         (btn_m),
  .debounced  (debounced[1]),
  .signal     (pressed[1]),
  .signal_long(long_pressed[1])
);

Button button2(
  .clock      (clk),
  .reset      (rst),
  .in         (btn_l),
  .debounced  (debounced[2]),
  .signal     (pressed[2]),
  .signal_long(long_pressed[2])
);

/** Clock/Timer modes **/
localparam MODE_CLOCK = 0;
localparam MODE_TIMER = 1;

reg mode = MODE_CLOCK;

/** Switch between clock/timer mode **/
always @(posedge long_pressed[1]) begin
  mode <= ~mode;
end

/** Clock module **/
wire [5:0]  clock_num0, clock_num1;
wire        clock_dp;

Clock clock(
  .clock              (clk),
  .write_n            (iow_n),
  .read_n             (ior_n),
  .address            (ab),
  .aen                (aen),
  .data_bus_in        (db_in),
  .data_bus_out       (db_out),
  .irq11              (irq11),
  .button0_signal     (pressed[0]),
  .button1_signal     (pressed[1]),
  .button2_signal     (pressed[2]),
  .button0_signal_long(long_pressed[0]),
  .button1_signal_long(long_pressed[1]),
  .button2_signal_long(long_pressed[2]),
  .led_num0           (clock_num0),
  .led_num1           (clock_num1),
  .led_dot            (clock_dp)
);

/** Timer module **/
wire [5:0]  timer_num0, timer_num1;
wire        timer_dp;

Timer timer(
  .clock         (clk),
  .button0_signal(pressed[0]),
  .button1_signal(pressed[1]),
  .led_num0      (timer_num0),
  .led_num1      (timer_num1),
  .led_dot       (timer_dp)
);

/** LED display **/
wire [6:0] num0, num1;
wire [3:0] digit0, digit1, digit2, digit3;

BCD7 bcd_num0(
  .binary(num0),
  .ones  (digit0),
  .tens  (digit1)
);

BCD7 bcd_num1(
  .binary(num1),
  .ones  (digit2),
  .tens  (digit3)
);

LEDSegments led(
  .clock   (clk),
  .reset   (rst),
  .in0     (digit0),
  .in1     (digit1),
  .in2     (digit2),
  .in3     (digit3),
  .a       (led_a),
  .b       (led_b),
  .c       (led_c),
  .d       (led_d),
  .e       (led_e),
  .f       (led_f),
  .g       (led_g),
  .choice_n({time_ml, time_ll, time_mh, time_hh})
);

assign num0 = {1'b0, mode == MODE_CLOCK ? clock_num0 : timer_num0};
assign num1 = {1'b0, mode == MODE_CLOCK ? clock_num1 : timer_num1};
assign led_dp = mode == MODE_CLOCK ? clock_dp : timer_dp;

endmodule
