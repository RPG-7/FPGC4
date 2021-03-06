/*
* Memory Unit
*/
module MemoryUnit(
    //clocks
    input clk, reset,

    //I/O
    input  [26:0]   address,
    input  [31:0]   data,
    input           we,
    input           start,          //Start should be high until busy = low
    output          initDone,       //High when initialization is done
    output reg      busy,
    output reg [31:0]  q,


    //vram32 cpu side
    output [31:0]   vram32_cpu_d,
    output [13:0]   vram32_cpu_addr, 
    output          vram32_cpu_we,
    input  [31:0]   vram32_cpu_q,

    //vram8 cpu side
    output [7:0]    vram8_cpu_d,
    output [13:0]   vram8_cpu_addr, 
    output          vram8_cpu_we,
    input  [7:0]    vram8_cpu_q,

    //vramSPR cpu side
    output [8:0]    vramSPR_cpu_d,
    output [13:0]   vramSPR_cpu_addr, 
    output          vramSPR_cpu_we,
    input  [8:0]    vramSPR_cpu_q,

    //ROM
    output [8:0]    rom_addr,
    input  [31:0]   rom_q,

    //SPI Flash
    inout           spi_data, spi_q, spi_wp, spi_hold,
    output          spi_cs, 
    output          spi_clk,

    //SDRAM
    output          SDRAM_CSn, SDRAM_WEn, SDRAM_CASn,
    output          SDRAM_CKE, SDRAM_RASn,
    output [12:0]   SDRAM_A,
    output [1:0]    SDRAM_BA,
    output [1:0]    SDRAM_DQM,
    inout [15:0]    SDRAM_DQ,

    //PS/2
    input           ps2d, ps2c,
    output          scan_code_ready,
    
    //(S)NESpad
    output          nesc, nesl,
    input           nesd,

    //OStimers
    output          t1_interrupt,
    output          t2_interrupt,
    output          t3_interrupt,

    //UART
    output          uart_out,
    output          uart_rx_interrupt,
    input           uart_in,

    //UART2
    output          uart2_out,
    output          uart2_rx_interrupt,
    input           uart2_in,

    //GPIO
    input [7:0]     GPI,
    output reg [7:0]GPO,

    //SPI
    output          s_clk,
    input           s_miso,
    output          s_mosi,
    input           s_nint,

    //SPI2
    output          spi2_clk,
    output          spi2_mosi,
    input           spi2_miso
);  

    //SDRAMcontroller, SPIreader, vram, and I/O should work on negedge clock

    wire [23:0] sr_addr;            //address of spi
    wire        sr_start;           //start of spi

    wire [31:0] sr_q;               //q of spi
    wire        sr_initDone;        //initdone of spi
    wire        sr_recvDone;        //recvdone of spi TODO might change this to busy
    wire        sr_reset;

    //SPIreader
    wire spi_write;
    wire io0_out, io1_out, io2_out, io3_out;    //d, q wp, hold
    wire io0_in,  io1_in,  io2_in,  io3_in;     //d, q wp, hold

    //SPI3
    wire spi3_clk;
    wire spi3_mosi;

    reg enableSPI3; //1 to enable SPI3 and disable SPIreader

    wire dRead, qRead, wpRead, holdRead, csRead, writeRead;

    assign spi_clk  = (enableSPI3) ? spi3_clk   : clk;      //run SPI flash at 25MHz when in read mode
    assign spi_cs   = (enableSPI3) ? GPO[2]     : csRead;   //in SPI3 mode, set CS to GPO[2]
    assign sr_reset = (enableSPI3) ? 1'b1       : reset;    //reset SPI reader when disabled

    assign dRead        = (enableSPI3) ? spi3_mosi  : io0_out;
    assign qRead        = (enableSPI3) ? 'bz        : io1_out;
    assign wpRead       = (enableSPI3) ? 1'b1       : io2_out;
    assign holdRead     = (enableSPI3) ? 1'b1       : io3_out;
    assign writeRead    = (enableSPI3) ? 1'b1       : spi_write;

    assign spi_data  = (writeRead) ? dRead : 'bz;
    assign spi_q     = (writeRead) ? qRead : 'bz;
    assign spi_wp    = (writeRead) ? wpRead : 'bz;
    assign spi_hold  = (writeRead) ? holdRead : 'bz;

    assign io0_in  = (~writeRead) ? spi_data : 'bz;
    assign io1_in  = (~writeRead) ? spi_q    : 'bz;
    assign io2_in  = (~writeRead) ? spi_wp   : 'bz;
    assign io3_in  = (~writeRead) ? spi_hold : 'bz;

    SPIreader sreader (
    .clk        (spi_clk),
    .reset      (sr_reset),
    .cs         (csRead),
    .address    (sr_addr),
    .instr      (sr_q),
    .start      (sr_start),
    .initDone   (sr_initDone), 
    .recvDone   (sr_recvDone),
    .write      (spi_write),
    .io0_out    (io0_out),
    .io1_out    (io1_out),
    .io2_out    (io2_out),
    .io3_out    (io3_out),
    .io0_in     (io0_in),
    .io1_in     (io1_in),
    .io2_in     (io2_in),
    .io3_in     (io3_in)
    );


    //----SDRAM----
    wire        sd_we;
    wire        sd_start;
    wire [31:0] sd_d; 
    wire [23:0] sd_addr;

    wire        sd_busy;
    wire        sd_initDone;
    wire        sd_q_ready;
    wire [31:0] sd_q;

    SDRAMcontroller sdramcontroller(
    .clk        (clk),
    .reset      (reset),

    .busy       (sd_busy),       // high if controller is busy
    .addr       (sd_addr),       // addr to read or write
    .d          (sd_d),          // data to write
    .we         (sd_we),         // high if write, low if read
    .q          (sd_q),          // read data output
    .q_ready_delay(sd_q_ready),    // read data ready
    .start      (sd_start),
    .initDone   (sd_initDone),

    // SDRAM
    .SDRAM_CKE  (SDRAM_CKE), 
    .SDRAM_CSn  (SDRAM_CSn),
    .SDRAM_WEn  (SDRAM_WEn), 
    .SDRAM_CASn (SDRAM_CASn), 
    .SDRAM_RASn (SDRAM_RASn),
    .SDRAM_A    (SDRAM_A),
    .SDRAM_BA   (SDRAM_BA),
    .SDRAM_DQM  (SDRAM_DQM),
    .SDRAM_DQ   (SDRAM_DQ)
    );

