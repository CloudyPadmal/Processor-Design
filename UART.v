module UART
(
    input RX,
    input CLOCK,
    output TX
);

    // Rates and constants
    

endmodule

/*****************************************************************************/
/***************************** UART Transmitter ******************************/
/*****************************************************************************/
module Transmitter
(
    input CLOCK,
    input RESET,
    input TXSTART,
    input TICK,
    input [7:0] LINEIN,
    output DATA,
    output reg DONE
);

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] STRT = 2'b01;
    localparam [1:0] FETC = 2'b10;
    localparam [1:0] STOP = 2'b11;
    
    reg [1:0] STATE_REG, STATE_NEXT;
    reg [2:0] N_REG, N_NEXT;
    reg [7:0] B_REG, B_NEXT;
    reg TX_REG, TX_NEXT;
    
    always @ (posedge CLOCK, posedge RESET)
        if (RESET)
            begin
                STATE_REG <= IDLE;
                N_REG <= 3'b000;
                B_REG <= 8'b0000_0000;
                TX_REG <= 1'b1;
            end
        else
            begin
                STATE_REG <= STATE_NEXT;
                N_REG <= N_NEXT;
                B_REG <= B_NEXT;
                TX_REG <= TX_NEXT;
            end
            
    always @ (*)
        begin
            STATE_NEXT = STATE_REG;
            DONE = 1'b0;
            N_NEXT = N_REG;
            B_NEXT = B_REG;
            TX_NEXT = TX_REG;
            
            case (STATE_REG)
                IDLE:
                    begin
                        TX_NEXT = 1'b1;
                        if (TXSTART)
                            begin
                                STATE_NEXT = STRT;
                                B_NEXT = LINEIN;
                            end
                    end
                    
                STRT:
                    begin
                        TX_NEXT = 1'b0;
                        if (TICK)
                            begin
                                STATE_NEXT = FETC;
                                N_NEXT = 3'b000;
                            end
                    end
                    
                FETC:
                    begin
                        TX_NEXT = B_REG[0];
                        if (TICK)
                            begin
                                B_NEXT = B_REG >> 1;
                                if (N_REG == 7) STATE_NEXT = STOP;
                                else N_NEXT = N_REG + 3'b001;
                            end
                    end
                    
                STOP:
                    begin
                        TX_NEXT = 1'b1;
                        if (TICK)
                            begin
                                STATE_NEXT = IDLE;
                                DONE = 1'b1;
                            end
                    end
                    
            endcase
            
        end
        
    assign DATA = TX_REG;
    
endmodule

/*****************************************************************************/
/*************************** Transmitter Test Bench **************************/
/*****************************************************************************/
module testTransmitter;

    reg PULSE;
    reg ENABLE;
    reg RESET;
    reg TXSTART;
    reg [7:0] LINEIN;
    wire TICK, DATA, DONE;
    
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
        // Enable the baud generator
        ENABLE = 1'b1;
        TXSTART = 1'b0;
        RESET = 1'b1;
    end
    
    BaudSync UUT(
        .CLOCK(PULSE),
        .ENABLE(ENABLE), 
        .TICK(TICK)
    );
    
    Transmitter VVT(
        .CLOCK(PULSE),
        .RESET(RESET),
        .TXSTART(TXSTART),
        .LINEIN(LINEIN),
        .DATA(DATA),
        .DONE(DONE),
        .TICK(TICK)
    );
    
    // Test
    initial begin
        @ (posedge TICK);
            LINEIN = 8'b1011_0110;
            TXSTART = 1'b1;
            RESET = 1'b0;
        repeat(10) @(posedge TICK);
            LINEIN = 8'b1010_0010;
            TXSTART = 1'b1;
            RESET = 1'b0;
        repeat(10) @(posedge TICK);
            $finish;
    end

endmodule

