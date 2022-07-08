`timescale 1 ns / 1 ps

// define GENERATE_PC_LOG to gerenate the PC log of each pipeline stage (only available in RTL simulation)
`define GENERATE_PC_LOG 

`ifdef GATELEVEL
  `ifndef PROC_BRAM_MACROS
    `define PROC_BRAM_MACROS 1
    `define PROGRAM_BRAM_MEMORY memory.memory.ram
    `define REGISTER_FILE "uut.\core_ID_base_decode_registers_register_file"
  `endif
`else
  `ifndef PROC_BRAM_MACROS
    `define PROC_BRAM_MACROS 1
    `define PROGRAM_BRAM_MEMORY memory.memory.ram
    `define REGISTER_FILE uut.core.ID.base_decode.registers.register_file
    `define CURRENT_PC uut.core.FI.PC_reg
  `endif
`endif

`ifdef GATELEVEL
        `define RAM_DATA_BLK00 memory.memory.BYTE_LOOP[0].BRAM_byte.ram_data
        `define RAM_DATA_BLK01 memory.memory.BYTE_LOOP[1].BRAM_byte.ram_data
        `define RAM_DATA_BLK02 memory.memory.BYTE_LOOP[2].BRAM_byte.ram_data
        `define RAM_DATA_BLK03 memory.memory.BYTE_LOOP[3].BRAM_byte.ram_data
`else
        `define RAM_DATA_BLK00 memory.memory.BYTE_LOOP[0].BRAM_byte.ram_data
        `define RAM_DATA_BLK01 memory.memory.BYTE_LOOP[1].BRAM_byte.ram_data
        `define RAM_DATA_BLK02 memory.memory.BYTE_LOOP[2].BRAM_byte.ram_data
        `define RAM_DATA_BLK03 memory.memory.BYTE_LOOP[3].BRAM_byte.ram_data
`endif


module test_skivav();

// for AES test
parameter KEY_ADDRESS = 32'h00000002;
parameter PT_ADDRESS  = 32'h00000006;
parameter CT_ADDRESS  = 32'h0000000a;
parameter RAND_ADDRESS  = 32'h0000000e;
reg [127:0] aes_key;
reg [127:0] aes_pt;
reg [127:0] ct;
reg [127:0] ct_dir_coproc;
reg [31:0] rand;

parameter CORE             = 0;
parameter DATA_WIDTH       = 32;
parameter ADDRESS_BITS     = 32;
parameter MEM_ADDRESS_BITS = 20;
parameter SCAN_CYCLES_MIN  = 0;
parameter SCAN_CYCLES_MAX  = 1000;
parameter PROGRAM          = "./present_tornado.vmh"; // vmh

genvar byte;
integer x;

reg clock;
reg reset;
reg [ADDRESS_BITS-1:0] program_address;

wire [ADDRESS_BITS-1:0] PC;

reg scan;

// annotate with the sdf delay file
`ifdef GATELEVEL
	initial $sdf_annotate("skivav.sdf", test_skivav.uut, , ,"MAXIMUM");
