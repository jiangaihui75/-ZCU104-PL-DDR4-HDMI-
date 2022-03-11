module top_ddr4_hdmi(
    input                 sys_rst, //Common port for all controllers


    output                  c0_init_calib_complete,
    output                  c0_data_compare_error,
    input                   c0_sys_clk_p,
    input                   c0_sys_clk_n,
    output                  c0_ddr4_act_n,
    output [16:0]           c0_ddr4_adr,
    output [1:0]            c0_ddr4_ba,
    output [1:0]            c0_ddr4_bg,
    output [0:0]            c0_ddr4_cke,
    output [0:0]            c0_ddr4_odt,
    output [0:0]            c0_ddr4_cs_n,
    output [0:0]            c0_ddr4_ck_t,
    output [0:0]            c0_ddr4_ck_c,
    output                  c0_ddr4_reset_n,
    inout  [7:0]            c0_ddr4_dm_dbi_n,
    inout  [63:0]           c0_ddr4_dq,
    inout  [7:0]            c0_ddr4_dqs_t,
    inout  [7:0]            c0_ddr4_dqs_c                             
);

	wire 	dbg_clk;
	wire 	ui_clk,c0_ddr4_ui_clk_sync_rst;
	wire	app_en,app_en_rd,app_en_wr,app_wdf_end,app_wdf_wren,app_rd_data_end,app_rd_data_valid;
	wire	app_rdy,app_wdf_rdy;
	wire 	[28 : 0]app_addr_rd;
	wire 	[28 : 0]app_addr_wr;
	wire 	[28 : 0]app_addr;
	wire 	[2:0]app_cmd;
	wire 	[511:0]app_wdf_data;
	wire	[63:0]app_wdf_mask;
	wire 	[511:0]app_rd_data;
	wire	addn_ui_clkout1;
	wire 	data_req,wr_end,wr_cmd_start;

	wire [511:0]data_512bit;
	wire [511:0]data_512bit_rd;
	wire mode;
	wire [2:0]app_cmd_wr;
	wire [2:0]app_cmd_rd;
	
	assign app_cmd = (mode==1'b1)?app_cmd_rd:app_cmd_wr;
	assign app_en = (mode==1'b1)?app_en_rd:app_en_wr;
	assign app_addr = (mode==1'b1)?app_addr_rd:app_addr_wr;
	wire	p1_rd_en,p1_rd_empty,p1_rd_full,p2_wr_en;
	wire [2:0]	cmd_intr;
	wire [7:0]	cmd_bl;
	wire [28:0]	cmd_addr;
	wire [2:0]	out_cmd_intr;
	wire [7:0]	out_cmd_bl;
	wire [28:0]	out_cmd_addr;
	wire [511:0]	rdfifo_output_data,p2_wr_data;
	
	wire [63:0] p2_wr_mask,wr_cmd_mask;
	wire	[6:0]	p2_wr_count;
	wire	[5:0]	p1_rd_count;
	
	wire			wr_en;
	wire			rd_start;
	wire [511:0]	wr_data;
	wire			user_rd_end;
	wire			user_wr_end;
	wire			p1_clk,clk1x,clk5x,locked;

  hdmi_clk_gen hdmi_clk_gen
   (
    // Clock out ports
    .p1_clk(p1_clk),     // output p1_clk
    .clk1x(clk1x),     // output clk1x
    .clk5x(clk5x),     // output clk5x
    // Status and control signals
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1_p(c0_sys_clk_p),    // input clk_in1_p
    .clk_in1_n(c0_sys_clk_n));    // input clk_in1_n
  top_hdmi inst_top_hdmi
    (
      .wrclk         (p1_clk),
      .rst           (ui_clk_sync_rst |(~init_calib_complete)),
      .locked        (locked),
      .clk1x         (clk1x),
      .clk5x         (clk5x),
      .rd_start      (rd_start),
      .user_rd_end   (user_rd_end),
      .rd_data_valid (p1_rd_en),
      .rd_data       (rdfifo_output_data),
      .hdmi_clk_p    (hdmi_clk_p),
      .hdmi_clk_n    (hdmi_clk_n),
      .hdmi_d0_p     (hdmi_d0_p),
      .hdmi_d0_n     (hdmi_d0_n),
      .hdmi_d1_p     (hdmi_d1_p),
      .hdmi_d1_n     (hdmi_d1_n),
      .hdmi_d2_p     (hdmi_d2_p),
      .hdmi_d2_n     (hdmi_d2_n)
    );
user_ctrl user_ctrl(
	//系统信号
	.clk				(p1_clk),
	.rst_n				(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),
				
	.wr_en				(wr_en),
	.wr_data			(wr_data),
					
	.rd_start			(rd_start),
				
	.p1_rd_empty		(p1_rd_empty),			//rd_fifo_ctrl 的fifo空信号
	.p1_rd_full			(p1_rd_full),				//rd_fifo_ctrl 的fifo满信号
	.p1_rd_count		(p1_rd_count),			//rd_fifo_ctrl 的fifo数据个数信号
	.rdfifo_output_data	(rdfifo_output_data),		//rd_fifo_ctrl 的fifo输出数据信号
				
	.p2_wr_empty		(p2_wr_empty),			//wr_fifo_ctrl 的fifo空信号
	.p2_wr_full			(p2_wr_full),				//wr_fifo_ctrl 的fifo满信号
	.p2_wr_count		(p2_wr_count),			//wr_fifo_ctrl 的fifo数据个数信号
				
	.cmd_full			(cmd_full),				//cmd_fifo_ctrl 的反馈的fifo满信号
					
	.p1_rd_en			(p1_rd_en),				//rd_fifo_ctrl 的读fifo信号
			
	.cmd_en				(cmd_en),
	.cmd_intr			(cmd_intr),
	.cmd_bl				(cmd_bl),
	.cmd_addr			(cmd_addr),

	.p2_wr_en			(p2_wr_en),
	.p2_wr_mask			(p2_wr_mask),	
	.p2_wr_data			(p2_wr_data),		

	.user_wr_end		(user_wr_end),
	.user_rd_end        (user_rd_end)
);
//wr_data_fifo_ctrl
wr_data_fifo_ctrl wr_data_fifo_ctrl(
	.wrfifo_data_clk(p1_clk),
	.ui_clk			(ui_clk),
	.rst_n			(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),
	.p2_wr_en		(p2_wr_en),
	.p2_wr_mask		(p2_wr_mask),
	.p2_wr_data		(p2_wr_data),	
	.data_req		(data_req),
		
	.data_512bit	(data_512bit),		
	.p2_wr_empty	(p2_wr_empty),
	.p2_wr_full		(p2_wr_full),
	.p2_wr_count	(p2_wr_count),
	.wr_cmd_mask    (wr_cmd_mask)
	);
//rd_data_fifo_ctrl
rd_data_fifo_ctrl rd_data_fifo_ctrl(
	.rdfifo_data_clk    (p1_clk),
	.ui_clk				(ui_clk),
	.rst_n				(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),
	.p1_rd_en			(p1_rd_en),
	.rd_data_valid		(rd_data_valid),
	.rd_data_512bit		(data_512bit_rd),

	.rdfifo_output_data	(rdfifo_output_data),		
	.p1_rd_empty		(p1_rd_empty),
	.p1_rd_full			(p1_rd_full),
	.p1_rd_count        (p1_rd_count)

);
//cmd_fifo_ctrl
cmd_fifo_ctrl cmd_fifo_ctrl(
	.cmd_clk		(p1_clk),
	.ui_clk			(ui_clk),
	.rst_n			(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),
	.cmd_en			(cmd_en),
	.cmd_intr		(cmd_intr),
	.cmd_bl			(cmd_bl),
	.cmd_addr		(cmd_addr),
	.rd_cmd_start	(rd_cmd_start),
	.wr_cmd_start	(wr_cmd_start),
		
	.out_cmd_bl		(out_cmd_bl),		
	.out_cmd_intr	(out_cmd_intr),
	.out_cmd_addr	(out_cmd_addr),
			
	.rd_req			(read_req),
	.wr_req			(write_req),
	.cmd_full       (cmd_full)
);
//仲裁模块
	arbitrator arbitrator(
	.clk		(ui_clk),
	.rst_n		(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),
	.read_req	(read_req),
	.write_req	(write_req),
	.rd_end		(rd_end),
	.wr_end		(wr_end),
	.rd_cmd_start(rd_cmd_start)	,
	.wr_cmd_start(wr_cmd_start)	,
	.mode		(mode)				//0 = 写状态活着仲裁，1 = 读状态
);

//读模块
read_module read_module(
	.clk					(ui_clk),                      // output wire c0_ddr4_ui_clk
	.rst_n					(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),      			 // output 
	.rd_cmd_addr			(out_cmd_addr)	,				 //起始地址
	.rd_cmd_start			(rd_cmd_start),				 //开始信号
	.rd_cmd_bl				(out_cmd_bl),					 //连续读写512bit数据的突发长度
	.rd_cmd_intr			(out_cmd_intr),				 //cmd
	.app_rdy				(app_rdy),                     
	.app_rd_data_end		(app_rd_data_end),
	.app_rd_data_valid		(app_rd_data_valid),                     
	.app_rd_data			(app_rd_data),     

	.data_512bit		(data_512bit_rd),				 //相当于fifo的读数据
	.rd_data_valid			(rd_data_valid),					 //fifo数据请求信号
	.rd_end					(rd_end),						 //写结束信号
	.app_en					(app_en_rd),                               	          	         	 
	.app_addr				(app_addr_rd),                    
	.app_cmd				(app_cmd_rd)                    

);

//写模块	
write_module write_module(
	.clk(ui_clk),                      // output wire c0_ddr4_ui_clk
	.rst_n(~c0_ddr4_ui_clk_sync_rst & c0_init_calib_complete),      			 // output 
	.wr_cmd_addr(out_cmd_addr),				 //起始地址
	.wr_cmd_start(wr_cmd_start),				 //开始信号
	.wr_cmd_bl(out_cmd_bl),					 //连续读写512bit数据的突发长度
	.data_512bit(data_512bit),				 //相当于fifo的读数据
	.wr_cmd_intr(out_cmd_intr),				 //cmd
	.wr_cmd_mask(wr_cmd_mask),
	.data_req(data_req),					 //fifo数据请求信号
	.wr_end(wr_end),						 //写结束信号
	.app_en(app_en_wr),                     
	.app_wdf_end(app_wdf_end),           
	.app_wdf_wren(app_wdf_wren),         
	.app_rdy(app_rdy),                   
	.app_wdf_rdy(app_wdf_rdy),           
	.app_addr(app_addr_wr),                 
	.app_cmd(app_cmd_wr),                   
	.app_wdf_data(app_wdf_data),         
	.app_wdf_mask(app_wdf_mask)      
);
ddr4_0 ddr4_0 (
  .c0_init_calib_complete(c0_init_calib_complete),        // output wire c0_init_calib_complete
  .dbg_clk(dbg_clk),                                      // output wire dbg_clk
  .c0_sys_clk_p(c0_sys_clk_p),                            // input wire c0_sys_clk_p
  .c0_sys_clk_n(c0_sys_clk_n),                            // input wire c0_sys_clk_n
  .dbg_bus(dbg_bus),                                      // output wire [511 : 0] dbg_bus
  .c0_ddr4_adr(c0_ddr4_adr),                              // output wire [16 : 0] c0_ddr4_adr
  .c0_ddr4_ba(c0_ddr4_ba),                                // output wire [1 : 0] c0_ddr4_ba
  .c0_ddr4_cke(c0_ddr4_cke),                              // output wire [0 : 0] c0_ddr4_cke
  .c0_ddr4_cs_n(c0_ddr4_cs_n),                            // output wire [0 : 0] c0_ddr4_cs_n
  .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),                    // inout wire [7 : 0] c0_ddr4_dm_dbi_n
  .c0_ddr4_dq(c0_ddr4_dq),                                // inout wire [63 : 0] c0_ddr4_dq
  .c0_ddr4_dqs_c(c0_ddr4_dqs_c),                          // inout wire [7 : 0] c0_ddr4_dqs_c
  .c0_ddr4_dqs_t(c0_ddr4_dqs_t),                          // inout wire [7 : 0] c0_ddr4_dqs_t
  .c0_ddr4_odt(c0_ddr4_odt),                              // output wire [0 : 0] c0_ddr4_odt
  .c0_ddr4_bg(c0_ddr4_bg),                                // output wire [1 : 0] c0_ddr4_bg
  .c0_ddr4_reset_n(c0_ddr4_reset_n),                      // output wire c0_ddr4_reset_n
  .c0_ddr4_act_n(c0_ddr4_act_n),                          // output wire c0_ddr4_act_n
  .c0_ddr4_ck_c(c0_ddr4_ck_c),                            // output wire [0 : 0] c0_ddr4_ck_c
  .c0_ddr4_ck_t(c0_ddr4_ck_t),                            // output wire [0 : 0] c0_ddr4_ck_t
  .c0_ddr4_ui_clk(ui_clk),                        		  // output wire c0_ddr4_ui_clk
  .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),      // output wire c0_ddr4_ui_clk_sync_rst
  .c0_ddr4_app_en(app_en),                       		 // input wire c0_ddr4_app_en
  .c0_ddr4_app_hi_pri(1'b0),               				 // input wire c0_ddr4_app_hi_pri
  .c0_ddr4_app_wdf_end(app_wdf_end),              // input wire c0_ddr4_app_wdf_end
  .c0_ddr4_app_wdf_wren(app_wdf_wren),            // input wire c0_ddr4_app_wdf_wren
  .c0_ddr4_app_rd_data_end(app_rd_data_end),      // output wire c0_ddr4_app_rd_data_end
  .c0_ddr4_app_rd_data_valid(app_rd_data_valid),  // output wire c0_ddr4_app_rd_data_valid
  .c0_ddr4_app_rdy(app_rdy),                      // output wire c0_ddr4_app_rdy
  .c0_ddr4_app_wdf_rdy(app_wdf_rdy),              // output wire c0_ddr4_app_wdf_rdy
  .c0_ddr4_app_addr(app_addr),                    // input wire [28 : 0] c0_ddr4_app_addr
  .c0_ddr4_app_cmd(app_cmd ),                      // input wire [2 : 0] c0_ddr4_app_cmd
  .c0_ddr4_app_wdf_data(app_wdf_data),            // input wire [511 : 0] c0_ddr4_app_wdf_data
  .c0_ddr4_app_wdf_mask(app_wdf_mask),            // input wire [63 : 0] c0_ddr4_app_wdf_mask
  .c0_ddr4_app_rd_data(app_rd_data),              // output wire [511 : 0] c0_ddr4_app_rd_data
  .addn_ui_clkout1(addn_ui_clkout1),                      // output wire addn_ui_clkout1
  .sys_rst(sys_rst)                                      // input wire sys_rst
);




endmodule