module write_module(
	input		wire			clk,                      // output wire c0_ddr4_ui_clk
	input		wire			rst_n,      			 // output 
	input		wire[28 : 0]	wr_cmd_addr,				 //起始地址
	input		wire			wr_cmd_start,				 //开始信号
	input		wire[7 : 0]		wr_cmd_bl,					 //连续读写512bit数据的突发长度
	input		wire[511 : 0]	data_512bit,				 //相当于fifo的读数据
	input		wire[2 : 0]		wr_cmd_intr,				 //cmd
	input		wire[63 : 0] 	wr_cmd_mask,
	output	wire			data_req,					 //fifo数据请求信号
	output	wire			wr_end,						 //写结束信号
	output	wire			app_en,                      
	output	wire			app_wdf_end,             	 
	output	wire			app_wdf_wren,           	 
	input	wire			app_rdy,                     
	input	wire			app_wdf_rdy,             	 
	output	wire[28 : 0]	app_addr,                    
	output	wire[2 : 0]		app_cmd,                     
	output	wire[511 : 0]	app_wdf_data,            	 
	output	wire[63 : 0] 	app_wdf_mask	          	 
);
	reg 	[7:0]	data_cnt;
	reg 	[7:0]	addr_cnt;

    reg[7 : 0]		bl ;
    reg[2 : 0]		intr;
    reg[63 : 0] 	mask;
	
	reg 		app_wdf_wren_r;
	reg 		app_en_r;
	reg	[28:0]	app_addr_r;
	reg 		wr_end_r;
	
	//data_req
	assign data_req = app_wdf_wren_r & app_wdf_rdy;
	//app_wdf_end
	assign app_wdf_end = app_wdf_wren;
	assign app_wdf_wren = app_wdf_wren_r;
	assign app_en = app_en_r;
	assign app_cmd = intr;
	assign app_wdf_mask = mask;
	assign app_wdf_data = data_512bit;
	assign app_addr = app_addr_r;
	assign wr_end = wr_end_r;
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			bl<='d0;
			intr<='d0;
			mask<='d0;
		end
		else if(wr_cmd_start == 1'b1) begin
			bl <= wr_cmd_bl;
			intr <= wr_cmd_intr;
			mask <= wr_cmd_mask;
		end
		else begin
			bl <= bl;
			intr <= intr;
			mask <= mask;
		end
	end
	//app_wdf_wren_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			app_wdf_wren_r <= 1'b0;
		else if(data_cnt == (bl-1'b1))
			app_wdf_wren_r <= 1'b0;
		else if(wr_cmd_start == 1'b1)
			app_wdf_wren_r <= 1'b1;
		else 
			app_wdf_wren_r <= app_wdf_wren_r;
	end
	//data_cnt
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			data_cnt <= 'd0;
		else if(data_cnt == (bl-1'b1) & app_wdf_wren & app_wdf_rdy)
			data_cnt <= 'd0;
		else if(app_wdf_wren & app_wdf_rdy)
			data_cnt <= data_cnt + 1'b1;
		else	
			data_cnt <= data_cnt;
	end
	//app_en_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			app_en_r <= 1'b0;
		else if(addr_cnt == (bl-1'b1) & app_rdy)
			app_en_r <= 1'b0;
		else if(data_req == 1'b1)
			app_en_r <= 1'b1;
		else if((addr_cnt > (bl-'d5)) & (addr_cnt < (bl- 1'b1)))
			app_en_r <= 1'b1;
	end
	//addr_cnt
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			addr_cnt <= 'd0;
		else if(addr_cnt == (bl-1'b1) & app_en & app_rdy)
			addr_cnt <= 'd0;
		else if(app_en & app_rdy)
			addr_cnt <= addr_cnt+1'b1;
		else 
			addr_cnt <= addr_cnt;
	end
	//app_addr_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			app_addr_r <= 'd0;
		else if(wr_cmd_start == 1'b1)
			app_addr_r <= wr_cmd_addr;
		else if(app_en & app_rdy)
			app_addr_r <= app_addr_r +'d8;
		else
			app_addr_r <= app_addr_r;
	end
	
	//wr_end_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			wr_end_r <= 1'b0;
		else if(addr_cnt == (bl-1'b1) & app_en & app_rdy)
			wr_end_r <= 1'b1;
		else 
			wr_end_r <= 1'b0;
	end
	
	
	


endmodule