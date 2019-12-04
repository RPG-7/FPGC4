/*
* Top level design of the FPGC4
*/
module FPGC4(
    input           clk, //50MHz
    input           nreset,

    //VGA for GM7123 module
    output          vga_clk,
    output          vga_hs,
    output          vga_vs,
    output [2:0]    vga_r,
    output [2:0]    vga_g,
    output [1:0]    vga_b,
    output          vga_blk,

    //SDRAM
    output          SDRAM_CLK,
    output          SDRAM_CSn, 
    output          SDRAM_WEn, 
    output          SDRAM_CASn, 
    output          SDRAM_RASn,
    output          SDRAM_CKE, 
    output [12:0]   SDRAM_A,
    output [1:0]    SDRAM_BA,
    output [1:0]    SDRAM_DQM,
    inout  [15:0]   SDRAM_DQ,

    //SPI
    output          spi_cs,
    output          spi_clk,
    inout           spi_data, 
    inout           spi_q, 
    inout           spi_wp, 
    inout           spi_hold
);

//----------------Reset Stabilizer-------------------
//Reset stabilizer I/O
wire reset;
ResetStabilizer resStabilizer (
.nreset(nreset),
.clk(clk),
.reset(reset)
);


//--------------------Clocks----------------------
assign SDRAM_CLK = clk;

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

assign vga_clk = clk; //should become 6 ish mhz eventually


FSX fsx(
//VGA
.vga_clk        (vga_clk),
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
.ontile_v       (ontile_v)
);


//----------------Memory Unit--------------------
//Memory Unit I/O
reg [26:0] address;
reg [31:0] data;
reg        we;
reg        start;
wire        initDone;
wire        busy;
wire [31:0] q;

MemoryUnit mu(
//clocks
.clk            (clk),

//I/O
.address        (address),
.data           (data),
.we             (we),
.start          (start),
.initDone       (initDone),       //High when initialization is done
.busy           (busy),
.q              (q),


//vram32 cpu side
.vram32_cpu_d   (vram32_cpu_d),        
.vram32_cpu_addr(vram32_cpu_addr), 
.vram32_cpu_we  (vram32_cpu_we),
.vram32_cpu_q   (vram32_cpu_q),

//vram8 cpu side
.vram8_cpu_d    (vram8_cpu_d),
.vram8_cpu_addr (vram8_cpu_addr), 
.vram8_cpu_we   (vram8_cpu_we),
.vram8_cpu_q    (vram8_cpu_q),

//SPI
.spi_data       (spi_data), 
.spi_q          (spi_q), 
.spi_wp         (spi_wp), 
.spi_hold       (spi_hold),
.spi_cs         (spi_cs), 
.spi_clk        (spi_clk),

//SDRAM
.SDRAM_CSn      (SDRAM_CSn), 
.SDRAM_WEn      (SDRAM_WEn), 
.SDRAM_CASn     (SDRAM_CASn),
.SDRAM_CKE      (SDRAM_CKE), 
.SDRAM_RASn     (SDRAM_RASn),
.SDRAM_A        (SDRAM_A),
.SDRAM_BA       (SDRAM_BA),
.SDRAM_DQM      (SDRAM_DQM),
.SDRAM_DQ       (SDRAM_DQ)
);


reg [63:0] c = 0;

//DEBUG SIM
always @(posedge clk)
begin
    c <= c + 1;

    if (c == 0)
    begin
        address <= 0;
        data <= 0;
        we <= 0;
        start <= 0;
    end

    if (c == 101)
    begin
        address <= 27'h800007;
        start <= 1;
    end

    if (c > 101 && c <900)
    begin
        if (!busy)
        begin
            data <= q;
            we <= 1;
            address <= 27'h800008;
            start <= 0;
            c <= 999;
        end
    end

    if (c == 1003)
        start <= 1;

    if (c > 1003 && c < 2000)
    begin

        if (!busy)
        begin
            start <= 0;
            c <= 2000;
        end
    end


    if (c == 2002)
    begin
        start <= 1;
        we <= 0;
        address <= 27'h800009;
        data <= 0;
    end
        

    if (c > 2002 && c < 3000)
    begin

        if (!busy)
        begin
            start <= 0;
            //c <= 2000;
        end
    end





end

endmodule