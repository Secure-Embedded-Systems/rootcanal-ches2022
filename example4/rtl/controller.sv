`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Tom Conroy
// 
// Module Name: controller
// Description: 
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller (
        input logic			clk_i,
		input logic		    rstn_i,
		input logic [31:0]  src_addr_i,
		input logic [15:0]  data_word_count_i,
		input logic [11:0]  data_word_length_i,
		input logic [1:0]   D_i,
		input logic [1:0]   R_s_i,
		input logic         direction_i,
		input logic [31:0]  dst_addr_i,
		input logic         fifo_full_i,
		input logic         fifo_empty_i,
		input logic         read_complete_i,
		input logic         axi_error_i,
		input logic         redundancy_error_i,
		input logic [1:0]   status_i,
		input logic         start_i,
		
		output logic        clear_internal_mem_o,
		output logic        read_mem_o,
		output logic        write_mem_o,
		output logic [31:0] addr_o,
		output logic [15:0] data_word_count_o,
		output logic [4:0]  word_sel_o,
		output logic [4:0]  bit_sel_o,
		output logic        run_prng_o,
		output logic        irq_o,
		output logic [1:0]  status_o, 
        output logic        busy // pk
    );
    
    localparam STATUS_OK        = 2'b00;
    localparam STATUS_AXI_ERR   = 2'b01;
    localparam STATUS_RED_ERR   = 2'b10;
    
    enum    {idle, load, unload, fifo_wait, done}
                                        state,          next_state;
    logic   [5:0]                       internal_ptr,   next_internal_ptr;
    logic   [29:0]                      src_mem_ptr,    next_src_mem_ptr;
    logic   [29:0]                      base_mem_ptr,   next_base_mem_ptr;
    logic   [29:0]                      dst_mem_ptr,    next_dst_mem_ptr;
    logic   [7:0]                       offset,         next_offset;
    logic   [5:0]                       dst_bit,        next_dst_bit;
    
    logic   [5:0]                       block_size;
    logic   [7:0]                       stride;
    logic   [5:0]                       bits_left_in_offset;
    logic   [5:0]                       words_per_slice;
    
    always_ff @(posedge clk_i)
    begin
        if(rstn_i == 1'b0)
        begin
            state <= idle;
            internal_ptr <= 6'b0;
            src_mem_ptr <= 30'b0;
            base_mem_ptr <= 30'b0;
            dst_mem_ptr <= 30'b0;
            offset <= 8'b0;
            dst_bit <= 6'b0;
        end
        else
        begin
            state <= next_state;
            internal_ptr <= next_internal_ptr;
            src_mem_ptr <= next_src_mem_ptr;
            base_mem_ptr <= next_base_mem_ptr;
            dst_mem_ptr <= next_dst_mem_ptr;
            offset <= next_offset;
            dst_bit <= next_dst_bit;
        end
    end
    
    assign block_size = (data_word_count_i >= 16'd32) ? 6'd32 : {1'b0, data_word_count_i[4:0]};
    
    // stride = Ceiling(DataWordLength / 32)
    assign stride = (data_word_length_i[4:0] != 5'd0) ?
                        {1'b0, data_word_length_i[11:5]} + 8'd1 : {1'b0, data_word_length_i[11:5]};
                        
    // min(32, DataWordLength - (32 * Offset))
    assign bits_left_in_offset = (data_word_length_i - ({4'd0, offset} << 5) >= 12'd32) ? 6'd32 :
                                    {1'b0, data_word_length_i[4:0]};
    
    assign words_per_slice = (D_i == 2'd0) ? 
                                             (R_s_i == 2'd0) ? 6'd32 :          // D = 1, R_s = 1
                                             (R_s_i == 2'd1) ? 6'd16 :          // D = 1, R_s = 2
                                                                6'd8 :          // D = 1, R_s = 4
                             (D_i == 2'd1) ? 
                                             (R_s_i == 2'd0) ? 6'd16 :          // D = 2, R_s = 1
                                             (R_s_i == 2'd1) ?  6'd8 :          // D = 2, R_s = 2
                                                                6'd4 :          // D = 2, R_s = 4
                             // (D_i == 2'd2)                
                                             (R_s_i == 2'd0) ?  6'd8 :          // D = 4, R_s = 1
                                             (R_s_i == 2'd1) ?  6'd4 :          // D = 4, R_s = 2
                                                                6'd2;           // D = 4, R_s = 4
                                             
    always_comb
    begin
        // default values
        next_state = state;
        next_internal_ptr = internal_ptr;
        next_src_mem_ptr = src_mem_ptr;
        next_base_mem_ptr = base_mem_ptr;
        next_dst_mem_ptr = dst_mem_ptr;
        next_offset = offset;
        next_dst_bit = dst_bit;
        clear_internal_mem_o = 1'b0;
        read_mem_o = 1'b0;
        write_mem_o = 1'b0;
        data_word_count_o = data_word_count_i;
        irq_o = 1'b0;
        status_o = status_i;
        
        if(state == idle)
        begin
            if(start_i)
            begin
                next_state = load;
            end 
        end
        else if(state == load)
        begin
            if(axi_error_i)
            begin
                status_o    = STATUS_AXI_ERR;
                next_state  = fifo_wait;
            end
            else
            begin
                read_mem_o = 1'b1;
                if(read_complete_i)
                begin
                    if(direction_i == 1'b0) // FORWARD
                    begin
                        if(internal_ptr + 6'd1 < block_size)
                        begin
                            next_internal_ptr = internal_ptr + 6'd1;
                            next_src_mem_ptr = src_mem_ptr + {22'd0, stride};
                        end
                        else
                        begin
                            next_state = unload;
                            next_internal_ptr = 6'd0;
                            if(offset + 8'd1 < stride)
                            begin
                                next_src_mem_ptr = base_mem_ptr + {22'd0, offset + 8'd1};
                            end
                            else
                            begin
                                next_src_mem_ptr = src_mem_ptr + 30'd1;
                                next_base_mem_ptr = src_mem_ptr + 30'd1;
                            end
                        end
                    end
                    else // direction_i == REVERSE
                    begin
                        if(redundancy_error_i)
                        begin
                            status_o    = STATUS_RED_ERR;
                            next_state  = done;
                        end
                        else
                        begin
                            next_src_mem_ptr = src_mem_ptr + 30'd1;
                            if(internal_ptr + 6'd1 < bits_left_in_offset)
                            begin
                                next_internal_ptr = internal_ptr + 6'd1;
                            end
                            else
                            begin
                                next_internal_ptr = 6'd0;
                                next_state = unload;
                            end
                        end
                    end
                end
            end
        end
        else if(state == unload)
        begin
            if(axi_error_i)
            begin
                status_o    = STATUS_AXI_ERR;
                next_state  = fifo_wait;
            end
            else
            begin
                if(!fifo_full_i)
                begin
                    write_mem_o = 1'b1;
                    
                    if(direction_i == 1'b0) // FORWARD
                    begin
                        next_dst_mem_ptr = dst_mem_ptr + 30'd1;
                        if(dst_bit + 6'd1 < bits_left_in_offset)
                        begin
                            next_dst_bit = dst_bit + 6'd1;
                        end
                        else
                        begin
                            next_dst_bit = 6'd0;
                            if(internal_ptr + words_per_slice < block_size)
                            begin
                                next_internal_ptr = internal_ptr + words_per_slice;
                            end
                            else
                            begin
                                next_internal_ptr = 6'd0;
                                clear_internal_mem_o = 1'b1;
                                if(offset + 8'd1 < stride)
                                begin
                                    next_state = load;
                                    next_offset = offset + 8'd1;
                                end
                                else
                                begin
                                    next_offset = 8'd0;
                                    data_word_count_o = data_word_count_i - {10'd0, block_size};
                                    if(data_word_count_i - {10'd0, block_size} == 16'd0)
                                    begin
                                        next_state = fifo_wait;
                                        status_o   = STATUS_OK;
                                    end
                                    else
                                    begin
                                        next_state = load;
                                    end
                                end
                            end
                        end
                    end
                    else // direction_i == REVERSE
                    begin
                        if(dst_bit + internal_ptr + 6'd1 < block_size)
                        begin
                            next_dst_mem_ptr = dst_mem_ptr + {22'd0, stride};
                            if(internal_ptr + 6'd1 < words_per_slice)
                            begin
                                next_internal_ptr = internal_ptr + 6'd1;
                            end
                            else
                            begin
                                next_internal_ptr = 6'd0;
                                next_dst_bit = dst_bit + words_per_slice;
                                next_state = load;
                                clear_internal_mem_o = 1'b1;
                            end
                        end
                        else
                        begin
                            next_internal_ptr = 6'd0;
                            next_dst_bit = 6'd0;
                            clear_internal_mem_o = 1'b1;
                            if(offset + 8'd1 < stride)
                            begin
                                next_offset = offset + 8'd1;
                                next_dst_mem_ptr = base_mem_ptr + {22'd0, offset + 8'd1};
                                next_state = load;
                            end
                            else
                            begin
                                next_offset = 8'd0;
                                next_dst_mem_ptr = dst_mem_ptr + 30'd1;
                                data_word_count_o = data_word_count_i - {10'd0, block_size};
                                if(data_word_count_i - {10'd0, block_size} == 16'd0)
                                begin
                                    next_state = fifo_wait;
                                    status_o   = STATUS_OK;
                                end
                                else
                                begin
                                    next_state = load;
                                    next_base_mem_ptr = dst_mem_ptr + 30'd1;
                                end
                            end
                        end
                    end
                end
            end
        end
        else if(state == fifo_wait)
        begin
            if(axi_error_i)
            begin
                status_o        = STATUS_AXI_ERR;
            end
            if(fifo_empty_i)
            begin
                next_state      = done;
            end
        end
        else if(state == done)
        begin
            next_state          = idle;
            next_src_mem_ptr    = 30'b0;
            next_base_mem_ptr   = 30'b0;
            next_dst_mem_ptr    = 30'b0;
            
            irq_o               = 1'b1;
        end
    end
    
    assign addr_o = (state == load)   ? src_addr_i + {src_mem_ptr, 2'b00} :
                    (state == unload) ? dst_addr_i + {dst_mem_ptr, 2'b00} :
                        src_addr_i;
    
    assign word_sel_o   = internal_ptr[4:0];
    assign bit_sel_o    = dst_bit[4:0];
    assign run_prng_o   = (direction_i == 1'b0) && ((state == load) || (state == unload));

    assign busy = (state != idle);
endmodule