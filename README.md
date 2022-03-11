# 基于ZCU104的PL端外接DDR4/A7的PL端外接DDR3实现uart+DDR4+HDMI联合图片显示
<img width="598" alt="1646989251(1)" src="https://user-images.githubusercontent.com/94519594/157835602-8f8ed3a6-51c5-4098-8901-8e044993f080.png">

（1）由UART将图片数据写入到DDR4 SDRAM中； 
（2）将写入的图片由8bit转换位512bit写入到wr_data_fifo_ctrl中，而hdmi_buffer模块当fifo中的数据小于1500个时不断地请求读取ddr4中的数据，当数据大于1500时vga模块启动工作开始从fifo中读取数据显示到显示器中；
（3）实现效果：HDMI 显示器以帧率为 60HZ，720P 模式显示由uart串口写入的图像，ddr4 中保存了一帧图像。
