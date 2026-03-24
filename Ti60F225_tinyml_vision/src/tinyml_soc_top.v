//***************************************************************/
//
// Moudel Name    : ddr3_example_top.v
// Version        : 1.1
// Date Created   : 2023-02-23 10:37:59
// Last Modified  : 2023-02-24 15:27:41
// Abstract       : ---
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`include "ddr3_controller/ddr3_parameter.vh"
`include "define.v"
`include "src/tinyml/defines.v"
module tinyml_soc_top #
(
parameter                       RANK_RATIO         = 1,       // # of unique CS outputs per rank
parameter                       CK_RATIO           = `CK_RATIO, 
parameter                       ASYN_AXI_CLK       = `ASYN_AXI_CLK, 
parameter                       RANKS              = `RANKS,
parameter                       CK_WIDTH           = `CK_WIDTH,       // # of CK/CK# outputs to memory   
parameter                       CKE_WIDTH          = `CKE_WIDTH,       // # of cke outputs
parameter                       CS_WIDTH           = `CS_WIDTH,       // # of unique CS outputs
parameter                       BANK_WIDTH         = `BANK_WIDTH,       // # of bank bits
parameter                       ROW_WIDTH          = `ROW_WIDTH,       // DRAM address bus width
parameter                       COL_WIDTH          = `COL_WIDTH,      // column address width
parameter                       DM_WIDTH           = `DM_WIDTH,       // # of DM (data mask)
parameter                       DQS_WIDTH          = `DQS_WIDTH,       // # of DQS (strobe)
parameter                       DQ_WIDTH           = `DQ_WIDTH,      // # of DQ (data)
parameter                       ODT_WIDTH          = `ODT_WIDTH,
parameter                       DQ_CNT_WIDTH       = `DQ_CNT_WIDTH,       // = ceil(log2(DQ_WIDTH))
parameter                       DQS_CNT_WIDTH      = `DQS_CNT_WIDTH,       // = ceil(log2(DQS_WIDTH))  
parameter                       DRAM_WIDTH         = `DRAM_WIDTH,       // # of DQ per DQS   
parameter                       DATA_WIDTH         = `DATA_WIDTH,
parameter                       ADDR_WIDTH         = `ADDR_WIDTH,    
parameter                       AXI_ID_WIDTH       = `AXI_ID_WIDTH,
parameter                       AXI_ADDR_WIDTH     = `AXI_ADDR_WIDTH,
parameter                       AXI_DATA_WIDTH     = `AXI_DATA_WIDTH,
//Input frame resolution from MIPI Rx.
parameter                       MIPI_FRAME_WIDTH      = 1920,  
parameter                       MIPI_FRAME_HEIGHT     = 1080,
//Actual frame resolution used for subsequent processing (after cropping/scaling).
parameter                       FRAME_WIDTH           = 540, //Multiple of 2 - To match with 2PPC pixel data.
parameter                       FRAME_HEIGHT          = 540  //Multiple of 2 - To preserve bayer format prior to raw2rgb conversion.
)
(

   // Clock and reset ports
   input                              i_arstn,
   input                              core_clk,     // CORE CLK @ 100MHz
   input                              sdram_clk,    // SDRAM CK @ 400MHz
   input                              rx_cal_clk,   // SDRAM CK @ 400MHz
   input                              tx_cal_clk,   // SDRAM CK @ 400MHz
   input                              tx_cal_clk_90edge,   // SDRAM CK @ 400MHz
   input                              pll_locked,
   input                              user_pll_locked,
   input                              i_sysclk,
   input                              i_peripheralClk,
   input                              i_fb_clk,
   input                              clk_pixel,
   input                              clk_pixel_2x,
   input                              clk_pixel_10x,
   //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
   output  wire                       system_uart_0_io_txd,
   input                              system_uart_0_io_rxd,   
    // debug core ports
`ifdef  Efinity_Debug  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& 
  input                               jtag_inst1_CAPTURE ,
  input                               jtag_inst1_DRCK    ,
  input                               jtag_inst1_RESET   ,
  input                               jtag_inst1_RUNTEST ,
  input                               jtag_inst1_SEL     ,
  input                               jtag_inst1_SHIFT   ,
  input                               jtag_inst1_TCK     ,
  input                               jtag_inst1_TDI     ,
  input                               jtag_inst1_TMS     ,
  input                               jtag_inst1_UPDATE  ,
  output                              jtag_inst1_TDO     ,
`endif  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
   //Camera MIPI RX
   input    wire                      i_cam_ck_LP_P_IN,
   input    wire                      i_cam_ck_LP_N_IN,
   output   wire                      o_cam_ck_HS_TERM,
   output   wire                      o_cam_ck_HS_ENA,
   input    wire                      i_cam_ck_CLKOUT_0,
   
   input    wire  [7:0]               i_cam_d0_HS_IN_0,
   input    wire                      i_cam_d0_LP_P_IN,
   input    wire                      i_cam_d0_LP_N_IN,
   output   wire                      o_cam_d0_HS_TERM,
   output   wire                      o_cam_d0_HS_ENA,
   output   wire                      o_cam_d0_RST,
   output   wire                      o_cam_d0_FIFO_RD,
   input    wire                      i_cam_d0_FIFO_EMPTY,
   
   input    wire  [7:0]               i_cam_d1_HS_IN_0,
   input    wire                      i_cam_d1_LP_P_IN,
   input    wire                      i_cam_d1_LP_N_IN,
   output   wire                      o_cam_d1_HS_TERM,
   output   wire                      o_cam_d1_HS_ENA,
   output   wire                      o_cam_d1_RST,
   output   wire                      o_cam_d1_FIFO_RD,
   input    wire                      i_cam_d1_FIFO_EMPTY,
  //Camera configuration
   output  wire                       mipi_i2c_0_io_scl_write,
   output  wire                       mipi_i2c_0_io_sda_write,
   output  wire                       mipi_i2c_0_io_sda_writeEnable,
   input   wire                       mipi_i2c_0_io_sda_read,
   output  wire                       mipi_i2c_0_io_scl_writeEnable,
   input   wire                       mipi_i2c_0_io_scl_read,
   output  wire			                  csi_ctl0_o,
	 output  wire			                  csi_ctl0_oe,
	 input 	 wire		                    csi_ctl0_i,
	 output  wire			                  csi_ctl1_o,
	 output  wire			                  csi_ctl1_oe,
	 input 	 wire		                    csi_ctl1_i,
  //HDMI Interface
  	//	HDMI Interface
	output 			                        hdmi_txc_oe,
	output 			                        hdmi_txd0_oe,
	output 			                        hdmi_txd1_oe,
	output 			                        hdmi_txd2_oe,
	
	output 			                        hdmi_txc_rst_o,
	output 			                        hdmi_txd0_rst_o,
	output 			                        hdmi_txd1_rst_o,
	output 			                        hdmi_txd2_rst_o,
	
	output 	[9:0] 	                    hdmi_txc_o,
	output 	[9:0] 	                    hdmi_txd0_o,
	output 	[9:0] 	                    hdmi_txd1_o,
	output 	[9:0] 	                    hdmi_txd2_o,
    
   // PLL status flags  
   output [2:0]                       pll_shift,  
   output [4:0]                       pll_shift_sel,
   output                             pll_shift_ena,  
   // memory interface ports
   output                             ddr_ck_hi,
   output                             ddr_ck_lo,
   output                             ddr_reset_n,
   output [CKE_WIDTH-1:0]             ddr_cke,     
   output [ROW_WIDTH-1:0]             ddr_addr,
   output [BANK_WIDTH-1:0]            ddr_ba,
   output                             ddr_cas_n,

   output [CS_WIDTH*RANK_RATIO-1:0]   ddr_cs_n,
   output                             ddr_ras_n,
   output                             ddr_we_n,
   
   input  [DQS_WIDTH-1:0]             ddr_dqs_in_hi,
   input  [DQS_WIDTH-1:0]             ddr_dqs_in_lo,
   input  [DQ_WIDTH-1:0]              ddr_dq_in_hi,
   input  [DQ_WIDTH-1:0]              ddr_dq_in_lo,
   
   output [DQS_WIDTH-1:0]             ddr_dqs_oe,
   output [DQS_WIDTH-1:0]             ddr_dqs_oe_n,
   output [DQ_WIDTH-1:0]              ddr_dq_oe,  
   output [DQS_WIDTH-1:0]             ddr_dqs_out_hi,
   output [DQS_WIDTH-1:0]             ddr_dqs_out_lo,
   output [DQ_WIDTH-1:0]              ddr_dq_out_hi,
   output [DQ_WIDTH-1:0]              ddr_dq_out_lo,
   output [DM_WIDTH-1:0]              ddr_dm_hi,
   output [DM_WIDTH-1:0]              ddr_dm_lo,
   output [ODT_WIDTH-1:0]             ddr_odt

   );


      
//Parameter Define
parameter FREQ = 200;			// default is 100 MHz.  Redefine as needed.
`ifndef SIM
    localparam CNT_INIT = 1.5*FREQ*1000;
`else
    localparam CNT_INIT = 10;
