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
    input STICK,
    input [7:0] LINEIN,
    output DATA,
    output reg DONE
);

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] STRT = 2'b01;
    localparam [1:0] FETC = 2'b10;
    localparam [1:0] STOP = 2'b11;
    
    reg [1:0] STATE_REG, STATE_NEXT;
    reg [3:0] S_REG, S_NEXT;
    reg [2:0] N_REG, N_NEXT;
    reg [7:0] B_REG, B_NEXT;
    reg TX_REG, TX_NEXT;
    
    always @ (posedge CLOCK, posedge RESET)
        if (RESET)
            begin
                STATE_REG <= IDLE;
                S_REG <= 4'b0000;
                N_REG <= 3'b000;
                B_REG <= 8'b0000_0000;
                TX_REG <= 1'b1;
            end
        else
            begin
                STATE_REG <= STATE_NEXT;
                S_REG <= S_NEXT;
                N_REG <= N_NEXT;
                B_REG <= B_NEXT;
                TX_REG <= TX_NEXT;
            end
            
    always @ (*)
        begin
            STATE_NEXT = STATE_REG;
            DONE = 1'b0;
            S_NEXT = S_REG;
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
                                S_NEXT = 4'b0000;
                                B_NEXT = LINEIN;
                            end
                    end
                    
                STRT:
                    begin
                        TX_NEXT = 1'b0;
                        if (STICK)
                            if (S_REG == 15)
                                begin
                                    STATE_NEXT = FETC;
                                    S_NEXT = 4'b0000;
                                    N_NEXT = 3'b000;
                                end
                            else
                                S_NEXT = S_REG + 4'b0001;
                    end
                    
                FETC:
                    begin
                        TX_NEXT = B_REG[0];
                        if (STICK)
                            if (S_REG == 15)
                                begin
                                    S_NEXT = 4'b0000;
                                    B_NEXT = B_REG >> 1;
                                    if (N_REG == 7) STATE_NEXT = STOP;
                                    else N_NEXT = N_REG + 3'b001;                                        
                                end
                            else
                                S_NEXT = S_REG + 4'b0001;
                    end
                    
                STOP:
                    begin
                        TX_NEXT = 1'b1;
                        if (STICK)
                            if (S_REG == 15)
                                begin
                                    STATE_NEXT = IDLE;
                                    DONE = 1'b1;
                                end
                            else
                                S_NEXT = S_REG + 4'b0001;
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
        .CLOCK(TICK),
        .RESET(RESET),
        .TXSTART(TXSTART),
        .LINEIN(LINEIN),
        .DATA(DATA),
        .DONE(DONE),
        .STICK(TICK)
    );
    
    // Test
    initial begin
        @ (posedge TICK);
            LINEIN = 8'b1011_0110;
            TXSTART = 1'b1;
            RESET = 1'b0;
    end

endmodule

/*****************************************************************************/
/******************************* UART Receiver *******************************/
/*****************************************************************************/
module Receiver (
	input CLOCK, RESET,
    input rx, s_tick,
    output reg rx_done_tick,
    output [7:0] dout
);

    localparam [1:0] idle = 2'b00;
    localparam [1:0] start = 2'b01; 
    localparam [1:0] data = 2'b10; 
    localparam [1:0] stop = 2'b11;
   
    reg [1:0] state_reg, state_next;
    reg [3:0] s_reg, s_next;
    reg [2:0] n_reg, n_next;
    reg [7:0] b_reg, b_next;
    
    always @ (posedge CLOCK, posedge RESET)
        if(RESET) 
            begin 
                state_reg<= idle;
                s_reg<= 0;
                n_reg<= 0;
                b_reg<= 0;
            end 
        else 
            begin 
                state_reg<= state_next;
                s_reg<= s_next;
                n_reg<= n_next;
                b_reg<= b_next;
            end
    
    always @ (*)
        begin 
            state_next = state_reg; 
            rx_done_tick = 1'b0; 
            s_next = s_reg; 
            n_next = n_reg; 
            b_next = b_reg; 
            
            case (state_reg) 
                idle: 
                    if (~rx) 
                        begin 
                            state_next = start; 
                            s_next = 0; 
                        end 
                
                start: 
                    if (s_tick) 
                        if(s_reg == 7) 
                            begin 
                                state_next = data; 
                                s_next = 0; 
                                n_next = 0; 
                            end 
                    else 
                        s_next = s_reg + 1'b1; 
                    
                data: 
                    if (s_tick) 
                        if (s_reg == 15) 
                        begin 
                            s_next = 0; 
                            b_next = {rx, b_reg[7:1]}; 
                            if (n_reg == (7)) 
                                state_next = stop; 
                            else 
                                n_next = n_reg + 1'b1; 
                        end 
                    else 
                        s_next = s_reg + 1'b1; 
                
                stop:
                    if (s_tick) 
                        if (s_reg == (15)) 
                            begin 
                                state_next = idle; 
                                rx_done_tick = 1'b1; 
                            end 
                    else
                        s_next = s_reg + 1'b1; 
            
            endcase 
        end 
        
        assign dout = b_reg;
        
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
