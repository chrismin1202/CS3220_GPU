`include "global_def.h"
  
module Geometry(
  
  /* inputs */
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_Opcode,
  I_FetchStall,
  I_DepStall,
  
  I_Type, 
  
  // vectors
  I_VR,
  
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

input [`VREG_WIDTH-1:0] I_VR;

input [3:0] I_Type;

output reg O_LOCK;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg O_FetchStall;
output reg O_DepStall;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//

// 16 bit in 1.8.7 format
reg[`DATA_WIDTH-1:0] SinTable[0:72];
reg[`DATA_WIDTH-1:0] CosTable[0:72];

reg[`VREG_WIDTH-1:0] Vertex_Array[1:0];
reg[1:0] Vertex_CurrIdx; // keep track of up to 3 vertices
reg[1:0] Num_Vertices;   // if Opcode == ENDPRIMITIVE, Num_vertices = Vertex_CurrIdx

// wire[`MATRIX_SIZE-1:0] Vertex_Curr;

// signals
reg _BeginPrimitive;
reg _EndPrimitive;
reg _PushMatrix;
reg _PopMatrix;

// matrix
reg [255:0] Matrix_Curr;

// angle
wire [7:0] Angle; // 8 bit integer 
wire Z_Value; // sign (since it's fixed point, only bit-15 matters)
	
// sine and cosine
wire[15:0] Sine_Value;   // odd, 
wire[15:0] Cosine_Value; // even, ignore sine: Theta[14:7]



wire [255:0] Attribute_Matrix;
wire [255:0] Rotate_Matrix;
wire [255:0] Scale_Matrix;
wire [255:0] Translate_Matrix;
wire [63:0] Vertex_Vector;


// set colors
wire Color1_Set;
wire Color2_Set;
wire Color3_Set;

wire [1:0] Color1_Count;
wire [1:0] Color2_Count;
wire [1:0] Color3_Count;

wire [11:0] T1C1R;
wire [11:0] T1C1G;
wire [11:0] T1C1B;
wire [11:0] T1C2R;
wire [11:0] T1C2G;
wire [11:0] T1C2B;
wire [11:0] T1C3R;
wire [11:0] T1C3G;
wire [11:0] T1C3B;

wire [11:0] T2C1R;
wire [11:0] T2C1G;
wire [11:0] T2C1B;
wire [11:0] T2C2R;
wire [11:0] T2C2G;
wire [11:0] T2C2B;
wire [11:0] T2C3R;
wire [11:0] T2C3G;
wire [11:0] T2C3B;

wire [11:0] T3C1R;
wire [11:0] T3C1G;
wire [11:0] T3C1B;
wire [11:0] T3C2R;
wire [11:0] T3C2G;
wire [11:0] T3C2B;
wire [11:0] T3C3R;
wire [11:0] T3C3G;
wire [11:0] T3C3B;

// translate

// scale

// matrix
	
/////////////////////////////////////////
// INITIAL STATEMENT GOES HERE
/////////////////////////////////////////
//
initial 
begin
  $readmemh("sine_table.hex", SinTable);
  $readmemh("cosine_table.hex", CosTable);
  
  Triangle1_Set = 1'b0;
  Triangle2_Set = 1'b0;
  Triangle3_Set = 1'b0;

  Triangle1_Vertex_Count = 2'b0;
  Triangle2_Vertex_Count = 2'b0;
  Triangle3_Vertex_Count = 2'b0;
  
  _BeginPrimitive = 1'b0;
  
  
end


/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
//

// vector
//
// [ elmt0 ] => [ 15:0  ]
// | elmt1 | => | 31:16 |
// | elmt2 | => | 47:32 |
// [ elmt3 ] => [ 63:48 ]

// ############
// ## ROTATE ##		  
// ############

assign Z_Value = // vr[3]
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_VR[63]
				): (1'bX)	
			): (1'bX) // end I_DepStall
		): (1'bX) // end I_FetchStall
	): (1'bX); // end I_LOCK

// assume Anlge = [0,36]
assign Angle = // vr[0] 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_DestValueV[14:7]; // grab 8 int bits from 15:0
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK


// index the trig tables using Z_Value and Angle 
// if      Angle == 0,   index == Angle
// else if Z_Value == 1, index == Angle + 36
// else                  index == Angle
	
assign Sine_Value = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					(Angle==8'h0) ?
					(
						SinTable[Angle]
					): 
					(Z_Value==1'b1) ?
					(
						SinTable[Angle+36]
					): (SinTable[Angle])
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK

assign Cosine_Value = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					(Angle==8'h0) ?
					(
						CosTable[Angle]
					): 
					(Z_Value==1'b1) ?
					(
						CosTable[Angle+36]
					): (CosTable[Angle])
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK

	
// ##################
// ## SET VERTICES ##		  
// ##################

// Matrix Assignments
// 	
// [ [ 15:0  ] [ 31:16 ] [ 47:32 ] [ 63:48 ] ]
// | [ 79:64 ] [ 95:80 ] [111:96 ] [127:112] |
// | [143:128] [159:144] [175:160] [191:176] |
// [ [207:192] [223:208] [239:224] [255:240] ]

// The value of vr[1]: X coordinate
// The value of vr[2]: Y coordinate
// The value of vr[3]: Z coordinate
assign Vertex_Curr = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_SETVERTEX) ? 
				(
					
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK



// ################
// ## SET COLORS ##		  
// ################



// ###############
// ## TRANSLATE ##		  
// ###############

// ###########
// ## SCALE ##		  
// ###########

	
// Matrix Assignments
// 	
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

	   O_Opcode <= I_Opcode;
		O_DepStall <= 1'b0;
		O_FetchStall <= 1'b0;
		
		// if SETVERTEX, form a triangle
		
		// if BEGINPRIMITIVE, enable _BeginPrimitive
	 
	   case (I_Opcode)
		  	// GPU 
			`OP_BEGINPRIMITIVE:
			begin
				O_Type <= I_Type;
			end
			`OP_SETVERTEX:
			begin
				Vertex_List[Vertex_CurrIdx] <= I_VR;
				Vertex_CurrIdx = Vertex_CurrIdx + 1;
			end
			`OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
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

endmodule // module geometry