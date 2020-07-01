//
// top end ff for verilator
//

//`define sdl_display
`define USE_VGA
//`define USE_CGA

module top(VGA_R,VGA_B,VGA_G,VGA_HS,VGA_VS,reset,clk_50,clk_25,clk_10,ioctl_download,ioctl_addr,ioctl_dout,ioctl_index,ioctl_wait,ioctl_wr,start);

   input clk_50/*verilator public_flat*/;
   input clk_25/*verilator public_flat*/;
   input clk_10/*verilator public_flat*/;
   input reset/*verilator public_flat*/;

   output [7:0] VGA_R/*verilator public_flat*/;
   output [7:0] VGA_G/*verilator public_flat*/;
   output [7:0] VGA_B/*verilator public_flat*/;
   
   output VGA_HS;
   output VGA_VS;
   
   input        ioctl_download;
   input        ioctl_wr;
   input [24:0] ioctl_addr;
   input [7:0] ioctl_dout;
   input [7:0]  ioctl_index;
   output  reg     ioctl_wait=1'b0;
   input        start;
 
   

   
   //-------------------------------------------------------------------

////////////////////////////  HPS I/O  //////////////////////////////////

wire  [1:0] buttons;
wire [31:0] status;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire        ioctl_wr;
wire [7:0]  ioctl_index;

wire [15:0] joy0,joy1;

reg [9:0] hcnt;
wire [7:0] ld;


LASER310_TOP LASER310_TOP(
        .CLK50MHZ(clk_50),
        .CLK25MHZ(clk_25),
        .CLK10MHZ(clk_10),
        .RESET(~reset),
        .VGA_RED(VGA_R),
        .VGA_GREEN(VGA_G),
        .VGA_BLUE(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .h_blank(),
        .v_blank(),
        .AUD_ADCDAT(),
//      .VIDEO_MODE(1'b0),
        .audio_s(),
        .key_strobe     (),
        .key_pressed    (),
        .key_code       (),

	.dn_index(ioctl_index),
	.dn_data(ioctl_dout),
	.dn_addr(ioctl_addr[15:0]),
	.dn_wr(ioctl_wr),
	.led(),
	.led2(),
        .SWITCH(10'b0000000101),
        .UART_RXD(),
        .UART_TXD()
        );




endmodule // ff_cpu_test

