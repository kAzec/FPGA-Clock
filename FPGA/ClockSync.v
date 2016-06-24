module ClockSync (
  input       clock,
  /** PC104 **/
  input             write_n,
  input             read_n,
  input       [9:0] address,
  input             aen,
  input       [7:0] data_bus_in,
  output  reg [7:0] data_bus_out,
  /** Local time **/
  input       [4:0] hr_in,
  input       [5:0] min_in,
  input       [5:0] sec_in,
  /** Synced remote time **/
  output  reg [4:0] hr_out,
  output  reg [5:0] min_out,
  output  reg [5:0] sec_out,
  /** Sync **/
  input             request,  // Request signal that activate a time-sync phase.
  output            done,     // Notify that time sync is done successfully.
  /** Interrupts **/
  output irq11
);

localparam ADDRESS = 10'h233;

assign cs = address == ADDRESS && aen == 0;

/** Modes **/
localparam CHOICE_HR    = 2'b00;
localparam CHOICE_MIN   = 2'b01;
localparam CHOICE_SEC   = 2'b10;
localparam CHOICE_DONE  = 2'b11;

localparam MODE_READ  = 0;
localparam MODE_WRITE = 1;

reg read_choice = CHOICE_HR;

reg done_flip;
Impulse done_impulse(
  .clock  (clock),
  .flip   (done_flip),
  .impulse(done)
);

always @(posedge write_n) begin
  if(cs) begin
    if(data_bus_in[7] == MODE_WRITE) begin // Set time.
      case(data_bus_in[6:5])
        CHOICE_HR   : hr_out  <= data_bus_in[3:0];
        CHOICE_MIN  : min_out <= data_bus_in[4:0];
        CHOICE_SEC  : sec_out <= data_bus_in[4:0];
        CHOICE_DONE : done_flip <= ~done_flip;
      endcase
    end else if(data_bus_in[6:5] != CHOICE_DONE) // Pre-read time.
      read_choice <= data_bus_in[6:5];
  end
end

always @(negedge read_n) begin
  if(cs) begin
    data_bus_out[0]   <= MODE_READ;
    data_bus_out[6:5] <= read_choice;

    case(read_choice)
      CHOICE_HR   : data_bus_out[3:0] <= hr_in;
      CHOICE_MIN  : data_bus_out[4:0] <= min_in;
      CHOICE_SEC  : data_bus_out[4:0] <= sec_in;
    endcase
  end
end

reg irq_flip;

Impulse irq_impulse(
  .clock  (clock),
  .flip   (irq_flip),
  .impulse(irq11)
);

always @(posedge request) begin
  irq_flip <= ~irq_flip;
end

endmodule