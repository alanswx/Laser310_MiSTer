//============================================================================
//  HT1080Z port to MiSTer
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//
//============================================================================

module emu
(
        //Master input clock
        input         CLK_50M,

        //Async reset from top-level module.
        //Can be used as initial reset.
        input         RESET,

        //Must be passed to hps_io module
        inout  [45:0] HPS_BUS,

        //Base video clock. Usually equals to CLK_SYS.
        output        CLK_VIDEO,

        //Multiple resolutions are supported using different CE_PIXEL rates.
        //Must be based on CLK_VIDEO
        output        CE_PIXEL,

        //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
        output  [7:0] VIDEO_ARX,
        output  [7:0] VIDEO_ARY,

        output  [7:0] VGA_R,
        output  [7:0] VGA_G,
        output  [7:0] VGA_B,
        output        VGA_HS,
        output        VGA_VS,
        output        VGA_DE,    // = ~(VBlank | HBlank)
        output        VGA_F1,
        output [1:0]  VGA_SL,

        output        LED_USER,  // 1 - ON, 0 - OFF.

        // b[1]: 0 - LED status is system status OR'd with b[0]
        //       1 - LED status is controled solely by b[0]
        // hint: supply 2'b00 to let the system control the LED.
        output  [1:0] LED_POWER,
        output  [1:0] LED_DISK,

        // I/O board button press simulation (active high)
        // b[1]: user button
        // b[0]: osd button
        output  [1:0] BUTTONS,


        output [15:0] AUDIO_L,
        output [15:0] AUDIO_R,
        output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
        output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
        input         TAPE_IN,
        //ADC
        inout   [3:0] ADC_BUS,

        // SD-SPI
        output        SD_SCK,
        output        SD_MOSI,
        input         SD_MISO,
        output        SD_CS,
        input         SD_CD,

        //High latency DDR3 RAM interface
        //Use for non-critical time purposes
        output        DDRAM_CLK,
        input         DDRAM_BUSY,
        output  [7:0] DDRAM_BURSTCNT,
        output [28:0] DDRAM_ADDR,
        input  [63:0] DDRAM_DOUT,
        input         DDRAM_DOUT_READY,
        output        DDRAM_RD,
        output [63:0] DDRAM_DIN,
        output  [7:0] DDRAM_BE,
        output        DDRAM_WE,

        //SDRAM interface with lower latency
        output        SDRAM_CLK,
        output        SDRAM_CKE,
        output [12:0] SDRAM_A,
        output  [1:0] SDRAM_BA,
        inout  [15:0] SDRAM_DQ,
        output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nCS,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nWE,

        input         UART_CTS,
        output        UART_RTS,
        input         UART_RXD,
        output        UART_TXD,
        output        UART_DTR,
        input         UART_DSR,


        // Open-drain User port.
        // 0 - D+/RX
        // 1 - D-/TX
        // 2..6 - USR2..USR6
        // Set USER_OUT to 1 to read from USER_IN.
        input   [6:0] USER_IN,
        output  [6:0] USER_OUT,

        input         OSD_STATUS
);

//`define SOUND_DBG
assign VGA_SL=0;
assign VGA_F1=0;
//assign CE_PIXEL=1;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign USER_OUT = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign ADC_BUS  = 'Z;
assign {SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 6'b111111;
assign SDRAM_DQ = 'Z;


//assign VIDEO_ARX = status[9] ? 8'd16 : 8'd4;
//assign VIDEO_ARY = status[9] ? 8'd9  : 8'd3;

assign BUTTONS = 0;

assign VIDEO_ARX = 4;
assign VIDEO_ARY = 3;

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_DISK  = LED;						/* later add disk motor on/off */
assign LED_POWER = 0;
assign LED_USER  = ioctl_download;



`include "build_id.v"
localparam CONF_STR = {
        "Laser;;",
        "-;",
        "F1,VZ ,Load VZ Image;",
        "-;",
        "O1,Turbo,Off,On;",
        "O2,Dos Rom,Off,On;",
        "O34,Scanlines,Off,25%,50%,75%;",
        "O5,SHRG,Off,On;",
        "O67,Screen Color,White,Green,Amber;",
        "-;",
        "R0,Reset;",
        "V,v",`BUILD_DATE
};

wire LED;