`endif    
  localparam   AIW               = AXI_ID_WIDTH      ;
  localparam   ADW               = AXI_DATA_WIDTH    ;
  localparam   ABN               = AXI_DATA_WIDTH/8   ;
  /////////////////////////////////////////////////////////
  // Wire declarations
  reg  [19:0]                       cnt;    
  wire                              clk;
  wire                              rst;
  wire                              mmcm_locked;
  reg                               aresetn;
  wire                              app_sr_active;
  wire                              app_ref_ack;
  wire                              app_zq_ack;
  wire                              axi_clk;

  wire                              cal_done;

  wire                  io_systemReset;
  wire                  io_memoryClk;
  wire                  io_peripheralReset;
//MIPI RX Camera
wire  [7:0]             w_cam_d0_HS_IN;
wire  [7:0]             w_cam_d1_HS_IN;

wire                    w_cam_ck_HS_ENA_0;
wire                    w_cam_ck_HS_TERM_0;
wire  [1:0]             w_cam_d_HS_ENA_0;
wire                    i_mipi_rx_pclk;
wire  [5:0]             w_mipi_rx_dt;
wire                    w_mipi_rx_vs;
wire                    w_mipi_rx_hs;
wire                    w_mipi_rx_de;
wire  [63:0]            w_mipi_rx_data;

reg   [10:0]            r_rx_x_mipi;
reg   [10:0]            r_rx_y_mipi;
reg                     r_rx_hs;
reg                     r_rx_vs;  

(* async_reg = "true" *)reg   [1:0]    r_mipi_rx_data_LP_P_IN_0_1P;
(* async_reg = "true" *)reg   [1:0]    r_mipi_rx_data_LP_N_IN_0_1P;
(* async_reg = "true" *)reg   [15:0]   r_mipi_rx_data_HS_IN_0_1P;
(* async_reg = "true" *)reg   [1:0]    r_mipi_rx_data_LP_P_IN_0_2P;
(* async_reg = "true" *)reg   [1:0]    r_mipi_rx_data_LP_N_IN_0_2P;
(* async_reg = "true" *)reg   [15:0]   r_mipi_rx_data_HS_IN_0_2P;

wire  [31:0]            debug_cam_display_fifo_status;
wire  [15:0]            rgb_control;
wire                    trigger_capture_frame;
wire                    continuous_capture_frame;
wire                    rgb_gray;
wire                    cam_dma_init_done;
wire  [31:0]            frames_per_second;
wire                    cam_confdone;

wire                    r_rstn_video;

wire                    dp_vs;
wire                    dp_hs;
wire                    dp_data_valid;
wire  [15:0]            dp_r_data;
wire  [15:0]            dp_g_data;
wire  [15:0]            dp_b_data;
wire  [8:0]             dp_frame_cnt;

wire            hdmi_vs ;
wire            hdmi_hs ;
wire            hdmi_de ;
wire    [23:0]  hdmi_data;

////////////////////////////////////////////////////////////////
// DMA controller
wire [63:0]             display_dma_rdata;
wire                    display_dma_rvalid;
wire [7:0]              display_dma_rkeep;
wire                    display_dma_rready;
wire                    debug_display_dma_fifo_overflow;
wire                    debug_display_dma_fifo_underflow;
wire [31:0]             debug_display_dma_fifo_rcount;
wire [31:0]             debug_display_dma_fifo_wcount;
wire                    set_red_green;

wire                    cam_dma_wready;
wire                    cam_dma_wvalid;
wire                    cam_dma_wlast;
wire [63:0]             cam_dma_wdata;
wire                    debug_cam_dma_fifo_overflow;
wire                    debug_cam_dma_fifo_underflow;
wire [31:0]             debug_cam_dma_fifo_rcount;
wire [31:0]             debug_cam_dma_fifo_wcount;
wire [31:0]             debug_cam_dma_status;

wire                    hw_accel_dma_rready;
wire                    hw_accel_dma_rvalid;
wire  [3:0]             hw_accel_dma_rkeep;
wire  [31:0]            hw_accel_dma_rdata;
wire                    hw_accel_dma_wready;
wire                    hw_accel_dma_wvalid;
wire                    hw_accel_dma_wlast;
wire  [31:0]            hw_accel_dma_wdata;

wire                    debug_dma_hw_accel_in_fifo_underflow;
wire                    debug_dma_hw_accel_in_fifo_overflow;
wire                    debug_dma_hw_accel_out_fifo_underflow;
wire                    debug_dma_hw_accel_out_fifo_overflow;
wire  [31:0]            debug_dma_hw_accel_in_fifo_wcount;
wire  [31:0]            debug_dma_hw_accel_out_fifo_rcount;

wire  [3:0]             dma_interrupts;

wire  [15:0]            io_apbSlave_0_PADDR;
wire                    io_apbSlave_0_PSEL;
wire                    io_apbSlave_0_PENABLE;
wire                    io_apbSlave_0_PREADY;
wire                    io_apbSlave_0_PWRITE;
wire  [31:0]            io_apbSlave_0_PWDATA;
wire  [31:0]            io_apbSlave_0_PRDATA;
wire                    io_apbSlave_0_PSLVERROR;
wire  [15:0]            io_apbSlave_1_PADDR;
wire                    io_apbSlave_1_PSEL;
wire                    io_apbSlave_1_PENABLE;
wire                    io_apbSlave_1_PREADY;
wire                    io_apbSlave_1_PWRITE;
wire  [31:0]            io_apbSlave_1_PWDATA;
wire  [31:0]            io_apbSlave_1_PRDATA;
wire                    io_apbSlave_1_PSLVERROR;

(* keep , syn_keep *) wire [3:0] dma_awregion /* synthesis syn_keep = 1 */;
(* keep , syn_keep *) wire [3:0] dma_arregion /* synthesis syn_keep = 1 */;

////////////////////////////////////////////////////////////////
// MIPI CSI RX Channel - Camera

assign i_mipi_rx_pclk = i_peripheralClk;

always@(posedge i_cam_ck_CLKOUT_0 or posedge io_systemReset)
begin
   if (io_systemReset)
   begin
      r_mipi_rx_data_LP_P_IN_0_1P   <= 2'b0;
      r_mipi_rx_data_LP_N_IN_0_1P   <= 2'b0;
      r_mipi_rx_data_HS_IN_0_1P     <= {16{1'b0}};
      
      r_mipi_rx_data_LP_P_IN_0_2P   <= 2'b0;
      r_mipi_rx_data_LP_N_IN_0_2P   <= 2'b0;
      r_mipi_rx_data_HS_IN_0_2P     <= {16{1'b0}};
   end
   else
   begin
      r_mipi_rx_data_LP_P_IN_0_1P   <= {i_cam_d1_LP_P_IN, i_cam_d0_LP_P_IN}; 
      r_mipi_rx_data_LP_N_IN_0_1P   <= {i_cam_d1_LP_N_IN, i_cam_d0_LP_N_IN};
      r_mipi_rx_data_HS_IN_0_1P     <= {w_cam_d1_HS_IN[7:0], w_cam_d0_HS_IN[7:0]};
               
      r_mipi_rx_data_LP_P_IN_0_2P   <= r_mipi_rx_data_LP_P_IN_0_1P;
      r_mipi_rx_data_LP_N_IN_0_2P   <= r_mipi_rx_data_LP_N_IN_0_1P;
      r_mipi_rx_data_HS_IN_0_2P     <= r_mipi_rx_data_HS_IN_0_1P;
   end
end

assign   w_cam_d0_HS_IN    = i_cam_d0_HS_IN_0;
assign   w_cam_d1_HS_IN    = i_cam_d1_HS_IN_0;

//assign   w_cam_d0_HS_IN    = {i_cam_d0_HS_IN_3, i_cam_d0_HS_IN_2, i_cam_d0_HS_IN_1, i_cam_d0_HS_IN_0};
//assign   w_cam_d1_HS_IN    = {i_cam_d1_HS_IN_3, i_cam_d1_HS_IN_2, i_cam_d1_HS_IN_1, i_cam_d1_HS_IN_0};

assign   o_cam_ck_HS_TERM  = w_cam_ck_HS_ENA_0;
assign   o_cam_ck_HS_ENA   = w_cam_ck_HS_ENA_0;
assign   o_cam_d0_HS_TERM  = w_cam_d_HS_ENA_0[0];
assign   o_cam_d1_HS_TERM  = w_cam_d_HS_ENA_0[1];
assign   o_cam_d0_HS_ENA   = w_cam_d_HS_ENA_0[0];
assign   o_cam_d1_HS_ENA   = w_cam_d_HS_ENA_0[1];
assign   o_cam_d0_RST      = 1'b0;
assign   o_cam_d1_RST      = 1'b0;

csi2_rx_cam #(
) u_csi2_rx_cam (
   .reset_n             (~io_systemReset),
   //.clk                 (i_mipi_clk),
   .clk                 (i_mipi_rx_pclk),
   .reset_byte_HS_n     (~io_systemReset),
   .clk_byte_HS         (i_cam_ck_CLKOUT_0),
   .reset_pixel_n       (~io_systemReset),
   .clk_pixel           (i_mipi_rx_pclk),
      
   .Rx_LP_CLK_P         (i_cam_ck_LP_P_IN),
   .Rx_LP_CLK_N         (i_cam_ck_LP_N_IN),
   .Rx_HS_enable_C      (w_cam_ck_HS_ENA_0),
   .LVDS_termen_C       (w_cam_ck_HS_TERM_0),

   //.Rx_LP_D_P           (r_mipi_rx_data_LP_P_IN_0_2P),
   //.Rx_LP_D_N           (r_mipi_rx_data_LP_N_IN_0_2P),
   
   .Rx_LP_D_P           (r_mipi_rx_data_LP_N_IN_0_2P),
   .Rx_LP_D_N           (r_mipi_rx_data_LP_P_IN_0_2P),
   .Rx_HS_D_0           (8'hff ^ r_mipi_rx_data_HS_IN_0_2P[7:0]),
   .Rx_HS_D_1           (8'hff ^ r_mipi_rx_data_HS_IN_0_2P[15:8]),
   
   .Rx_HS_D_2           (),
   .Rx_HS_D_3           (),
   .Rx_HS_D_4           (),
   .Rx_HS_D_5           (),
   .Rx_HS_D_6           (),
   .Rx_HS_D_7           (),
   .Rx_HS_enable_D      (w_cam_d_HS_ENA_0),
   .LVDS_termen_D       (),
   .fifo_rd_enable      ({o_cam_d1_FIFO_RD,    o_cam_d0_FIFO_RD}),
   .fifo_rd_empty       ({i_cam_d1_FIFO_EMPTY, i_cam_d0_FIFO_EMPTY}),
   .DLY_enable_D        (),
   .DLY_inc_D           (),
   .u_dly_enable_D      (),
   .u_dly_inc_D         (),
   
   .axi_clk             (1'b0),
   .axi_reset_n         (1'b0),
   .axi_awaddr          (6'b0),
   .axi_awvalid         (1'b0),
   .axi_awready         (),
   .axi_wdata           (32'b0),
   .axi_wvalid          (1'b0),
   .axi_wready          (),
   
   .axi_bvalid          (),
   .axi_bready          (1'b0),
   .axi_araddr          (6'b0),
   .axi_arvalid         (1'b0),
   .axi_arready         (),
   .axi_rdata           (),
   .axi_rvalid          (),
   .axi_rready          (1'b0),
   
   .hsync_vc0           (w_mipi_rx_hs),
   .hsync_vc1           (),
   .hsync_vc2           (),
   .hsync_vc3           (),
   .hsync_vc4           (),
   .hsync_vc5           (),
   .hsync_vc6           (),
   .hsync_vc7           (),
   .hsync_vc8           (),
   .hsync_vc9           (),
   .hsync_vc10          (),
   .hsync_vc11          (),
   .hsync_vc12          (),
   .hsync_vc13          (),
   .hsync_vc14          (),
   .hsync_vc15          (),
   .vsync_vc0           (w_mipi_rx_vs),
   .vsync_vc1           (),
   .vsync_vc2           (),
   .vsync_vc3           (),
   .vsync_vc4           (),
   .vsync_vc5           (),
   .vsync_vc6           (),
   .vsync_vc7           (),
   .vsync_vc8           (),
   .vsync_vc9           (),
   .vsync_vc10          (),
   .vsync_vc11          (),
   .vsync_vc12          (),
   .vsync_vc13          (),
   .vsync_vc14          (),
   .vsync_vc15          (),
   .vc                  (),
   .vcx                 (),
   .word_count          (),
   .shortpkt_data_field (),
   .datatype            (w_mipi_rx_dt),
   .pixel_per_clk       (),
   .pixel_data          (w_mipi_rx_data),
   .pixel_data_valid    (w_mipi_rx_de),
   .irq                 ()
);

////////////////////////////////////////////////////////////////
// Camera
      
assign mipi_i2c_0_io_sda_writeEnable = !mipi_i2c_0_io_sda_write;
assign mipi_i2c_0_io_scl_writeEnable = !mipi_i2c_0_io_scl_write;

assign csi_ctl0_oe = 0; 
assign csi_ctl1_oe = 0; 

cam_picam_v2 # (
   .MIPI_FRAME_WIDTH     (MIPI_FRAME_WIDTH),             //Input frame resolution from MIPI
   .MIPI_FRAME_HEIGHT    (MIPI_FRAME_HEIGHT),            //Input frame resolution from MIPI
   .FRAME_WIDTH          (FRAME_WIDTH),                  //Output frame resolution to external memory
   .FRAME_HEIGHT         (FRAME_HEIGHT),                 //Output frame resolution to external memory
   .DMA_TRANSFER_LENGTH  ((FRAME_WIDTH*FRAME_HEIGHT)/2)  //2PPC
) u_cam (
   .mipi_pclk                             (i_mipi_rx_pclk),
   .rst_n                                 (cal_done),
   .mipi_cam_data                         (w_mipi_rx_data),
   .mipi_cam_valid                        (w_mipi_rx_de),
   .mipi_cam_vs                           (w_mipi_rx_vs),
   .mipi_cam_hs                           (w_mipi_rx_hs),
   .mipi_cam_type                         (w_mipi_rx_dt),
   .cam_dma_wready                        (cam_dma_wready),
   .cam_dma_wvalid                        (cam_dma_wvalid),
   .cam_dma_wlast                         (cam_dma_wlast),
   .cam_dma_wdata                         (cam_dma_wdata),
   .rgb_control                           (rgb_control),
   .trigger_capture_frame                 (trigger_capture_frame),
   .continuous_capture_frame              (continuous_capture_frame),
   .rgb_gray                              (rgb_gray),
   .cam_dma_init_done                     (cam_dma_init_done),
   .frames_per_second                     (frames_per_second),
   .debug_cam_pixel_remap_fifo_overflow   (debug_cam_pixel_remap_fifo_overflow),
   .debug_cam_pixel_remap_fifo_underflow  (debug_cam_pixel_remap_fifo_underflow),
   .debug_cam_dma_fifo_overflow           (debug_cam_dma_fifo_overflow),
   .debug_cam_dma_fifo_underflow          (debug_cam_dma_fifo_underflow),
   .debug_cam_dma_fifo_rcount             (debug_cam_dma_fifo_rcount),
   .debug_cam_dma_fifo_wcount             (debug_cam_dma_fifo_wcount),
   .debug_cam_dma_status                  (debug_cam_dma_status)
);

////////////////////////////////////////////////////////////////
// Display
wire rstn_video;

wire                    bbox_dma_tvalid;
wire                    bbox_dma_tready;
wire                    bbox_dma_tlast;
wire [63:0]             bbox_dma_tdata;

display_annotator #(
   .FRAME_WIDTH  (FRAME_WIDTH),
   .FRAME_HEIGHT (FRAME_HEIGHT),
   .MAX_BBOX     (16)
) u_display_annotator (
   .clk        (clk_pixel_2x),
   .rst        (io_systemReset),
   .in_valid   (bbox_dma_tvalid),
   .in_last    (bbox_dma_tlast),
   .in_data    (bbox_dma_tdata),
   .in_ready   (bbox_dma_tready),
   .out_valid  (display_dma_rvalid),
   .out_data   (display_dma_rdata),
   .out_ready  (display_dma_rready)
);

localparam  VIDEO_MAX_HRES  = 11'd1920;
localparam  VIDEO_HSP       = 8'd44;
localparam  VIDEO_HBP       = 8'd148;
localparam  VIDEO_HFP       = 8'd88;

localparam  VIDEO_MAX_VRES  = 11'd1080;
localparam  VIDEO_VSP       = 6'd5;
localparam  VIDEO_VBP       = 6'd36;
localparam  VIDEO_VFP       = 6'd4;

display_hdmi_rgb #(
    .FRAME_WIDTH     (FRAME_WIDTH),
    .FRAME_HEIGHT    (FRAME_HEIGHT),

    .VIDEO_MAX_HRES  (VIDEO_MAX_HRES),
    .VIDEO_HSP       (VIDEO_HSP),
    .VIDEO_HBP       (VIDEO_HBP),
    .VIDEO_HFP       (VIDEO_HFP),

    .VIDEO_MAX_VRES  (VIDEO_MAX_VRES),
    .VIDEO_VSP       (VIDEO_VSP),
    .VIDEO_VBP       (VIDEO_VBP),
    .VIDEO_VFP       (VIDEO_VFP)
    
) inst_display_hdmi_rgb(
    .iHdmiClk                           (clk_pixel_2x),
    .iRst_n                             (~io_systemReset),
    
    // control offset display to red or green 
    .set_offset_display_rgb             (set_offset_display_rgb),
    
    //DMA RGB Input
    .ivDisplayDmaRdData                 (display_dma_rdata),
    .iDisplayDmaRdValid                 (display_dma_rvalid),
    .iv7DisplayDmaRdKeep                (8'hFF),
    .oDisplayDmaRdReady                 (display_dma_rready),
    
    // Status.
    .iRstDebugReg                       (1'b0),
    .oDebugDisplayDmaFifoUnderflow      (debug_display_dma_fifo_underflow),
    .oDebugDisplayDmaFifoOverflow       (debug_display_dma_fifo_overflow),
    .ov32DebugDisplayDmaFifoRCount      (debug_display_dma_fifo_rcount), 
    .ov32DebugDisplayDmaFifoWCount      (debug_display_dma_fifo_wcount),

    // Output to HDMI
    .oHdmiVs                         (hdmi_vs),
    .oHdmiHs                         (hdmi_hs),
    .oHdmiDe                         (hdmi_de),
    .oHdmiData                       (hdmi_data)
);

////////////////////////////////////////////////////////////////
// APB3 for camera & display
wire hw_accel_dma_init_done;

assign debug_cam_display_fifo_status = {22'd0,debug_dma_hw_accel_out_fifo_overflow,debug_dma_hw_accel_out_fifo_underflow,debug_dma_hw_accel_in_fifo_overflow,debug_dma_hw_accel_in_fifo_underflow, debug_cam_pixel_remap_fifo_underflow, debug_cam_pixel_remap_fifo_overflow, debug_cam_dma_fifo_underflow, debug_cam_dma_fifo_overflow, 
                                        debug_display_dma_fifo_underflow, debug_display_dma_fifo_overflow};

//Shared for both camera and display
common_apb3 #(
   .ADDR_WIDTH (16),
   .DATA_WIDTH (32),
   .NUM_REG    (7)
) u_apb3_cam_display (
//   .select_demo_mode                  ({user_dip1,user_dip0}),
   .cam_confdone                        (cam_confdone),
   .rgb_control                         (rgb_control),
   .trigger_capture_frame               (trigger_capture_frame),
   .continuous_capture_frame            (continuous_capture_frame),
   .rgb_gray                            (rgb_gray),
   .set_red_green                       (set_red_green),
   .cam_dma_init_done                   (cam_dma_init_done),
   .hw_accel_dma_init_done              (hw_accel_dma_init_done),

   .frames_per_second                   (frames_per_second),
   .debug_fifo_status                   (debug_cam_display_fifo_status),
   .debug_cam_dma_fifo_rcount           (debug_cam_dma_fifo_rcount),
   .debug_cam_dma_fifo_wcount           (debug_cam_dma_fifo_wcount),
   .debug_cam_dma_status                (debug_cam_dma_status),
   .debug_display_dma_fifo_rcount       (debug_display_dma_fifo_rcount),
   .debug_display_dma_fifo_wcount       (debug_display_dma_fifo_wcount),
   .debug_dma_hw_accel_in_fifo_wcount   (debug_dma_hw_accel_in_fifo_wcount),
   .debug_dma_hw_accel_out_fifo_rcount  (debug_dma_hw_accel_out_fifo_rcount),
   .clk                                 (i_peripheralClk),
   .resetn                              (~io_peripheralReset),
   .PADDR                               (io_apbSlave_1_PADDR),
   .PSEL                                (io_apbSlave_1_PSEL),
   .PENABLE                             (io_apbSlave_1_PENABLE),
   .PREADY                              (io_apbSlave_1_PREADY),
   .PWRITE                              (io_apbSlave_1_PWRITE),
   .PWDATA                              (io_apbSlave_1_PWDATA),
   .PRDATA                              (io_apbSlave_1_PRDATA),
   .PSLVERROR                           (io_apbSlave_1_PSLVERROR)
);


//Custom instruction
wire                    cpu_customInstruction_cmd_valid;
wire                    cpu_customInstruction_cmd_ready;
wire  [9:0]             cpu_customInstruction_function_id;
wire  [31:0]            cpu_customInstruction_inputs_0;
wire  [31:0]            cpu_customInstruction_inputs_1;
wire                    cpu_customInstruction_rsp_valid;
wire                    cpu_customInstruction_rsp_ready;
wire  [31:0]            cpu_customInstruction_outputs_0;
wire                    cpu_customInstruction_cmd_int;
wire                    userInterruptA;

localparam AXI_TINYML_DATA_WIDTH = 128;

wire [7:0]              axi_inter_s0_awid;
wire [31:0]             axi_inter_s0_awaddr;
wire [7:0]              axi_inter_s0_awlen;
wire [2:0]              axi_inter_s0_awsize;
wire [1:0]              axi_inter_s0_awburst;
wire                    axi_inter_s0_awlock;
wire [3:0]              axi_inter_s0_awcache;
wire [2:0]              axi_inter_s0_awprot;
wire [3:0]              axi_inter_s0_awqos;
wire                    axi_inter_s0_awvalid;
wire                    axi_inter_s0_awready;
wire [127:0]            axi_inter_s0_wdata;
wire [15:0]             axi_inter_s0_wstrb;
wire                    axi_inter_s0_wlast;
wire                    axi_inter_s0_wvalid;
wire                    axi_inter_s0_wready;
wire [7:0]              axi_inter_s0_bid;
wire [1:0]              axi_inter_s0_bresp;
wire                    axi_inter_s0_bvalid;
wire                    axi_inter_s0_bready;
wire [7:0]              axi_inter_s0_arid;
wire [31:0]             axi_inter_s0_araddr;
wire [7:0]              axi_inter_s0_arlen;
wire [2:0]              axi_inter_s0_arsize;
wire [1:0]              axi_inter_s0_arburst;
wire                    axi_inter_s0_arlock;
wire [3:0]              axi_inter_s0_arcache;
wire [2:0]              axi_inter_s0_arprot;
wire [3:0]              axi_inter_s0_arqos;
wire                    axi_inter_s0_arvalid;
wire                    axi_inter_s0_arready;
wire [7:0]              axi_inter_s0_rid;
wire [127:0]            axi_inter_s0_rdata;
wire [1:0]              axi_inter_s0_rresp;
wire                    axi_inter_s0_rlast;
wire                    axi_inter_s0_rvalid;
wire                    axi_inter_s0_rready;

wire [7:0]              axi_inter_s1_awid;
wire [31:0]             axi_inter_s1_awaddr;
wire [7:0]              axi_inter_s1_awlen;
wire [2:0]              axi_inter_s1_awsize;
wire [1:0]              axi_inter_s1_awburst;
wire                    axi_inter_s1_awlock;
wire [3:0]              axi_inter_s1_awcache;
wire [2:0]              axi_inter_s1_awprot;
wire [3:0]              axi_inter_s1_awqos;
wire                    axi_inter_s1_awvalid;
wire                    axi_inter_s1_awready;
wire [127:0]            axi_inter_s1_wdata;
wire [15:0]             axi_inter_s1_wstrb;
wire                    axi_inter_s1_wlast;
wire                    axi_inter_s1_wvalid;
wire                    axi_inter_s1_wready;
wire [7:0]              axi_inter_s1_bid;
wire [1:0]              axi_inter_s1_bresp;
wire                    axi_inter_s1_bvalid;
wire                    axi_inter_s1_bready;
wire [7:0]              axi_inter_s1_arid;
wire [31:0]             axi_inter_s1_araddr;
wire [7:0]              axi_inter_s1_arlen;
wire [2:0]              axi_inter_s1_arsize;
wire [1:0]              axi_inter_s1_arburst;
wire                    axi_inter_s1_arlock;
wire [3:0]              axi_inter_s1_arcache;
wire [2:0]              axi_inter_s1_arprot;
wire [3:0]              axi_inter_s1_arqos;
wire                    axi_inter_s1_arvalid;
wire                    axi_inter_s1_arready;
wire [7:0]              axi_inter_s1_rid;
wire [127:0]            axi_inter_s1_rdata;
wire [1:0]              axi_inter_s1_rresp;
wire                    axi_inter_s1_rlast;
wire                    axi_inter_s1_rvalid;
wire                    axi_inter_s1_rready;

wire [7:0]              axi_inter_s2_awid;
wire [31:0]             axi_inter_s2_awaddr;
wire [7:0]              axi_inter_s2_awlen;
wire [2:0]              axi_inter_s2_awsize;
wire [1:0]              axi_inter_s2_awburst;
wire                    axi_inter_s2_awlock;
wire [3:0]              axi_inter_s2_awcache;
wire [2:0]              axi_inter_s2_awprot;
wire [3:0]              axi_inter_s2_awqos;
wire                    axi_inter_s2_awvalid;
wire                    axi_inter_s2_awready;
wire [AXI_TINYML_DATA_WIDTH-1:0]            axi_inter_s2_wdata;
wire [AXI_TINYML_DATA_WIDTH/8-1:0]             axi_inter_s2_wstrb;
wire                    axi_inter_s2_wlast;
wire                    axi_inter_s2_wvalid;
wire                    axi_inter_s2_wready;
wire [7:0]              axi_inter_s2_bid;
wire [1:0]              axi_inter_s2_bresp;
wire                    axi_inter_s2_bvalid;
wire                    axi_inter_s2_bready;
wire [7:0]              axi_inter_s2_arid;
wire [31:0]             axi_inter_s2_araddr;
wire [7:0]              axi_inter_s2_arlen;
wire [2:0]              axi_inter_s2_arsize;
wire [1:0]              axi_inter_s2_arburst;
wire                    axi_inter_s2_arlock;
wire [3:0]              axi_inter_s2_arcache;
wire [2:0]              axi_inter_s2_arprot;
wire [3:0]              axi_inter_s2_arqos;
wire                    axi_inter_s2_arvalid;
wire                    axi_inter_s2_arready;
wire [7:0]              axi_inter_s2_rid;
wire [AXI_TINYML_DATA_WIDTH-1:0]            axi_inter_s2_rdata;
wire [1:0]              axi_inter_s2_rresp;
wire                    axi_inter_s2_rlast;
wire                    axi_inter_s2_rvalid;
wire                    axi_inter_s2_rready;

wire [7:0]              axi_inter_m_awid;
wire [31:0]             axi_inter_m_awaddr;
wire [7:0]              axi_inter_m_awlen;
wire [2:0]              axi_inter_m_awsize;
wire [1:0]              axi_inter_m_awburst;
wire                    axi_inter_m_awlock;
wire [3:0]              axi_inter_m_awcache;
wire [2:0]              axi_inter_m_awprot;
wire [3:0]              axi_inter_m_awqos;
wire [3:0]              axi_inter_m_awregion;
wire                    axi_inter_m_awvalid;
wire                    axi_inter_m_awready;
wire [127:0]            axi_inter_m_wdata;
wire [15:0]             axi_inter_m_wstrb;
wire                    axi_inter_m_wlast;
wire                    axi_inter_m_wvalid;
wire                    axi_inter_m_wready;
wire [7:0]              axi_inter_m_bid;
wire [1:0]              axi_inter_m_bresp;
wire                    axi_inter_m_bvalid;
wire                    axi_inter_m_bready;
wire [7:0]              axi_inter_m_arid;
wire [31:0]             axi_inter_m_araddr;
wire [7:0]              axi_inter_m_arlen;
wire [2:0]              axi_inter_m_arsize;
wire [1:0]              axi_inter_m_arburst;
wire                    axi_inter_m_arlock;
wire [3:0]              axi_inter_m_arcache;
wire [2:0]              axi_inter_m_arprot;
wire [3:0]              axi_inter_m_arqos;
wire [3:0]              axi_inter_m_arregion;
wire                    axi_inter_m_arvalid;
wire                    axi_inter_m_arready;
wire [7:0]              axi_inter_m_rid;
wire [127:0]            axi_inter_m_rdata;
wire [1:0]              axi_inter_m_rresp;
wire                    axi_inter_m_rlast;
wire                    axi_inter_m_rvalid;
wire                    axi_inter_m_rready;

  wire                              ddr_reset; 
  wire                              sys_rst;
  wire  [2:0]                       phy_wr_pll_shift;
  wire                              idelay_ld       ;
  wire                              mpr_rdlvl_dly   ;
  wire  [7:0]                       wrlvl_dq_check  ;
  wire  [7:0]                       rd_level_dqs_check;  
  wire  [2:0]                       rdlvl_shift;  
  wire  [2:0]                       wrlvl_shift;  
  wire  [15:0]                      debug_fifo;  
  wire  [15:0]                      overflow_fifo;  
  wire  [6:0]                       init_cur_state;  
  wire  [35:0]                      ddr_debug_port;  
  wire                              app_rdy;  
  wire                              user_clk;  
  wire                              ddr_rstn;  

  
// Start of User Design top instance
//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************
always @(posedge user_clk or negedge sys_rst) begin
	if (!sys_rst)
		cnt <= 0;
    else if (cnt != CNT_INIT) 
        cnt <= cnt + 20'd1;
	else 
        cnt <= cnt;
end
assign ddr_rstn = (cnt == CNT_INIT);


generate
if (ASYN_AXI_CLK) begin
assign user_clk = axi_clk;

end else begin
assign user_clk = core_clk;
end
endgenerate
//***************************************************************************
// The traffic generation module instantiated below drives traffic (patterns)
// on the application interface of the memory controller
//***************************************************************************
//***************************************************************************

assign sys_rst       = pll_locked & user_pll_locked;

//***************************************************************************
ddr3_top                 u_ddr3_top
      (
      
    .axi_clk                (user_clk            ),
    .core_clk               (core_clk            ),
    .sdram_clk              (sdram_clk           ),  
    .rx_cal_clk             (rx_cal_clk          ),
    .tx_cal_clk             (tx_cal_clk          ),
    .tx_cal_clk_90edge      (tx_cal_clk_90edge   ),
    .rstn                   (ddr_rstn            ),      
    .pll_shift              (pll_shift           ),
    .pll_shift_sel          (pll_shift_sel       ),
    .pll_shift_ena          (pll_shift_ena       ), 
///////////////DDR BUS
    .ddr_ck_hi              (ddr_ck_hi           ),
    .ddr_ck_lo              (ddr_ck_lo           ),
    .ddr_cke                (ddr_cke             ),    
    .ddr_reset_n            (ddr_reset_n         ),
    .ddr_cs_n               (ddr_cs_n            ),
    .ddr_ras_n              (ddr_ras_n           ),
    .ddr_cas_n              (ddr_cas_n           ),
    .ddr_we_n               (ddr_we_n            ),     
    .ddr_addr               (ddr_addr            ),
    .ddr_ba                 (ddr_ba              ),

    .ddr_dqs_oe             (ddr_dqs_oe          ),
    .ddr_dqs_oe_n           (ddr_dqs_oe_n        ),
    .ddr_dq_oe              (ddr_dq_oe           ),
    .ddr_dqs_in_hi          (ddr_dqs_in_hi       ),
    .ddr_dqs_in_lo          (ddr_dqs_in_lo       ),
    .ddr_dq_in_hi           (ddr_dq_in_hi        ),
    .ddr_dq_in_lo           (ddr_dq_in_lo        ),

    .ddr_dqs_out_hi         (ddr_dqs_out_hi      ),
    .ddr_dqs_out_lo         (ddr_dqs_out_lo      ),
    .ddr_dq_out_hi          (ddr_dq_out_hi       ),
    .ddr_dq_out_lo          (ddr_dq_out_lo       ),
    
    .ddr_dm_hi              (ddr_dm_hi           ),
    .ddr_dm_lo              (ddr_dm_lo           ),
    .ddr_odt                (ddr_odt             ),

// Application interface ports
       .app_sr_req                     (1'b0),
       .app_ref_req                    (1'b0),
       .app_zq_req                     (1'b0),
       .app_sr_active                  (app_sr_active),
       .app_ref_ack                    (app_ref_ack),
       .app_zq_ack                     (app_zq_ack),

// Slave Interface Write Address Ports
       .s_axi_awid                     (axi_inter_m_awid        ),
       .s_axi_awaddr                   (axi_inter_m_awaddr      ),
       .s_axi_awlen                    (axi_inter_m_awlen       ),
       .s_axi_awsize                   (axi_inter_m_awsize      ),
       .s_axi_awburst                  (axi_inter_m_awburst     ),
       .s_axi_awlock                   (axi_inter_m_awlock      ),
       .s_axi_awcache                  (axi_inter_m_awcache     ),
       .s_axi_awprot                   (axi_inter_m_awprot      ),
       .s_axi_awqos                    (axi_inter_m_awqos       ),
       .s_axi_awvalid                  (axi_inter_m_awvalid     ),
       .s_axi_awready                  (axi_inter_m_awready     ),
// Slave Interface Write Data Ports
       .s_axi_wdata                    (axi_inter_m_wdata       ),
       .s_axi_wstrb                    (axi_inter_m_wstrb       ),
       .s_axi_wlast                    (axi_inter_m_wlast       ),
       .s_axi_wvalid                   (axi_inter_m_wvalid      ),
       .s_axi_wready                   (axi_inter_m_wready      ),
// Slave Interface Write Response Ports
       .s_axi_bid                      (axi_inter_m_bid         ),
       .s_axi_bresp                    (axi_inter_m_bresp       ),
       .s_axi_bvalid                   (axi_inter_m_bvalid      ),
       .s_axi_bready                   (axi_inter_m_bready      ),
// Slave Interface Read Address Ports
       .s_axi_arid                     (axi_inter_m_arid        ),
       .s_axi_araddr                   (axi_inter_m_araddr      ),
       .s_axi_arlen                    (axi_inter_m_arlen       ),
       .s_axi_arsize                   (axi_inter_m_arsize      ),
       .s_axi_arburst                  (axi_inter_m_arburst     ),
       .s_axi_arlock                   (axi_inter_m_arlock      ),
       .s_axi_arcache                  (axi_inter_m_arcache     ),
       .s_axi_arprot                   (axi_inter_m_arprot      ),
       .s_axi_arqos                    (axi_inter_m_arqos              ),
       .s_axi_arvalid                  (axi_inter_m_arvalid     ),
       .s_axi_arready                  (axi_inter_m_arready     ),
// Slave Interface Read Data Ports
       .s_axi_rid                      (axi_inter_m_rid         ),
       .s_axi_rdata                    (axi_inter_m_rdata       ),
       .s_axi_rresp                    (axi_inter_m_rresp       ),
       .s_axi_rlast                    (axi_inter_m_rlast       ),
       .s_axi_rvalid                   (axi_inter_m_rvalid      ),
       .s_axi_rready                   (axi_inter_m_rready      ),
//DEBUG       
       .wrlvl_dq_check                 (wrlvl_dq_check    ) ,
       .rd_level_dqs_check             (rd_level_dqs_check) ,
       .rdlvl_shift                    (rdlvl_shift) ,
       .wrlvl_shift                    (wrlvl_shift) ,
       .init_cur_state                 (init_cur_state    ) ,
       .idelay_ld                      (idelay_ld         ) ,
       .mpr_rdlvl_dly                  (mpr_rdlvl_dly     ) ,
       .ddr_debug_port                 (ddr_debug_port    ) ,
       .cal_done                       (cal_done          ) 
       );
// End of User Design top instance

//***************************************************************************

//***************************************************************************

assign io_memoryClk = user_clk;
assign userInterruptA = cpu_customInstruction_cmd_int;
assign userInterruptB = |dma_interrupts;

sapphire_soc u_sapphire_soc(
    .io_asyncReset                      (!cal_done                        ),
    .io_systemClk                       (i_sysclk                           ),

    //UART 0
    .system_uart_0_io_txd               (system_uart_0_io_txd               ),
    .system_uart_0_io_rxd               (system_uart_0_io_rxd               ),
    .io_memoryClk                       (io_memoryClk                       ),
    .io_systemReset                     (io_systemReset                     ),
    .io_memoryReset                     (                                   ),
    .io_peripheralClk                   (i_peripheralClk                    ),
    .io_peripheralReset                 (io_peripheralReset                  ),    
    //External Memory AXI4 Interface
    .io_ddrA_aw_payload_prot            (                                  ),
    .io_ddrA_aw_payload_qos             (                                  ),
    .io_ddrA_aw_payload_cache           (                                  ),
    .io_ddrA_aw_payload_lock            (axi_inter_s0_awlock                     ),
    .io_ddrA_aw_payload_burst           (axi_inter_s0_awburst                    ),
    .io_ddrA_aw_payload_size            (axi_inter_s0_awsize                     ),
    .io_ddrA_aw_payload_len             (axi_inter_s0_awlen                      ),
    .io_ddrA_aw_payload_region          (                                  ),
    .io_ddrA_aw_payload_id              (axi_inter_s0_awid                       ),
    .io_ddrA_aw_payload_addr            (axi_inter_s0_awaddr                     ),
    .io_ddrA_aw_ready                   (axi_inter_s0_awready                    ),
    .io_ddrA_aw_valid                   (axi_inter_s0_awvalid                    ),

    .io_ddrA_w_payload_last             (axi_inter_s0_wlast                      ),
    .io_ddrA_w_ready                    (axi_inter_s0_wready                     ),
    .io_ddrA_w_valid                    (axi_inter_s0_wvalid                     ),    
    .io_ddrA_w_payload_strb             (axi_inter_s0_wstrb                      ),
    .io_ddrA_w_payload_data             (axi_inter_s0_wdata                      ),

    .io_ddrA_b_payload_resp             (                                  ),
    .io_ddrA_b_payload_id               (axi_inter_s0_bid                        ),
    .io_ddrA_b_ready                    (axi_inter_s0_bready                     ),
    .io_ddrA_b_valid                    (axi_inter_s0_bvalid                     ),

    .io_ddrA_ar_payload_prot            (                                  ),
    .io_ddrA_ar_payload_qos             (                                  ),
    .io_ddrA_ar_payload_cache           (                                  ),
    .io_ddrA_ar_payload_region          (                                  ),
    .io_ddrA_ar_payload_lock            (axi_inter_s0_arlock                     ),
    .io_ddrA_ar_payload_burst           (axi_inter_s0_arburst                    ),
    .io_ddrA_ar_payload_size            (axi_inter_s0_arsize                     ),
    .io_ddrA_ar_payload_len             (axi_inter_s0_arlen                      ),
    .io_ddrA_ar_payload_id              (axi_inter_s0_arid                       ),
    .io_ddrA_ar_payload_addr            (axi_inter_s0_araddr                     ),
    .io_ddrA_ar_ready                   (axi_inter_s0_arready                    ),
    .io_ddrA_ar_valid                   (axi_inter_s0_arvalid                    ),

    .io_ddrA_r_payload_last             (axi_inter_s0_rlast                      ),
    .io_ddrA_r_payload_resp             (axi_inter_s0_rresp                      ),
    .io_ddrA_r_payload_id               (axi_inter_s0_rid                        ),
    .io_ddrA_r_payload_data             (axi_inter_s0_rdata                      ),
    .io_ddrA_r_ready                    (axi_inter_s0_rready                     ),
    .io_ddrA_r_valid                    (axi_inter_s0_rvalid                     ),
    
    //custom instruction
    .cpu0_customInstruction_cmd_valid   (cpu_customInstruction_cmd_valid),
    .cpu0_customInstruction_cmd_ready   (cpu_customInstruction_cmd_ready),
    .cpu0_customInstruction_function_id (cpu_customInstruction_function_id),
    .cpu0_customInstruction_inputs_0    (cpu_customInstruction_inputs_0),
    .cpu0_customInstruction_inputs_1    (cpu_customInstruction_inputs_1),
    .cpu0_customInstruction_rsp_valid   (cpu_customInstruction_rsp_valid),
    .cpu0_customInstruction_rsp_ready   (cpu_customInstruction_rsp_ready),
    .cpu0_customInstruction_outputs_0   (cpu_customInstruction_outputs_0),
     //SPI 0
    .system_spi_0_io_sclk_write         (system_spi_0_io_sclk_write         ),
    .system_spi_0_io_data_0_writeEnable (system_spi_0_io_data_0_writeEnable ),
    .system_spi_0_io_data_0_read        (system_spi_0_io_data_0_read        ),
    .system_spi_0_io_data_0_write       (system_spi_0_io_data_0_write       ),
    .system_spi_0_io_data_1_writeEnable (system_spi_0_io_data_1_writeEnable ),
    .system_spi_0_io_data_1_read        (system_spi_0_io_data_1_read        ),
    .system_spi_0_io_data_1_write       (system_spi_0_io_data_1_write       ),
    .system_spi_0_io_data_2_writeEnable (                                   ),
    .system_spi_0_io_data_2_read        (                                   ),
    .system_spi_0_io_data_2_write       (                                   ),
    .system_spi_0_io_data_3_writeEnable (                                   ),
    .system_spi_0_io_data_3_read        (                                   ),
    .system_spi_0_io_data_3_write       (                                   ),
    .system_spi_0_io_ss                 (system_spi_0_io_ss                 ),

    .system_i2c_0_io_sda_write          (mipi_i2c_0_io_sda_write),
    .system_i2c_0_io_sda_read           (mipi_i2c_0_io_sda_read),
    .system_i2c_0_io_scl_write          (mipi_i2c_0_io_scl_write),
    .system_i2c_0_io_scl_read           (mipi_i2c_0_io_scl_read),
    .io_apbSlave_0_PADDR                (io_apbSlave_0_PADDR),
    .io_apbSlave_0_PSEL                 (io_apbSlave_0_PSEL),
    .io_apbSlave_0_PENABLE              (io_apbSlave_0_PENABLE),
    .io_apbSlave_0_PREADY               (io_apbSlave_0_PREADY),
    .io_apbSlave_0_PWRITE               (io_apbSlave_0_PWRITE),
    .io_apbSlave_0_PWDATA               (io_apbSlave_0_PWDATA),
    .io_apbSlave_0_PRDATA               (io_apbSlave_0_PRDATA),
    .io_apbSlave_0_PSLVERROR            (io_apbSlave_0_PSLVERROR),
    .io_apbSlave_1_PADDR                (io_apbSlave_1_PADDR),
    .io_apbSlave_1_PSEL                 (io_apbSlave_1_PSEL),
    .io_apbSlave_1_PENABLE              (io_apbSlave_1_PENABLE),
    .io_apbSlave_1_PREADY               (io_apbSlave_1_PREADY),
    .io_apbSlave_1_PWRITE               (io_apbSlave_1_PWRITE),
    .io_apbSlave_1_PWDATA               (io_apbSlave_1_PWDATA),
    .io_apbSlave_1_PRDATA               (io_apbSlave_1_PRDATA),
    .io_apbSlave_1_PSLVERROR            (io_apbSlave_1_PSLVERROR),
    .userInterruptA                     (userInterruptA),
    .userInterruptB                     (userInterruptB),

    //Hard Jtag Tap
    .jtagCtrl_tck                       (jtag_inst1_TCK                     ),
    .jtagCtrl_tdi                       (jtag_inst1_TDI                     ),
    .jtagCtrl_tdo                       (jtag_inst1_TDO                     ),
    .jtagCtrl_enable                    (jtag_inst1_SEL                     ),
    .jtagCtrl_capture                   (jtag_inst1_CAPTURE                 ),
    .jtagCtrl_shift                     (jtag_inst1_SHIFT                   ),
    .jtagCtrl_update                    (jtag_inst1_UPDATE                  ),
    .jtagCtrl_reset                     (jtag_inst1_RESET                   )
);


////////////////////////////////////////////////////////////////
// Hardware Accelerator

//For mediapipe face landmark model
//Scale from FRAME_WIDTHxFRAME_HEIGHT to 192x192 resolution

`define YOLO_DEMO

