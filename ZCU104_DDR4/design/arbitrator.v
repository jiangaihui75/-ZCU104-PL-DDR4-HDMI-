module arbitrator(
	input 	wire	clk,
	input	wire	rst_n,
	input 	wire	read_req,
	input	wire	write_req,
	input   wire	rd_end,
	input   wire	wr_end,
	output 	wire	rd_cmd_start,
	output	wire	wr_cmd_start,
	output 	wire	mode
);
	reg read_flag;
	reg write_flag;
	reg [2:0]state;
	reg rd_cmd_start_r,wr_cmd_start_r;
	
	parameter ART = 3'B001;
	parameter WRITE = 3'B010;
	parameter READ = 3'B100;
	
	assign rd_cmd_start = rd_cmd_start_r;
	assign wr_cmd_start = wr_cmd_start_r;
	assign mode = (state==READ)?1'b1:1'b0;
	
	//state
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			state <= ART;
		else begin
			case(state)
				ART:begin
					if(write_flag == 1'b1)
						state <= WRITE;
					else if(write_flag == 1'b0 & read_flag == 1'b1)
						state <= READ;
					else 
						state <= state;
				end
				WRITE:begin
					if(wr_end == 1'b1)
						state <= ART;
					else
						state <= state;
				end
				READ:begin
					if(rd_end == 1'b1)
						state <= ART;
					else
						state <= state;
				end
			endcase	
		end
	end
	//read_flag
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			read_flag <= 1'b0;
		else if(state == READ)
			read_flag <= 1'b0;
		else if(read_req == 1'b1)
			read_flag <= 1'b1;
		else 
			read_flag <= read_flag;
	end
	//write_flag
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			write_flag <= 1'b0;
		else if(state == WRITE)
			write_flag <= 1'b0;
		else if(write_req == 1'b1)
			write_flag <= 1'b1;
		else 
			write_flag <= write_flag;
	end
	//wr_cmd_start_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			wr_cmd_start_r <= 1'b0;
		else if(state == WRITE && write_flag == 1'b1)
			wr_cmd_start_r <= 1'b1;	
		else
			wr_cmd_start_r <= 1'b0;
	end
	//rd_cmd_start_r
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			rd_cmd_start_r <= 1'b0;
		else if(state == READ && read_flag == 1'b1)
			rd_cmd_start_r <= 1'b1;	
		else
			rd_cmd_start_r <= 1'b0;
	end
endmodule