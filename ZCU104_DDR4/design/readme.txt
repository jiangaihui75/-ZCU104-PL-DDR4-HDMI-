zcu104_ddr4_design
在zcu104的ddr4中每个存储单元存储着512bit数据，并且使用的是差分时钟，在此模块中相较于ddr3，我将读写cmd_ctrl合并成一个，所有代码修改完成，但是如要使用，请自行编写uart8bitto512bit的代码
