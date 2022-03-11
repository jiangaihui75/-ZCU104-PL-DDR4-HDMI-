/*
*五个输入 六个输出
//输入
	input	

//输出

*/


module	cmd_fifo_ctrl(
	input	wire		cmd_clk,
	input	wire		ui_clk,
	input	wire		rst_n,
	input	wire		cmd_en,
	input	wire[2:0]	cmd_intr,
	input	wire[7:0]	cmd_bl,
	input	wire[28:0]	cmd_addr,
	input	wire		rd_cmd_start,
	input	wire		wr_cmd_start,
	
	output	wire[7:0]	out_cmd_bl,		
	output	wire[2:0]	out_cmd_intr,
	output	wire[28:0]	out_cmd_addr,
	
	//output	wire[7:0]	wr_cmd_bl,		
	//output	wire[2:0]	wr_cmd_intr,
	//output	wire[28:0]	wr_cmd_addr,
	
	output	wire		rd_req,
	output	wire		wr_req,
	output	wire		cmd_full
);
	
wire	wr_rst_busy,rd_rst_busy,full;
wire	fifo_rd_en;
	wire [39:0]	fifo_output_data;
	wire [39:0]	fifo_input_data;
	wire empty;										//empty信号如果为0，表示不为空，那么就可以控制产生rd_req或者wr_req信号			具体什么信号由输出data的intr控制
	assign	fifo_input_data = {cmd_intr,cmd_bl,cmd_addr};
	assign 	cmd_full = full;
	/*
		将rd_cmd和wr_cmd全部和fifo_output_data一样，因为只要不给start，cmd是没有作用的，重要的是控制req的产生
	*/
	assign	out_cmd_addr = fifo_output_data[28:0];
	assign	out_cmd_bl = fifo_output_data[36:29];
	assign	out_cmd_intr = fifo_output_data[39:37];

	
	//如何产生fifo_rd_en信号  不论是rd_start还是wr_start都是希望由cmd产生，那么由或产生fifo_rd_en信号
	assign	fifo_rd_en = rd_cmd_start | wr_cmd_start;
	
	//rd_req   : 首先需要fifo不空，其次在fifo_output_data的[39:37]需要是3'b001才产生rd_req信号
	assign	rd_req = (empty == 1'b0 && fifo_output_data[39:37]==3'b001) ;
	assign	wr_req = (empty == 1'b0 && fifo_output_data[39:37]==3'b000) ;
	cmd_fifo cmd_fifo (
  .rst(~rst_n),                  // input wire rst
  .wr_clk(cmd_clk),            // input wire wr_clk
  .rd_clk(ui_clk),            // input wire rd_clk
  .din(fifo_input_data),      // input wire [39 : 0] din
  .wr_en(cmd_en),              // input wire wr_en
  .rd_en(fifo_rd_en),              // input wire rd_en
  .dout(fifo_output_data),                // output wire [39 : 0] dout
  .full(full),                // output wire full
  .empty(empty),              // output wire empty
  .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
);


endmodule