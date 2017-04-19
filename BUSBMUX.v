module BUSBMUX
(
    input [2:0] FLAGB,
    input [15:0] PC,
    input [15:0] R1,
    input [15:0] R2,
    input [15:0] TR,
    input [15:0] R,
    input [15:0] AC,
    input [7:0] DM,
    input [7:0] IM,
    output reg [15:0] BUSB
);

    always @ (FLAGB or PC or R1 or R2 or TR or R or AC or DM or IM)
        begin
            case (FLAGB)
                3'd0:
                    BUSB = PC;
                3'd1:
                    BUSB = R1;
                3'd2:
                    BUSB = R2;
                3'd3:
                    BUSB = TR;
                3'd4:
                    BUSB = R;
                3'd5:
                    BUSB = AC;
                3'd6:
                    BUSB = {8'b00000000, DM};
                3'd7:
                    BUSB = {8'b00000000, IM};
            endcase
        end
    
endmodule
