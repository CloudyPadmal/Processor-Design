module PROCESSOR
(
    input CLOCK,
    input EN,
    input [7:0] dm_data, im_data,
    output finish,d_write,
    output [15:0] dm_write,
    output [7:0] dm_val,im_addr
);

    wire clk,z,pcinc,r1inc,r2inc,arinc,fetch;
    wire [2:0] bflag,aluop;
    wire [7:0] IR,cflag;
    wire [15:0] bus,PC,R1,R2,TR,R,AC,C_bus;
    
    assign d_write=cflag[0];
    assign dm_val=bus[7:0];
    assign im_addr=PC[7:0];
    
    CONTROLUNIT CUnit(
        clk,
        z,
        IR,
        pcinc,
        r1inc,
        r2inc,
        arinc,
        bflag,
        aluop,
        fetch,
        cflag,
        finish
    ); 
    
    BUSBMUX MUXer(
        bflag,
        PC,
        R1,
        R2,
        TR,
        R,
        AC,
        dm_data,
        im_data,
        bus
    );
  
    ALU ALUnit(AC,bus,aluop,C_bus,z); 
 reg_inc ar(clk,cflag[7],arinc,bus,dm_write); 
 reg_inc pc(clk,cflag[6],pcinc,bus,PC); 
 ir ir(clk,fetch,bus[7:0],IR); 
 reg_inc r1(clk,cflag[5],r1inc,bus,R1); 
 reg_inc r2(clk,cflag[4],r2inc,bus,R2); 
 register tr(clk,cflag[3],bus,TR); 
 register r(clk,cflag[2],bus,R);  
 register ac(clk,cflag[1],C_bus,AC); 

endmodule
