module memory_interface #(
  parameter DATA_WIDTH   = 32,
  parameter ADDRESS_BITS = 32
)(
  //fetch stage interface
  input  fetch_read,
  input  [ADDRESS_BITS-1:0] fetch_address_out,
  output [DATA_WIDTH-1  :0] fetch_data_in,
  output [ADDRESS_BITS-1:0] fetch_address_in,
  output fetch_valid,
  output fetch_ready,
  //memory stage interface
  input  memory_read,
  input  memory_write,
  input  [DATA_WIDTH/8-1:0] memory_byte_en,
  input  [ADDRESS_BITS-1:0] memory_address_out,
  input  [DATA_WIDTH-1  :0] memory_data_out,
  output [DATA_WIDTH-1  :0] memory_data_in,
  output [ADDRESS_BITS-1:0] memory_address_in,
  output memory_valid,
  output memory_ready,
  //instruction memory/cache interface
  input  [DATA_WIDTH-1  :0] i_mem_data_out,
  input  [ADDRESS_BITS-1:0] i_mem_address_out,
  input  i_mem_valid,
  input  i_mem_ready,
  output i_mem_read,
  output [ADDRESS_BITS-1:0] i_mem_address_in,
  //data memory/cache interface
  input  [DATA_WIDTH-1  :0] d_mem_data_out,
  input  [ADDRESS_BITS-1:0] d_mem_address_out,
  input  d_mem_valid,
  input  d_mem_ready,
  output d_mem_read,
  output d_mem_write,
  output [DATA_WIDTH/8-1:0] d_mem_byte_en,
  output [ADDRESS_BITS-1:0] d_mem_address_in,
  output [DATA_WIDTH-1  :0] d_mem_data_in,
  // gpio interface
  input  [DATA_WIDTH-1  :0] gpio_data_out,
  input  [ADDRESS_BITS-1:0] gpio_address_out,
  input  gpio_valid,
  input  gpio_ready,
  output gpio_read,
  output gpio_write,
  output [ADDRESS_BITS-1:0] gpio_address_in,
  output [DATA_WIDTH-1  :0] gpio_data_in,
  // uart interface
  output [DATA_WIDTH/8-1:0] uart_reg_div_we,
  output [DATA_WIDTH-1  :0] uart_reg_div_di,
  input  [DATA_WIDTH-1  :0] uart_reg_div_do,
  output                    uart_reg_dat_we,
  output                    uart_reg_dat_re,
  output [DATA_WIDTH-1  :0] uart_reg_dat_di,
  input  [DATA_WIDTH-1  :0] uart_reg_dat_do,
  input                     uart_reg_dat_wait,
  input                     uart_recv_buf_valid,
  // tdma interface
  input  [DATA_WIDTH-1  :0] tdma_data_out,
  // input  [ADDRESS_BITS-1:0] tdma_address_out,
  input  tdma_valid,
  input  tdma_ready,
  output tdma_read,
  output tdma_write,
  output [ADDRESS_BITS-1:0] tdma_address_in,
  output [DATA_WIDTH-1  :0] tdma_data_in,
  // timer interface
  input  [DATA_WIDTH-1  :0] timer_data_out,
  input  timer_valid,
  input  timer_ready,
  output timer_read,
  output [ADDRESS_BITS-1:0] timer_address_in,
  // AES coprocessor interface
  input  [DATA_WIDTH-1  :0] aes_data_out,
  input  [ADDRESS_BITS-1:0] aes_address_out,
  input  aes_valid,
  input  aes_ready,
  output aes_read,
  output aes_write,
  output [ADDRESS_BITS-1:0] aes_address_in,
  output [DATA_WIDTH-1  :0] aes_data_in
);

//************** instruction memory connections:
assign fetch_data_in     = i_mem_data_out;
assign fetch_address_in  = i_mem_address_out;
assign fetch_valid       = i_mem_valid;
assign fetch_ready       = i_mem_ready;

assign i_mem_read        = fetch_read;
assign i_mem_address_in  = fetch_address_out;

//************ data memory (or mem. mapped registers) connections
wire sel_dmem;
wire sel_uart_div;
wire sel_uart_dat;
wire sel_uart_recv_valid;
wire sel_uart_dat_wait;
wire sel_gpio;
wire sel_tdma;
wire sel_timer;
wire sel_aes;

