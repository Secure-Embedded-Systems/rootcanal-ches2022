`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Tom Conroy
// 
// Module Name: fifo
// Description: generic FIFO
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_dma #(
        parameter integer C_WIDTH       = 64,   // width of FIFO in bits
        parameter integer C_DEPTH       = 5     // depth of FIFO = 2^C_DEPTH
    )
    (
        input   logic                   clk_i,
        input   logic                   rstn_i,
        
        input   logic   [C_WIDTH-1:0]   data_i,
        input   logic                   push_i,
        
        output  logic   [C_WIDTH-1:0]   data_o,
        input   logic                   pop_i,
        
        output  logic                   empty_o,
        output  logic                   full_o
    );
    
    enum {not_full, full} state;
    
    logic   [(2**C_DEPTH)-1:0][C_WIDTH-1:0] buffer;
    logic   [C_DEPTH-1:0]                   write_ptr, read_ptr;
    
    always_ff @(posedge clk_i)
    begin
        if(rstn_i == 1'b0)
        begin
            state       <= not_full;
            buffer      <= 'd0;
            write_ptr   <= 'd0;
            read_ptr    <= 'd0;
        end
        else
        begin
            if(state == not_full)
            begin
                if(push_i)
                begin
                    buffer[write_ptr]   <= data_i;
                    write_ptr           <= write_ptr + 'd1;
                    
                    if(!pop_i && write_ptr == read_ptr - {{{C_DEPTH-1} {1'b0}}, 1'd1})
                    begin
                        state           <= full;
                    end
                end
                if(pop_i && !empty_o)
                begin
                    read_ptr            <= read_ptr + 'd1;
                end
            end
            else // FIFO is full
            begin
                if(pop_i)
                begin
                    read_ptr            <= read_ptr + 'd1;
                    state               <= not_full;
                end
            end
        end
    end
    
    assign data_o   = buffer[read_ptr];
    
    assign empty_o  = (state == not_full) && (write_ptr == read_ptr);
    assign full_o   = (state == full);
endmodule
