module Debounce (
  input       clock, reset, // Clock and reset.
  input       in,           // Raw input.
  output reg  out           // Debounced output
);

parameter INACTIVE_OUT = 1'b1; // Assuming the button outputs active low by default.

parameter N = 14; // Counter which counts delay for debouncing, which defaults to approx. 8ms.

reg [N-1:0] counter;

wire tick;
assign tick = counter[N-1];

always @(posedge clock or posedge reset) begin
  counter <= reset ? 0 : counter + 1;
end

reg [2:0] state;
reg [2:0] state_next;

localparam [2:0] STATE_ZERO   = 3'b000;
localparam [2:0] STATE_HIGH1  = 3'b001;
localparam [2:0] STATE_HIGH2  = 3'b010;
localparam [2:0] STATE_HIGH3  = 3'b011;
localparam [2:0] STATE_ONE    = 3'b100;
localparam [2:0] STATE_LOW1   = 3'b101;
localparam [2:0] STATE_LOW2   = 3'b110;
localparam [2:0] STATE_LOW3   = 3'b111;

always @(posedge clock or posedge reset) begin
  state <= reset ? STATE_ZERO : state_next;
end

always @(*) begin
  state_next <= state; // Cache the current state.
  out <= INACTIVE_OUT;

  case (state)
    STATE_ZERO: begin
      if(in == ~INACTIVE_OUT)
        state_next <= STATE_HIGH1;
    end
    STATE_HIGH1: begin
      if(in == INACTIVE_OUT)
        state_next <= STATE_ZERO;
      else if(tick)
        state_next <= STATE_HIGH2;
    end
    STATE_HIGH2: begin
      if(in == INACTIVE_OUT)
        state_next <= STATE_ZERO;
      else if(tick)
        state_next <= STATE_HIGH3;
    end
    STATE_HIGH3: begin
      if(in == INACTIVE_OUT)
        state_next <= STATE_ZERO;
      else if(tick)
        state_next <= STATE_ONE;
    end
    STATE_ONE: begin
      out <= ~INACTIVE_OUT;
      if(in == ~INACTIVE_OUT)
        state_next <= STATE_LOW1;
    end
    STATE_LOW1: begin
      if(in == ~INACTIVE_OUT)
        state_next <= STATE_ONE;
      else if(tick)
        state_next <= STATE_LOW2;
    end
    STATE_LOW2: begin
      if(in == ~INACTIVE_OUT)
        state_next <= STATE_ONE;
      else if(tick)
        state_next <= STATE_LOW3;
    end
    STATE_LOW2: begin
      if(in == ~INACTIVE_OUT)
        state_next <= STATE_ONE;
      else if(tick)
        state_next <= STATE_ZERO;
    end
    default: state_next <= STATE_ZERO;
  endcase
end

endmodule

module Button(
  input   clock, reset, // Clock and reset.
  input   in,           // Button raw input(un-debounced).
  output  debounced,    // Debounced signal.
  output  signal,	      // 1 bit signal which emit a positive pulse when a press action is done.
  output  signal_long	  // 1 bit signal which emit a positive pulse when a long-press action is done.
);

Debounce debounce(
  .clock(clock),
  .reset(reset),
  .in   (in),
  .out  (debounced)
);

/* Detect press & long-press action */
parameter LONG_PRESS_DELAY = 20;

reg [LONG_PRESS_DELAY-1:0] counter = 0;  // Counter which counts delay for detecting long-press action, which defaults to approx. 524ms.

reg old_state = 0;
reg timeout = 0;

reg signal_flip;
reg signal_long_flip;

Impulse signal_impulse(
  .clock  (clock),
  .flip   (signal_flip),
  .impulse(signal)
);

Impulse signal_long_impulse(
  .clock  (clock),
  .flip   (signal_long_flip),
  .impulse(signal_long)
);

always @(posedge clock or posedge reset) begin
  if(reset) begin
    counter <= 0;
    timeout <= 0;
  end else begin
    if(~debounced) begin                            // Button state is down.
      if(old_state)                                 // Button state changed.
        counter <= 0;
      else if(counter[LONG_PRESS_DELAY-1]) begin    // Long press detection timed out.
        timeout <= 1;
        signal_long_flip <= ~signal_long_flip;
      end else
        counter <= counter + 1; // Continue counting long press
    end else begin              // Button is released.
      if(~old_state) begin      // Button state changed.
        if(timeout)             // It's a long press action, ignoring.
          timeout <= 0;
        else                    // It's a normal press action, emit signal.
          signal_flip <= ~signal_flip;
      end
    end
  end

  old_state <= debounced;
end

endmodule