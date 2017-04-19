module INSTRUCTIONREGISTER
(
    input CLOCK,
    input LOAD,
    input [8:0] DATAIN,
    output reg [8:0] DATAOUT = 16'd99
);
    always @ (posedge CLOCK)
        if (LOAD) DATAOUT <= DATAIN;

endmodule  