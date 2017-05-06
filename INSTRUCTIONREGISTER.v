module INSTRUCTIONREGISTER
(
    input CLOCK,
    input LOAD,
    input [8:0] DATAIN,
    output reg [8:0] DATAOUT
);
    always @ (posedge CLOCK)
        if (LOAD) DATAOUT <= DATAIN;

endmodule

/*****************************************************************************/
/************************* TEST BENCH FOR IREGISTER **************************/
/*****************************************************************************/
module testINSREGISTER;

    // Registers for inputs
    reg CLOCK, LOAD;
    reg [8:0] DATA;
    // Wires for output
    wire [8:0] OUTPUT;
    
    INSTRUCTIONREGISTER UUT(
        .CLOCK(CLOCK),
        .LOAD(LOAD),
        .DATAIN(DATA),
        .DATAOUT(OUTPUT)
    );
    
    // Initiate registers with values
    initial begin
        CLOCK = 1'b0;
        LOAD = 1'b0;
        DATA = 16'b0_0000_0000;
    end
    
    // Test
    initial begin
        #10
        CLOCK = 1'b1;
        LOAD = 1'b1;
        DATA = 16'b0_1100_0010;
        #10
        CLOCK = 1'b0;
        LOAD = 1'b1;
        DATA = 16'b0_0100_1100;
        #10
        CLOCK = 1'b1;
        LOAD = 1'b0;
        DATA = 16'b0_0011_1110;
        #10
        $finish;
    end
    
endmodule