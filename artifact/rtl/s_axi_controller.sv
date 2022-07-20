`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Tom Conroy
// 
// Module Name: s_axi_controller
// Description: tDMA Slave AXI4-Lite Controller
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module s_axi_controller # (
        parameter C_BASE_ADDR =   32'h00000000
    )
    (
        input   logic           aclk_i,
        input   logic           aresetn_i,
        
        input   logic           awvalid_i,
        output  logic           awready_o,
        input   logic   [31:0]  awaddr_i,
        input   logic   [2:0]   awprot_i,
        
        input   logic           wvalid_i,
        output  logic           wready_o,
        // input   logic   [31:0]  wdata_i,
        // input   logic   [3:0]   wstrb_i,
        
        output  logic           bvalid_o,
        input   logic           bready_i,
        output  logic   [1:0]   bresp_o,
        
        input   logic           arvalid_i,
        output  logic           arready_o,
        input   logic   [31:0]  araddr_i,
        input   logic   [2:0]   arprot_i,
        
        output  logic           rvalid_o,
        input   logic           rready_i,
        output  logic   [31:0]  rdata_o,
        output  logic   [1:0]   rresp_o,
        
        input   logic   [1:0]   status_reg_i,
        input   logic           busy_flag_i,
        output  logic           write_src_addr_o,
        output  logic           write_config_reg_o,
        output  logic           write_config_reg_two_o,
        output  logic           write_prng_seed_o,
        output  logic           write_dst_addr_o
    );
    
    enum {write_idle, write_accept, write_resp_valid, write_resp_err}
        write_state, next_write_state;
    
    enum {read_idle, read_ok, read_err} read_state, next_read_state;
    
    always_ff @(posedge aclk_i)
    begin
        if(aresetn_i == 1'b0)
        begin
            write_state <= write_idle;
            read_state  <= read_idle;
        end
        else
        begin
            write_state <= next_write_state;
            read_state  <= next_read_state;
        end
    end
    
    always_comb
    begin
        // default values
        next_write_state        = write_state;
        next_read_state         = read_state;
        awready_o               = 1'b0;
        wready_o                = 1'b0;
        bvalid_o                = 1'b0;
        bresp_o                 = 2'b10; // SLVERR
        arready_o               = 1'b0;
        rvalid_o                = 1'b0;
        rresp_o                 = 2'b10; // SLVERR
        write_src_addr_o        = 1'b0;
        write_config_reg_o      = 1'b0;
        write_config_reg_two_o  = 1'b0;
        write_prng_seed_o       = 1'b0;
        write_dst_addr_o        = 1'b0;
        
        if(aresetn_i == 1'b0)
        begin
            bvalid_o = 1'b0;
            rvalid_o = 1'b0;
        end
        else
        begin
            if(write_state == write_idle)
            begin
                if(awvalid_i && wvalid_i)
                begin
                    next_write_state = write_accept;
                end
            end
            else if(write_state == write_accept)
            begin
                awready_o   = 1'b1;
                wready_o    = 1'b1;
                if({awaddr_i[31:5], 5'h0} == C_BASE_ADDR)
                begin
                    next_write_state = write_resp_valid;
                    case(awaddr_i[4:0])
                        5'h00:
                        begin
                            write_src_addr_o        = 1'b1;
                        end
                        5'h04:
                        begin
                            write_config_reg_o      = 1'b1;
                        end
                        5'h08:
                        begin
                            write_config_reg_two_o  = 1'b1;
                        end
                        5'h0c:
                        begin
                            write_prng_seed_o       = 1'b1;
                        end
                        5'h10:
                        begin
                            write_dst_addr_o        = 1'b1;
                        end
                        default:
                        begin
                            next_write_state    = write_resp_err;
                        end
                    endcase
                end
                else
                begin
                    next_write_state = write_resp_err;
                end
            end
            else if(write_state == write_resp_valid)
            begin
                bresp_o  = 2'b00; // OKAY
                bvalid_o = 1'b1;
                if(bready_i)
                begin
                    next_write_state = write_idle;
                end
            end
            else if(write_state == write_resp_err)
            begin
                bresp_o  = 2'b10; // SLVERR
                bvalid_o = 1'b1;
                if(bready_i)
                begin
                    next_write_state = write_idle;
                end
            end
            
            if(read_state == read_idle)
            begin
                arready_o = 1'b1;
                if(arvalid_i)
                begin
                    if(araddr_i == {C_BASE_ADDR[31:5], 5'h14}) // status register
                    begin
                        next_read_state = read_ok;
                    end
                    else
                    begin
                        next_read_state = read_err;
                    end
                end
            end
            else if(read_state == read_ok)
            begin
                rvalid_o    = 1'b1;
                rresp_o     = 2'b00; // OKAY
                if(rready_i)
                begin
                    next_read_state = read_idle;
                end
            end
            else if(read_state == read_err)
            begin
                rvalid_o    = 1'b1;
                rresp_o     = 2'b10; // SLVERR
                if(rready_i)
                begin
                    next_read_state = read_idle;
                end
            end
        end
    end
    
    assign rdata_o  =  (araddr_i == {C_BASE_ADDR[31:5], 5'h14}) ? {30'd0, status_reg_i}:
                       (araddr_i == {C_BASE_ADDR[31:5], 5'h18}) ? {31'd0, busy_flag_i}: // pk
                                                                  {30'd0, status_reg_i};
endmodule