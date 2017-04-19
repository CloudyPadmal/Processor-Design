module REGISTER
(
    input CLOCK,
    input LOAD,
    input [15:0] DATAIN,
    output reg [15:0] DATAOUT = 16'b0000_0000_0000_0000
);
    
    always @ (posedge CLOCK)
        begin
            if(LOAD) DATAOUT <= DATAIN;
        end

endmodule

/*****************************************************************************/
/************************* TEST BENCH FOR REGISTER ***************************/
/*****************************************************************************/
module testREGISTER;

    // Registers for inputs
    reg CLOCK, LOAD;
    reg [15:0] DATA;
    // Wires for output
    wire [15:0] OUTPUT;
    
    REGISTER UUT(
        .CLOCK(CLOCK),
        .LOAD(LOAD),
        .DATAIN(DATA),
        .DATAOUT(OUTPUT)
    );
    
    // Initiate registers with values
    initial begin
        CLOCK = 1'b0;
        LOAD = 1'b0;
        DATA = 16'b0000_0000_0000_0000;
    end
    
    // Test
    initial begin
        #10
        CLOCK = 1'b1;
        LOAD = 1'b1;
        DATA = 16'b0110_0100_1100_0010;
        #10
        CLOCK = 1'b0;
        LOAD = 1'b1;
        DATA = 16'b0100_0010_0100_1100;
        #10
        CLOCK = 1'b1;
        LOAD = 1'b0;
        DATA = 16'b0011_0010_0011_1110;
        #10
        $finish;
    end
    
endmodule