/*****************************************************************************/
/******************************* UART Receiver *******************************/
/*****************************************************************************/
module Receiver (
	input CLOCK, RESET,
    input LINEIN, TICK,
    output reg DONE,
    output reg BUSY,
    output [7:0] DATA
);

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] STRT = 2'b01; 
    localparam [1:0] FETC = 2'b10; 
    localparam [1:0] STOP = 2'b11;
   
    reg [1:0] CURRENT_STATE, STATE_NEXT;
    reg [2:0] N_REG, N_NEXT;
    reg [7:0] B_REG, B_NEXT;
    
    always @ (posedge CLOCK, posedge RESET)
        if (RESET) 
            begin 
                CURRENT_STATE <= IDLE;
                N_REG <= 0;
                B_REG <= 0;
            end
        else 
            begin 
                CURRENT_STATE <= STATE_NEXT;
                N_REG <= N_NEXT;
                B_REG <= B_NEXT;
            end
    
    always @ (*)
        begin 
            STATE_NEXT = CURRENT_STATE; 
            DONE = 1'b0; 
            N_NEXT = N_REG; 
            B_NEXT = B_REG; 

            case (CURRENT_STATE) 
                IDLE:
                    // If LINEIN goes low when in IDLE
                    // that is beginning of a bit stream
                    if (~LINEIN)
                        begin 
                            STATE_NEXT = STRT;
                        end

                STRT:
                    if (TICK)
                        begin
                            STATE_NEXT = FETC; 
                            N_NEXT = 0;
                        end

                FETC: 
                    if (TICK)
                        begin
                            B_NEXT = {LINEIN, B_REG[7:1]}; 
                            if (N_REG == 7)
                                STATE_NEXT = STOP;
                            else
                                begin
                                    N_NEXT = N_REG + 1'b1;
                                    BUSY = 1'b1;
                                end
                        end

                STOP:
                    if (TICK)
                        begin
                            STATE_NEXT = IDLE;
                            DONE = 1'b1;
                            BUSY = 1'b0;
                        end

            endcase 
        end 
        
        assign DATA = B_REG;
        
endmodule

/*****************************************************************************/
/**************************** Receiver Test Bench ****************************/
/*****************************************************************************/
module testReceiver;

    reg PULSE;
    reg ENABLE;
    reg RESET;
    reg LINEIN;
    wire [7:0] DATA;
    wire TICK, DONE, BUSY;
    
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
        // Enable the baud generator
        ENABLE = 1'b1;
        RESET = 1'b1;
        LINEIN = 1'b1;
    end
    
    BaudSync UUT(
        .CLOCK(PULSE),
        .ENABLE(ENABLE), 
        .TICK(TICK)
    );

    Receiver VVT(
        .CLOCK(PULSE),
        .RESET(RESET),
        .LINEIN(LINEIN),
        .DATA(DATA),
        .BUSY(BUSY),
        .DONE(DONE),
        .TICK(TICK)
    );
    
    // Test
    initial begin
        @ (posedge TICK);
            LINEIN = 1'b1;
            RESET = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b0;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b1;
        @ (posedge TICK);
            LINEIN = 1'b0;
        repeat(10) @(posedge TICK);
            $finish;
    end

endmodule

/*****************************************************************************/
/************************** Baud Rate Synchronizer ***************************/
/*****************************************************************************/
module BaudSync 
(
    input CLOCK,    // FPGA Clock input
    input ENABLE,   // Enabler for the module
    output TICK     // TICK will be [baud rate * oversample factor]
);

    localparam FPGACLOCK = 25000000;     // 25 MHz Clock
    localparam BAUDRATE = 115200;        // Optimum Baud rate
    parameter OVERSAMPLE = 1;           // Default sampling factor

    function integer BASE2(input integer VAL);
        begin
            BASE2 = 0;
            while (VAL >> BASE2) BASE2 = BASE2 + 1;
        end
    endfunction
    
    localparam ACCUMULATE = BASE2(FPGACLOCK / BAUDRATE) + 8;
    // SHIFT will limit INCREMENT from overflowing
    localparam SHIFT = BASE2(BAUDRATE * OVERSAMPLE >> (31 - ACCUMULATE));
    localparam INCFAC1 = (BAUDRATE * OVERSAMPLE << (ACCUMULATE - SHIFT));
    localparam INCFAC2 = (FPGACLOCK >> (SHIFT + 1));
    localparam INCFAC3 = (FPGACLOCK >> SHIFT);
    localparam INCREMENT = (INCFAC1 + INCFAC2) / INCFAC3;
    
    reg [ACCUMULATE:0] ACCUMULATOR = 0;
    
    always @ (posedge CLOCK) 
        begin 
            if (ENABLE) ACCUMULATOR <= ACCUMULATOR[ACCUMULATE-1:0] + INCREMENT[ACCUMULATE:0];
            else ACCUMULATOR <= INCREMENT[ACCUMULATE:0];
        end
    
    assign TICK = ACCUMULATOR[ACCUMULATE];
    
endmodule

/*****************************************************************************/
/**************************** BaudSync Test Bench ****************************/
/*****************************************************************************/
module testBaudSync;

    reg PULSE;
    reg ENABLE;
    wire TICK;

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
        // Enable the baud generator
        ENABLE = 1'b1;
    end
    
    BaudSync UUT(
        .CLOCK(PULSE),
        .ENABLE(ENABLE), 
        .TICK(TICK)
    );

endmodule