assign sel_dmem = memory_address_out < 32'h0100_0000 ? 1'b1 : 1'b0;
assign sel_gpio = (memory_address_out >= 32'h0100_0000 && memory_address_out < 32'h0200_0000) ? 1'b1 : 1'b0;
assign sel_uart_div = memory_address_out == 32'h0200_0004;
assign sel_uart_dat = memory_address_out == 32'h0200_0008;
assign sel_uart_recv_valid = memory_address_out == 32'h0200_000C;
assign sel_uart_dat_wait  = memory_address_out == 32'h0200_0010;
assign sel_tdma = (memory_address_out >= 32'h0300_0000 && memory_address_out < 32'h0400_0000) ? 1'b1 : 1'b0;
assign sel_timer = (memory_address_out >= 32'h0200_0040) && (memory_address_out < 32'h0200_0080);
assign sel_aes = (memory_address_out >= 32'h0400_0000) && (memory_address_out < 32'h0500_0080);

// to processor pipeline:
assign memory_data_in    =  sel_dmem ? d_mem_data_out  :
                            sel_uart_div ? uart_reg_div_do :
                            sel_uart_dat ? uart_reg_dat_do:
                            sel_uart_recv_valid ? {31'b0, uart_recv_buf_valid}:
                            sel_uart_dat_wait ? {31'b0, uart_reg_dat_wait}:
                            sel_gpio ? gpio_data_out   :
                            sel_tdma ? tdma_data_out   :
                            sel_timer ? timer_data_out   :
                            sel_aes ? aes_data_out   :
                            0;                         

assign memory_address_in =  sel_dmem ? d_mem_address_out:
                            sel_uart_div ? memory_address_out:
                            sel_uart_dat ? memory_address_out:
                            sel_uart_recv_valid ? memory_address_out:
                            sel_uart_dat_wait ? memory_address_out:
                            sel_gpio ? memory_address_out:
                            sel_tdma ? memory_address_out:
                            sel_timer ? memory_address_out:
                            sel_aes ? memory_address_out:
                            0;                            

assign memory_valid      =  sel_dmem     ? d_mem_valid  :
                            sel_uart_div ? sel_uart_div :
                            sel_uart_dat ? (sel_uart_dat && !uart_reg_dat_wait) :
                            sel_gpio     ? gpio_valid   :
                            sel_tdma     ? tdma_valid   :
                            sel_timer    ? timer_valid  :
                            sel_aes      ? aes_valid  :
                            1'b1;                      

assign memory_ready      =  sel_dmem     ? d_mem_ready :
                            sel_uart_div ? 1'b1        :
                            sel_uart_dat ? (sel_uart_dat && !uart_reg_dat_wait) :
                            sel_gpio     ? gpio_ready  :
                            sel_tdma     ? tdma_ready  :
                            sel_timer    ? timer_ready  :
                            sel_aes      ? aes_ready  :
                            1'b1;                      

// from processor pipeline to data memory:
assign d_mem_byte_en     = sel_dmem ? memory_byte_en : 0;
assign d_mem_read        = sel_dmem ? memory_read : 0;
assign d_mem_write       = sel_dmem ? memory_write : 0;
assign d_mem_address_in  = sel_dmem ? memory_address_out : 0;
assign d_mem_data_in     = sel_dmem ? memory_data_out : 0;

// from processor pipeline to gpio:
assign gpio_read        = sel_gpio ? memory_read : 0;
assign gpio_write       = sel_gpio ? memory_write : 0;
assign gpio_address_in  = sel_gpio ? memory_address_out : 0;
assign gpio_data_in     = sel_gpio ? memory_data_out : 0;

// from processor pipeline to timer:
assign timer_read       = sel_timer ? memory_read : 0;
assign timer_address_in = sel_timer ? memory_address_out : 0;

// from processor pipeline to AES coprocessor:
assign aes_read       = sel_aes ? memory_read : 0;
assign aes_write       = sel_aes ? memory_write : 0;
assign aes_address_in = sel_aes ? memory_address_out : 0;
assign aes_data_in     = sel_aes ? memory_data_out : 0;

// from processor pipeline to uart:
assign uart_reg_div_we  = (sel_uart_div & memory_write) ? memory_byte_en : 0;
assign uart_reg_div_di  = sel_uart_div ? memory_data_out : 0;
assign uart_reg_dat_we  = (sel_uart_dat & memory_write) ? memory_byte_en[0] : 0;
assign uart_reg_dat_re  = (sel_uart_dat & memory_read)  ? |memory_byte_en : 0;
assign uart_reg_dat_di  = sel_uart_dat ? memory_data_out : 0;

// from processor pipeline to tdma:
assign tdma_read        = sel_tdma ? memory_read : 0;
assign tdma_write       = sel_tdma ? memory_write : 0;
assign tdma_address_in  = sel_tdma ? memory_address_out : 0;
assign tdma_data_in     = sel_tdma ? memory_data_out : 0;

endmodule
