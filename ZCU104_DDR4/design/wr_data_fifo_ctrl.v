module	wr_data_fifo_ctrl(
	input	wire		wrfifo_data_clk,
	input	wire		ui_clk,
	input	wire		rst_n,
	input	wire		p2_wr_en,
	input	wire[63:0]	p2_wr_mask,
	input	wire[511:0]	p2_wr_data,
	input	wire		data_req,
	
	output	wire[511:0]	data_512bit,		
	output	wire		p2_wr_empty,
	output	wire		p2_wr_full,
	output	wire[6 : 0]	p2_wr_count,
	output	wire[63:0]	wr_cmd_mask
	);
	
	wire	[575 : 0]		wrfifo_output_data;
	wire	[575 : 0]		wrfifo_input_data;
	
	assign	wrfifo_input_data = {p2_wr_mask,p2_wr_data};
	assign	data_512bit = wrfifo_output_data[511:0];
	assign	wr_cmd_mask = wrfifo_output_data[575:512];
	
wire wr_rst_busy,rd_rst_busy;

wr_data_fifo wr_data_fifo (
  .rst(~rst_n),                      // input wire rst
  .wr_clk(wrfifo_data_clk),                // input wire wr_clk
  .rd_clk(ui_clk),                // input wire rd_clk
  .din(wrfifo_input_data),                      // input wire [575 : 0] din
  .wr_en(p2_wr_en),                  // input wire wr_en
  .rd_en(data_req),                  // input wire rd_en
  .dout(wrfifo_output_data),                    // output wire [575 : 0] dout
  .full(p2_wr_full),                    // output wire full
  .empty(p2_wr_empty),                  // output wire empty
  .wr_data_count(p2_wr_count),  // output wire [6 : 0] wr_data_count
  .wr_rst_busy(wr_rst_busy),      // output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy)      // output wire rd_rst_busy
);

endmodule