`endif

// initialize data RAM with key and pt
initial begin
	#2
        aes_key = `AES_KEY;
        aes_pt = `AES_PLAINTEXT;
	rand = $urandom();
	$display("random:%0x",rand);

        `RAM_DATA_BLK00[KEY_ADDRESS] = aes_key[103:96];
        `RAM_DATA_BLK01[KEY_ADDRESS] = aes_key[111:104];
        `RAM_DATA_BLK02[KEY_ADDRESS] = aes_key[119:112];
        `RAM_DATA_BLK03[KEY_ADDRESS] = aes_key[127:120];

        `RAM_DATA_BLK00[KEY_ADDRESS+1] = aes_key[71:64];
        `RAM_DATA_BLK01[KEY_ADDRESS+1] = aes_key[79:72];
        `RAM_DATA_BLK02[KEY_ADDRESS+1] = aes_key[87:80];
        `RAM_DATA_BLK03[KEY_ADDRESS+1] = aes_key[95:88];

        `RAM_DATA_BLK00[KEY_ADDRESS+2] = aes_key[39:32];
        `RAM_DATA_BLK01[KEY_ADDRESS+2] = aes_key[47:40];
        `RAM_DATA_BLK02[KEY_ADDRESS+2] = aes_key[55:48];
        `RAM_DATA_BLK03[KEY_ADDRESS+2] = aes_key[63:56];

        `RAM_DATA_BLK00[KEY_ADDRESS+3] = aes_key[7:0];
        `RAM_DATA_BLK01[KEY_ADDRESS+3] = aes_key[15:8];
        `RAM_DATA_BLK02[KEY_ADDRESS+3] = aes_key[23:16];
        `RAM_DATA_BLK03[KEY_ADDRESS+3] = aes_key[31:24];

        `RAM_DATA_BLK00[PT_ADDRESS] = aes_pt[103:96];
        `RAM_DATA_BLK01[PT_ADDRESS] = aes_pt[111:104];
        `RAM_DATA_BLK02[PT_ADDRESS] = aes_pt[119:112];
        `RAM_DATA_BLK03[PT_ADDRESS] = aes_pt[127:120];

        `RAM_DATA_BLK00[PT_ADDRESS+1] = aes_pt[71:64];
        `RAM_DATA_BLK01[PT_ADDRESS+1] = aes_pt[79:72];
        `RAM_DATA_BLK02[PT_ADDRESS+1] = aes_pt[87:80];
        `RAM_DATA_BLK03[PT_ADDRESS+1] = aes_pt[95:88];

        `RAM_DATA_BLK00[PT_ADDRESS+2] = aes_pt[39:32];
        `RAM_DATA_BLK01[PT_ADDRESS+2] = aes_pt[47:40];
        `RAM_DATA_BLK02[PT_ADDRESS+2] = aes_pt[55:48];
        `RAM_DATA_BLK03[PT_ADDRESS+2] = aes_pt[63:56];

        `RAM_DATA_BLK00[PT_ADDRESS+3] = aes_pt[7:0];
        `RAM_DATA_BLK01[PT_ADDRESS+3] = aes_pt[15:8];
        `RAM_DATA_BLK02[PT_ADDRESS+3] = aes_pt[23:16];
        `RAM_DATA_BLK03[PT_ADDRESS+3] = aes_pt[31:24];

        `RAM_DATA_BLK00[RAND_ADDRESS] = rand[7:0];
        `RAM_DATA_BLK01[RAND_ADDRESS] = rand[15:8];
        `RAM_DATA_BLK02[RAND_ADDRESS] = rand[23:16];
        `RAM_DATA_BLK03[RAND_ADDRESS] = rand[31:24];
end


// gpio connections:
wire [7:0] gpio;
wire [7:0] led;

// uart connections:
reg ser_rx;
wire ser_tx;

// tracking PC:
wire [ADDRESS_BITS-1:0] PC_fetch;
wire [ADDRESS_BITS-1:0] PC_decode;
wire [ADDRESS_BITS-1:0] PC_execute;
wire [ADDRESS_BITS-1:0] PC_memory;
wire [ADDRESS_BITS-1:0] PC_writeback;

// memory connections: 
// instruction memory/cache interface
wire i_mem_read;
wire [ADDRESS_BITS-1:0] i_mem_address_in;
wire [DATA_WIDTH-1  :0] i_mem_data_out;
wire [ADDRESS_BITS-1:0] i_mem_address_out;
wire i_mem_valid;
wire i_mem_ready;
// memory arbiter to data memory/cache connections
wire d_mem_read;
wire d_mem_write;
wire [DATA_WIDTH/8-1:0] d_mem_byte_en;
wire [ADDRESS_BITS-1:0] d_mem_address_in;
wire [DATA_WIDTH-1  :0] d_mem_data_in;
wire [DATA_WIDTH-1  :0] d_mem_data_out;
wire [ADDRESS_BITS-1:0] d_mem_address_out;
wire d_mem_valid;
wire d_mem_ready;


`ifdef GATELEVEL
  skivav uut (
    .clk(clock),
    .rst(reset),
    .program_address(program_address),
    
    // gpio
    .gpio(gpio),
    .led(led),
  
    // uart
    .ser_rx(ser_rx),
    .ser_tx(ser_tx),

    // memory signals
    // instruction memory/cache interface
    .i_mem_read(i_mem_read),
    .i_mem_address_in(i_mem_address_in),
    .i_mem_data_out(i_mem_data_out),
    .i_mem_address_out(i_mem_address_out),
    .i_mem_valid(i_mem_valid),
    .i_mem_ready(i_mem_ready),
    // memory arbiter to data memory/cache connections
    .d_mem_read(d_mem_read),
    .d_mem_write(d_mem_write),
    .d_mem_byte_en(d_mem_byte_en),
    .d_mem_address_in(d_mem_address_in),
    .d_mem_data_in(d_mem_data_in),
    .d_mem_data_out(d_mem_data_out),
    .d_mem_address_out(d_mem_address_out),
    .d_mem_valid(d_mem_valid),
    .d_mem_ready(d_mem_ready),
  
    .scan(1'b0)
  );
`else
  skivav #(
    .CORE(CORE),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_BITS(ADDRESS_BITS),
    .MEM_ADDRESS_BITS(MEM_ADDRESS_BITS),
    .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
    .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
  ) uut (
    .clk(clock),
    .rst(reset),
    .program_address(program_address),
    
    // gpio
    .gpio(gpio),
    .led(led),
  
    // uart
    .ser_rx(ser_rx),
    .ser_tx(ser_tx),

    // tracking PC 
    .PC_fetch(PC_fetch),
    .PC_decode(PC_decode),
    .PC_execute(PC_execute),
    .PC_memory(PC_memory),
    .PC_writeback(PC_writeback),
  
    // memory signals
    // instruction memory/cache interface
    .i_mem_read(i_mem_read),
    .i_mem_address_in(i_mem_address_in),
    .i_mem_data_out(i_mem_data_out),
    .i_mem_address_out(i_mem_address_out),
    .i_mem_valid(i_mem_valid),
    .i_mem_ready(i_mem_ready),
    // memory arbiter to data memory/cache connections
    .d_mem_read(d_mem_read),
    .d_mem_write(d_mem_write),
    .d_mem_byte_en(d_mem_byte_en),
    .d_mem_address_in(d_mem_address_in),
    .d_mem_data_in(d_mem_data_in),
    .d_mem_data_out(d_mem_data_out),
    .d_mem_address_out(d_mem_address_out),
    .d_mem_valid(d_mem_valid),
    .d_mem_ready(d_mem_ready),
  
    .scan(1'b0)
  );
`endif


dual_port_BRAM_memory_subsystem #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_BITS(ADDRESS_BITS),
  .MEM_ADDRESS_BITS(MEM_ADDRESS_BITS),
  .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
  .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
) memory (
  .clock(clock),
  .reset(reset),
  //instruction memory
  .i_mem_read(i_mem_read),
  .i_mem_address_in(i_mem_address_in),
  .i_mem_data_out(i_mem_data_out),
  .i_mem_address_out(i_mem_address_out),
  .i_mem_valid(i_mem_valid),
  .i_mem_ready(i_mem_ready),
  //data memory
  .d_mem_read(d_mem_read),
  .d_mem_write(d_mem_write),
  .d_mem_byte_en(d_mem_byte_en),
  .d_mem_address_in(d_mem_address_in),
  .d_mem_data_in(d_mem_data_in),
  .d_mem_data_out(d_mem_data_out),
  .d_mem_address_out(d_mem_address_out),
  .d_mem_valid(d_mem_valid),
  .d_mem_ready(d_mem_ready),

  .scan(scan)
);


