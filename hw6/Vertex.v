`include "global_def.h"
  
module Vertex(
  
  /* inputs */
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_Opcode,
  I_Src1Value,
  I_Src2Value,
  I_DestRegIdx,
  I_Imm,
  I_DestValue,
  I_FetchStall,
  I_DepStall,
  
  I_Type, 
  
  // vectors
  I_DestValueV,
  
  /* outputs */
  O_LOCK,
  O_ALUOut,
  O_Opcode,
  O_DestRegIdx,
  O_DestValue,
  O_FetchStall,
  O_DepStall
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the decode stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input I_FetchStall;
input I_DepStall;

input [`REG_WIDTH-1:0] I_Imm;

// scalar
input [3:0] I_DestRegIdx;
input [`REG_WIDTH-1:0] I_Src1Value;
input [`REG_WIDTH-1:0] I_Src2Value;
input [`REG_WIDTH-1:0] I_DestValue;

// vector
input [5:0] I_DestRegIdxV;
input [1:0] I_DestRegIdxV_Idx;
input [`VREG_WIDTH-1:0] I_Src1ValueV;
input [`VREG_WIDTH-1:0] I_Src2ValueV;
input [`VREG_WIDTH-1:0] I_DestValueV;

// GPU
input [3:0] O_Type;

// Outputs to the memory stage
output reg O_LOCK;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg O_FetchStall;
output reg O_DepStall;

// scalar
output reg [`REG_WIDTH-1:0] O_ALUOut;
output reg [3:0] O_DestRegIdx;
output reg [`REG_WIDTH-1:0] O_DestValue;

// vector
output reg [`VREG_WIDTH-1:0] O_ALUOutV;
output reg [`VREG_WIDTH-1:0] O_DestValueV;
output reg [5:0] O_DestRegIdxV;
output reg [1:0] O_DestRegIdxV_Idx;

// GPU
output reg [3:0] O_Type;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//

// rotation
// [  cos(theta)  sin(theta)     0          0 ]
// | -sin(theta)  cos(theta)     0          0 |
// |      0           0          0          0 |
// [      0           0          0          0 ]

// angle
wire [15:0] Theta;
wire [15:0] Z_Coordinate;

