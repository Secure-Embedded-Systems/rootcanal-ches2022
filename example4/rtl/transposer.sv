`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Tom Conroy
// 
// Module Name: transposer
// Description: 
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module transposer (
		input logic							clk_i,
		input logic							rstn_i,
		input logic		[31:0]	            data_i,
		input logic		[4:0]				word_sel_i,
		input logic							write_valid_i,
		input logic                         clear_mem_i,
		input logic		[23:0]				random_i,
		input logic		[1:0]				D_i,
		input logic		[1:0]				R_s_i,
		input logic		[4:0]				bit_sel_i,
		input logic                         direction_i,
		input logic                         comp_redund_i,
        
		output logic	[31:0]				data_o,
		output logic                        redundancy_error_o
	);

	logic [31:0] [31:0] word_buffer;
	logic [31:0] bit_selection, bit_selection_out;
	logic [31:0] share_generation_out;
    logic [31:0] slice_out;
    
    logic [31:0] masked_slice;
    logic [31:0] unmasked_slice;
    logic [31:0] word_out;
    
	always_ff @(posedge clk_i)
	begin
		if(rstn_i == 1'b0)
		begin
			word_buffer <= 1024'd0;
		end
		else
		begin
		    if(clear_mem_i)
		    begin
		        word_buffer <= 1024'd0;
		    end
			else if(write_valid_i)
			begin
			    if(direction_i == 1'b0) // FORWARD
			    begin
				    word_buffer[word_sel_i][31:0] <= data_i;
				end
				else // REVERSE
				begin
				    word_buffer[word_sel_i][31:0] <= unmasked_slice;
				end
			end
		end
	end

    // Forward bit selection
    always_comb
    begin
        for(integer i = 0; i < 32; i = i + 1)
        begin
            bit_selection[i] = word_buffer[i][bit_sel_i];           
        end
                        
        case(word_sel_i)
            5'd0:       bit_selection_out = bit_selection;
            5'd2:       bit_selection_out = { bit_selection[1:0],  bit_selection[31:2]  };
            5'd4:       bit_selection_out = { bit_selection[3:0],  bit_selection[31:4]  };            
            5'd6:       bit_selection_out = { bit_selection[5:0],  bit_selection[31:6]  };
            5'd8:       bit_selection_out = { bit_selection[7:0],  bit_selection[31:8]  };
            5'd10:      bit_selection_out = { bit_selection[9:0],  bit_selection[31:10] };
            5'd12:      bit_selection_out = { bit_selection[11:0], bit_selection[31:12] };
            5'd14:      bit_selection_out = { bit_selection[13:0], bit_selection[31:14] };
            5'd16:      bit_selection_out = { bit_selection[15:0], bit_selection[31:16] };
            5'd18:      bit_selection_out = { bit_selection[17:0], bit_selection[31:18] };
            5'd20:      bit_selection_out = { bit_selection[19:0], bit_selection[31:20] };
            5'd22:      bit_selection_out = { bit_selection[21:0], bit_selection[31:22] };
            5'd24:      bit_selection_out = { bit_selection[23:0], bit_selection[31:24] };
            5'd26:      bit_selection_out = { bit_selection[25:0], bit_selection[31:26] };
            5'd28:      bit_selection_out = { bit_selection[27:0], bit_selection[31:28] };
            5'd30:      bit_selection_out = { bit_selection[29:0], bit_selection[31:30] };
            default:    bit_selection_out = bit_selection;
        endcase
    end

	// Slice generation
	always_comb
	begin
		if(D_i == 2'h2) // D == 4 shares
		begin
			share_generation_out = { bit_selection_out[7] ^ random_i[23] ^ random_i[22] ^ random_i[21], random_i[22], random_i[21], random_i[23],
                                     bit_selection_out[6] ^ random_i[20] ^ random_i[19] ^ random_i[18], random_i[19], random_i[18], random_i[20],
                                     bit_selection_out[5] ^ random_i[17] ^ random_i[16] ^ random_i[15], random_i[16], random_i[15], random_i[17],
                                     bit_selection_out[4] ^ random_i[14] ^ random_i[13] ^ random_i[12], random_i[13], random_i[12], random_i[14],
                                     bit_selection_out[3] ^ random_i[11] ^ random_i[10] ^ random_i[9],  random_i[10], random_i[9],  random_i[11],
                                     bit_selection_out[2] ^ random_i[8]  ^ random_i[7]  ^ random_i[6],  random_i[7],  random_i[6],  random_i[8],
                                     bit_selection_out[1] ^ random_i[5]  ^ random_i[4]  ^ random_i[3],  random_i[4],  random_i[3],  random_i[5],
                                     bit_selection_out[0] ^ random_i[2]  ^ random_i[1]  ^ random_i[0],  random_i[1],  random_i[0],  random_i[2]
                                   };
		end
		else if(D_i == 2'h1) // D == 2 shares
		begin
			share_generation_out = { bit_selection_out[15] ^ random_i[22], random_i[22],
                                     bit_selection_out[14] ^ random_i[19], random_i[19],
                                     bit_selection_out[13] ^ random_i[16], random_i[16],
                                     bit_selection_out[12] ^ random_i[13], random_i[13],
                                     bit_selection_out[11] ^ random_i[10], random_i[10],
                                     bit_selection_out[10] ^ random_i[7],  random_i[7],
                                     bit_selection_out[9]  ^ random_i[4],  random_i[4],
                                     bit_selection_out[8]  ^ random_i[1],  random_i[1],
                                     bit_selection_out[7]  ^ random_i[21], random_i[21],
                                     bit_selection_out[6]  ^ random_i[18], random_i[18],
                                     bit_selection_out[5]  ^ random_i[15], random_i[15],
                                     bit_selection_out[4]  ^ random_i[12], random_i[12],
                                     bit_selection_out[3]  ^ random_i[9],  random_i[9],
                                     bit_selection_out[2]  ^ random_i[6],  random_i[6],
                                     bit_selection_out[1]  ^ random_i[3],  random_i[3],
                                     bit_selection_out[0]  ^ random_i[0],  random_i[0]
                                   };
		end
		else // D == 1 share
		begin
			share_generation_out = bit_selection_out;
		end
	end

	// Spacial redundancy generation
	always_comb
	begin
		if(R_s_i == 2'h2) // R_s == 4
		begin
		    if(comp_redund_i)
		    begin
		        slice_out = { ~share_generation_out[7:0], share_generation_out[7:0], ~share_generation_out[7:0], share_generation_out[7:0] };
		    end
		    else
		    begin
			    slice_out = { share_generation_out[7:0], share_generation_out[7:0], share_generation_out[7:0], share_generation_out[7:0] };
			end
		end
		else if(R_s_i == 2'h1) // R_s == 2
		begin
		    if(comp_redund_i)
		    begin
		        slice_out = { ~share_generation_out[15:0], share_generation_out[15:0] };
		    end
		    else
		    begin
		        slice_out = { share_generation_out[15:0], share_generation_out[15:0] };
		    end
		end
		else // R_s == 1
		begin
			slice_out = share_generation_out;
		end
	end
	
	// redundancy check & remove redundancy
    always_comb
	begin
	    if(R_s_i == 2'h2) // R_s == 4
	    begin
	       masked_slice = { 24'd0, data_i[7:0] };
	       if(comp_redund_i)
            begin
                redundancy_error_o =
                     (~data_i[31:24] != data_i[7:0] ||
                       data_i[23:16] != data_i[7:0] ||
                      ~data_i[15:8]  != data_i[7:0]);
            end
            else
            begin
                redundancy_error_o =
                    (data_i[31:24] != data_i[7:0] ||
                     data_i[23:16] != data_i[7:0] ||
                     data_i[15:8]  != data_i[7:0]);
            end
	    end
	    else if(R_s_i == 2'h1) // R_s == 2
	    begin
	       masked_slice = { 16'd0, data_i[15:0] };
	       if(comp_redund_i)
            begin
                redundancy_error_o = (~data_i[31:16] != data_i[15:0]);
            end
            else
            begin
                redundancy_error_o = ( data_i[31:16] != data_i[15:0]);
            end
	    end
	    else // R_s == 1
	    begin
	       masked_slice = data_i;
	       redundancy_error_o = 1'b0;
	    end
    end
    
    // unmasking
    always_comb
    begin
        if(D_i == 2'h2) // D == 4 shares
        begin
            
            unmasked_slice = {  24'd0,
                                masked_slice[31]  ^ masked_slice[30]  ^ masked_slice[29]  ^ masked_slice[28],
                                masked_slice[27]  ^ masked_slice[26]  ^ masked_slice[25]  ^ masked_slice[24],
                                masked_slice[23]  ^ masked_slice[22]  ^ masked_slice[21]  ^ masked_slice[20],
                                masked_slice[19]  ^ masked_slice[18]  ^ masked_slice[17]  ^ masked_slice[16],
                                masked_slice[15]  ^ masked_slice[14]  ^ masked_slice[13]  ^ masked_slice[12],
                                masked_slice[11]  ^ masked_slice[10]  ^ masked_slice[9]   ^ masked_slice[8],
                                masked_slice[7]   ^ masked_slice[6]   ^ masked_slice[5]   ^ masked_slice[4],
                                masked_slice[3]   ^ masked_slice[2]   ^ masked_slice[1]   ^ masked_slice[0]
                             };
        end
        else if(D_i == 2'h1) // D == 2 shares
        begin
            unmasked_slice = {  16'd0,
                                masked_slice[31]  ^ masked_slice[30],
                                masked_slice[29]  ^ masked_slice[28],
                                masked_slice[27]  ^ masked_slice[26],
                                masked_slice[25]  ^ masked_slice[24],
                                masked_slice[23]  ^ masked_slice[22],
                                masked_slice[21]  ^ masked_slice[20],
                                masked_slice[19]  ^ masked_slice[18],
                                masked_slice[17]  ^ masked_slice[16],
                                masked_slice[15]  ^ masked_slice[14],
                                masked_slice[13]  ^ masked_slice[12],
                                masked_slice[11]  ^ masked_slice[10],
                                masked_slice[9]   ^ masked_slice[8],
                                masked_slice[7]   ^ masked_slice[6],
                                masked_slice[5]   ^ masked_slice[4],
                                masked_slice[3]   ^ masked_slice[2],
                                masked_slice[1]   ^ masked_slice[0]
                             };
        end
        else // D == 1 share
        begin
            unmasked_slice = masked_slice;
        end
    end
    
    // reverse bit selection
    always_comb
    begin
        for(integer i = 0; i < 32; i = i + 1)
        begin
            word_out[i] = word_buffer[i][word_sel_i];
        end
    end
    
	assign data_o = (direction_i) ? word_out : slice_out;
endmodule