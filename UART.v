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
    input TXSTART,
    input [7:0] LINEIN,
    output DATA,
    output BUSY
);

    wire TICK;
    
    BaudSync BaudTicker(
        .CLOCK(CLOCK), 
        .ENABLE(BUSY), 
        .TICK(TICK)
    );
    
    reg [3:0] STATE = 4'b0000;
    reg MUX;
    wire READY = (STATE == 0);
    assign BUSY = ~READY;
    
    reg [7:0] SHIFT = 8'b0000_0000;
    
    always @ (posedge CLOCK)
        begin
            if (READY & TXSTART) SHIFT <= LINEIN;
            else if (STATE[3] & TICK) SHIFT <= (SHIFT >> 1);

            case(STATE)
                4'b0000: 
                    if(TXSTART) STATE <= 4'b0100;
                4'b0100:
                    if(TICK) STATE <= 4'b1000;  // START
                4'b1000:
                    if(TICK) STATE <= 4'b1001;  // BIT 0
                4'b1001:
                    if(TICK) STATE <= 4'b1010;  // BIT 1
                4'b1010:
                    if(TICK) STATE <= 4'b1011;  // BIT 2
                4'b1011:
                    if(TICK) STATE <= 4'b1100;  // BIT 3
                4'b1100:
                    if(TICK) STATE <= 4'b1101;  // BIT 4
                4'b1101:
                    if(TICK) STATE <= 4'b1110;  // BIT 5
                4'b1110:
                    if(TICK) STATE <= 4'b1111;  // BIT 6
                4'b1111:
                    if(TICK) STATE <= 4'b0010;  // BIT 7
                4'b0010:
                    if(TICK) STATE <= 4'b0011;  // STOP1
                4'b0011:
                    if(TICK) STATE <= 4'b0000;  // STOP2
                default:
                    if(TICK) STATE <= 4'b0000;
            endcase
        end
    

    always @ (STATE[2:0])
        case(STATE[2:0])
            0: MUX <= LINEIN[0];
            1: MUX <= LINEIN[1];
            2: MUX <= LINEIN[2];
            3: MUX <= LINEIN[3];
            4: MUX <= LINEIN[4];
            5: MUX <= LINEIN[5];
            6: MUX <= LINEIN[6];
            7: MUX <= LINEIN[7];
        endcase

    // START + DATA + STOP
    assign DATA = (STATE < 4) | (STATE[3] & MUX);
    
endmodule

/*****************************************************************************/
/*************************** Transmitter Test Bench **************************/
/*****************************************************************************/
module testTransmitter;

    reg PULSE;
    reg ENABLE;
    reg TXSTART;
    reg [7:0] LINEIN;
    wire TICK, DATA, BUSY;

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
    end
    
    BaudSync UUT(
        .CLOCK(PULSE),
        .ENABLE(ENABLE), 
        .TICK(TICK)
    );
    
    Transmitter VVT(
        .CLOCK(TICK),
        .TXSTART(TXSTART),
        .LINEIN(LINEIN),
        .DATA(DATA),
        .BUSY(BUSY)
    );
    
    // Test
    initial begin
        @ (posedge TICK);
            LINEIN = 8'b1011_0110;
            TXSTART = 1'b1;        
    end

endmodule

/*****************************************************************************/
/******************************* UART Receiver *******************************/
/*****************************************************************************/
module Receiver (
	input clk,
	input RxD,
	output reg RxD_data_ready = 0,
	output reg [7:0] RxD_data = 0,  // data received, valid only (for one clock cycle) when RxD_data_ready is asserted

	// We also detect if a gap occurs in the received stream of characters
	// That can be useful if multiple characters are sent in burst
	//  so that multiple characters can be treated as a "packet"
	output RxD_idle,  // asserted when no data has been received for a while
	output reg RxD_endofpacket = 0  // asserted for one clock cycle when a packet has been detected (i.e. RxD_idle is going high)
);

