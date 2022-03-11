// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Youkaiyuan  v3eduyky@126.com
// wechat : 15921999232
// File   : hdmi_buffer.v
// Create : 2019-10-05 14:28:19
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------
module hdmi_buffer(
		input	wire 				wrclk,
		input	wire 				hdmiclk,
		input	wire 				rst,
		output	wire 				rd_start,
		input	wire 				user_rd_end,
		input	wire 				rd_data_valid,
		input	wire 	[511:0]		rd_data,
		output	wire 				hdmi_rst_n,
		input	wire 				rd_fifo_en,
		output	wire 	[23:0]		rd_fifo_data
	);

parameter IDLE = 3'b001;
parameter JUDGE = 3'b010;
parameter RD  = 3'b100;

reg [2:0]	state;
reg 		rd_start_r;
wire	[9 : 0]		cfifo_rd_data_count;
wire 	[9:0]		asfifo_wr_data_count;
wire 	[11:0]		asfifo_rd_data_count;
reg 		hdmi_rst_n_r =1'b0;
wire 	[4:0] red,blue;
wire 	[5:0] green;
reg 	[7:0]	test_cnt;
wire			cfifo_rd_en;
wire	[63:0]	cfifo_dout;

assign	cfifo_rd_en = (cfifo_rd_data_count=='d0)?1'b0:1'b1;
assign rd_start = rd_start_r;
assign hdmi_rst_n = hdmi_rst_n_r;

always @(posedge wrclk) begin
	if (rst == 1'b1) begin
		state <= IDLE;
	end
	else 
	case (state)
		IDLE : begin
			state <= JUDGE;
		end
		JUDGE : begin
			if(asfifo_wr_data_count < 384) begin
				state <= RD;
			end
		end
		RD : begin
			if (user_rd_end == 1'b1) begin
				state <= JUDGE;
			end
		end
		default : state <= IDLE;
	endcase
end

always @(posedge wrclk) begin
	if (rst == 1'b1) begin
		rd_start_r <= 1'b0;
	end
	else if (state == JUDGE && asfifo_wr_data_count < 384) begin
		rd_start_r <= 1'b1;
	end
	else begin
		rd_start_r <= 1'b0;
	end
end



always @(posedge hdmiclk) begin
	if (rst == 1'b1) begin
		test_cnt <='d0;
	end
	else if (rd_fifo_en) begin
		test_cnt <= test_cnt + 1'b1;
	end
end

assign rd_fifo_data = {red,3'd0,green,2'd0,blue,3'd0};

always @(posedge hdmiclk) begin
	if (rst == 1'b1) begin
		hdmi_rst_n_r <= 1'b0;
	end
	else if (asfifo_rd_data_count >= 1500) begin
		hdmi_rst_n_r <= 1'b1;
	end
end
cfifo_wr512x64_rd64x512 cfifo_wr512x64_rd64x512 (
  .clk(wrclk),                      // input wire clk
  .din(rd_data),                      // input wire [511 : 0] din
  .wr_en(rd_data_valid),                  // input wire wr_en
  .rd_en(cfifo_rd_en),                  // input wire rd_en
  .dout(cfifo_dout),                    // output wire [63 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .rd_data_count(cfifo_rd_data_count)  // output wire [9 : 0] rd_data_count
);
asfifo_wr64x512_rd16x2048 asfifo_wr64x512_rd16x2048 (
  .wr_clk(wrclk),                // input wire wr_clk
  .rd_clk(hdmiclk),                // input wire rd_clk
  .din(cfifo_dout),                      // input wire [63 : 0] din
  .wr_en(cfifo_rd_en),                  // input wire wr_en
  .rd_en(rd_fifo_en),                  // input wire rd_en
  .dout({red,green,blue}),                    // output wire [15 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .rd_data_count(asfifo_rd_data_count),  // output wire [11 : 0] rd_data_count
  .wr_data_count(asfifo_wr_data_count)  // output wire [9 : 0] wr_data_count
);
endmodule 