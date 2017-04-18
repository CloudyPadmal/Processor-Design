module ALU
(
	input [15:0] BusA,					// Bus line for A - Input
	input [15:0] BusB,					// Bus line for B - Input
	output reg [15:0] BusC,				// Bus line for C - Output
	input [2:0] Operation,				// Busline defining the operation of ALU
	output reg FlagZ						// Z Flag for if else conditions
);

	// Operation Identifiers
	parameter ADDITION 	= 3'b100;	// [C = A + B] and [Z = 0]
	parameter SUBSTRACT	= 3'b101;	// [C = A - B] and [Z = 1 if A = 0]
	parameter MULTIPLY	= 3'b110;	// [C = A x 4] and [Z = 0]
	parameter DIVISION	= 3'b111;	// [C = A / 2] and [Z = 0]
	parameter RESETCBUS	= 3'b000;	// [C = 0] and [Z = 0]
	parameter GOTHROUGH	= 3'b001;	// [C = B] and [Z = 1 if A = 0]
	
	always @ (Operation or BusA or BusB)
		begin
			case (Operation)
				// Addition
				ADDITION:
					begin
						BusC = BusA + BusB;
						FlagZ = 1'b0;
					end
				// Substraction
				SUBSTRACT:
					begin
						BusC = BusA - BusB;
						FlagZ = ((BusA == 16'b0000_0000_0000_0000) ? 1'b1 : 1'b0);
					end
				// Multiplication
				MULTIPLY:
					begin
						BusC = BusA << 2;
						FlagZ = 1'b0;
					end
				// Division
				DIVISION:
					begin
						BusC = BusA >> 1;
						FlagZ = 1'b0;
					end
				// Reset Bus line C
				RESETCBUS:
					begin
						BusC = 16'b0000_0000_0000_0000;
						FlagZ = 1'b0;
					end
				// Go through ALU
				GOTHROUGH:
					begin
						BusC = BusB;
						FlagZ = ((BusA == 16'b0000_0000_0000_0000) ? 1'b1 : 1'b0);
					end
				// Default Case
				default:
					begin
						BusC = 16'b0000_0000_0000_0000;
						FlagZ = 1'b0;
					end
			endcase
		end

endmodule


module testALU;

	// Registers for inputs
	reg [15:0] BusA, BusB;
	reg [2:0] Operation;
	// Output wires
	wire FlagZ;
	wire [15:0] BusC;
	
	ALU UUT(
		.BusA(BusA),
		.BusB(BusB),
		.BusC(BusC),
		.Operation(Operation),
		.FlagZ(FlagZ)	
	);
	
	// Initiate Input bus lines
	initial begin
		BusA = 16'b0000_0000_0000_0000;
		BusB = 16'b0000_0000_0000_0000;
		Operation = 3'b000;
	end
	
	// Run test
	initial begin
		#10 // Addition
			BusA = 16'b0000_0000_0000_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b100;
		#10 // Substraction
			BusA = 16'b0000_0000_1111_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b101;
		#10 // Multiplication
			BusA = 16'b0000_0000_0000_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b110;
		#10 // Division
			BusA = 16'b0000_0000_0000_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b111;
		#10 // Go Through
			BusA = 16'b0000_1100_0011_0011;
			BusB = 16'b0000_1010_0101_0101;
			Operation = 3'b001;
		#10 // Reset C Bus
			BusA = 16'b0000_0000_0000_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b000;
		#10 // Default Cases
			BusA = 16'b0000_0000_0000_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b010;
		#10 // Default Cases
			BusA = 16'b0000_0000_0000_1111;
			BusB = 16'b0000_0000_1111_0000;
			Operation = 3'b011;
	end

endmodule