hw_accel_wrapper #(
   .FRAME_WIDTH         (FRAME_WIDTH),
   .FRAME_HEIGHT        (FRAME_HEIGHT),
`ifdef YOLO_DEMO
   .DOWN_WIDTH          (56),
   .DOWN_HEIGHT         (56),
   .DMA_TRANSFER_LENGTH ((56*56*3)/4) //S2MM DMA transfer for mediapipe face landmark demo
`else
   .DOWN_WIDTH          (192),
   .DOWN_HEIGHT         (192),
   .DMA_TRANSFER_LENGTH ((192*192*3)/4) //S2MM DMA transfer for mediapipe face landmark demo
`endif
) u_hw_accel_wrapper (
   .clk                                         (i_sysclk               ),
   .rst                                         (io_systemReset         ),
   .hw_accel_dma_init_done                      (hw_accel_dma_init_done ),
   .dma_rready                                  (hw_accel_dma_rready),
   .dma_rvalid                                  (hw_accel_dma_rvalid),
   .dma_rdata                                   (hw_accel_dma_rdata),
   .dma_rkeep                                   (hw_accel_dma_rkeep),
   .dma_wready                                  (hw_accel_dma_wready),
   .dma_wvalid                                  (hw_accel_dma_wvalid),
   .dma_wlast                                   (hw_accel_dma_wlast),
   .dma_wdata                                   (hw_accel_dma_wdata),
   
   // Debug Register
   .debug_dma_hw_accel_in_fifo_underflow        (debug_dma_hw_accel_in_fifo_underflow),
   .debug_dma_hw_accel_in_fifo_overflow         (debug_dma_hw_accel_in_fifo_overflow),
   .debug_dma_hw_accel_out_fifo_underflow       (debug_dma_hw_accel_out_fifo_underflow),
   .debug_dma_hw_accel_out_fifo_overflow        (debug_dma_hw_accel_out_fifo_overflow),
   .debug_dma_hw_accel_in_fifo_wcount           (debug_dma_hw_accel_in_fifo_wcount),
   .debug_dma_hw_accel_out_fifo_rcount          (debug_dma_hw_accel_out_fifo_rcount)
);

////////////////////////////////////////////////////////////////
// DMA controller

dma u_dma (
   .clk              (io_memoryClk),
   .reset            (io_systemReset),
   .ctrl_clk         (i_peripheralClk),
   .ctrl_reset       (io_peripheralReset),
   .ctrl_PADDR       (io_apbSlave_0_PADDR),
   .ctrl_PSEL        (io_apbSlave_0_PSEL),
   .ctrl_PENABLE     (io_apbSlave_0_PENABLE),
   .ctrl_PREADY      (io_apbSlave_0_PREADY),
   .ctrl_PWRITE      (io_apbSlave_0_PWRITE),
   .ctrl_PWDATA      (io_apbSlave_0_PWDATA),
   .ctrl_PRDATA      (io_apbSlave_0_PRDATA),
   .ctrl_PSLVERROR   (io_apbSlave_0_PSLVERROR),
   .ctrl_interrupts  (dma_interrupts),
   .read_arvalid     (axi_inter_s1_arvalid),
   .read_arready     (axi_inter_s1_arready),
   .read_araddr      (axi_inter_s1_araddr),
   .read_arregion    (dma_arregion),         //Keep from synthesized away
   .read_arlen       (axi_inter_s1_arlen),
   .read_arsize      (axi_inter_s1_arsize),
   .read_arburst     (axi_inter_s1_arburst),
   .read_arlock      (axi_inter_s1_arlock),
   .read_arcache     (axi_inter_s1_arcache),
   .read_arqos       (axi_inter_s1_arqos),
   .read_arprot      (axi_inter_s1_arprot),
   .read_rvalid      (axi_inter_s1_rvalid),
   .read_rready      (axi_inter_s1_rready),
   .read_rdata       (axi_inter_s1_rdata),
   .read_rresp       (axi_inter_s1_rresp),
   .read_rlast       (axi_inter_s1_rlast),
   .write_awvalid    (axi_inter_s1_awvalid),
   .write_awready    (axi_inter_s1_awready),
   .write_awaddr     (axi_inter_s1_awaddr),
   .write_awregion   (dma_awregion),         //Keep from synthesized away
   .write_awlen      (axi_inter_s1_awlen),
   .write_awsize     (axi_inter_s1_awsize),
   .write_awburst    (axi_inter_s1_awburst),
   .write_awlock     (axi_inter_s1_awlock),
   .write_awcache    (axi_inter_s1_awcache),
   .write_awqos      (axi_inter_s1_awqos),
   .write_awprot     (axi_inter_s1_awprot),
   .write_wvalid     (axi_inter_s1_wvalid),
   .write_wready     (axi_inter_s1_wready),
   .write_wdata      (axi_inter_s1_wdata),
   .write_wstrb      (axi_inter_s1_wstrb),
   .write_wlast      (axi_inter_s1_wlast),
   .write_bvalid     (axi_inter_s1_bvalid),
   .write_bready     (axi_inter_s1_bready),
   .write_bresp      (axi_inter_s1_bresp), 
   //64-bit dma channel (S2MM - to external memory)
   .dat0_i_clk       (i_mipi_rx_pclk),
   .dat0_i_reset     (io_systemReset),
   .dat0_i_tvalid    (cam_dma_wvalid),
   .dat0_i_tready    (cam_dma_wready),
   .dat0_i_tdata     (cam_dma_wdata),
   .dat0_i_tkeep     ({8{cam_dma_wvalid}}),
   .dat0_i_tdest     (4'd0),
   .dat0_i_tlast     (cam_dma_wlast),
   //64-bit dma channel (MM2S - from external memory)
   .dat1_o_clk       (clk_pixel_2x),
   .dat1_o_reset     (io_systemReset),
   .dat1_o_tvalid    (bbox_dma_tvalid),
   .dat1_o_tready    (bbox_dma_tready),
   .dat1_o_tdata     (bbox_dma_tdata),
   .dat1_o_tkeep     (),
   .dat1_o_tdest     (),
   .dat1_o_tlast     (bbox_dma_tlast),
   //32-bit dma channel (S2MM - to external memory)
   .dat2_i_clk       (i_sysclk),
   .dat2_i_reset     (io_systemReset),
   .dat2_i_tvalid    (hw_accel_dma_wvalid),
   .dat2_i_tready    (hw_accel_dma_wready),
   .dat2_i_tdata     (hw_accel_dma_wdata),
   .dat2_i_tkeep     ({4{hw_accel_dma_wvalid}}),
   .dat2_i_tdest     (4'd0),
   .dat2_i_tlast     (hw_accel_dma_wlast),
   //32-bit dma channel (MM2S - from external memory)
   .dat3_o_clk       (i_sysclk),
   .dat3_o_reset     (io_systemReset),
   .dat3_o_tvalid    (hw_accel_dma_rvalid),
   .dat3_o_tready    (hw_accel_dma_rready),
   .dat3_o_tdata     (hw_accel_dma_rdata),
   .dat3_o_tkeep     (hw_accel_dma_rkeep),
   .dat3_o_tdest     (),
   .dat3_o_tlast     ()
);

//////////////////////////////////////////////////////////////////////////////
// TinyML accelerator

tinyml_top#(
  .AXI_DW             (AXI_TINYML_DATA_WIDTH)
) u_tinyml_top(
   .clk              (i_sysclk),
   .reset            (io_systemReset),
   .cmd_valid        (cpu_customInstruction_cmd_valid),
   .cmd_ready        (cpu_customInstruction_cmd_ready),
   .cmd_function_id  (cpu_customInstruction_function_id),
   .cmd_inputs_0     (cpu_customInstruction_inputs_0),
   .cmd_inputs_1     (cpu_customInstruction_inputs_1),
   .cmd_int          (cpu_customInstruction_cmd_int),
   .rsp_valid        (cpu_customInstruction_rsp_valid),
   .rsp_ready        (cpu_customInstruction_rsp_ready),
   .rsp_outputs_0    (cpu_customInstruction_outputs_0),
   .m_axi_clk        (io_memoryClk),
   .m_axi_rstn       (!io_systemReset),
   .m_axi_awvalid    (axi_inter_s2_awvalid),
   .m_axi_awaddr     (axi_inter_s2_awaddr),
   .m_axi_awlen      (axi_inter_s2_awlen),
   .m_axi_awsize     (axi_inter_s2_awsize),
   .m_axi_awburst    (axi_inter_s2_awburst),
   .m_axi_awprot     (axi_inter_s2_awprot),
   .m_axi_awlock     (axi_inter_s2_awlock),
   .m_axi_awcache    (axi_inter_s2_awcache),
   .m_axi_awready    (axi_inter_s2_awready),
   .m_axi_wdata      (axi_inter_s2_wdata),
   .m_axi_wstrb      (axi_inter_s2_wstrb),
   .m_axi_wlast      (axi_inter_s2_wlast),
   .m_axi_wvalid     (axi_inter_s2_wvalid),
   .m_axi_wready     (axi_inter_s2_wready),
   .m_axi_bresp      (axi_inter_s2_bresp),
   .m_axi_bvalid     (axi_inter_s2_bvalid),
   .m_axi_bready     (axi_inter_s2_bready),
   .m_axi_arvalid    (axi_inter_s2_arvalid),
   .m_axi_araddr     (axi_inter_s2_araddr),
   .m_axi_arlen      (axi_inter_s2_arlen),
   .m_axi_arsize     (axi_inter_s2_arsize),
   .m_axi_arburst    (axi_inter_s2_arburst),
   .m_axi_arprot     (axi_inter_s2_arprot),
   .m_axi_arlock     (axi_inter_s2_arlock),
   .m_axi_arcache    (axi_inter_s2_arcache),
   .m_axi_arready    (axi_inter_s2_arready),
   .m_axi_rvalid     (axi_inter_s2_rvalid),
   .m_axi_rdata      (axi_inter_s2_rdata),
   .m_axi_rlast      (axi_inter_s2_rlast),
   .m_axi_rresp      (axi_inter_s2_rresp),
   .m_axi_rready     (axi_inter_s2_rready)
);

axi_interconnect #(
   .S_COUNT    (3),
   .M_COUNT    (1),
   .DATA_WIDTH (AXI_DATA_WIDTH),
   .ADDR_WIDTH (32),
   .ID_WIDTH   (8)
) u_axi_interconnect (
   .clk              (io_memoryClk),
   .rst              (io_systemReset),
   .s_axi_awid       ({axi_inter_s2_awid   , axi_inter_s1_awid   , axi_inter_s0_awid   }),
   .s_axi_awaddr     ({axi_inter_s2_awaddr , axi_inter_s1_awaddr , axi_inter_s0_awaddr }),
   .s_axi_awlen      ({axi_inter_s2_awlen  , axi_inter_s1_awlen  , axi_inter_s0_awlen  }),
   .s_axi_awvalid    ({axi_inter_s2_awvalid, axi_inter_s1_awvalid, axi_inter_s0_awvalid}),
   .s_axi_awready    ({axi_inter_s2_awready, axi_inter_s1_awready, axi_inter_s0_awready}),
   .s_axi_wdata      ({axi_inter_s2_wdata  , axi_inter_s1_wdata  , axi_inter_s0_wdata  }),
   .s_axi_wstrb      ({axi_inter_s2_wstrb  , axi_inter_s1_wstrb  , axi_inter_s0_wstrb  }),
   .s_axi_wlast      ({axi_inter_s2_wlast  , axi_inter_s1_wlast  , axi_inter_s0_wlast  }),
   .s_axi_wvalid     ({axi_inter_s2_wvalid , axi_inter_s1_wvalid , axi_inter_s0_wvalid }),
   .s_axi_wready     ({axi_inter_s2_wready , axi_inter_s1_wready , axi_inter_s0_wready }),
   .s_axi_bid        ({axi_inter_s2_bid    , axi_inter_s1_bid    , axi_inter_s0_bid    }),
   .s_axi_bresp      ({axi_inter_s2_bresp  , axi_inter_s1_bresp  , axi_inter_s0_bresp  }),
   .s_axi_bvalid     ({axi_inter_s2_bvalid , axi_inter_s1_bvalid , axi_inter_s0_bvalid }),
   .s_axi_bready     ({axi_inter_s2_bready , axi_inter_s1_bready , axi_inter_s0_bready }),
   .s_axi_arid       ({axi_inter_s2_arid   , axi_inter_s1_arid   , axi_inter_s0_arid   }),
   .s_axi_araddr     ({axi_inter_s2_araddr , axi_inter_s1_araddr , axi_inter_s0_araddr }),
   .s_axi_arlen      ({axi_inter_s2_arlen  , axi_inter_s1_arlen  , axi_inter_s0_arlen  }),
   .s_axi_arvalid    ({axi_inter_s2_arvalid, axi_inter_s1_arvalid, axi_inter_s0_arvalid}),
   .s_axi_arready    ({axi_inter_s2_arready, axi_inter_s1_arready, axi_inter_s0_arready}),
   .s_axi_rid        ({axi_inter_s2_rid    , axi_inter_s1_rid    , axi_inter_s0_rid    }),
   .s_axi_rdata      ({axi_inter_s2_rdata  , axi_inter_s1_rdata  , axi_inter_s0_rdata  }),
   .s_axi_rresp      ({axi_inter_s2_rresp  , axi_inter_s1_rresp  , axi_inter_s0_rresp  }),
   .s_axi_rlast      ({axi_inter_s2_rlast  , axi_inter_s1_rlast  , axi_inter_s0_rlast  }),
   .s_axi_rvalid     ({axi_inter_s2_rvalid , axi_inter_s1_rvalid , axi_inter_s0_rvalid }),
   .s_axi_rready     ({axi_inter_s2_rready , axi_inter_s1_rready , axi_inter_s0_rready }),

   .m_axi_awid       (axi_inter_m_awid),
   .m_axi_awaddr     (axi_inter_m_awaddr),
   .m_axi_awlen      (axi_inter_m_awlen),
   .m_axi_awsize     (axi_inter_m_awsize),
   .m_axi_awburst    (axi_inter_m_awburst),
   .m_axi_awlock     (axi_inter_m_awlock),
   .m_axi_awcache    (axi_inter_m_awcache),
   .m_axi_awprot     (axi_inter_m_awprot),
   .m_axi_awvalid    (axi_inter_m_awvalid),
   .m_axi_awready    (axi_inter_m_awready),
   .m_axi_wdata      (axi_inter_m_wdata),
   .m_axi_wstrb      (axi_inter_m_wstrb),
   .m_axi_wlast      (axi_inter_m_wlast),
   .m_axi_wvalid     (axi_inter_m_wvalid),
   .m_axi_wready     (axi_inter_m_wready),
   .m_axi_bresp      (axi_inter_m_bresp),
   .m_axi_bvalid     (axi_inter_m_bvalid),
   .m_axi_bready     (axi_inter_m_bready),
   .m_axi_arid       (axi_inter_m_arid),
   .m_axi_araddr     (axi_inter_m_araddr),
   .m_axi_arlen      (axi_inter_m_arlen),
   .m_axi_arsize     (axi_inter_m_arsize),
   .m_axi_arburst    (axi_inter_m_arburst),
   .m_axi_arlock     (axi_inter_m_arlock),
   .m_axi_arcache    (axi_inter_m_arcache),
   .m_axi_arprot     (axi_inter_m_arprot),
   .m_axi_arvalid    (axi_inter_m_arvalid),
   .m_axi_arready    (axi_inter_m_arready),
   .m_axi_rdata      (axi_inter_m_rdata),
   .m_axi_rresp      (axi_inter_m_rresp),
   .m_axi_rlast      (axi_inter_m_rlast),
   .m_axi_rvalid     (axi_inter_m_rvalid),
   .m_axi_rready     (axi_inter_m_rready)
);

/*
wire                              boundcrop_vs  ;
wire                              boundcrop_hs  ;
wire                              boundcrop_de  ;
wire [23:0]                       boundcrop_data;
FrameBoundCrop #(
  .SKIP_ROWS(2),
  .SKIP_COLS(2),
  .TOTAL_ROWS(MIPI_FRAME_HEIGHT),
  .TOTAL_COLS(MIPI_FRAME_WIDTH)
  ) inst2_FrameCrop(
  .clk_i                             (clk_pixel_2x               ),
  .rst_i                             (io_systemReset            ),
   
  .vs_i                              (hdmi_vs              ),
  .hs_i                              (hdmi_hs              ),
  .de_i                              (hdmi_de              ),
  .data_i                            (hdmi_data            ),
    
  .vs_o                              (boundcrop_vs               ),
  .hs_o                              (boundcrop_hs               ),
  .de_o                              (boundcrop_de               ),
  .data_o                            (boundcrop_data             ) 
);
*/

	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	LVDS Output 
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	HDMI requires specific timing, thus is not compatible with LCD & LVDS & DSI. Must implement standalone. 
	
  assign hdmi_txd0_rst_o = io_systemReset; 
  assign hdmi_txd1_rst_o = io_systemReset; 
  assign hdmi_txd2_rst_o = io_systemReset; 
  assign hdmi_txc_rst_o  = io_systemReset; 

  assign hdmi_txd0_oe = 1'b1; 
  assign hdmi_txd1_oe = 1'b1; 
  assign hdmi_txd2_oe = 1'b1; 
  assign hdmi_txc_oe = 1'b1; 

   rgb2dvi #(.ENABLE_OSERDES(0)) u_rgb2dvi 
	(
		.oe_i 		(1                   ), 			//	Always enable output
		.bitflip_i  (4'b0000             ), 		//	Reverse clock & data lanes. 
		
		.aRst	    (1'b0                ), 
		.aRst_n		(1'b1                ), 
		
		.PixelClk	(clk_pixel_2x        ),//pixel clk = 74.25M
		.SerialClk  (                    ),//pixel clk *5 = 371.25M
		
		.vid_pVSync(hdmi_vs               ), 
		.vid_pHSync(hdmi_hs               ), 
		.vid_pVDE  (hdmi_de               ), 
		.vid_pData (hdmi_data             ), 
		
		.txc_o		(hdmi_txc_o           ), 
		.txd0_o		(hdmi_txd0_o          ), 
		.txd1_o		(hdmi_txd1_o          ), 
		.txd2_o		(hdmi_txd2_o          )
	); 
endmodule
