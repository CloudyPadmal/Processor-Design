module UART
(
    input RX,
    input CLOCK,
    output TX
);

    // Rates and constants
    

endmodule


/*****************************************************************************/
/************************** Baud Rate Synchronizer ***************************/
/*****************************************************************************/
module BaudSync
(
    input CLOCK,
    input RESET,
    output TICK
);

    // Rates and Constants
    
    reg [RegistrySpace-1:0] counter;
	
    always @ (posedge CLOCK, posedge RESET)
        begin
            counter = (RESET | (counter == (ClockCounts - 1))) ? 1'b0 : counter + 1'b1;
        end
		  
	assign TICK = (counter == (ClockCounts - 1)) ? 1'b1 : 1'b0;
    
endmodule

/*****************************************************************************/
/***************************** UART Transmitter ******************************/
/*****************************************************************************/
module Transmitter
(
    input RESET,
    input TXBegin,
    input TICK,
    input wire [7:0] DATA,
    input CLOCK,
    output TX,
    output TXComplete
);

endmodule

/*****************************************************************************/
/******************************* UART Receiver *******************************/
/*****************************************************************************/
module Receiver
(
    input RESET,
    input RX,
    input CLOCK,
    input TICK,
    output reg [7:0] DATA,
    output RXComplete
);



endmodule

/*****************************************************************************/
/****************************** UART Test Bench ******************************/
/*****************************************************************************/
module testUART;

    reg PULSE;
    reg RESET;
    wire RATE;

    // Clock for simulation purposes
    initial begin
        // Initiate clock_pulse reg value
        PULSE = 0;
        forever begin
            #1 PULSE = ~PULSE;
        end
    end
	 
    // Initiate registers with values
    initial begin
        // Reset the circuit as it starts
        RESET = 1'b1;
        #1
        RESET = 1'b0;
    end

    BaudSync UUT(
        .CLOCK(PULSE),
        .RESET(RESET),
        .TICK(RATE)
    );

endmodule
