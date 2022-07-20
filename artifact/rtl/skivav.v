module skivav #(
  parameter CORE             = 0,
  parameter DATA_WIDTH       = 32,
  parameter ADDRESS_BITS     = 32,
  parameter MEM_ADDRESS_BITS = 12, //pk 12,
  parameter SCAN_CYCLES_MIN  = 0,
  parameter SCAN_CYCLES_MAX  = 1000
) (
  input clk,
  input rst,

  input [ADDRESS_BITS-1:0] program_address,

//pk  output [ADDRESS_BITS-1:0] PC,

  inout [7:0] gpio,
  output [7:0] led,

  // uart signals:
  input ser_rx,
  output ser_tx,

  input scan,
  output [ADDRESS_BITS-1:0] issue_PC,


  // pk: tracking PC 
  output [ADDRESS_BITS-1:0] PC_fetch,
  output [ADDRESS_BITS-1:0] PC_decode,
  output [ADDRESS_BITS-1:0] PC_execute,
  output [ADDRESS_BITS-1:0] PC_memory,
  output [ADDRESS_BITS-1:0] PC_writeback,

  // memory signals
// instruction memory/cache interface
  output i_mem_read,
  output [ADDRESS_BITS-1:0] i_mem_address_in,
  input [DATA_WIDTH-1  :0] i_mem_data_out,
  input [ADDRESS_BITS-1:0] i_mem_address_out,
  input i_mem_valid,
  input i_mem_ready,
// memory arbiter to data memory/cache connections
  output d_mem_read,
  output d_mem_write,
  output [DATA_WIDTH/8-1:0] d_mem_byte_en,
  output [ADDRESS_BITS-1:0] d_mem_address_in,
  output [DATA_WIDTH-1  :0] d_mem_data_in,
  input [DATA_WIDTH-1  :0] d_mem_data_out,
  input [ADDRESS_BITS-1:0] d_mem_address_out,
  input d_mem_valid,
  input d_mem_ready
);

// gpio signals:
wire [7:0] gpio_i;
wire [7:0] gpio_o;
wire [7:0] gpio_oen;

// leds:
genvar ledi;
generate
  for (ledi=0 ; ledi<8 ; ledi=ledi+1) begin
    assign led[ledi] = gpio_o[ledi];
  end
endgenerate
  
