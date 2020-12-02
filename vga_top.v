`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Brian Nlong Zhao, Zoe Zhu
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name:
// Module Name:    vga_top 
// Project Name: EE354 Final Project - Binary Racing
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module vga_top (
	input ClkPort,
	input BtnC, BtnU, BtnR, BtnL, BtnD,
	input Sw0, Sw1, Sw2, Sw3, Sw4, Sw5, Sw6, Sw7, Sw8, Sw9, Sw10, Sw11, Sw12, Sw13, Sw14, Sw15,

	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSG signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	
	output MemOE, MemWR, RamCS, QuadSpiFlashCS
);

	wire Reset;
	assign Reset = BtnC;
	wire bright;
	wire [9:0] hc, vc;
	wire [15:0] score;
	wire up, down, left, right;
	wire [3:0] anode;
	wire [11:0] rgb;
	wire rst;

	wire [7:0] Ain, Bin;
	reg [7:0] Ain_temp, Bin_temp;
	wire [3:0] Ain_b1, Ain_b0, Bin_b1, Bin_b0;
	wire [15:0] Ain_bcd, Bin_bcd;
	reg [3:0] Ain_bcd3, Ain_bcd2, Ain_bcd1, Ain_bcd0, Bin_bcd3, Bin_bcd2, Bin_bcd1, Bin_bcd0;
	integer i;

	reg [3:0] SSD;
	wire [3:0] SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
	reg [7:0] SSD_CATHODES;
	wire [2:0] ssdscan_clk;
	
	reg [27:0] DIV_CLK;

	// Assign input of switches to Ain and Bin
	assign Ain = {Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0};
	assign Bin = {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8};

	// Clock divider
	always @ (posedge ClkPort, posedge Reset)  
	begin : CLOCK_DIVIDER
		if (Reset) begin
			DIV_CLK <= 0;
		end
		else begin
			DIV_CLK <= DIV_CLK + 1'b1;
		end
	end

	wire move_clk;
	assign move_clk = DIV_CLK[19]; //slower clock to drive the movement of objects on the vga screen
	wire [11:0] background;

	display_controller dc(
		.clk(ClkPort), 
		.hSync(hSync), 
		.vSync(vSync), 
		.bright(bright), 
		.hCount(hc), 
		.vCount(vc)
	);

	binary_racing br(
		.clk(move_clk), 
		.bright(bright), 
		.rst(BtnC), 
		.Ain(Ain),
		.Bin(Bin),
		.left(BtnL),
		.right(BtnR),
		.hCount(hc), 
		.vCount(vc), 
		.rgb(rgb), 
		.background(background)
	);
	
	assign vgaR = rgb[11:8];
	assign vgaG = rgb[7:4];
	assign vgaB = rgb[3:0];
	
	// Disable mamory ports
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	// Binary to BCD conversion on Ain
	always @ (Ain) 
	begin : BINARY_TO_BCD_Ain
		Ain_temp = Ain;
		Ain_bcd3 = 4'b0000;
		Ain_bcd2 = 4'b0000;
		Ain_bcd1 = 4'b0000;
		Ain_bcd0 = 4'b0000;
		for (i=0; i<8; i=i+1) begin
			if (Ain_bcd3 > 3'b100) begin
				Ain_bcd3 = Ain_bcd3 + 2'b11;
			end
			if (Ain_bcd2 > 3'b100) begin
				Ain_bcd2 = Ain_bcd2 + 2'b11;
			end
			if (Ain_bcd1 > 3'b100) begin
				Ain_bcd1 = Ain_bcd1 + 2'b11;
			end
			if (Ain_bcd0 > 3'b100) begin
				Ain_bcd0 = Ain_bcd0 + 2'b11;
			end
			{Ain_bcd3, Ain_bcd2, Ain_bcd1, Ain_bcd0, Ain_temp} = {Ain_bcd3, Ain_bcd2, Ain_bcd1, Ain_bcd0, Ain_temp} << 1;
		end
	end

	// Binary to BCD conversion on Bin
	always @ (Bin) 
	begin : BINARY_TO_BCD_Bin
		Bin_temp = Bin;
		Bin_bcd3 = 4'b0000;
		Bin_bcd2 = 4'b0000;
		Bin_bcd1 = 4'b0000;
		Bin_bcd0 = 4'b0000;
		for (i=0; i<8; i=i+1) begin
			if (Bin_bcd3 > 3'b100) begin
				Bin_bcd3 = Bin_bcd3 + 2'b11;
			end
			if (Bin_bcd2 > 3'b100) begin
				Bin_bcd2 = Bin_bcd2 + 2'b11;
			end
			if (Bin_bcd1 > 3'b100) begin
				Bin_bcd1 = Bin_bcd1 + 2'b11;
			end
			if (Bin_bcd0 > 3'b100) begin
				Bin_bcd0 = Bin_bcd0 + 2'b11;
			end
			{Bin_bcd3, Bin_bcd2, Bin_bcd1, Bin_bcd0, Bin_temp} = {Bin_bcd3, Bin_bcd2, Bin_bcd1, Bin_bcd0, Bin_temp} << 1;
		end
	end
	
	// SSDs display 
	assign SSD7 = Bin_bcd3;
	assign SSD6 = Bin_bcd2;
	assign SSD5 = Bin_bcd1;
	assign SSD4 = Bin_bcd0;
	assign SSD3 = Ain_bcd3;
	assign SSD2 = Ain_bcd2;
	assign SSD1 = Ain_bcd1;
	assign SSD0 = Ain_bcd0;

	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	assign ssdscan_clk = DIV_CLK[19:17];
	assign An0 = !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 000
	assign An1 = !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 001
	assign An2 = !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 010
	assign An3 = !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 011
	assign An4 = !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 100
	assign An5 = !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 101
	assign An6 = !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 110
	assign An7 = !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 111

	// Turn off unused anodes
	//assign {An7, An3} = 2'b11;
	
	// SSD scan on 8 SSDs
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			3'b000: SSD = SSD0;
			3'b001: SSD = SSD1;
			3'b010: SSD = SSD2;
			3'b011: SSD = SSD3;
			3'b100: SSD = SSD4;
			3'b101: SSD = SSD5;
			3'b110: SSD = SSD6;
			3'b111: SSD = SSD7;
		endcase 
	end

	// Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule
