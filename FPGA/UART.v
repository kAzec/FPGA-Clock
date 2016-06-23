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
  if(reset) begin
    RESET();
  end else begin
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
  input             rxd,
  input             notify,
  output reg [7:0]  data_out
);

endmodule

module UART(
  input         clock,
  input         reset,
  input         rxd,
  output        txd,
  input         tx_request,
  input         tx_done,
  input   [7:0] data_in,
  input         rx_notify,
  output  [7:0] data_out
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
  .rxd      (rxd),
  .notify   (rx_notify),
  .data_out (data_out)
);

endmodule