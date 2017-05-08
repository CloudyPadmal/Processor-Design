module CONTROLUNIT
(
    input CLOCK,
    input FLAGZ,
    input [7:0] IR,
    output reg [5:0] FLAGS,
    output reg [2:0] FLAGB,
    output reg [2:0] ALU,    
    output reg [7:0] FLAGC
);

    // Constants
    localparam FETCH1      = 6'b000_000;
    localparam FETCH2      = 6'b000_001;
    localparam FETCH3      = 6'b000_010;
    localparam FETCH4      = 6'b111_001;
    localparam CLAC        = 6'b000_011;
    localparam MVACAR      = 6'b111_011;
    localparam STAC1       = 6'b000_100;
    localparam WRITE       = 6'b110_101;
    localparam MVACRI      = 6'b000_110;
    localparam MVACRII     = 6'b000_111;
    localparam MVACTR      = 6'b001_000;
    localparam MVACR       = 6'b001_001;
    localparam MVRIAC      = 6'b001_010;
    localparam MVRIIAC     = 6'b001_011;
    localparam MVTRAC      = 6'b001_100;
    localparam MVRAC       = 6'b001_101;
    localparam INCAR       = 6'b001_110;
    localparam INCR1       = 6'b101_000;
    localparam INCR2       = 6'b101_001;
    localparam LDAC1       = 6'b001_111;
    localparam LDAC2       = 6'b010_000;
    localparam SUB         = 6'b010_001;
    localparam ADD         = 6'b010_011;
    localparam DIV2        = 6'b010_100;
    localparam MUL4        = 6'b010_101;
    localparam JPNZ        = 6'b010_110;
    localparam JPNZY1      = 6'b010_111;
    localparam JPNZN1      = 6'b011_000;
    localparam JPNZN2      = 6'b011_001;
    localparam JPNZN3      = 6'b011_010;
    localparam JPNZNSKIP   = 6'b110_111;
    localparam ADDM1       = 6'b011_011;
    localparam ADDM2       = 6'b011_100;
    localparam ADDMPC      = 6'b110_110;
    localparam NOP         = 6'b111_010;
    localparam END         = 6'b111_100;
    // FLAGS = PCI R1I R2I ARI FET FIN
    // ALU Operation Identifiers
    localparam RESETCBUS = 3'b000;   // [C = 0] and [Z = 0]
    localparam ADDITION  = 3'b001;   // [C = A + B] and [Z = 0]
    localparam SUBSTRACT = 3'b010;   // [C = A - B] and [Z = 1 if A = 0]
    localparam MULTIPLY2 = 3'b100;   // [C = A x 2] and [Z = 0]
    localparam MULTIPLY4 = 3'b101;   // [C = A x 4] and [Z = 0]
    localparam DIVISION2 = 3'b110;   // [C = A / 2] and [Z = 0]
    localparam DIVISION4 = 3'b111;   // [C = A / 4] and [Z = 0]
    localparam GOTHROUGH = 3'b011;   // [C = B] and [Z = 1 if A = 0]
    
    reg [5:0] PRESENT_STAGE;
    // When the program starts, CU starts with FETCH1
    reg [5:0] NEXT_STAGE = FETCH1;
    
    // At each negative clock edge, refresh the current stage
    always @ (negedge CLOCK) PRESENT_STAGE <= NEXT_STAGE;
    // When a stage changes or a flag pops or a new instruction
    always @ (PRESENT_STAGE or FLAGZ or IR)
        case (PRESENT_STAGE)
            FETCH1: /* Reset the Control unit and set next stage to FETCH2 */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b111;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000;
                    NEXT_STAGE <= FETCH2;
                end

            FETCH2: /* Issue a fetch signal to fetch the instruction from IR */
                begin
                    FLAGS <= 6'b000_010;
                    FLAGB <= 3'b111; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= FETCH3; 
                end

            FETCH3: /* Increment PC by 1 and ready for the instruction */
                begin
                    FLAGS <= 6'b100_000;
                    FLAGB <= 3'b110;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= FETCH4; 
                end

            FETCH4: /* Set next stage to the New Instruction */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b110;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= IR[5:0]; 
                end

            CLAC: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b110;
                    ALU <= RESETCBUS;
                    FLAGC <= 8'b0000_0010;
                    NEXT_STAGE <= FETCH1;
                end

            MVACAR: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b1000_0000;
                    NEXT_STAGE <= FETCH1;
                end 

            STAC1: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0001;
                    NEXT_STAGE <= WRITE; 
                end

            WRITE: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0001;
                    NEXT_STAGE <= FETCH1; 
                end 

            MVACRI: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0010_0000;
                    NEXT_STAGE <= FETCH1; 
                end

            MVACRII: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0001_0000;
                    NEXT_STAGE <= FETCH1; 
                end

            MVACTR: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_1000;
                    NEXT_STAGE <= FETCH1; 
                end

            MVACR: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0100;
                    NEXT_STAGE <= FETCH1; 
                end

            MVRIAC: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b001;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0010;
                    NEXT_STAGE <= FETCH1; 
                end

            MVRIIAC: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b010; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0010; 
                    NEXT_STAGE <= FETCH1; 
                end

            MVTRAC: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b011;   
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0010; 
                    NEXT_STAGE <= FETCH1; 
                end

            MVRAC: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b100; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0010; 
                    NEXT_STAGE <= FETCH1; 
                end

            INCAR: /*  */
                begin
                    FLAGS <= 6'b000_100; 
                    FLAGB <= 3'b110;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= FETCH1; 
                end

            INCR1: /*  */
                begin
                    FLAGS <= 6'b010_000;
                    FLAGB <= 3'b110; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= FETCH1; 
                end

            INCR2: /*  */
                begin
                    FLAGS <= 6'b001_000;
                    FLAGB <= 3'b110; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= FETCH1; 
                end

            LDAC1: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b110;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= LDAC2; 
                end
                
            LDAC2: /*  */
                begin
                    FLAGS <= 6'b000_000; 
                    FLAGB <= 3'b110; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010;
                    NEXT_STAGE <= FETCH1; 
                end
               
            ADD: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b100;
                    ALU <= ADDITION;
                    FLAGC <= 8'b00000010;
                    NEXT_STAGE <= FETCH1; 
                end 

            SUB: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b100; 
                    ALU <= SUBSTRACT;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            MUL4: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b110;
                    ALU <= MULTIPLY4;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end

            DIV2: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b110; 
                    ALU <= DIVISION2;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end

            JPNZ: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b110;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    if(FLAGZ)NEXT_STAGE <= JPNZY1; 
                    else NEXT_STAGE <= JPNZN1; 
                end

            JPNZY1: /*  */
                begin
                    FLAGS <= 6'b100_000;
                    FLAGB <= 3'b110; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1; 
                end

            JPNZN1: /*  */
                begin 
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b111;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0000; 
                    NEXT_STAGE <= JPNZN2; 
                end

            JPNZN2: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b111; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b0000_0010;
                    NEXT_STAGE <= JPNZN3; 
                end

            JPNZN3: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b01000000;
                    NEXT_STAGE <= FETCH1; 
                end

            ADDM1: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b000;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= ADDM2; 
                end

            ADDMPC: /*  */
                begin
                    FLAGS <= 6'b100_000;
                    FLAGB <= 3'b010;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1;
                end

            ADDM2: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b111;
                    ALU <= ADDITION;
                    FLAGC <= 8'b00000010;
                    NEXT_STAGE <= ADDMPC; 
                end

            NOP: /*  */
                begin
                    FLAGS <= 6'b000_000;
                    FLAGB <= 3'b101;
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1;
                end

            END: /*  */
                begin
                    FLAGS <= 6'b000_001;
                    FLAGB <= 3'b000; 
                    ALU <= GOTHROUGH; 
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= END;
                end
        endcase
        
