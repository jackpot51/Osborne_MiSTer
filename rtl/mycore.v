
module mycore
(
	input         clk,
	input         reset,
	
	input         pal,
	input         scandouble,

	output reg    ce_pix,

	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,

	output  [7:0] video
);

reg   [9:0] hc;
reg   [9:0] vc;
reg   [9:0] vvc;
reg  [63:0] rnd_reg;

wire  [5:0] rnd_c = {rnd_reg[0],rnd_reg[1],rnd_reg[2],rnd_reg[2],rnd_reg[2],rnd_reg[2]};
wire [63:0] rnd;

lfsr random(rnd);

always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		hc <= 0;
		vc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 511) begin
			hc <= 0;
			if(vc == (pal ? (scandouble ? 623 : 311) : (scandouble ? 523 : 261))) begin 
				vc <= 0;
				vvc <= vvc + 9'd6;
			end else begin
				vc <= vc + 1'd1;
			end
		end else begin
			hc <= hc + 1'd1;
		end

		rnd_reg <= rnd;
	end
end

always @(posedge clk) begin
	if (hc == 416) HBlank <= 1;
		else if (hc == 0) HBlank <= 0;

	if (hc == 437) begin
		HSync <= 1;

		if(pal) begin
			if(vc == (scandouble ? 609 : 304)) VSync <= 1;
				else if (vc == (scandouble ? 617 : 308)) VSync <= 0;

			if(vc == (scandouble ? 601 : 300)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
		else begin
			if(vc == (scandouble ? 490 : 245)) VSync <= 1;
				else if (vc == (scandouble ? 496 : 248)) VSync <= 0;

			if(vc == (scandouble ? 480 : 240)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
	end
	
	if (hc == 473) HSync <= 0;
end

reg  [7:0] cos_out;
wire [5:0] cos_g = cos_out[7:3]+6'd32;
cos cos(vvc + {vc>>scandouble, 2'b00}, cos_out);

//assign video = (cos_g >= rnd_c) ? {cos_g - rnd_c, 2'b00} : 8'd0;
assign video = (char_data[(3'd7 - hc[2:0])] && !VBlank && !HBlank) ? 8'd255 : 8'd0;

// System, TODO: move to another file?

wire cpu_clock;
wire [15:0] cpu_address;
wire [7:0] cpu_data;
wire boot_rom_read_n;
wire ram_read_n;
wire ram_write_n;

osborne_1 osborne_1
(
	.reset_n(!reset),
	.clock_cpu(cpu_clock),
	.address(cpu_address),
	.data(cpu_data),
	.clock_62ns(clk),
	.boot_rom_read_n(boot_rom_read_n),
	.ram_read_n(ram_read_n),
	.ram_write_n(ram_write_n)
);

wire [7:0] boot_rom_data;
assign cpu_data = !boot_rom_read_n ? boot_rom_data : 1'bZ;
boot_rom boot_rom
(
	.address(cpu_address),
	//TODO: best clock?
	.clock(clk),
	.rden(!boot_rom_read_n),
	.q(boot_rom_data)
);

//TODO: ensure char_data is 0 when out of bounds!
reg [3:0] row_mod_10;
reg [4:0] row_div_10;
always @(posedge HBlank) begin
	if (vc < 239) begin
		if (row_mod_10 == 9) begin
			row_mod_10 <= 0;
			row_div_10 <= row_div_10 + 1'd1;
		end else begin
			row_mod_10 <= row_mod_10 + 1'd1;
		end
	end else begin
		row_mod_10 <= 0;
		row_div_10 <= 0;
	end
end

wire [10:0] char_address = {row_mod_10[3:0], video_data[6:0]};
wire [7:0] char_data;
char_rom char_rom
(
	.address(char_address),
	//TODO: best clock?
	.clock(clk),
	.q(char_data)
);

wire [7:0] ram_data;
assign cpu_data = !ram_read_n ? ram_data : 1'bZ;
wire [15:0] video_address = {4'b1111, row_div_10[4:0], hc[9:3]};
wire [7:0] video_data;
ram ram
(
	.address_a(cpu_address),
	//TODO: best clock?
	.clock_a(clk),
	.data_a(cpu_data),
	.rden_a(!ram_read_n),
	.wren_a(!ram_write_n),
	.q_a(ram_data),

	.address_b(video_address),
	//TODO: best clock?
	.clock_b(!clk),
	.data_b(video_data),
	.rden_b(1),
	.q_b(video_data)
);

endmodule
