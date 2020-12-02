`timescale 1ns / 1ps

module binary_racing(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input left, right,
	input [7:0] Ain, Bin,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background
);

	// Game logic variables
	reg [9:0] Axpos, Aypos, Bxpos, Bypos, Oxpos, Oypos;
	reg [3:0] Ascore, Bscore, Oscore;
	reg [7:0] target, target_temp;
	wire [7:0] target_r;
	reg [5:0] oppo_counter;
	reg single_player;
	reg [3:0] state;
	parameter win_score = 4'b0011;

	// State representations
	localparam TITLE   = 4'b0000;
	localparam WAIT_1P = 4'b0001;
	localparam INC_1P  = 4'b0010;
	localparam WIN_1P  = 4'b0011;
	localparam LOSE_1P = 4'b0100;
	localparam WAIT_2P = 4'b0101;
	localparam INC_A   = 4'b0110;
	localparam INC_B   = 4'b0111;
	localparam WIN_A   = 4'b1000;
	localparam WIN_B   = 4'b1001;

	// Critical locations on screen
	parameter TOP = 10'd036;
	parameter BTM = 10'd513;
	parameter LFT = 10'd145;
	parameter RGT = 10'd783;
	parameter MDY = (TOP+BTM)/2;
	parameter MDX = (LFT+RGT)/2;

	// Other critical display parameters
	parameter MGN = 10'd20;
	parameter FMW = 10'd10;
	parameter TARGETY = TOP+MGN+FMW+20;
	parameter TARGETXA = ((MDX+(FMW/2))+(RGT-MGN-FMW))/2;
	parameter TARGETXB = ((MDX-(FMW/2))+(LFT+MGN+FMW))/2;
	parameter STARTY = BTM-MGN-FMW-20;
	parameter STARTXA = TARGETXA;
	parameter STARTXB = TARGETXB;
	parameter STEP = (STARTY-TARGETY)/win_score;
	parameter TITLE1Y = TOP+((BTM-TOP)/3);
	parameter TITLE2Y = BTM-((BTM-TOP)/3);

	// Color representation
	parameter BLK = 12'b0000_0000_0000;
	parameter WTE = 12'b1111_1111_1111;
	parameter RED = 12'b1111_0000_0000;
	parameter GRE = 12'b0000_1111_0000;
	parameter BLU = 12'b0000_0000_1111;

	// Initialization on registers
 	initial begin
		state = TITLE;
		target = target_r;
		Ascore = 0;
		Bscore = 0;
		Oscore = 0;
		Aypos = STARTY;
		Axpos = STARTXA;
		Bypos = STARTY;
		Bxpos = STARTXB;
		Oypos = STARTY;
		Oxpos = STARTXB;
		single_player = 0;
		background = 0;
		oppo_counter = 0;
	end
	
	// Main state machine
	always @ (posedge clk, posedge rst) 
	begin : MAIN_SM
		if (rst) begin
			state <= TITLE;
			target <= target_r;
			Ascore <= 0;
			Bscore <= 0;
			Oscore <= 0;
			Aypos <= STARTY;
			Axpos <= STARTXA;
			Bypos <= STARTY;
			Bxpos <= STARTXB;
			Oypos <= STARTY;
			Oxpos <= STARTXB;
			single_player <= 0;
			oppo_counter <= 0;
		end
		else begin
			case (state)
				TITLE : begin
					// State
					if (left) begin
						state <= WAIT_1P;
					end
					else if (right) begin
						state <= WAIT_2P;
					end
					if (left) begin
						single_player <= 1'b1;
					end
					else if (right) begin
						single_player <= 1'b0;
					end
				end
				WAIT_1P : begin
					// State
					if (Ain == target) begin
						state <= INC_1P;
					end
					else if (Oypos <= TARGETY) begin
						state <= LOSE_1P;
					end
					// Data
					oppo_counter <= oppo_counter + 1;
					if (oppo_counter[3]) begin
						oppo_counter <= 0;
						Oypos <= Oypos - 1;
					end
					if (Ain == target) begin
						target <= target_r;
						Ascore <= Ascore + 1;
						Aypos <= Aypos - STEP;
					end
					if (Oypos <= TARGETY) begin
						state <= LOSE_1P;
					end
				end
				INC_1P : begin
					// State
					if (Ascore >= win_score) begin
						state <= WIN_1P;
					end
					else begin
						state <= WAIT_1P;
					end
				end
				WAIT_2P : begin
					// State
					if (Ain == target) begin
						state <= INC_A;
					end
					else if (Bin == target) begin
						state <= INC_B;
					end
					// Data
					if (Ain == target) begin
						Ascore <= Ascore + 1;
						Aypos <= Aypos - STEP;
						target <= target_r;
					end
					else if (Bin == target) begin
						Bscore <= Bscore + 1;
						Bypos <= Bypos - STEP;
						target <= target_r;
					end
				end
				INC_A : begin
					// State
					if (Ascore >= win_score) begin
						state <= WIN_A;
					end
					else begin
						state <= WAIT_2P;
					end
				end
				INC_B : begin
					// State
					if (Bscore >= win_score) begin
						state <= WIN_B;
					end
					else begin
						state <= WAIT_2P;
					end
				end
			endcase
		end
	end

	// Counters for generating random number
	reg [6:0] random_counter6;
	reg [5:0] random_counter5;
	reg [4:0] random_counter4;
	reg [3:0] random_counter3;
	reg [2:0] random_counter2;

	// Random number generator on target_r
	always @ (posedge clk) 
	begin : RANDOM_COUNTER
		if (rst) begin
			random_counter6 <= 0;
			random_counter5 <= 0;
			random_counter4 <= 0;
			random_counter3 <= 0;
		end
		else begin
			random_counter6 <= random_counter6 + 1;
			random_counter5 <= random_counter5 + 1;
			random_counter4 <= random_counter4 + 1;
			random_counter3 <= random_counter3 + 1;
		end
	end
	assign target_r = {random_counter2, random_counter6} ^ {random_counter5, random_counter3} ^ {random_counter4, random_counter4};

	// Temporary registers for displaying target numbers
	reg [19:0] target_3, target_2, target_1, target_0;
	reg [3:0] target_bcd3, target_bcd2, target_bcd1, target_bcd0;

	// Index for for loops
	integer i;

	// Binary to BCD conversion on target
	always @ (target) 
	begin : BINARY_TO_BCD_TARGET
		target_temp = target;
		target_bcd3 = 4'b0000;
		target_bcd2 = 4'b0000;
		target_bcd1 = 4'b0000;
		target_bcd0 = 4'b0000;
		for (i=0; i<8; i=i+1) begin
			if (target_bcd3 > 3'b100) begin
				target_bcd3 = target_bcd3 + 2'b11;
			end
			if (target_bcd2 > 3'b100) begin
				target_bcd2 = target_bcd2 + 2'b11;
			end
			if (target_bcd1 > 3'b100) begin
				target_bcd1 = target_bcd1 + 2'b11;
			end
			if (target_bcd0 > 3'b100) begin
				target_bcd0 = target_bcd0 + 2'b11;
			end
			{target_bcd3, target_bcd2, target_bcd1, target_bcd0, target_temp} = {target_bcd3, target_bcd2, target_bcd1, target_bcd0, target_temp} << 1;
		end
	end

	// BCD to display converter
	always @ (*)
	begin : BCD_TO_DISPLAY
		case (target_bcd2)
			4'b0000 : target_2 <= xbits0;
			4'b0001 : target_2 <= xbits1;
			4'b0010 : target_2 <= xbits2;
			4'b0011 : target_2 <= xbits3;
			4'b0100 : target_2 <= xbits4;
			4'b0101 : target_2 <= xbits5;
			4'b0110 : target_2 <= xbits6;
			4'b0111 : target_2 <= xbits7;
			4'b1000 : target_2 <= xbits8;
			4'b1001 : target_2 <= xbits9;
		endcase
		case (target_bcd1)
			4'b0000 : target_1 <= xbits0;
			4'b0001 : target_1 <= xbits1;
			4'b0010 : target_1 <= xbits2;
			4'b0011 : target_1 <= xbits3;
			4'b0100 : target_1 <= xbits4;
			4'b0101 : target_1 <= xbits5;
			4'b0110 : target_1 <= xbits6;
			4'b0111 : target_1 <= xbits7;
			4'b1000 : target_1 <= xbits8;
			4'b1001 : target_1 <= xbits9;
		endcase
		case (target_bcd0)
			4'b0000 : target_0 <= xbits0;
			4'b0001 : target_0 <= xbits1;
			4'b0010 : target_0 <= xbits2;
			4'b0011 : target_0 <= xbits3;
			4'b0100 : target_0 <= xbits4;
			4'b0101 : target_0 <= xbits5;
			4'b0110 : target_0 <= xbits6;
			4'b0111 : target_0 <= xbits7;
			4'b1000 : target_0 <= xbits8;
			4'b1001 : target_0 <= xbits9;
		endcase
	end

	// Clock divider
	reg [7:0] DIV_CLK;
	always @ (posedge clk, posedge rst)  
	begin : CLOCK_DIVIDER
		if (rst) begin
			DIV_CLK <= 0;
		end
		else begin
			DIV_CLK <= DIV_CLK + 1'b1;
		end
	end

	// Flashing background
	reg [11:0] background_flash;
	always @ (posedge DIV_CLK[2])
	begin : FLASH_BACKGROUND
		background_flash <= background_flash + 1;
	end
	
	// Pixel slices pf images 
	wire [19:0] xbits_target, xbits_P1, xbits_P2;
	wire [19:0] xbits0, xbits1, xbits2, xbits3, xbits4, xbits5, xbits6, xbits7, xbits8, xbits9;
	wire [29:0] xbitsW, xbitsI, xbitsN;
	wire [29:0] xbitsL, xbitsO, xbitsS, xbitsE;
	wire [29:0] xbitsY, xbitsO_, xbitsU;
	wire [29:0] xbitsB, xbitsI_, xbitsN_, xbitsA, xbitsR, xbitsY_, xbits_, xbitsR_, xbitsA_, xbitsC, xbitsI__, xbitsN__, xbitsG;
	wire [29:0] xbits1_, xbits2_, xbits__, xbitsP;

	// Vertical and horizontal display control variables
	wire [4:0] target_img_y, target_num_y, P1_y, P2_y, title_y, option_y, you_y, win_y, lose_y;
	wire [19:0] target_img_l_xbits, target_img_r_xbits;
	wire [59:0] target_num_xbits;
	wire [19:0] P1_xbits, P2_xbits;
	wire [89:0] you_xbits, win_xbits;
	wire [119:0] lose_xbits;
	wire [389:0] title_xbits;
	wire [359:0] option_xbits;

	// Initialize the image pixel modules from bitmaps.v
	_0 _0(.y(target_num_y), .xbits(xbits0));
	_1 _1(.y(target_num_y), .xbits(xbits1));
	_2 _2(.y(target_num_y), .xbits(xbits2));
	_3 _3(.y(target_num_y), .xbits(xbits3));
	_4 _4(.y(target_num_y), .xbits(xbits4));
	_5 _5(.y(target_num_y), .xbits(xbits5));
	_6 _6(.y(target_num_y), .xbits(xbits6));
	_7 _7(.y(target_num_y), .xbits(xbits7));
	_8 _8(.y(target_num_y), .xbits(xbits8));
	_9 _9(.y(target_num_y), .xbits(xbits9));
	W W(.y(win_y), .xbits(xbitsW));
	I I(.y(win_y), .xbits(xbitsI));
	N N(.y(win_y), .xbits(xbitsN));
	L L(.y(lose_y), .xbits(xbitsL));
	O O(.y(you_y), .xbits(xbitsO));
	S S(.y(lose_y), .xbits(xbitsS));
	E E(.y(lose_y), .xbits(xbitsE));
	Y Y(.y(you_y), .xbits(xbitsY));
	O O_(.y(lose_y), .xbits(xbitsO_));
	U U(.y(you_y), .xbits(xbitsU));
	B B(.y(title_y), .xbits(xbitsB));
	I I_(.y(title_y), .xbits(xbitsI_));
	N N_(.y(title_y), .xbits(xbitsN_));
	A A(.y(title_y), .xbits(xbitsA));
	R R(.y(title_y), .xbits(xbitsR));
	Y Y_(.y(title_y), .xbits(xbitsY_));
	_ _(.y(title_y), .xbits(xbits_));
	R R_(.y(title_y), .xbits(xbitsR_));
	A A_(.y(title_y), .xbits(xbitsA_));
	C C(.y(title_y), .xbits(xbitsC));
	I I__(.y(title_y), .xbits(xbitsI__));
	N N__(.y(title_y), .xbits(xbitsN__));
	G G(.y(title_y), .xbits(xbitsG));
	target_img target_img(.y(target_num_y), .xbits(xbits_target));
	P1_img P1_img(.y(P1_y), .xbits(xbits_P1));
	P2_img P2_img(.y(P2_y), .xbits(xbits_P2));
	_1_ _1_(.y(option_y), .xbits(xbits1_));
	_2_ _2_(.y(option_y), .xbits(xbits2_));
	P P(.y(option_y), .xbits(xbitsP));

	// Regulating pixel slices
	assign target_img_y = (vCount - (TARGETY-10));
	assign target_img_l_xbits = xbits_target;
	assign target_img_r_xbits = xbits_target;
	assign target_num_y = (vCount - (TARGETY-10));
	assign target_num_xbits = {target_0, target_1, target_2};
	assign P1_y = (vCount - (Aypos-10));
	assign P2_y = (vCount - (Bypos-10));
	assign you_y = (vCount - (TITLE1Y-15));
	assign win_y = (vCount - (TITLE2Y-15));
	assign lose_y = (vCount - (TITLE2Y-15));
	assign you_xbits = {xbitsU, xbitsO, xbitsY};
	assign win_xbits = {xbitsN, xbitsI, xbitsW};
	assign lose_xbits = {xbitsE, xbitsS, xbitsO_, xbitsL};
	assign title_y = (vCount - (TITLE1Y-15));
	assign title_xbits = {xbitsG, xbitsN__, xbitsI_, xbitsC, xbitsA_, xbitsR_, xbits_, xbitsY_, xbitsR, xbitsA, xbitsN_, xbitsI_, xbitsB};
	assign option_y = (vCount - (TITLE2Y-15));
	assign option_xbits = {xbitsP, xbits2_, xbits__, xbits__, xbits__, xbits__, xbits__, xbits__, xbits__, xbits__, xbitsP, xbits1_};

	// Regions of rendering display elements 
	/*wire render_target_l, render_target_r;
	wire render_A, render_B, render_O;
	wire topframe, btmframe, lftframe, rgtframe, midframe, frame;
	wire target_num;
	wire render_A_img, render_B_img, render_O_img, render_target_img_l, render_target_img_r;*/
	assign render_A = (vCount >= (Aypos-10)) && (vCount < (Aypos+10)) && (hCount >= (Axpos-10)) && (hCount < (Axpos+10));
	assign render_B = (vCount >= (Bypos-10)) && (vCount < (Bypos+10)) && (hCount >= (Bxpos-10)) && (hCount < (Bxpos+10)) && (single_player == 1'b0);
	assign render_O = (vCount >= (Oypos-10)) && (vCount < (Oypos+10)) && (hCount >= (Oxpos-10)) && (hCount < (Oxpos+10)) && (single_player == 1'b1);
	assign render_target_l = (vCount >= (TARGETY-10)) && (vCount < (TARGETY+10)) && (hCount >= (TARGETXB-10)) && (hCount < (TARGETXB+10));
	assign render_target_r = (vCount >= (TARGETY-10)) && (vCount < (TARGETY+10)) && (hCount >= (TARGETXA-10)) && (hCount < (TARGETXA+10));
	assign topframe = (vCount >= TOP+MGN) && (vCount < TOP+MGN+FMW) && (hCount >= LFT+MGN) && (hCount < RGT-MGN);
	assign btmframe = (vCount >= BTM-MGN-FMW) && (vCount < BTM-MGN) && (hCount >= LFT+MGN) && (hCount < RGT-MGN);
	assign lftframe = (vCount >= TOP+MGN) && (vCount < BTM-MGN) && (hCount >= LFT+MGN) && (hCount < LFT+MGN+FMW);
	assign rgtframe = (vCount >= TOP+MGN) && (vCount < BTM-MGN) && (hCount >= RGT-MGN-FMW) && (hCount < RGT-MGN);
	assign midframe = (vCount >= TOP+MGN) && (vCount < BTM-MGN) && (hCount >= MDX-(FMW/2)) && (hCount < MDX+(FMW/2));
	assign frame = topframe || btmframe || lftframe || rgtframe || midframe;
	assign target_num = (vCount >= (TARGETY-10)) && (vCount < (TARGETY+10)) && (hCount >= (MDX-30)) && (hCount < (MDX+30));
	assign you = (vCount >= (TITLE1Y-15)) && (vCount < (TITLE1Y+15)) && (hCount >= (MDX-45)) && (hCount < (MDX+45));
	assign win = (vCount >= (TITLE2Y-15)) && (vCount < (TITLE2Y+15)) && (hCount >= (MDX-45)) && (hCount < (MDX+45));
	assign lose = (vCount >= (TITLE2Y-15)) && (vCount < (TITLE2Y+15)) && (hCount >= (MDX-60)) && (hCount < (MDX+60));
	assign title = (vCount >= (TITLE1Y-15)) && (vCount < (TITLE1Y+15)) && (hCount >= (MDX-195)) && (hCount < (MDX+195));
	assign option = (vCount >= (TITLE2Y-15)) && (vCount < (TITLE2Y+15)) && (hCount >= (MDX-180)) && (hCount < (MDX+180));

	// Render the shapes of the elements by anding with corresponding image pixel
	assign render_A_img = render_A && xbits_P1[hCount-(Axpos-10)];
	assign render_B_img = render_B && xbits_P2[hCount-(Bxpos-10)];
	assign render_target_number = target_num && target_num_xbits[hCount-(MDX-30)];
	assign render_target_img_l = render_target_l && target_img_l_xbits[hCount-(TARGETXB-10)];
	assign render_target_img_r = render_target_r && target_img_r_xbits[hCount-(TARGETXA-10)];
	assign render_target_img = render_target_img_l || render_target_img_r;
	assign render_you = you && you_xbits[hCount-(MDX-45)];
	assign render_win = win && win_xbits[hCount-(MDX-45)];
	assign render_lose = lose && lose_xbits[hCount-(MDX-60)];
	assign render_win_msg = render_you || render_win;
	assign render_lose_msg = render_you || render_lose;
	assign render_title = title && title_xbits[hCount-(MDX-195)];
	assign render_option = option && option_xbits[hCount-(MDX-180)];

	// Background control
	always @ (posedge clk, posedge rst) 
	begin : BACKGROUND_CONTROL
		if(rst) begin
			background <= BLK;
		end
		else begin
			case (state)
				TITLE : begin
					background <= BLK;
				end
				WAIT_1P : begin
					background <= WTE;
				end
				WAIT_2P : begin
					background <= WTE;
				end
				WIN_1P : begin
					background <= background_flash;
				end
				WIN_A : begin
					background <= background_flash;
				end
				WIN_B : begin
					background <= background_flash;
				end
				LOSE_1P : begin
					background <= BLK;
				end
			endcase
		end
	end

	// Output rgb values to the screen
	always @ (*) 
	begin : RENDER
    	if (~bright) begin
			rgb = BLK;
		end
		else if (state == TITLE) begin
			if (render_title) begin
				rgb = background_flash;
			end
			else if (render_option) begin
				rgb = WTE;
			end
			else begin
				rgb = BLK;
			end
		end
		else if (state == WIN_1P || state == WIN_A || state == WIN_B) begin
			if (render_win_msg) begin
				rgb = WTE;
			end
			else if (state == WIN_A && render_A_img) begin
				rgb = BLU;
			end
			else if (state == WIN_B && render_B_img) begin
				rgb = GRE;
			end
			else begin
				rgb = background_flash;
			end
		end
		else if (state == LOSE_1P) begin
			if (render_lose_msg) begin
				rgb = WTE;
			end
			else begin
				rgb = BLK;
			end
		end
		else begin // In-game state
			if (render_A_img) begin
				rgb = BLU;
			end
			else if (render_O) begin
				rgb = BLK;
			end
			else if (render_B_img) begin
				rgb = GRE;
			end
			else if (render_target_number) begin
				rgb = RED;
			end
			else if (render_target_img) begin
				rgb = RED; 
			end
			else if (frame) begin
				rgb = background_flash;
			end
			else begin	
				rgb = background;
			end
		end
	end

endmodule
