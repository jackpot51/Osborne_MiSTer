
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

reg   [9:0] x;
reg   [9:0] y;

always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		x <= 0;
		y <= 0;
	end
	else if(ce_pix) begin
		if(x == 511) begin
			x <= 0;
			if(y == (pal ? (scandouble ? 623 : 311) : (scandouble ? 523 : 261))) begin 
				y <= 0;
			end else begin
				y <= y + 1'd1;
			end
		end else begin
			x <= x + 1'd1;
		end
	end
end

always @(posedge clk) begin
	if (x == 416) HBlank <= 1;
		else if (x == 0) HBlank <= 0;

	if (x == 437) begin
		HSync <= 1;

		if(pal) begin
			if(y == (scandouble ? 609 : 304)) VSync <= 1;
				else if (y == (scandouble ? 617 : 308)) VSync <= 0;

			if(y == (scandouble ? 601 : 300)) VBlank <= 1;
				else if (y == 0) VBlank <= 0;
		end
		else begin
			if(y == (scandouble ? 490 : 245)) VSync <= 1;
				else if (y == (scandouble ? 496 : 248)) VSync <= 0;

			if(y == (scandouble ? 480 : 240)) VBlank <= 1;
				else if (y == 0) VBlank <= 0;
		end
	end
	
	if (x == 473) HSync <= 0;
end

// We need to get char data exactly one clock early
//TODO: is there a cleaner way?
reg   [9:0] next_x;
reg   [9:0] next_y;
reg [3:0] row_mod_10;
reg [4:0] row_div_10;
always @(posedge clk) begin
	if(reset) begin
		next_x <= 1;
		next_y <= 0;
	end
	else if(ce_pix) begin
		if(next_x == 511) begin
			next_x <= 0;
			if(next_y == (pal ? (scandouble ? 623 : 311) : (scandouble ? 523 : 261))) begin 
				next_y <= 0;
			end else begin
				if (next_y < 239) begin
					if (row_mod_10 == 9) begin
						row_mod_10 <= 0;
						row_div_10 <= row_div_10 + 1'd1;
					end else begin
						row_mod_10 <= row_mod_10 + 1'd1;
					end
					next_y <= next_y + 1'd1;
				end else begin
					row_mod_10 <= 0;
					row_div_10 <= 0;
					next_y <= next_y + 1'd1;
				end
			end
		end else begin
			next_x <= next_x + 1'd1;
		end
	end
end

assign video = (char_data[(3'd7 - x[2:0])] && !VBlank && !HBlank) ? (video_dim ? 8'd255 : 8'd127) : 8'd0;

// System, TODO: move to another file?

wire cpu_clock;
wire [15:0] cpu_address;
wire [7:0] cpu_data;
wire boot_rom_read_n;
wire dim_read_n;
wire dim_write_n;
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
	.dim_read_n(dim_read_n),
	.dim_write_n(dim_write_n),
	.ram_read_n(ram_read_n),
	.ram_write_n(ram_write_n),
	.keyboard(64'd0)
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

wire [10:0] char_address = {row_mod_10[3:0], video_data[6:0]};
wire [7:0] char_data;
char_rom char_rom
(
	.address(char_address),
	//TODO: best clock?
	.clock(!clk),
	.q(char_data)
);

wire [15:0] video_address = {4'b1111, row_div_10[4:0], next_x[9:3]};
wire [7:0] video_data;
wire video_dim;

wire dim_data;
assign cpu_data = !dim_read_n ? {dim_data,7'b0000000} : 1'bZ;
dim dim
(
	.address_a(cpu_address),
	//TODO: best clock?
	.clock_a(clk),
	.data_a(cpu_data[7]),
	.rden_a(!dim_read_n),
	.wren_a(!dim_write_n),
	.q_a(dim_data),

	.address_b(video_address),
	//TODO: best clock?
	.clock_b(clk),
	.rden_b(1),
	.q_b(video_dim)
);

wire [7:0] ram_data;
assign cpu_data = !ram_read_n ? ram_data : 1'bZ;
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
	.clock_b(clk),
	.rden_b(1),
	.q_b(video_data)
);

endmodule
