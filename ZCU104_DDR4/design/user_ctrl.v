module	user_ctrl(
//系统信号
input	wire		clk,
input	wire		rst_n,
//写控制信号
input	wire		wr_en,
input	wire[511:0]	wr_data,
//读控制信号
input	wire		rd_start,
//反馈的输入信号
	//rd_fifo_ctrl的反馈
	input	wire		p1_rd_empty,			//rd_fifo_ctrl 的fifo空信号
	input	wire		p1_rd_full,				//rd_fifo_ctrl 的fifo满信号
	input	wire		p1_rd_count,			//rd_fifo_ctrl 的fifo数据个数信号
	input	wire		rdfifo_output_data,		//rd_fifo_ctrl 的fifo输出数据信号
	//wr_fifo_ctrl的反馈
	input	wire		p2_wr_empty,			//wr_fifo_ctrl 的fifo空信号
	input	wire		p2_wr_full,				//wr_fifo_ctrl 的fifo满信号
	input	wire		p2_wr_count,			//wr_fifo_ctrl 的fifo数据个数信号
	//cmd_fifo_ctrl的反馈
	input	wire		cmd_full,				//cmd_fifo_ctrl 的反馈的fifo满信号
//输出信号
	//输出给rd_fifo_ctrl的信号
	output	wire		p1_rd_en,				//rd_fifo_ctrl 的读fifo信号
	//输出给cmd_ctrl的控制信号
	output	wire		cmd_en,
	output	wire[2:0]	cmd_intr,
	output	wire[7:0]	cmd_bl,
	output	wire[28:0]	cmd_addr,
	//输出给wr_fifo_ctrl的信号
	output	wire		p2_wr_en,
	output	wire[63:0]	p2_wr_mask,	
	output	wire[511:0]	p2_wr_data,		
	//结束信号
	output	reg		user_wr_end,
	output	reg		user_rd_end
);
//1024 * 768 * 16 /64 -512 = 196096
parameter BURST_LEN = 64;				//每次写入到ddr4的数据个数
parameter START_ADDR = 0;
parameter STOP_ADDR = 196096;

//输出给cmd_ctrl的控制信号
	reg	[28:0]	cmd_addr_r;

	
//读控制
//rd
	reg[7:0]	rd_data_cnt;
	reg			p1_rd_en_r;
	reg[28:0] 	p1_cmd_addr;
	reg			p1_cmd_en;

	wire[2:0]	p1_cmd_intr;	
//wr	
	reg[7:0]	wr_data_cnt;
	reg[28:0] 	p2_cmd_addr;
	reg			p2_cmd_en;
	reg			p2_wr_en_r;
	reg[511:0]	p2_wr_data_r;
	wire[2:0] 	p2_cmd_intr;
	reg p2_wr_empty_reg1;

	assign	p2_wr_data = p2_wr_data_r;
	assign p2_wr_en = p2_wr_en_r;
	assign p2_wr_mask = 64'd0;
	assign	p2_cmd_bl = BURST_LEN;	
	
	assign cmd_en = (p2_cmd_en | p1_cmd_en);
	assign cmd_intr = (p1_cmd_en)?3'd1:3'd0;
	assign cmd_bl = BURST_LEN;
	assign cmd_addr = cmd_addr_r;

	
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p2_wr_empty_reg1 <= 1'b0;
		else 
			p2_wr_empty_reg1 <= p2_wr_empty;
	end
	
//user_wr_end
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			user_wr_end <= 1'b0;
		else if(p2_wr_empty == 1'b1 & p2_wr_empty_reg1 == 1'b0)
			user_wr_end <= 1'b1;
		else 	
			user_rd_end <= 1'b0;
	end
//user_rd_end	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			user_rd_end <= 1'b0;
		else if(rd_data_cnt ==(BURST_LEN-1'b1) &p1_rd_en==1'b1)
			user_rd_end <= 1'b1;
		else
			user_rd_end <=1'b0;
	end
	

	
	assign	p1_cmd_intr = 3'b001;
	assign	p1_rd_en = p1_rd_en_r;

	//rd_data_cnt
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			rd_data_cnt <= 'd0;
		else if(p1_rd_en == 1'b1 && rd_data_cnt == (BURST_LEN-1'b1))
			rd_data_cnt <= 'd0;			
		else if(p1_rd_en == 1'b1)
			rd_data_cnt <= rd_data_cnt +1'b1;	
	end
	
	//p1_rd_en
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p1_rd_en_r <= 1'b0;
		else if(p1_rd_en_r == 1'b1 & rd_data_cnt == (BURST_LEN-1'b1))
			p1_rd_en_r <= 1'b0;
		else if(p1_rd_count == BURST_LEN)
			p1_rd_en_r <= 1'b1;
		else 
			p1_rd_en_r <= p1_rd_en_r;
	end
	
	//p1_cmd_en
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p1_cmd_en <= 1'b0;
		else if(rd_start == 1'b1)
			p1_cmd_en <= 1'b1;
		else 
			p1_cmd_en <= 1'b0;		
	end
	//p1_cmd_addr
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p1_cmd_addr <= START_ADDR;
		else if(p1_cmd_en == 1'b1 & p2_cmd_addr == STOP_ADDR)
			p1_cmd_addr <= START_ADDR;		
		else if(p1_cmd_en == 1'b1)
			p1_cmd_addr <= p1_cmd_addr + 8*BURST_LEN;
	end
	
	//
//写控制
	//wr_data_cnt
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			wr_data_cnt <= 'd0;
		else if(p2_cmd_en == 1'b1 & wr_data_cnt == BURST_LEN)
			wr_data_cnt <= 'd0;
		else if(wr_en == 1'b1 | p2_cmd_en == 1'b1)
			wr_data_cnt <= wr_data_cnt + 1'b1;
	end
	
	//p2_wr_en
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p2_wr_en_r <= 1'b0;
		else 
			p2_wr_en_r <= wr_en;
	end
	//p2_wr_data
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p2_wr_data_r <= 'd0;
		else 	
			p2_wr_data_r <= wr_data;
	end
	//p2_cmd_en
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p2_cmd_en <= 1'b0;
		else if(p2_wr_en == 1'b1 & wr_data_cnt == BURST_LEN)
			p2_cmd_en <= 1'b1;
		else 
			p2_cmd_en <= 1'b0;
	end
	//p2_cmd_bl;
	/*
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p2_cmd_bl <= 'd0;
		else if(p2_wr_en == 1'b1 & data_cnt == BURST_LEN)
			p2_cmd_bl <= BURST_LEN;
	end
	*/
	//p2_cmd_addr
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			p2_cmd_addr <= START_ADDR;
		else if(p2_cmd_en == 1'b1 & p2_cmd_addr == STOP_ADDR)
			p2_cmd_addr <= START_ADDR;
		else if(p2_cmd_en)
			p2_cmd_addr <= p2_cmd_addr + 8*BURST_LEN;
	end

	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			cmd_addr_r <= 'd0;
		else if(rd_start == 1'b1)
			cmd_addr_r <= p1_cmd_addr;
		else if(p2_wr_en == 1'b1 & wr_data_cnt == BURST_LEN)
			cmd_addr_r <= p2_cmd_addr;
	end
endmodule