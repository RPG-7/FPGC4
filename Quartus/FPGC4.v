/*
* Top level design of the FPGC4
*/
module FPGC4( 
    input clk, nreset,

    //VGA for GM7123 module
    output wire vga_clk,
    output wire vga_hs,
    output wire vga_vs,
    output wire [7:0] vga_r,
    output wire [7:0] vga_g,
    output wire [7:0] vga_b,
    output wire vga_blk
);


//PLL for CPU and VGA
pll pll (
.inclk0(clk),
.c0(clk_100),
.c1(vga_clk)
);

//-----------------Clock Divider---------------------
//Clock Divider I/O
wire pixel_clk_e;

ClockDivider #(
.DIVISOR(4)
) clkdiv (
.clk(clk_100),
.clk_e(pixel_clk_e)
);


//----------------Reset Stabilizer-------------------
//Reset stabilizer I/O
wire reset;
ResetStabilizer resStabilizer (
.nreset(nreset),
.clk(clk_100),
.reset(reset)
);


//---------------------------VRAM32---------------------------------
//VRAM32 I/O
wire        vram32_gpu_clk;
wire [10:0] vram32_gpu_addr;
wire [31:0] vram32_gpu_d;
wire        vram32_gpu_we;
wire [31:0] vram32_gpu_q;

wire        vram32_cpu_clk;
wire [10:0] vram32_cpu_addr;
wire [31:0] vram32_cpu_d;
wire        vram32_cpu_we; 
wire [31:0] vram32_cpu_q;

//as long as we do not have a cpu
assign vram32_cpu_addr 	= 0;
assign vram32_cpu_clk 	= 0;
assign vram32_cpu_d 	= 0;
assign vram32_cpu_we 	= 0;

//because FSX will not write to VRAM
assign vram32_gpu_we    = 1'b0;
assign vram32_gpu_d     = 32'd0;

VRAM #(
.WIDTH(32), 
.WORDS(1152), 
.LIST("../memory/vram32.list")
)   vram32(
//CPU port
.cpu_clk    (clk),
.cpu_d      (vram32_cpu_d),
.cpu_addr   (vram32_cpu_addr),
.cpu_we     (vram32_cpu_we),
.cpu_q      (vram32_cpu_q),

//GPU port
.gpu_clk    (vga_clk),
.gpu_d      (vram32_gpu_d),
.gpu_addr   (vram32_gpu_addr),
.gpu_we     (vram32_gpu_we),
.gpu_q      (vram32_gpu_q)
);


//--------------------------VRAM8--------------------------------
//VRAM8 I/O
wire        vram8_gpu_clk;
wire [10:0] vram8_gpu_addr;
wire [7:0]  vram8_gpu_d;
wire        vram8_gpu_we;
wire [7:0]  vram8_gpu_q;

wire        vram8_cpu_clk;
wire [10:0] vram8_cpu_addr;
wire [7:0]  vram8_cpu_d;
wire        vram8_cpu_we;
wire [7:0]  vram8_cpu_q;

//as long as we do not have a cpu
assign vram8_cpu_addr 	= 0;
assign vram8_cpu_clk 	= 0;
assign vram8_cpu_d 		= 0;
assign vram8_cpu_we 	= 0;

//because FSX will not write to VRAM
assign vram8_gpu_we     = 1'b0;
assign vram8_gpu_d      = 8'd0;

VRAM #(
.WIDTH(8), 
.WORDS(1792), 
.LIST("../memory/vram8.list")
)   vram8(
//CPU port
.cpu_clk    (clk),
.cpu_d      (vram8_cpu_d),
.cpu_addr   (vram8_cpu_addr),
.cpu_we     (vram8_cpu_we),
.cpu_q      (vram8_cpu_q),

//GPU port
.gpu_clk    (vga_clk),
.gpu_d      (vram8_gpu_d),
.gpu_addr   (vram8_gpu_addr),
.gpu_we     (vram8_gpu_we),
.gpu_q      (vram8_gpu_q)
);


//-----------------------FSX-------------------------
//FSX I/O
wire ontile_v;      //high when rendering on current line
					//needs to be stabilized

FSX fsx(
//VGA
.vga_clk   		(vga_clk),
.vga_r          (vga_r),
.vga_g          (vga_g),
.vga_b          (vga_b),
.vga_hs         (vga_hs),
.vga_vs         (vga_vs),
.vga_blk        (vga_blk),

//VRAM32
.vram32_addr    (vram32_gpu_addr),
.vram32_q       (vram32_gpu_q),

//VRAM8
.vram8_addr     (vram8_gpu_addr),
.vram8_q        (vram8_gpu_q),

//Interrupt signal
.ontile_v 		(ontile_v)
);

endmodule