//fetch stage interface
wire fetch_read;
wire [ADDRESS_BITS-1:0] fetch_address_out;
wire [DATA_WIDTH-1  :0] fetch_data_in;
wire [ADDRESS_BITS-1:0] fetch_address_in;
wire fetch_valid;
wire fetch_ready;
//memory stage interface
wire memory_read;
wire memory_write;
wire [DATA_WIDTH/8-1:0] memory_byte_en;
wire [ADDRESS_BITS-1:0] memory_address_out;
wire [DATA_WIDTH-1  :0] memory_data_out;
wire [DATA_WIDTH-1  :0] memory_data_in;
wire [ADDRESS_BITS-1:0] memory_address_in;
wire memory_valid;
wire memory_ready;
//data memory/cache interface
wire [DATA_WIDTH-1  :0] interface_d_mem_data_out;
wire [DATA_WIDTH-1  :0] interface_d_mem_data_in;
wire [ADDRESS_BITS-1:0] interface_d_mem_address_out;
wire interface_d_mem_valid;
wire interface_d_mem_ready;
wire interface_d_mem_read;
wire interface_d_mem_write;
wire [DATA_WIDTH/8-1:0] interface_d_mem_byte_en;
wire [ADDRESS_BITS-1:0] interface_d_mem_address_in;
// gpio interface
wire [DATA_WIDTH-1  :0] gpio_data_out;
wire [ADDRESS_BITS-1:0] gpio_address_out;
// wire gpio_valid;
wire gpio_valid;
wire gpio_read;
wire gpio_write;
wire [ADDRESS_BITS-1:0] gpio_address_in;
wire [DATA_WIDTH-1  :0] gpio_data_in;
// uart interface
wire [DATA_WIDTH/8-1:0] uart_reg_div_we;
wire [DATA_WIDTH-1  :0] uart_reg_div_di;
wire [DATA_WIDTH-1  :0] uart_reg_div_do;
wire uart_reg_dat_we;
wire uart_reg_dat_re;
wire [DATA_WIDTH-1  :0] uart_reg_dat_di;
wire [DATA_WIDTH-1  :0] uart_reg_dat_do;
wire uart_reg_dat_wait;
wire uart_recv_buf_valid;
// timer interface
wire [DATA_WIDTH-1  :0] timer_data_out;
wire timer_valid;
wire timer_ready;
wire timer_read;
wire [ADDRESS_BITS-1:0] timer_address_in;
// tdma signals
// tdma-memory_arbiter
wire [ADDRESS_BITS-1:0] tdma_ram_address_out;
wire [DATA_WIDTH/8-1:0] tdma_ram_wstrb_out;
wire tdma_ram_valid;
wire [DATA_WIDTH-1  :0] tdma_ram_data_out;
wire [DATA_WIDTH-1  :0] tdma_ram_data_in;
wire tdma_ram_write;
wire tdma_ram_read;
wire tdma_ram_ready;
wire ram_done;
// tdma-memory_interface
wire [DATA_WIDTH-1  :0] tdma_data_out;
// wire [ADDRESS_BITS-1:0] tdma_address_out;
wire tdma_valid;
wire tdma_ready;
wire tdma_read;
wire tdma_write;
wire [ADDRESS_BITS-1:0] tdma_address_in;
wire [DATA_WIDTH-1  :0] tdma_data_in;
// AES coprocessor interface
wire [DATA_WIDTH-1  :0] aes_data_out;
wire [ADDRESS_BITS-1:0] aes_address_out;
wire aes_valid;
wire aes_read;
wire aes_write;
wire [ADDRESS_BITS-1:0] aes_address_in;
wire [DATA_WIDTH-1  :0] aes_data_in;

assign PC = fetch_address_in << 1;

five_stage_core #(
  .CORE(CORE),
  .RESET_PC(32'd0),
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_BITS(ADDRESS_BITS),
  .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
  .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
) core (
  .clock(clk),
  .reset(rst),
  .program_address(program_address),
  //memory interface
  .fetch_valid(fetch_valid),
  .fetch_ready(fetch_ready),
  .fetch_data_in(fetch_data_in),
  .fetch_address_in(fetch_address_in),
  .memory_valid(memory_valid),
  .memory_ready(memory_ready),
  .memory_data_in(memory_data_in),
  .memory_address_in(memory_address_in),
  .fetch_read(fetch_read),
  .fetch_address_out(fetch_address_out),
  .memory_read(memory_read),
  .memory_write(memory_write),
  .memory_byte_en(memory_byte_en),
  .memory_address_out(memory_address_out),
  .memory_data_out(memory_data_out),
  // tracking PC
  .inst_PC_fetch(PC_fetch),
  .inst_PC_decode(PC_decode),
  .inst_PC_execute(PC_execute),
  .inst_PC_memory(PC_memory),
  .inst_PC_writeback(PC_writeback),
  //scan signal
  .issue_PC(issue_PC),
  .scan(scan)
);