assign Theta = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_DestValueV[`VREG_WIDTH-1:48]
				): (16'h0000)	
			): (16'h0000) // end I_DepStall
		): (16'h0000) // end I_FetchStall
	): (16'h0000); // end I_LOCK

assign Z_Coordinate = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_DestValueV[15:0]
				): (16'h0000)	
			): (16'h0000) // end I_DepStall
		): (16'h0000) // end I_FetchStall
	): (16'h0000); // end I_LOCK

	
	
// sine and cosine
wire[15:0] Sine_Value;   // odd, 
wire[15:0] Cosine_Value; // even, ignore sine: Theta[14:7]

assign Sine_Value = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_DestValueV[15:0]
				): (16'h0000)	
			): (16'h0000) // end I_DepStall
		): (16'h0000) // end I_FetchStall
	): (16'h0000); // end I_LOCK

// cosine even
// cos(theta) = cos (-theta)	

assign Cosine_Value = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					// in 1.8.7 format up to 2 decimal places
					(Theta[14:7]==8'h00) ? 16'h0080 : // 1.00
					(Theta[14:7]==8'h01) ? 16'h0080 :
					(Theta[14:7]==8'h02) ? 16'h0080 :
					(Theta[14:7]==8'h03) ? 16'h0080 :
					(Theta[14:7]==8'h04) ? 16'h0080 :
					(Theta[14:7]==8'h05) ? 16'h0080 :
					(Theta[14:7]==8'h06) ? 16'h0063 : // 0.99
					(Theta[14:7]==8'h07) ? 16'h0063 :
					(Theta[14:7]==8'h08) ? 16'h0063 :
					(Theta[14:7]==8'h09) ? 16'h0063 :
					(Theta[14:7]==8'h0A) ? 16'h0062 :
					(Theta[14:7]==8'h0B) ? 16'h0062 :
					(Theta[14:7]==8'h0C) ? 16'h0062 :
					(Theta[14:7]==8'h0D) ? 16'h0061 :
					(Theta[14:7]==8'h0E) ? 16'h0061 :
					(Theta[14:7]==8'h0F) ? 16'h0061 :
					(Theta[14:7]==8'h10) ? 16'h0060 :
					(Theta[14:7]==8'h11) ? 16'h0060 :
					(Theta[14:7]==8'h12) ? 16'h005F :
					(Theta[14:7]==8'h13) ? 16'h005F :
					(Theta[14:7]==8'h14) ? 16'h005E :
					(Theta[14:7]==8'h15) ? 16'h005D :
					(Theta[14:7]==8'h16) ? 16'h005D :
					(Theta[14:7]==8'h17) ? 16'h005C :
					(Theta[14:7]==8'h18) ? 16'h005B :
					(Theta[14:7]==8'h19) ? 16'h005B :
					(Theta[14:7]==8'h1A) ? 16'h005A :
					(Theta[14:7]==8'h1B) ? 16'h0059 :
					(Theta[14:7]==8'h1C) ? 16'h0058 :
					(Theta[14:7]==8'h1D) ? 16'h0057 :
					(Theta[14:7]==8'h1E) ? 16'h0057 :
					(Theta[14:7]==8'h1F) ? 16'h0056 :
					(Theta[14:7]==8'h20) ? 16'h0055 :
					(Theta[14:7]==8'h21) ? 16'h0054 :
					(Theta[14:7]==8'h22) ? 16'h0053 :
					(Theta[14:7]==8'h23) ? 16'h0052 :
					(Theta[14:7]==8'h24) ? 16'h0051 :
					(Theta[14:7]==8'h25) ? 16'h0050 :
					(Theta[14:7]==8'h26) ? 16'h004F :
					(Theta[14:7]==8'h27) ? 16'h004E :
					(Theta[14:7]==8'h28) ? 16'h004D :
					(Theta[14:7]==8'h29) ? 16'h004B :
					(Theta[14:7]==8'h2A) ? 16'h004A :
					(Theta[14:7]==8'h2B) ? 16'h0049 :
					(Theta[14:7]==8'h2C) ? 16'h0048 :
					(Theta[14:7]==8'h2D) ? 16'h0047 :
					(Theta[14:7]==8'h2E) ? 16'h0045 :
					(Theta[14:7]==8'h2F) ? 16'h0044 :
					(Theta[14:7]==8'h30) ? 16'h0043 :
					(Theta[14:7]==8'h31) ? 16'h0042 :
					(Theta[14:7]==8'h32) ? 16'h0040 :
					(Theta[14:7]==8'h33) ? 16'h003F :
					(Theta[14:7]==8'h34) ? 16'h003E :
					(Theta[14:7]==8'h35) ? 16'h003C :
					(Theta[14:7]==8'h36) ? 16'h003B :
					(Theta[14:7]==8'h37) ? 16'h0039 :
					(Theta[14:7]==8'h38) ? 16'h0038 :
					(Theta[14:7]==8'h39) ? 16'h0036 :
					(Theta[14:7]==8'h3A) ? 16'h0035 :
					(Theta[14:7]==8'h3B) ? 16'h0034 :
					(Theta[14:7]==8'h3C) ? 16'h0032 :
					(Theta[14:7]==8'h3D) ? 16'h0030 :
					(Theta[14:7]==8'h3E) ? 16'h002F :
					(Theta[14:7]==8'h3F) ? 16'h002D :
					(Theta[14:7]==8'h40) ? 16'h002C :
					(Theta[14:7]==8'h41) ? 16'h002A :
					(Theta[14:7]==8'h42) ? 16'h0029 :
					(Theta[14:7]==8'h43) ? 16'h0027 :
					(Theta[14:7]==8'h44) ? 16'h0025 :
					(Theta[14:7]==8'h45) ? 16'h0024 :
					(Theta[14:7]==8'h46) ? 16'h0022 :
					(Theta[14:7]==8'h47) ? 16'h0021 :
					(Theta[14:7]==8'h48) ? 16'h001F :
					(Theta[14:7]==8'h49) ? 16'h001D :
					(Theta[14:7]==8'h4A) ? 16'h001C :
					(Theta[14:7]==8'h4B) ? 16'h001A :
					(Theta[14:7]==8'h4C) ? 16'h0018 :
					(Theta[14:7]==8'h4D) ? 16'h0016 :
					(Theta[14:7]==8'h4E) ? 16'h0015 :
					(Theta[14:7]==8'h4F) ? 16'h0013 :
					(Theta[14:7]==8'h50) ? 16'h0011 :
					(Theta[14:7]==8'h51) ? 16'h0010 :
					(Theta[14:7]==8'h52) ? 16'h000E :
					(Theta[14:7]==8'h53) ? 16'h000C :
					(Theta[14:7]==8'h54) ? 16'h000A :
					(Theta[14:7]==8'h55) ? 16'h0009 :
					(Theta[14:7]==8'h56) ? 16'h0007 :
					(Theta[14:7]==8'h57) ? 16'h0005 :
					(Theta[14:7]==8'h58) ? 16'h0003 :
					(Theta[14:7]==8'h59) ? 16'h0002 :
					(Theta[14:7]==8'h5A) ? 16'h0000 :
					(Theta[14:7]==8'h5B) ? 16'h8002 :
					(Theta[14:7]==8'h5C) ? 16'h8003 :
					(Theta[14:7]==8'h5D) ? 16'h8005 :
					(Theta[14:7]==8'h5E) ? 16'h8007 :
					(Theta[14:7]==8'h5F) ? 16'h8009 :
					(Theta[14:7]==8'h60) ? 16'h800A :
					(Theta[14:7]==8'h61) ? 16'h800C :
					(Theta[14:7]==8'h62) ? 16'h800E :
					(Theta[14:7]==8'h63) ? 16'h8010 :
					(Theta[14:7]==8'h64) ? 16'h8011 :
					(Theta[14:7]==8'h65) ? 16'h8013 :
					(Theta[14:7]==8'h66) ? 16'h8015 :
					(Theta[14:7]==8'h67) ? 16'h8016 :
					(Theta[14:7]==8'h68) ? 16'h8018 :
					(Theta[14:7]==8'h69) ? 16'h801A :
					(Theta[14:7]==8'h6A) ? 16'h801C :
					(Theta[14:7]==8'h6B) ? 16'h801D :
					(Theta[14:7]==8'h6C) ? 16'h801F :
					(Theta[14:7]==8'h6D) ? 16'h8021 :
					(Theta[14:7]==8'h6E) ? 16'h8022 :
					(Theta[14:7]==8'h6F) ? 16'h8024 :
					(Theta[14:7]==8'h70) ? 16'h8025 :
					(Theta[14:7]==8'h71) ? 16'h8027 :
					(Theta[14:7]==8'h72) ? 16'h8029 :
					(Theta[14:7]==8'h73) ? 16'h802A :
					(Theta[14:7]==8'h74) ? 16'h802C :
					(Theta[14:7]==8'h75) ? 16'h802D :
					(Theta[14:7]==8'h76) ? 16'h802F :
					(Theta[14:7]==8'h77) ? 16'h8030 :
					(Theta[14:7]==8'h78) ? 16'h8032 :
					(Theta[14:7]==8'h79) ? 16'h8034 :
					(Theta[14:7]==8'h7A) ? 16'h8035 :
					(Theta[14:7]==8'h7B) ? 16'h8036 :
					(Theta[14:7]==8'h7C) ? 16'h8038 :
					(Theta[14:7]==8'h7D) ? 16'h8039 :
					(Theta[14:7]==8'h7E) ? 16'h803B :
					(Theta[14:7]==8'h7F) ? 16'h803C :
					(Theta[14:7]==8'h80) ? 16'h803E :
					(Theta[14:7]==8'h81) ? 16'h803F :
					(Theta[14:7]==8'h82) ? 16'h8040 :
					(Theta[14:7]==8'h83) ? 16'h8042 :
					(Theta[14:7]==8'h84) ? 16'h8043 :
					(Theta[14:7]==8'h85) ? 16'h8044 :
					(Theta[14:7]==8'h86) ? 16'h8045 :
					(Theta[14:7]==8'h87) ? 16'h8047 :
					(Theta[14:7]==8'h88) ? 16'h8048 :
					(Theta[14:7]==8'h89) ? 16'h8049 :
					(Theta[14:7]==8'h8A) ? 16'h804A :
					(Theta[14:7]==8'h8B) ? 16'h804B :
					(Theta[14:7]==8'h8C) ? 16'h804D :
					(Theta[14:7]==8'h8D) ? 16'h804E :
					(Theta[14:7]==8'h8E) ? 16'h804F :
					(Theta[14:7]==8'h8F) ? 16'h8050 :
					(Theta[14:7]==8'h90) ? 16'h8051 :
					(Theta[14:7]==8'h91) ? 16'h8052 :
					(Theta[14:7]==8'h92) ? 16'h8053 :
					(Theta[14:7]==8'h93) ? 16'h8054 :
					(Theta[14:7]==8'h94) ? 16'h8055 :
					(Theta[14:7]==8'h95) ? 16'h8056 :
					(Theta[14:7]==8'h96) ? 16'h8057 :
					(Theta[14:7]==8'h97) ? 16'h8057 :
					(Theta[14:7]==8'h98) ? 16'h8058 :
					(Theta[14:7]==8'h99) ? 16'h8059 :
					(Theta[14:7]==8'h9A) ? 16'h805A :
					(Theta[14:7]==8'h9B) ? 16'h805B :
					(Theta[14:7]==8'h9C) ? 16'h805B :
					(Theta[14:7]==8'h9D) ? 16'h805C :
					(Theta[14:7]==8'h9E) ? 16'h805D :
					(Theta[14:7]==8'h9F) ? 16'h805D :
					(Theta[14:7]==8'hA0) ? 16'h805E :
					(Theta[14:7]==8'hA1) ? 16'h805F :
					(Theta[14:7]==8'hA2) ? 16'h805F :
					(Theta[14:7]==8'hA3) ? 16'h8060 :
					(Theta[14:7]==8'hA4) ? 16'h8060 :
					(Theta[14:7]==8'hA5) ? 16'h8061 :
					(Theta[14:7]==8'hA6) ? 16'h8061 :
					(Theta[14:7]==8'hA7) ? 16'h8061 :
					(Theta[14:7]==8'hA8) ? 16'h8062 :
					(Theta[14:7]==8'hA9) ? 16'h8062 :
					(Theta[14:7]==8'hAA) ? 16'h8062 :
					(Theta[14:7]==8'hAB) ? 16'h8063 :
					(Theta[14:7]==8'hAC) ? 16'h8063 :
					(Theta[14:7]==8'hAD) ? 16'h8063 :
					(Theta[14:7]==8'hAE) ? 16'h8063 :
					(Theta[14:7]==8'hAF) ? 16'h8064 :
					(Theta[14:7]==8'hB0) ? 16'h8064 :
					(Theta[14:7]==8'hB1) ? 16'h8064 :
					(Theta[14:7]==8'hB2) ? 16'h8064 :
					(Theta[14:7]==8'hB3) ? 16'h8064 :
					(Theta[14:7]==8'hB4) ? 16'h8064 :
					(Theta[14:7]==8'hB5) ? 16'h8064 :
					(Theta[14:7]==8'hB6) ? 16'h8064 :
					(Theta[14:7]==8'hB7) ? 16'h8064 :
					(Theta[14:7]==8'hB8) ? 16'h8064 :
					(Theta[14:7]==8'hB9) ? 16'h8064 :
					(Theta[14:7]==8'hBA) ? 16'h8063 :
					(Theta[14:7]==8'hBB) ? 16'h8063 :
					(Theta[14:7]==8'hBC) ? 16'h8063 :
					(Theta[14:7]==8'hBD) ? 16'h8063 :
					(Theta[14:7]==8'hBE) ? 16'h8062 :
					(Theta[14:7]==8'hBF) ? 16'h8062 :
					(Theta[14:7]==8'hC0) ? 16'h8062 :
					(Theta[14:7]==8'hC1) ? 16'h8061 :
					(Theta[14:7]==8'hC2) ? 16'h8061 :
					(Theta[14:7]==8'hC3) ? 16'h8061 :
					(Theta[14:7]==8'hC4) ? 16'h8060 :
					(Theta[14:7]==8'hC5) ? 16'h8060 :
					(Theta[14:7]==8'hC6) ? 16'h805F :
					(Theta[14:7]==8'hC7) ? 16'h805F :
					(Theta[14:7]==8'hC8) ? 16'h805E :
					(Theta[14:7]==8'hC9) ? 16'h805D :
					(Theta[14:7]==8'hCA) ? 16'h805D :
					(Theta[14:7]==8'hCB) ? 16'h805C :
					(Theta[14:7]==8'hCC) ? 16'h805B :
					(Theta[14:7]==8'hCD) ? 16'h805B :
					(Theta[14:7]==8'hCE) ? 16'h805A :
					(Theta[14:7]==8'hCF) ? 16'h8059 :
					(Theta[14:7]==8'hD0) ? 16'h8058 :
					(Theta[14:7]==8'hD1) ? 16'h8057 :
					(Theta[14:7]==8'hD2) ? 16'h8057 :
					(Theta[14:7]==8'hD3) ? 16'h8056 :
					(Theta[14:7]==8'hD4) ? 16'h8055 :
					(Theta[14:7]==8'hD5) ? 16'h8054 :
					(Theta[14:7]==8'hD6) ? 16'h8053 :
					(Theta[14:7]==8'hD7) ? 16'h8052 :
					(Theta[14:7]==8'hD8) ? 16'h8051 :
					(Theta[14:7]==8'hD9) ? 16'h8050 :
					(Theta[14:7]==8'hDA) ? 16'h804F :
					(Theta[14:7]==8'hDB) ? 16'h804E :
					(Theta[14:7]==8'hDC) ? 16'h804D :
					(Theta[14:7]==8'hDD) ? 16'h804B :
					(Theta[14:7]==8'hDE) ? 16'h804A :
					(Theta[14:7]==8'hDF) ? 16'h8049 :
					(Theta[14:7]==8'hE0) ? 16'h8048 :
					(Theta[14:7]==8'hE1) ? 16'h8047 :
					(Theta[14:7]==8'hE2) ? 16'h8045 :
					(Theta[14:7]==8'hE3) ? 16'h8044 :
					(Theta[14:7]==8'hE4) ? 16'h8043 :
					(Theta[14:7]==8'hE5) ? 16'h8042 :
					(Theta[14:7]==8'hE6) ? 16'h8040 :
					(Theta[14:7]==8'hE7) ? 16'h803F :
					(Theta[14:7]==8'hE8) ? 16'h803E :
					(Theta[14:7]==8'hE9) ? 16'h803C :
					(Theta[14:7]==8'hEA) ? 16'h803B :
					(Theta[14:7]==8'hEB) ? 16'h8039 :
					(Theta[14:7]==8'hEC) ? 16'h8038 :
					(Theta[14:7]==8'hED) ? 16'h8036 :
					(Theta[14:7]==8'hEE) ? 16'h8035 :
					(Theta[14:7]==8'hEF) ? 16'h8034 :
					(Theta[14:7]==8'hF0) ? 16'h8032 :
					(Theta[14:7]==8'hF1) ? 16'h8030 :
					(Theta[14:7]==8'hF2) ? 16'h802F :
					(Theta[14:7]==8'hF3) ? 16'h802D :
					(Theta[14:7]==8'hF4) ? 16'h802C :
					(Theta[14:7]==8'hF5) ? 16'h802A :
					(Theta[14:7]==8'hF6) ? 16'h8029 :
					(Theta[14:7]==8'hF7) ? 16'h8027 :
					(Theta[14:7]==8'hF8) ? 16'h8025 :
					(Theta[14:7]==8'hF9) ? 16'h8024 :
					(Theta[14:7]==8'hFA) ? 16'h8022 :
					(Theta[14:7]==8'hFB) ? 16'h8021 :
					(Theta[14:7]==8'hFC) ? 16'h801F :
					(Theta[14:7]==8'hFD) ? 16'h801D :
					(Theta[14:7]==8'hFE) ? 16'h801C :
					(Theta[14:7]==8'hFF) ? 16'h801A : (16'h0000)
				): (16'h0000)	
			): (16'h0000) // end I_DepStall
		): (16'h0000) // end I_FetchStall
	): (16'h0000); // end I_LOCK

// [ [255:240] [239:224] [223:208] [207:192] ]
// | [191:176] [175:160] [159:144] [143:128] |
// | [127:112] [111:96 ] [ 95:80 ] [ 79:64 ] |
// [ [ 63:48 ] [ 47:32 ] [ 31:16 ] [ 15:0  ] ]

wire [255:0] Attribute_Matrix;
wire [255:0] Rotate_Matrix;
wire [255:0] Scale_Matrix;
wire [255:0] Translate_Matrix;

assign Rotate_Matrix = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_ROTATE) ? 
				(
					// logic goes here
				): (`ID_MATRIX)
				
			): (`ID_MATRIX) // end I_DepStall
		): (`ID_MATRIX) // end I_FetchStall
	): (`ID_MATRIX); // end I_LOCK

assign Scale_Matrix = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_SCALE) ? 
				(
					// logic goes here
				): (`ID_MATRIX)
				
			): (`ID_MATRIX) // end I_DepStall
		): (`ID_MATRIX) // end I_FetchStall
	): (`ID_MATRIX); // end I_LOCK

assign Translate_Matrix = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_TRANSLATE) ? 
				(
					// logic goes here
				): (`ID_MATRIX)
				
			): (`ID_MATRIX) // end I_DepStall
		): (`ID_MATRIX) // end I_FetchStall
	): (`ID_MATRIX); // end I_LOCK	


// [x] [63:48] 
// |y| [47:32]
// |z| [31:16] 0
//	[a] [15:0 ] 0
wire [63:0] Vertex_Vector;
assign Vertex_Vector = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_SETVERTEX) ? 
				(
					// logic goes here
				): (`VERTEX_INIT)
				
			): (`VERTEX_INIT) // end I_DepStall
		): (`VERTEX_INIT) // end I_FetchStall
	): (`VERTEX_INIT); // end I_LOCK	

	
/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  // O_FetchStall <= I_FetchStall;

  if (I_LOCK == 1'b1) 
  begin
    	 
	  if (I_FetchStall==1'b0 && I_DepStall==1'b0) begin
	 
		O_DestValue <= I_DestValue;
	   O_DestRegIdx <= I_DestRegIdx;
	   O_Opcode <= I_Opcode;
		O_DepStall <= 1'b0;
		O_FetchStall <= 1'b0;
	 
	   case (I_Opcode)
		  	// GPU 
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_BEGINPRIMITIVE:
			begin
				O_Type <= I_IR[19:16];
			end
		endcase
			 
	 end // if (I_FetchStall==1'b0 && I_DepStall==1'b0)
	 else O_DepStall <= 1'b1;
	 
  end // if (I_LOCK == 1'b1)
  else O_FetchStall <= 1'b1;
  
end // always @(negedge I_CLOCK)

endmodule // module Vertex