wire [31:0] status;
wire  [1:0] buttons;
wire        ioctl_download;
wire        ioctl_wr;
wire [15:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;

wire        forced_scandoubler;
wire [10:0] ps2_key;
//wire [24:0] ps2_mouse;
wire [21:0] gamma_bus;

wire [15:0] joystick_0, joystick_1;


hps_io #(.STRLEN(($size(CONF_STR)>>3) ), .PS2DIV(32)/*, .WIDE(0)*/) hps_io
(
        .clk_sys(/*CLK_VIDEO*/clk_sys),
        .HPS_BUS(HPS_BUS),

        .conf_str(CONF_STR),
        .joystick_0(joystick_0),
        .joystick_1(joystick_1),
        .buttons(buttons),
        .forced_scandoubler(forced_scandoubler),
        //.new_vmode(new_vmode),
        .gamma_bus(gamma_bus),


        .status(status),

        .ioctl_download(ioctl_download),
        .ioctl_wr(ioctl_wr),
        .ioctl_addr(ioctl_addr),
        .ioctl_dout(ioctl_data),
        .ioctl_index(ioctl_index),
        .ps2_key(ps2_key),

        .ps2_kbd_clk_out    ( ps2_kbd_clk    ),
        .ps2_kbd_data_out   ( ps2_kbd_data   )
);

wire reset;
wire rom_download = ioctl_download && !ioctl_index;
assign reset = (RESET | status[0] | buttons[1] | rom_download  );

wire ps2_kbd_clk;
wire ps2_kbd_data;

  //assign clk_sys  = clk_25;
  assign clk_sys  = clk_10;
  
wire       key_pressed = ps2_key[9];
wire [8:0] key_code    = ps2_key[8:0];
reg key_strobe;
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
	   key_strobe <= ~ key_strobe;
end
end

LASER310_TOP LASER310_TOP(
        .CLK50MHZ(clk_50),
        .CLK25MHZ(clk_25),
        .CLK10MHZ(clk_10),
        .RESET(~(status[0] | status[6] | buttons[1])),
        .VGA_RED(r),
        .VGA_GREEN(g),
        .VGA_BLUE(b),
        .VGA_HS(hs),
        .VGA_VS(vs),
        .h_blank(hblank),
        .v_blank(vblank),
        .AUD_ADCDAT(audio),
//      .VIDEO_MODE(1'b0),
        .audio_s(audio_s),
        .key_strobe     (key_strobe     ),
        .key_pressed    (key_pressed    ),
        .key_code       (key_code       ),

	.dn_index(ioctl_index),
	.dn_data(ioctl_data),
	.dn_addr(ioctl_addr[15:0]),
	.dn_wr(ioctl_wr),
	.led(LED),
        .SWITCH({"00000",~status[5],~status[2],~status[1]}),
        .UART_RXD(),
        .UART_TXD()
        );

wire clk_vid;
//assign CE_PIXEL = clk_vid;
assign CLK_VIDEO = clk_50;


///////////////////////////////////////////////////
//wire clk_sys, clk_ram, clk_ram2, clk_pixel, locked;
//
wire [2:0] scale = status[3:1];
wire  [7:0] r,g,b;

//video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
//video_mixer #(.LINE_LENGTH(384), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
video_mixer #(.GAMMA(1)) video_mixer
(
        .*,

        .clk_vid(clk_50),
        .ce_pix(clk_25),
        .ce_pix_out(CE_PIXEL),

        .scanlines(0),
        //.scandoubler(  scale || forced_scandoubler),
        .scandoubler(  scale|| forced_scandoubler),
        .hq2x(scale==1),

        .mono(0),

        .R(r),
        .G(g),
        .B(b),

        // Positive pulses.
        .HSync(hs),
        .VSync(vs),
        .HBlank(hblank),
        .VBlank(vblank)
);
//
//
wire clk_sys,locked;
wire hs,vs,hblank,vblank;

//assign VGA_VS=vs;
//assign VGA_HS=hs;
wire [8:0]audiomix;

wire [17:0] RGB;
/*
//assign VGA_R=8'b11111111;
assign VGA_R={RGB[5:0],2'b00};
assign VGA_G={RGB[11:6],2'b00};
assign VGA_B={RGB[17:12],2'b00};
//assign VGA_DE=~(vblank | hblank);
assign VGA_DE=(vblank & hblank);

*/
assign AUDIO_L={audiomix,7'b0000000};
assign AUDIO_R=AUDIO_L;


wire clk_50, clk_25, clk_10, clk_6p25;
wire pll_locked;


  
  
pll pll
  (
   .refclk   (CLK_50M),
   .rst      (0),
   .locked   (pll_locked),        // PLL is running stable
   .outclk_0 (clk_50),         // 50 MHz
   .outclk_1 (clk_25),         // 25 MHz
   .outclk_2 (clk_10),         // 10 MHz
   .outclk_3 (clk_6p25)         // 6.25 MHz
   );

  
  
  
endmodule