// Clock generator
initial begin
    clock = 0;
end

always #(`CLK_PERIOD/2) clock = ~clock;

// pk: for reading .vmh files:
// Single reg to load program into before splitting it into bytes in the
// byte enabled dual port BRAM
reg [7:0] dummy_ram [0:(2**MEM_ADDRESS_BITS)*(DATA_WIDTH/8)-1];

// Initialize program memory
initial begin
  for(x=0; x<(2**MEM_ADDRESS_BITS)*(DATA_WIDTH/8); x=x+1) begin
    dummy_ram[x] = {8{1'b0}};
  end
  $readmemh(PROGRAM, dummy_ram);
end

generate
for(byte=0; byte<DATA_WIDTH/8; byte=byte+1) begin : BYTE_LOOP
  initial begin
    #1 // Wait for dummy ram to be initialzed
    // Copy dummy ram contents into each byte BRAM
    for(x=0; x<2**MEM_ADDRESS_BITS; x=x+1) begin
      memory.memory.BYTE_LOOP[byte].BRAM_byte.ram[x] = dummy_ram[byte+4*x][7:0];
      memory.memory.BYTE_LOOP[byte].BRAM_byte.ram_data[x] = dummy_ram[byte+4*x][7:0];
    end
  end
end
endgenerate


integer start_time;
integer end_time;
integer total_cycles;

initial begin
  clock  = 1;
  reset  = 1;
  scan = 0;
  program_address = {ADDRESS_BITS{1'b0}};
  #10

  @(posedge clock);
  @(posedge clock);
  #10
  reset = 0;
  start_time = $time;
end

reg [7:0] buffer;
localparam ser_half_period = (104+2)/2; // pk: calculated as: (the uart config register + 2) /2
event ser_sample;


// capture received data via UART:
always begin
    @(negedge ser_tx);

    repeat (ser_half_period) @(posedge clock);
    -> ser_sample; // start bit
    
    repeat (8) begin
        repeat (ser_half_period) @(posedge clock);
        repeat (ser_half_period) @(posedge clock);
        buffer = {ser_tx, buffer[7:1]};
        -> ser_sample; // data bit
    end
    
    repeat (ser_half_period) @(posedge clock);
    repeat (ser_half_period) @(posedge clock);
    -> ser_sample; // stop bit
    
    if (buffer < 32 || buffer >= 127)
        $display("Serial data int: %d at time %0t", buffer, $time);
    else
        $display("Serial data char: '%c' at time %0t", buffer, $time);
end

initial begin
  $display("testbench info: start %t",$time);
  wait(reset===1'b0); // wait for reset
  $display("testbench info: reset %t",$time);
  wait(gpio[0]===1'b1); // gpio high shows test started
  $display("testbench info: uut test start: %t",$time);
  wait(gpio[0]===1'b0); // gpio low shows test finished
  $display("testbench info: uut test end: %t",$time);
  wait(gpio[0]===1'b1); // gpio high shows ct copied  
  $finish;
end

`ifdef GENERATE_PC_LOG
  `ifndef GATELEVEL
     integer f_pc_fetch_log, f_pc_decode_log, f_pc_execute_log, f_pc_memory_log, f_pc_writeback_log;
     initial begin
       f_pc_fetch_log = $fopen("pc_fetch.txt","w");
       f_pc_decode_log = $fopen("pc_decode.txt","w");
       f_pc_execute_log = $fopen("pc_execute.txt","w");
       f_pc_memory_log = $fopen("pc_memory.txt","w");
       f_pc_writeback_log = $fopen("pc_writeback.txt","w");
     end

     always@(posedge clock) begin
       $fwrite(f_pc_fetch_log,"%0t\t%08x\n", $time, PC_fetch);
     end

     always@(posedge clock) begin
       $fwrite(f_pc_decode_log,"%0t\t%08x\n", $time, PC_decode);
     end

     always@(posedge clock) begin
       $fwrite(f_pc_execute_log,"%0t\t%08x\n", $time, PC_execute);
     end

     always@(posedge clock) begin
       $fwrite(f_pc_memory_log,"%0t\t%08x\n", $time, PC_memory);
     end

     always@(posedge clock) begin
       $fwrite(f_pc_writeback_log,"%0t\t%08x\n", $time, PC_writeback);
     end
  `endif
`endif

endmodule
