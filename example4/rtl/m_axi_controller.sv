`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Tom Conroy
// 
// Module Name: m_axi_controller
// Description: tDMA Master AXI4-Lite Controller
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module m_axi_controller (
        input   logic           aclk_i,
        input   logic           aresetn_i,
        
        output  logic           awvalid_o,
        input   logic           awready_i,
        // output  logic   [31:0]  awaddr_o,
        output  logic   [2:0]   awprot_o,
        
        output  logic           wvalid_o,
        input   logic           wready_i,
        // output  logic   [31:0]  wdata_o,
        output  logic   [3:0]   wstrb_o,
        
        input   logic           bvalid_i,
        output  logic           bready_o,
        input   logic   [1:0]   bresp_i,
        
        output  logic           arvalid_o,
        input   logic           arready_i,
        // output  logic   [31:0]  araddr_o,
        output  logic   [2:0]   arprot_o,
        
        input   logic           rvalid_i,
        output  logic           rready_o,
        // input   logic   [31:0]  rdata_i,
        input   logic   [1:0]   rresp_i,
        
        input   logic           fifo_empty_i,
        input   logic           read_mem_i,
        output  logic           axi_err_o,
        output  logic           write_internal_mem_o,
        output  logic           write_complete_o
    );
    
    enum {write_idle, write_both, write_addr, write_data, write_wait_resp}
        write_state, next_write_state;
    
    enum {read_idle, read_send_addr, read_resp} read_state, next_read_state;
    
    logic write_err;
    logic read_err;
    
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
        awvalid_o               = 1'b0;
        wvalid_o                = 1'b0;
        bready_o                = 1'b0;
        arvalid_o               = 1'b0;
        rready_o                = 1'b0;
        write_err               = 1'b0;
        read_err                = 1'b0;
        write_internal_mem_o    = 1'b0;
        write_complete_o        = 1'b0;
        
        if(aresetn_i == 1'b0)
        begin
            arvalid_o   = 1'b0;
            awvalid_o   = 1'b0;
            wvalid_o    = 1'b0;
        end
        else
        begin
            if(write_state == write_idle)
            begin
                if(!fifo_empty_i)
                begin
                    next_write_state = write_both;
                    awvalid_o   = 1'b1;
                    wvalid_o    = 1'b1;
                    if(awready_i && wready_i)
                    begin
                        next_write_state = write_wait_resp;
                    end
                    else if(awready_i)
                    begin
                        next_write_state = write_data;
                    end
                    else if(wready_i)
                    begin
                        next_write_state = write_addr;
                    end
                end
            end
            else if(write_state == write_both)
            begin
                awvalid_o   = 1'b1;
                wvalid_o    = 1'b1;
                if(awready_i && wready_i)
                begin
                    next_write_state = write_wait_resp;
                end
                else if(awready_i)
                begin
                    next_write_state = write_data;
                end
                else if(wready_i)
                begin
                    next_write_state = write_addr;
                end
            end
            else if(write_state == write_addr)
            begin
                awvalid_o = 1'b1;
                if(awready_i)
                begin
                    next_write_state = write_data;
                end
            end
            else if(write_state == write_data)
            begin
                wvalid_o = 1'b1;
                if(wready_i)
                begin
                    next_write_state = write_wait_resp;
                end
            end
            else if(write_state == write_wait_resp)
            begin
                bready_o = 1'b1;
                if(bvalid_i)
                begin
                    next_write_state = write_idle;
                    write_complete_o = 1'b1;
                    if(bresp_i == 2'b10 || bresp_i == 2'b11) // SLVERR or DECERR
                    begin
                        write_err = 1'b1;
                    end
                end
            end
            
            if(read_state == read_idle)
            begin
                if(read_mem_i)
                begin
                    next_read_state = read_send_addr;
                    arvalid_o = 1'b1;
                    if(arready_i)
                    begin
                        next_read_state = read_resp;
                    end
                end
            end
            else if(read_state == read_send_addr)
            begin
                arvalid_o = 1'b1;
                if(arready_i)
                begin
                    next_read_state = read_resp;
                end
            end
            else if(read_state == read_resp)
            begin
                rready_o = 1'b1;
                if(rvalid_i)
                begin
                    write_internal_mem_o = 1'b1;
                    next_read_state = read_idle;
                    if(rresp_i == 2'b10 || rresp_i == 2'b11) // SLVERR or DECERR
                    begin
                        read_err = 1'b1;
                    end
                end
            end
        end
    end
    
    assign awprot_o = 3'b000;
    assign wstrb_o  = 4'hf;
    assign arprot_o = 3'b000;
    
    assign axi_err_o  = write_err | read_err;
endmodule