endmodule

/*****************************************************************************/
/*********************** TEST BENCH FOR CONTROL UNIT *************************/
/*****************************************************************************/
module testCONTROLUNIT;

    reg CLOCK;
    reg FLAGZ;
    reg [7:0] IR;
    wire [5:0] FLAGS;
    wire [2:0] FLAGB;
    wire [2:0] ALU;
    wire [7:0] FLAGC;
    
    // Constants
    localparam NOP         = 6'b111_010;
    localparam END         = 6'b111_100;

    // Instantiate Control Unit
    CONTROLUNIT UUT(
        .CLOCK(CLOCK),
        .FLAGZ(FLAGZ),
        .IR(IR),
        .FLAGS(FLAGS),
        .FLAGB(FLAGB),
        .ALU(ALU),
        .FLAGC(FLAGC)    
    );
    
    // Clock for simulation purposes
    initial begin
        // Initiate CLOCK reg value
        CLOCK = 1'b0;
        forever begin
            #1 CLOCK = ~CLOCK;
        end
    end
    
    // Initial registers
    initial begin
        FLAGZ = 1'b1;
        IR = 8'b0000_0000;        
    end
    
    // Test
    initial begin
        repeat(5) @(negedge CLOCK);
            IR = {2'b00, NOP};
        repeat(10) @(negedge CLOCK);
            IR = {2'b00, END};
        repeat(10) @(posedge CLOCK);
            $finish;
    end    

endmodule

