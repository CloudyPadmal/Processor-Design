module CONTROLUNIT
(
    input CLOCK,
    input FLAGZ,
    input [7:0] IR,
    output reg PCINCREMENT,
    output reg R1INCREMENT,
    output reg R2INCREMENT,
    output reg ARINCREMENT,
    output reg FETCH,
    output reg FINISH = 0,
    output reg [2:0] FLAGB,
    output reg [2:0] ALU,    
    output reg [7:0] FLAGC
);

    // Constants
    localparam FETCH1      = 6'b000_000;
    localparam FETCH2      = 6'b000_001;
    localparam FETCH3      = 6'b000_010;
    localparam FETCH4      = 6'd57;
    localparam CLAC        = 6'd3;
    localparam MVACAR      = 6'd59;
    localparam STAC1       = 6'd4;
    localparam WRITE       = 6'd53;
    localparam MVACRI      = 6'd6;
    localparam MVACRII     = 6'd7;
    localparam MVACTR      = 6'd8;
    localparam MVACR       = 6'd9;
    localparam MVRIAC      = 6'd10;
    localparam MVRIIAC     = 6'd11;
    localparam MVTRAC      = 6'd12;
    localparam MVRAC       = 6'd13;
    localparam INCAR       = 6'd14;
    localparam INCR1       = 6'd40;
    localparam INCR2       = 6'd41;
    localparam LDAC1       = 6'd15;
    localparam LDAC2       = 6'd16;
    localparam SUB         = 6'd17;
    localparam ADD         = 6'd19;
    localparam DIV2        = 6'd20;
    localparam MUL4        = 6'd21;
    localparam JPNZ        = 6'd22;
    localparam JPNZY1      = 6'd23;
    localparam JPNZN1      = 6'd24;
    localparam JPNZN2      = 6'd25;
    localparam JPNZN3      = 6'd26;
    localparam JPNZNSKIP   = 6'd55;
    localparam ADDM1       = 6'd27;
    localparam ADDM2       = 6'd28;
    localparam ADDMPC      = 6'd54;
    localparam NOP         = 6'd58;
    localparam END         = 6'd60;
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
            FETCH1:
                begin
                    PCINCREMENT <= 0;
                    R1INCREMENT <= 0;
                    R2INCREMENT <= 0;
                    ARINCREMENT <= 0;
                    FETCH <= 0;
                    FINISH <= 0;
                    FLAGB <= 3'b111; //im
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000;
                    NEXT_STAGE <= FETCH2;
                end
                
            FETCH2:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;   
                    ARINCREMENT <= 0; 
                    FETCH <= 1; //IR
                    FINISH <= 0; 
                    FLAGB <= 3'b111; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH3; 
                end
                
            FETCH3:
                begin
                    PCINCREMENT <= 1; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'b110;//dm 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH4; 
                end
                
            FETCH4:
                begin
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'b110;//dm 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= IR[5:0]; 
                end
                
            CLAC:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6;//dm 
                    ALU <= RESETCBUS;
                    FLAGC <= 8'b00000010;//ac 
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVACAR:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; //ac
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b10000000;//ar 
                    NEXT_STAGE <= FETCH1; 
                end 
                    
            STAC1:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5;//ac 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000001;//dm 
                    NEXT_STAGE <= WRITE; 
                end
                
            WRITE:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; //ac
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000001; //dm
                    NEXT_STAGE <= FETCH1; 
                end 

            MVACRI:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; //ac
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00100000; //r1
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVACRII:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00010000; //r2
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVACTR:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0;  
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00001000; //tr
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVACR:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000100; //r
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVRIAC:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0;  
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd1;//r1 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010;//ac 
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVRIIAC:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd2; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVTRAC:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd3;   
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            MVRAC:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd4; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            INCAR:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 1; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; //dm
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            INCR1:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 1; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            INCR2:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 1; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1; 
                end

            LDAC1:
                begin
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; //dm
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= LDAC2; 
                end
                
            LDAC2:
                begin
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010; //ac
                    NEXT_STAGE <= FETCH1; 
                end
               
            ADD:
                begin
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd4; //r
                    ALU <= ADDITION;
                    FLAGC <= 8'b00000010; //ac
                    NEXT_STAGE <= FETCH1; 
                end 

            SUB:
                begin
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0;   
                    FETCH <= 0;   
                    FINISH <= 0; 
                    FLAGB <= 3'd4; 
                    ALU <= SUBSTRACT;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            MUL4:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; //dm
                    ALU <= MULTIPLY4;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end

            DIV2:
                begin
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; 
                    ALU <= DIVISION2;
                    FLAGC <= 8'b00000010; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            JPNZ:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; //dm
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    if(FLAGZ)NEXT_STAGE <= JPNZY1; 
                    else NEXT_STAGE <= JPNZN1; 
                end
                
            JPNZY1:
                begin 
                    PCINCREMENT <= 1; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1; 
                end
                
            JPNZN1:
                begin 
                    PCINCREMENT <= 0;  
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd7; //im
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= JPNZN2; 
                end
                
            JPNZN2:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd7; 
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000010; //ac
                    NEXT_STAGE <= JPNZN3; 
                end
                
            JPNZN3:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd5; //ac
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b01000000; //pc
                    NEXT_STAGE <= FETCH1; 
                end
                
            ADDM1:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd0; //pc
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= ADDM2; 
                end
                    
            ADDMPC:
                begin //
                    PCINCREMENT <= 1; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0;  
                    FLAGB <= 3'd2; //r2?
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1;
                end
                
            ADDM2:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd7; //im
                    ALU <= ADDITION;
                    FLAGC <= 8'b00000010; //ac
                    NEXT_STAGE <= ADDMPC; 
                end
                    
            NOP:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0; 
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 0; 
                    FLAGB <= 3'd6; //dm
                    ALU <= GOTHROUGH;
                    FLAGC <= 8'b00000000; 
                    NEXT_STAGE <= FETCH1;
                end
                
            END:
                begin 
                    PCINCREMENT <= 0; 
                    R1INCREMENT <= 0; 
                    R2INCREMENT <= 0;  
                    ARINCREMENT <= 0; 
                    FETCH <= 0; 
                    FINISH <= 1; 
                    FLAGB <= 3'd0; 
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
    wire PCINCREMENT;
    wire R1INCREMENT;
    wire R2INCREMENT;
    wire ARINCREMENT;
    wire FETCH;
    wire FINISH;
    wire [2:0] FLAGB;
    wire [2:0] ALU;
    wire [7:0] FLAGC;
    
    // Constants
    localparam FETCH1      = 6'b000_000;
    localparam FETCH2      = 6'b000_001;
    localparam FETCH3      = 6'b000_010;
    localparam FETCH4      = 6'd57;
    localparam CLAC        = 6'd3;
    localparam MVACAR      = 6'd59;
    localparam STAC1       = 6'd4;
    localparam WRITE       = 6'd53;
    localparam MVACRI      = 6'd6;
    localparam MVACRII     = 6'd7;
    localparam MVACTR      = 6'd8;
    localparam MVACR       = 6'd9;
    localparam MVRIAC      = 6'd10;
    localparam MVRIIAC     = 6'd11;
    localparam MVTRAC      = 6'd12;
    localparam MVRAC       = 6'd13;
    localparam INCAR       = 6'd14;
    localparam INCR1       = 6'd40;
    localparam INCR2       = 6'd41;
    localparam LDAC1       = 6'd15;
    localparam LDAC2       = 6'd16;
    localparam SUB         = 6'd17;
    localparam ADD         = 6'd19;
    localparam DIV2        = 6'd20;
    localparam MUL4        = 6'd21;
    localparam JPNZ        = 6'd22;
    localparam JPNZY1      = 6'd23;
    localparam JPNZN1      = 6'd24;
    localparam JPNZN2      = 6'd25;
    localparam JPNZN3      = 6'd26;
    localparam JPNZNSKIP   = 6'd55;
    localparam ADDM1       = 6'd27;
    localparam ADDM2       = 6'd28;
    localparam ADDMPC      = 6'd54;
    localparam NOP         = 6'd58;
    localparam END         = 6'd60;

    // Instantiate Control Unit
    CONTROLUNIT UUT(
        .CLOCK(CLOCK),
        .FLAGZ(FLAGZ),
        .IR(IR),
        .PCINCREMENT(PCINCREMENT),
        .R1INCREMENT(R1INCREMENT),
        .R2INCREMENT(R2INCREMENT),
        .ARINCREMENT(ARINCREMENT),
        .FETCH(FETCH),
        .FINISH(FINISH),
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
        FLAGZ = 1'b0;
        IR = 8'b0000_0000;        
    end
    
    // Test
    initial begin
        repeat(10) @(negedge CLOCK);
            IR = 8'b0000_1100;
        repeat(10) @(posedge CLOCK);
            $finish;
    end
    

endmodule

