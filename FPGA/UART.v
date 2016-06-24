module UARTTransmitter(
  input       clock,
  input       reset,
  input [7:0] data_in,
  input       request,
  output reg  txd,
  output reg  done
);

reg       last_request;
reg [3:0] state;

assign parity = ~(^data_in);

task RESET(); begin
  state = 4'b0000;
  txd   = 1'b0;
  done  = 1'b1;
end
endtask

initial begin
  RESET();
end

always @(posedge clock or posedge reset) begin
  if(reset)
    RESET();
  else begin
    last_request <= request;

    case (state)
    4'b0000: begin
      if(request != last_request && request) begin
        done <= 1'b0;
        state <= 4'b0001;
      end
    end
    4'b0001: begin // Transmit start bit 0
      state <= 4'b0010;
      txd <= 1'b0;
    end
    4'b0010: begin // Transmit data bits
      state <= 4'b0011;
      txd <= data_in[0];
    end
    4'b0011: begin
      state <= 4'b0100;
      txd <= data_in[1];
    end
    4'b0100: begin
      state <= 4'b0101;
      txd <= data_in[2];
    end
    4'b0101: begin
      state <= 4'b0110;
      txd <= data_in[3];
    end
    4'b0110: begin
      state <= 4'b0111;
      txd <= data_in[4];
    end
    4'b0111: begin
      state <= 4'b1000;
      txd <= data_in[5];
    end
    4'b1000: begin
      state <= 4'b1001;
      txd <= data_in[6];
    end
    4'b1001: begin
      state <= 4'b1010;
      txd <= data_in[7];
    end
    4'b1010: begin // Transmit odd parity bit
      state <= 4'b1011;
      txd <= parity;
    end
    4'b1011: begin // Transmit stop bit
      state <= 4'b0000;
      txd <= 1'b1;
      done <= 1'b1;
    end
    default:begin
      state <= 4'b0000;
    end
    endcase
  end
end

endmodule

module UARTReceiver(
  input             clock,
  input             reset,
  output reg [7:0]  data_out,
  input             rxd,
  output reg        done
);

reg [3:0] state;

task RESET(); begin
  state     = 4'b0000;
  parity    = 1'b0;
  done      = 1'b1;
  data_out  = 8'b0;
end
endtask

initial begin
  RESET();
end

always @(posedge clk or posedge reset) begin
  if(reset)
    data_out <= 8'b0;
  else begin
    case (state)
    4'b0000: begin // Receive start bit 0
      if(rxd == 1'b0) begin 
        done <= 1'b0;
        state <= 4'b0001;
      end
    end
    4'b0001: begin // Receive data bits 
      state <= 4'b0010;
      data_out[0] = rxd;
    end
    4'b0010: begin
      state <= 4'b0011;
      data_out[1] = rxd;
    end
    4'b0011: begin
      state <= 4'b0100;
      data_out[2] = rxd;
    end
    4'b0100: begin
      state <= 4'b0101;
      data_out[3] = rxd;
    end
    4'b0101: begin
      state <= 4'b0110;
      data_out[4] = rxd;
    end
    4'b0110: begin
      state <= 4'b0111;
      data_out[5] = rxd;
    end
    4'b0111: begin
      state <= 4'b1000;
      data_out[6] = rxd;
    end
    4'b1000: begin
      state <= 4'b1001;
      data_out[7] = rxd;
    end
    4'b1001: begin // Receive odd parity bit
      state <= 4'b1010;
      
      if(rxd != ~(^data_in))
        $display("Error: Expecting parity %b, received %b", ~(^data_in), rxd);
    end
    4'b1010: begin // Receive stop bit
      state <= 4'b0000;
      done <= 1'b1;

      if(rxd != 1)
        $display("Error: Expecting 1 stop bit, received %b", rxd);
    end
    default: state <= 4'b0000;
    endcase
  end
end

endmodule

module UART(
  input         clock, reset, // Clock and reset.
  input         tx_request,   // Request to start transfer.
  input   [7:0] data_in,      // Data to transfer.
  output        tx_done,      // Transfer completes.
  output        rx_done,      // Data received.
  output  [7:0] data_out,     // Received dat.
  /** RS232C **/
  input         rxd,
  output        txd
);

UARTTransmitter transmitter(
  .clock(clock),
  .reset(reset),
  .data_in(data_in),
  .request(request),
  .txd(txd),
  .done(tx_done)
);

UARTReceiver receiver(
  .clock    (clock),
  .reset    (reset),
  .data_out (data_out),
  .rxd      (rxd),
  .done     (rx_done)
);

endmodule