memory_interface #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_BITS(ADDRESS_BITS)
) mem_interface (
  //fetch stage interface
  .fetch_read(fetch_read),
  .fetch_address_out(fetch_address_out),
  .fetch_data_in(fetch_data_in),
  .fetch_address_in(fetch_address_in),
  .fetch_valid(fetch_valid),
  .fetch_ready(fetch_ready),
  //memory stage interface
  .memory_read(memory_read),
  .memory_write(memory_write),
  .memory_byte_en(memory_byte_en),
  .memory_address_out(memory_address_out),
  .memory_data_out(memory_data_out),
  .memory_data_in(memory_data_in),
  .memory_address_in(memory_address_in),
  .memory_valid(memory_valid),
  .memory_ready(memory_ready),
  //instruction memory/cache interface
  .i_mem_data_out(i_mem_data_out),
  .i_mem_address_out(i_mem_address_out),
  .i_mem_valid(i_mem_valid),
  .i_mem_ready(i_mem_ready),
  .i_mem_read(i_mem_read),
  .i_mem_address_in(i_mem_address_in),
  //data memory/cache interface
  .d_mem_data_out(interface_d_mem_data_out),
  .d_mem_address_out(interface_d_mem_address_out),
  .d_mem_valid(interface_d_mem_valid),
  .d_mem_ready(interface_d_mem_ready),
  .d_mem_read(interface_d_mem_read),
  .d_mem_write(interface_d_mem_write),
  .d_mem_byte_en(interface_d_mem_byte_en),
  .d_mem_address_in(interface_d_mem_address_in),
  .d_mem_data_in(interface_d_mem_data_in),
  // gpio interface
  .gpio_data_out(gpio_data_out),
  .gpio_address_out(gpio_address_out),
  .gpio_valid(gpio_valid),
  .gpio_ready(1'b1),
  .gpio_read(gpio_read),
  .gpio_write(gpio_write),
  .gpio_address_in(gpio_address_in),
  .gpio_data_in(gpio_data_in),
  // uart interface
  .uart_reg_div_we(uart_reg_div_we),
  .uart_reg_div_di(uart_reg_div_di),
  .uart_reg_div_do(uart_reg_div_do),
  .uart_reg_dat_we(uart_reg_dat_we),
  .uart_reg_dat_re(uart_reg_dat_re),
  .uart_reg_dat_di(uart_reg_dat_di),
  .uart_reg_dat_do(uart_reg_dat_do),
  .uart_reg_dat_wait(uart_reg_dat_wait),
  .uart_recv_buf_valid(uart_recv_buf_valid),
  // tdma interface
  .tdma_data_out(tdma_data_out),
  // .tdma_address_out(tdma_address_out),
  .tdma_valid(tdma_valid),
  .tdma_ready(tdma_ready),
  .tdma_read(tdma_read),
  .tdma_write(tdma_write),
  .tdma_address_in(tdma_address_in),
  .tdma_data_in(tdma_data_in),
  // timer interface
  .timer_data_out(timer_data_out),
  .timer_valid(timer_valid),
  .timer_ready(timer_ready),
  .timer_read(timer_read),
  .timer_address_in(timer_address_in),
  // AES coprocessor
  .aes_data_out(aes_data_out),
  .aes_address_out(aes_address_out),
  .aes_valid(aes_valid),
  .aes_ready(1'b1),
  .aes_read(aes_read),
  .aes_write(aes_write),
  .aes_address_in(aes_address_in),
  .aes_data_in(aes_data_in)
);

aes_top aes_coprocessor (
  .clk (clk), 
  .resetn (~rst), 
  .valid (aes_read | aes_write),
  .ready (aes_valid),
  .wen (aes_write),
  .addr (aes_address_in[23:0]),
  .wdata (aes_data_in),
  .rdata (aes_data_out)
);

gpio_top gpio_inst (
  // internal:
  .clk (clk), 
  .resetn (~rst), 
  .valid (gpio_read | gpio_write),
  .ready (gpio_valid),
  .wen (gpio_write),
  .addr (gpio_address_in[23:0]),
  .wdata (gpio_data_in),
  .rdata (gpio_data_out),
  // external:
  .gpio_i (gpio_i),
  .gpio_o (gpio_o),
  .gpio_oen (gpio_oen)
);

timer_top timer_inst (
  .clk(clk), 
  .rst_n(~rst),
  .address_in(timer_address_in),
  .r_en(timer_read),
  .counter_out(timer_data_out),
  .valid(timer_valid),
  .ready(timer_ready) 
);

simpleuart uart (
  // internal:
  .clk         (clk         ),
  .resetn      (~rst      ),
  .reg_div_we  (uart_reg_div_we),
  .reg_div_di  (uart_reg_div_di),
  .reg_div_do  (uart_reg_div_do),
  .reg_dat_we  (uart_reg_dat_we),
  .reg_dat_re  (uart_reg_dat_re),
  .reg_dat_di  (uart_reg_dat_di),
  .reg_dat_do  (uart_reg_dat_do),
  .reg_dat_wait(uart_reg_dat_wait), 
  .recv_buf_valid  (uart_recv_buf_valid), 
  // external:
  .ser_tx      (ser_tx      ),
  .ser_rx      (ser_rx      )
);

dma_top  #(
  .DATA_WIDTH(32),
  .ADDRESS_BITS(32)
) tdma_top_inst(
  .clk_i (clk),    // Clock
  .rstn_i (~rst),   // reset active low
  // master (ram-dma) --> memory_arbiter
  .tdma_ram_address_out (tdma_ram_address_out),
  .tdma_ram_wstrb_out (tdma_ram_wstrb_out),
  .tdma_ram_valid (tdma_ram_valid),
  .tdma_ram_data_out (tdma_ram_data_out),
  .tdma_ram_data_in (tdma_ram_data_in),
  .tdma_ram_write (tdma_ram_write),
  .tdma_ram_read (tdma_ram_read),
  .tdma_ram_ready (tdma_ram_ready),
  .ram_done (ram_done),
  // slave (proc-dma) --> memory_interface
  .tdma_data_out (tdma_data_out),
  .tdma_valid (tdma_valid),
  .tdma_ready (tdma_ready),
  .tdma_read (tdma_read),
  .tdma_write (tdma_write),
  .tdma_address_in (tdma_address_in),
  .tdma_data_in (tdma_data_in)
  // .tdma_address_out (tdma_address_out),
);

memory_arbiter #(
  .DATA_WIDTH(32),
  .ADDRESS_BITS(32)
) memory_arbiter_inst (
    .clk (clk), 
    .reset_n (~rst),
    //-------- connections to ram
    .d_mem_data_out (d_mem_data_out),
    .d_mem_address_out (d_mem_address_out),
    .d_mem_valid (d_mem_valid),
    .d_mem_ready (d_mem_ready),
    .d_mem_read (d_mem_read),
    .d_mem_write (d_mem_write),
    .d_mem_byte_en (d_mem_byte_en),
    .d_mem_address_in (d_mem_address_in),
    .d_mem_data_in (d_mem_data_in),
    //-------- connections to memory interface
    .interface_d_mem_data_out (interface_d_mem_data_out),
    .interface_d_mem_address_out (interface_d_mem_address_out),
    .interface_d_mem_valid (interface_d_mem_valid),
    .interface_d_mem_ready (interface_d_mem_ready),
    .interface_d_mem_read (interface_d_mem_read),
    .interface_d_mem_write (interface_d_mem_write),
    .interface_d_mem_byte_en (interface_d_mem_byte_en),
    .interface_d_mem_address_in (interface_d_mem_address_in),
    .interface_d_mem_data_in (interface_d_mem_data_in),
    //-------- connections to dma
    // master (ram-dma)
    .tdma_ram_address_out (tdma_ram_address_out),
    .tdma_ram_wstrb_out (tdma_ram_wstrb_out),
    .tdma_ram_valid (tdma_ram_valid),
    .tdma_ram_data_out (tdma_ram_data_out),
    .tdma_ram_write (tdma_ram_write),
    .tdma_ram_read (tdma_ram_read),
    .tdma_ram_data_in (tdma_ram_data_in),
    .tdma_ram_ready (tdma_ram_ready),
    .ram_done (ram_done)
);


genvar i;
generate
  for (i=0; i<8 ; i=i+1) begin
    iopad #(.PADTECH("FPGA")) iopad_inst(.outp(gpio_i[i]), .inp(gpio_o[i]), .oen(gpio_oen[i]), .pad(gpio[i]));
  end
endgenerate

endmodule
