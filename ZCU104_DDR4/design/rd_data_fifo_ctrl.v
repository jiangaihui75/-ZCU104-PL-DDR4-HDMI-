module	rd_data_fifo_ctrl(
	input	wire		rdfifo_data_clk,
	input	wire		ui_clk,
	input	wire		rst_n,
	input	wire		p1_rd_en,
	input	wire		rd_data_valid,
	input	wire[511:0]	rd_data_512bit,
	
	output	wire[511:0]	rdfifo_output_data,		
	output	wire		p1_rd_empty,
	output	wire		p1_rd_full,
	output	wire[5 : 0]	p1_rd_count

);
	
wire wr_rst_busy,rd_rst_busy;
rd_data_fifo rd_data_fifo (
  .rst(~rst_n),                      // input wire rst
  .wr_clk(ui_clk),                // input wire wr_clk
  .rd_clk(rdfifo_data_clk),                // input wire rd_clk
  .din(rd_data_512bit),                      // input wire [511 : 0] din
  .wr_en(rd_data_valid),                  // input wire wr_en
  .rd_en(p1_rd_en),                  // input wire rd_en
  .dout(rdfifo_output_data),                    // output wire [511 : 0] dout
  .full(p1_rd_full),                    // output wire full
  .empty(p1_rd_empty),                  // output wire empty
  .rd_data_count(p1_rd_count),  // output wire [5 : 0] rd_data_count
  .wr_rst_busy(wr_rst_busy),      // output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy)      // output wire rd_rst_busy
);

endmodule