parameter Oversampling = 8;  // needs to be a power of 2
// we oversample the RxD line at a fixed rate to capture each RxD data bit at the "right" time
// 8 times oversampling by default, use 16 for higher quality reception


////////////////////////////////
reg [3:0] RxD_state = 0;

`ifdef SIMULATION
wire RxD_bit = RxD;
wire sampleNow = 1'b1;  // receive one bit per clock cycle

`else
wire OversamplingTick;
BaudSync #(Oversampling) tickgen(.clk(clk), .enable(1'b1), .tick(OversamplingTick));

// synchronize RxD to our clk domain
reg [1:0] RxD_sync = 2'b11;
always @(posedge clk) if(OversamplingTick) RxD_sync <= {RxD_sync[0], RxD};

// and filter it
reg [1:0] Filter_cnt = 2'b11;
reg RxD_bit = 1'b1;

always @(posedge clk)
if(OversamplingTick)
begin
	if(RxD_sync[1]==1'b1 && Filter_cnt!=2'b11) Filter_cnt <= Filter_cnt + 1'd1;
	else 
	if(RxD_sync[1]==1'b0 && Filter_cnt!=2'b00) Filter_cnt <= Filter_cnt - 1'd1;

	if(Filter_cnt==2'b11) RxD_bit <= 1'b1;
	else
	if(Filter_cnt==2'b00) RxD_bit <= 1'b0;
end

// and decide when is the good time to sample the RxD line
function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
localparam l2o = log2(Oversampling);
reg [l2o-2:0] OversamplingCnt = 0;
always @(posedge clk) if(OversamplingTick) OversamplingCnt <= (RxD_state==0) ? 1'd0 : OversamplingCnt + 1'd1;
wire sampleNow = OversamplingTick && (OversamplingCnt==Oversampling/2-1);
`endif

// now we can accumulate the RxD bits in a shift-register
always @(posedge clk)
case(RxD_state)
	4'b0000: if(~RxD_bit) RxD_state <= `ifdef SIMULATION 4'b1000 `else 4'b0001 `endif;  // start bit found?
	4'b0001: if(sampleNow) RxD_state <= 4'b1000;  // sync start bit to sampleNow
	4'b1000: if(sampleNow) RxD_state <= 4'b1001;  // bit 0
	4'b1001: if(sampleNow) RxD_state <= 4'b1010;  // bit 1
	4'b1010: if(sampleNow) RxD_state <= 4'b1011;  // bit 2
	4'b1011: if(sampleNow) RxD_state <= 4'b1100;  // bit 3
	4'b1100: if(sampleNow) RxD_state <= 4'b1101;  // bit 4
	4'b1101: if(sampleNow) RxD_state <= 4'b1110;  // bit 5
	4'b1110: if(sampleNow) RxD_state <= 4'b1111;  // bit 6
	4'b1111: if(sampleNow) RxD_state <= 4'b0010;  // bit 7
	4'b0010: if(sampleNow) RxD_state <= 4'b0000;  // stop bit
	default: RxD_state <= 4'b0000;
endcase

always @(posedge clk)
if(sampleNow && RxD_state[3]) RxD_data <= {RxD_bit, RxD_data[7:1]};

//reg RxD_data_error = 0;
always @(posedge clk)
begin
	RxD_data_ready <= (sampleNow && RxD_state==4'b0010 && RxD_bit);  // make sure a stop bit is received
	//RxD_data_error <= (sampleNow && RxD_state==4'b0010 && ~RxD_bit);  // error if a stop bit is not received
end

`ifdef SIMULATION
assign RxD_idle = 0;
`else
reg [l2o+1:0] GapCnt = 0;
always @(posedge clk) if (RxD_state!=0) GapCnt<=0; else if(OversamplingTick & ~GapCnt[log2(Oversampling)+1]) GapCnt <= GapCnt + 1'h1;
assign RxD_idle = GapCnt[l2o+1];
always @(posedge clk) RxD_endofpacket <= OversamplingTick & ~GapCnt[l2o+1] & &GapCnt[l2o:0];
`endif

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
