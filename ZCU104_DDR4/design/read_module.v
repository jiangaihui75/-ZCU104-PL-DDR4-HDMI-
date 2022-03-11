module read_module(
	input		wire			clk,                      // output wire c0_ddr4_ui_clk
	input		wire			rst_n,      			 // output 
	input		wire[28 : 0]	rd_cmd_addr,				 //起始地址
	input		wire			rd_cmd_start,				 //开始信号
	input		wire[7 : 0]		rd_cmd_bl,					 //连续读写512bit数据的突发长度
	input		wire[2 : 0]		rd_cmd_intr,				 //cmd
	input	wire			app_rdy,                     
	input	wire			app_rd_data_end,
	input	wire			app_rd_data_valid,                     
	input	wire[511 : 0]	app_rd_data,     
	
	output		wire[511 : 0]	data_512bit,				 //相当于fifo的读数据
	output	wire			rd_data_valid,					 //fifo数据请求信号
	output	wire			rd_end,						 //写结束信号
	output	wire			app_en,                               	          	         	 
	output	wire[28 : 0]	app_addr,                    
	output	wire[2 : 0]		app_cmd                    
	         	         	 
);
	reg 	[7:0]	addr_cnt;
	reg 	[7:0]	data_cnt;
    reg[7 : 0]		bl ;
    reg[2 : 0]		intr;

	
	reg 		app_en_r;
	reg	[28:0]	app_addr_r;
	reg 		rd_end_r;

	assign app_en = app_en_r;
	assign app_cmd = intr;
	assign rd_data_valid = app_rd_data_valid;
	assign data_512bit = app_rd_data;
	assign app_addr = app_addr_r;
	assign rd_end = rd_end_r;
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			bl<='d0;
			intr<='d0;

		end
		else if(rd_cmd_start == 1'b1) begin
			bl <= rd_cmd_bl;
			intr <= rd_cmd_intr;
		end
		else begin
			bl <= bl;
			intr <= intr;
		end
	end

	//data_cnt
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			data_cnt <= 'd0;
		else if(data_cnt == (bl-1'b1) & app_rd_data_valid)
			data_cnt <= 'd0;
		else if(app_rd_data_valid)
			data_cnt <= data_cnt + 1'b1;
		else	
			data_cnt <= data_cnt;
	end
	//addr_cnt
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			addr_cnt <= 'd0;
		else if(addr_cnt == (bl-1'b1) & app_en & app_rdy)
			addr_cnt <= 'd0;
		else if(app_en & app_rdy)
			addr_cnt <= addr_cnt + 1'b1;
		else	
			addr_cnt <= addr_cnt;
	end
	//app_en_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			app_en_r <= 1'b0;
		else if(addr_cnt == (bl-1'b1) & app_rdy)
			app_en_r <= 1'b0;
		else if(rd_cmd_start == 1'b1)
			app_en_r <= 1'b1;
		else 
			app_en_r <= app_en_r;
	end

	//app_addr_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			app_addr_r <= 'd0;
		else if(rd_cmd_start == 1'b1)
			app_addr_r <= rd_cmd_addr;
		else if(app_en & app_rdy)
			app_addr_r <= app_addr_r +'d8;
		else
			app_addr_r <= app_addr_r;
	end
	
	//rd_end_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			rd_end_r <= 1'b0;
		else if(data_cnt == (bl-1'b1) & app_rd_data_valid)
			rd_end_r <= 1'b1;
		else 
			rd_end_r <= 1'b0;
	end
	
	
	


endmodule