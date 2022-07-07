`define BUF_WIDTH 5    // BUF_SIZE = 32 -> BUF_WIDTH = 5, no. of bits to be used in pointer
`define BUF_WIDTH_P1 4
`define BUF_WIDTH_N1 2
`define BUF_SIZE ( 1<<`BUF_WIDTH )

module fifo ( clk, rst, buf_in, buf_out, wr_en, rd_en, buf_empty, buf_full);

input                 rst, clk, wr_en, rd_en;
// reset, system clock, write enable and read enable.
input [7:0]           buf_in;
// data input to be pushed to buffer
output[7:0]           buf_out;
// port to output the data using pop.
output                buf_empty, buf_full;
// buffer empty and full indication            

reg[`BUF_WIDTH :0]    fifo_counter;                     // number of data pushed in to buffer  
reg[`BUF_WIDTH -1:0]  rd_ptr, wr_ptr;           // pointer to read and write addresses  
reg[7:0]              buf_mem[`BUF_SIZE -1 : 0]; //  

assign  buf_empty = (fifo_counter==0)? 1'b1 : 1'b0;
assign  buf_full = (fifo_counter==`BUF_SIZE)? 1'b1: 1'b0;

always @(posedge clk or negedge rst) begin
   if( !rst )
       fifo_counter <= 0;

   else if( (!buf_full && wr_en) && ( !buf_empty && rd_en ) )
       fifo_counter <= fifo_counter;

   else if( !buf_full && wr_en )
       fifo_counter <= fifo_counter + `BUF_WIDTH'b1;

   else if( !buf_empty && rd_en )
       fifo_counter <= fifo_counter - `BUF_WIDTH'b1;

   else
      fifo_counter <= fifo_counter;
end

assign  buf_out = buf_mem[rd_ptr];

always @(posedge clk) begin
   if( wr_en && !buf_full )
      buf_mem[ wr_ptr ] <= buf_in;

   else
      buf_mem[ wr_ptr ] <= buf_mem[ wr_ptr ];
end

always@(posedge clk or negedge rst)
        if( !rst )begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                end
        else begin
                if( !buf_full && wr_en )
                        wr_ptr <= wr_ptr + `BUF_WIDTH_N1'b1;
                else
                        wr_ptr <= wr_ptr;

                if( !buf_empty && rd_en )
                        rd_ptr <= rd_ptr + `BUF_WIDTH_N1'b1;
                else
                        rd_ptr <= rd_ptr;
                end
endmodule