//-----------------NES Controller-------------------
//Controller I/O
wire [15:0] nesState;

NESpadReader npr (
.clk(clk),
.reset(reset),
.nesc(nesc),
.nesl(nesl),
.nesd(nesd),
.nesState(nesState)
);


//-----------------PS/2 Keyboard-------------------
//PS/2 Keyboard I/O
wire [7:0] scanCode;

Keyboard keyboard (
.clk(clk), 
.reset(reset), 
.rx_en(1'b1), 
.ps2d(ps2d), 
.ps2c(ps2c), 
.rx_done_tick(scan_code_ready), 
.rx_data(scanCode)
);


//----------------OS timer 1----------------------
//OS timer 1 I/O
wire t1_trigger, t1_set;
wire [31:0] t1_value;

OStimer osTimer1(
.clk(clk),
.reset(reset),
.timerValue(t1_value),
.setValue(t1_set),
.trigger(t1_trigger),
.interrupt(t1_interrupt)
);

//----------------OS timer 2----------------------
//OS timer 2 I/O
wire t2_trigger, t2_set;
wire [31:0] t2_value;

OStimer osTimer2(
.clk(clk),
.reset(reset),
.timerValue(t2_value),
.setValue(t2_set),
.trigger(t2_trigger),
.interrupt(t2_interrupt)
);

//----------------OS timer 3----------------------
//OS timer 3 I/O
wire t3_trigger, t3_set;
wire [31:0] t3_value;

OStimer osTimer3(
.clk(clk),
.reset(reset),
.timerValue(t3_value),
.setValue(t3_set),
.trigger(t3_trigger),
.interrupt(t3_interrupt)
);


//-------------------UART TX-----------------------
//UART TX I/O
wire r_Tx_DV, w_Tx_Done;
wire [7:0] r_Tx_Byte;

UARTtx uart_tx(
.i_Clock    (clk),
.reset      (reset),
.i_Tx_DV    (r_Tx_DV),
.i_Tx_Byte  (r_Tx_Byte),
.o_Tx_Active(),
.o_Tx_Serial(uart_out),
.o_Tx_Done_l(w_Tx_Done)
);

//-------------------UART RX-----------------------
//UART RX I/O
wire [7:0] w_Rx_Byte;


UARTrx uart_rx(
.i_Clock    (clk),
.reset      (reset),
.i_Rx_Serial(uart_in),
.o_Rx_DV    (uart_rx_interrupt),
.o_Rx_Byte  (w_Rx_Byte)
);


//-------------------UART2 TX-----------------------
//UART TX I/O
wire r2_Tx_DV, w2_Tx_Done;
wire [7:0] r2_Tx_Byte;

UARTtx uart_tx2(
.i_Clock    (clk),
.reset      (reset),
.i_Tx_DV    (r2_Tx_DV),
.i_Tx_Byte  (r2_Tx_Byte),
.o_Tx_Active(),
.o_Tx_Serial(uart2_out),
.o_Tx_Done_l(w2_Tx_Done)
);

//-------------------UART2 RX-----------------------
//UART2 RX I/O
wire [7:0] w2_Rx_Byte;


UARTrx uart_rx2(
.i_Clock    (clk),
.reset      (reset),
.i_Rx_Serial(uart2_in),
.o_Rx_DV    (uart2_rx_interrupt),
.o_Rx_Byte  (w2_Rx_Byte)
);

//----------------SPI-(USB disk)-------------------
//SPI I/O
wire s_start;
wire [7:0] s_in;
wire [7:0] s_out;
wire s_busy;

SimpleSPI spi(
.clk        (clk),
.reset      (reset),
.t_start    (s_start),
.d_in       (s_in),
.d_out      (s_out),
.spi_clk    (s_clk),
.miso       (s_miso),
.mosi       (s_mosi),
.busy       (s_busy)
);

//----------------SPI2-(W5500)-------------------
//SPI I/O
wire s2_start;
wire [7:0] s2_in;
wire [7:0] s2_out;
wire s2_busy;

SimpleSPI spi2(
.clk        (clk),
.reset      (reset),
.t_start    (s2_start),
.d_in       (s2_in),
.d_out      (s2_out),
.spi_clk    (spi2_clk),
.miso       (spi2_miso),
.mosi       (spi2_mosi),
.busy       (s2_busy)
);

//----------------SPI3-(Flash)-------------------
//SPI I/O

wire s3_start;
wire [7:0] s3_in;
wire [7:0] s3_out;
wire s3_busy;

SimpleSPI spi3(
.clk        (clk),
.reset      (reset),
.t_start    (s3_start),
.d_in       (s3_in),
.d_out      (s3_out),
.spi_clk    (spi3_clk),
.miso       (spi_q),
.mosi       (spi3_mosi),
.busy       (s3_busy)
);


assign initDone         = (sr_initDone && sd_initDone);

assign sd_addr          = (address < 27'h800000)                            ? address                   : 24'd0;
assign sd_d             = (address < 27'h800000)                            ? data                      : 32'd0;
assign sd_we            = (address < 27'h800000)                            ? we                        : 1'd0;
assign sd_start         = (address < 27'h800000)                            ? start                     : 1'd0;

assign sr_addr          = (address >= 27'h800000 && address < 27'hC00000)   ? address - 27'h800000      : 24'd0;
assign sr_start         = (address >= 27'h800000 && address < 27'hC00000)   ? start                     : 1'd0;


assign vram32_cpu_addr  = (address >= 27'hC00000 && address < 27'hC00420)   ? address - 27'hC00000      : 14'd0;
assign vram32_cpu_d     = (address >= 27'hC00000 && address < 27'hC00420)   ? data                      : 32'd0;
assign vram32_cpu_we    = (address >= 27'hC00000 && address < 27'hC00420)   ? we                        : 1'd0;

assign vram8_cpu_addr   = (address >= 27'hC00420 && address < 27'hC02422)   ? address - 27'hC00420      : 14'd0;
assign vram8_cpu_d      = (address >= 27'hC00420 && address < 27'hC02422)   ? data                      : 8'd0;
assign vram8_cpu_we     = (address >= 27'hC00420 && address < 27'hC02422)   ? we                        : 1'd0;

assign vramSPR_cpu_addr   = (address >= 27'hC02632 && address < 27'hC02732) ? address - 27'hC02632      : 14'd0;
assign vramSPR_cpu_d      = (address >= 27'hC02632 && address < 27'hC02732) ? data                      : 9'd0;
assign vramSPR_cpu_we     = (address >= 27'hC02632 && address < 27'hC02732) ? we                        : 1'd0;

assign rom_addr         = (address >= 27'hC02422 && address < 27'hC02622)   ? address - 27'hC02422      : 9'd0;

assign t1_value         = (address == 27'hC02626 && we)                     ? data                      : 32'd0;
assign t1_set           = (address == 27'hC02626 && we)                     ? 1'b1                      : 1'b0;
assign t1_trigger       = (address == 27'hC02627 && we)                     ? 1'b1                      : 1'b0;

assign t2_value         = (address == 27'hC02628 && we)                     ? data                      : 32'd0;
assign t2_set           = (address == 27'hC02628 && we)                     ? 1'b1                      : 1'b0;
assign t2_trigger       = (address == 27'hC02629 && we)                     ? 1'b1                      : 1'b0;

assign t3_value         = (address == 27'hC0262A && we)                     ? data                      : 32'd0;
assign t3_set           = (address == 27'hC0262A && we)                     ? 1'b1                      : 1'b0;
assign t3_trigger       = (address == 27'hC0262B && we)                     ? 1'b1                      : 1'b0;

assign r_Tx_DV          = (address == 27'hC0262E && we)                     ? start                     : 1'b0;
assign r_Tx_Byte        = (address == 27'hC0262E)                           ? data                      : 8'd0;

assign r2_Tx_DV         = (address == 27'hC02732 && we)                     ? start                     : 1'b0;
assign r2_Tx_Byte       = (address == 27'hC02732)                           ? data                      : 8'd0;

assign s_in             = (address == 27'hC02631)                           ? data                      : 8'd0;
assign s_start          = (address == 27'hC02631 && we)                     ? start                     : 1'b0;

assign s2_in            = (address == 27'hC02734)                           ? data                      : 8'd0;
assign s2_start         = (address == 27'hC02734 && we)                     ? start                     : 1'b0;

assign s3_in            = (address == 27'hC02735)                           ? data                      : 8'd0;
assign s3_start         = (address == 27'hC02735 && we)                     ? start                     : 1'b0;


initial
begin
    busy <= 0;
    q <= 32'd0;
    GPO <= 8'd0;
    enableSPI3 <= 1'b0;
end

always @(negedge clk)
begin
    if (reset)
    begin
        busy <= 0;
        q <= 32'd0;
        GPO <= 8'd0;
        enableSPI3 <= 1'b0;
    end
    else 
    begin
        
        if (start)
            busy <= 1;

        //SDRAM
        if (busy && sd_q_ready && address < 27'h800000)
        begin
            busy <= 0;
            q <= sd_q;
        end

        //SPI FLASH
        if (busy && (sr_recvDone || enableSPI3) && address >= 27'h800000 && address < 27'hC00000)
        begin
            busy <= 0;
            q <= sr_q;
        end

        //VRAM32
        if (busy && address >= 27'hC00000 && address < 27'hC00420)
        begin
            busy <= 0;
            q <= vram32_cpu_q;
        end

        //VRAM8
        if (busy && address >= 27'hC00420 && address < 27'hC02422)
        begin
            busy <= 0;
            q <= {24'd0, vram8_cpu_q};
        end

        //ROM
        if (busy && address >= 27'hC02422 && address < 27'hC02622)
        begin
            busy <= 0;
            q <= rom_q;
        end

        //NESPAD
        if (busy && address == 27'hC02622)
        begin
            busy <= 0;
            q <= {16'd0, nesState};
        end

        //Keyboard
        if (busy && address == 27'hC02623)
        begin
            busy <= 0;
            q <= {24'd0, scanCode};
        end

        //CH376 n_interrupt
        if (busy && address == 27'hC02624)
        begin
            busy <= 0;
            q <= s_nint;
        end

        //Unused2
        if (busy && address == 27'hC02625)
        begin
            busy <= 0;
            q <= 32'd0;
        end

        //OStimers and (removed) NotePlayers
        if (busy && address >= 27'hC02626 && address < 27'hC0262E)
        begin
            busy <= 0;
            q <= 32'd0;
        end

        //UART TX
        if (busy && address == 27'hC0262E)
        begin
            if (w_Tx_Done)
            begin
                busy <= 0;
                q <=32'd0;
            end
        end

        //UART RX
        if (busy && address == 27'hC0262F)
        begin
            busy <= 0;
            q <= w_Rx_Byte;
        end

        //GPIO
        if (busy && address == 27'hC02630)
        begin
            if (we)
            begin
                GPO <= data[15:8];
            end
            busy <= 0;
            q <= {GPO,GPI};
        end

        //CH376 SPI
        if (busy && address == 27'hC02631 && !s_busy)
        begin
            busy <= 0;
            q <= s_out;
        end

        //VRAM8
        if (busy && address >= 27'hC02632 && address < 27'hC02732)
        begin
            busy <= 0;
            q <= {23'd0, vramSPR_cpu_q};
        end

        //UART2 TX
        if (busy && address == 27'hC02732)
        begin
            if (w2_Tx_Done)
            begin
                busy <= 0;
                q <=32'd0;
            end
        end

        //UART2 RX
        if (busy && address == 27'hC02733)
        begin
            busy <= 0;
            q <= w2_Rx_Byte;
        end

        //SPI2 W5500
        if (busy && address == 27'hC02734 && !s2_busy)
        begin
            busy <= 0;
            q <= s2_out;
        end

        //SPI3 Flash
        if (busy && address == 27'hC02735 && !s3_busy)
        begin
            busy <= 0;
            q <= s3_out;
        end

        //SPI3 enable
        if (busy && address == 27'hC02736)
        begin
            if (we)
            begin
                enableSPI3 <= data[0];
            end
            busy <= 0;
            q <= data[0];
        end

        //Prevent lockups
        if (busy && address >= 27'hC02737)
        begin
            busy <= 0;
            q <= 32'd0;
        end


    end
    
end

endmodule