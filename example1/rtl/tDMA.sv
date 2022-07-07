`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Tom Conroy
// 
// Module Name: tDMA
// Description: 
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tDMA # (
        parameter C_BASE_ADDR =   32'h00000000
    )
    (
        input logic         clk_i,
        input logic         rstn_i,
        
        // AXI4-Lite Master Interface
        output  logic           m_axi_awvalid_o,
        input   logic           m_axi_awready_i,
        output  logic   [31:0]  m_axi_awaddr_o,
        output  logic   [2:0]   m_axi_awprot_o,
        
        output  logic           m_axi_wvalid_o,
        input   logic           m_axi_wready_i,
        output  logic   [31:0]  m_axi_wdata_o,
        output  logic   [3:0]   m_axi_wstrb_o,
        
        input   logic           m_axi_bvalid_i,
        output  logic           m_axi_bready_o,
        input   logic   [1:0]   m_axi_bresp_i,
        
        output  logic           m_axi_arvalid_o,
        input   logic           m_axi_arready_i,
        output  logic   [31:0]  m_axi_araddr_o,
        output  logic   [2:0]   m_axi_arprot_o,
        
        input   logic           m_axi_rvalid_i,
        output  logic           m_axi_rready_o,
        input   logic   [31:0]  m_axi_rdata_i,
        input   logic   [1:0]   m_axi_rresp_i,
        
        // AXI4-Lite Slave Interface
        input   logic           s_axi_awvalid_i,
        output  logic           s_axi_awready_o,
        input   logic   [31:0]  s_axi_awaddr_i,
        input   logic   [2:0]   s_axi_awprot_i,
        
        input   logic           s_axi_wvalid_i,
        output  logic           s_axi_wready_o,
        input   logic   [31:0]  s_axi_wdata_i,
        input   logic   [3:0]   s_axi_wstrb_i,
        
        output  logic           s_axi_bvalid_o,
        input   logic           s_axi_bready_i,
        output  logic   [1:0]   s_axi_bresp_o,
        
        input   logic           s_axi_arvalid_i,
        output  logic           s_axi_arready_o,
        input   logic   [31:0]  s_axi_araddr_i,
        input   logic   [2:0]   s_axi_arprot_i,
        
        output  logic           s_axi_rvalid_o,
        input   logic           s_axi_rready_i,
        output  logic   [31:0]  s_axi_rdata_o,
        output  logic   [1:0]   s_axi_rresp_o,
        
        output  logic           irq_o
    );
    
    localparam STATUS_OK        = 2'b00;
    
    logic    [31:0]    src_addr, next_src_addr;
    logic    [15:0]    data_word_count, next_data_word_count;
    logic    [11:0]    data_word_length, next_data_word_length;
    logic    [31:0]    dst_addr, next_dst_addr;
    logic              write_internal_mem;
    logic              clear_internal_mem;
    logic              read_mem;
    logic              write_mem;
    logic    [31:0]    master_addr;
    logic    [15:0]    controller_data_word_count;
    
    logic    [4:0]     word_sel;
    logic    [23:0]    random;
    logic    [1:0]     D, next_D;
    logic    [1:0]     R_s, next_R_s;
    logic    [4:0]     bit_sel;
    logic    [31:0]    transposer_out;
    
    logic              next_pattern;
    logic    [31:0]    prng_out;
    
    logic              write_src_addr;
    logic              write_config_reg;
    logic              write_config_reg_two;
    logic              write_prng_seed;
    logic              write_dst_addr;
    
    logic              axi_err;
    logic              write_complete;
    
    logic              direction, next_direction;
    logic              comp_redund, next_comp_redund;
    
    logic    [1:0]     status_reg, next_status_reg;

    logic              busy_flag, next_busy_flag;
    
    logic              fifo_empty, fifo_full;
    
    always_ff @(posedge clk_i)
    begin
        if(rstn_i == 1'b0)
        begin
            src_addr            <= 32'd0;
            data_word_count     <= 16'd0;
            data_word_length    <= 12'd0;
            dst_addr            <= 32'd0;
            D                   <= 2'd0;
            R_s                 <= 2'd0;
            direction           <= 1'b0;
            comp_redund         <= 1'b0;
            status_reg          <= STATUS_OK;
            busy_flag           <= 1'b0;
        end
        else
        begin
            src_addr            <= next_src_addr;
            data_word_count     <= next_data_word_count;
            data_word_length    <= next_data_word_length;
            dst_addr            <= next_dst_addr;
            D                   <= next_D;
            R_s                 <= next_R_s;
            direction           <= next_direction;
            comp_redund         <= next_comp_redund;
            status_reg          <= next_status_reg;
            busy_flag           <= next_busy_flag;
        end
    end
    
    assign next_src_addr = (write_src_addr) ? s_axi_wdata_i : src_addr;
    
    assign {next_D, next_R_s, next_data_word_length, next_data_word_count} =
        (write_config_reg) ? s_axi_wdata_i :
            {D, R_s, data_word_length, controller_data_word_count};
    
    assign {next_comp_redund, next_direction} =
        (write_config_reg_two) ? s_axi_wdata_i[1:0] :
        {comp_redund, direction};
            
    assign next_dst_addr = (write_dst_addr) ? s_axi_wdata_i : dst_addr;
    
    controller c (
        .clk_i(clk_i),
		.rstn_i(rstn_i),
		.src_addr_i(src_addr),
		.data_word_count_i(data_word_count),
		.data_word_length_i(data_word_length),
		.D_i(D),
		.R_s_i(R_s),
		.direction_i(direction),
		.dst_addr_i(dst_addr),
		.fifo_empty_i(fifo_empty),
		.fifo_full_i(fifo_full),
		.read_complete_i(write_internal_mem),
		.axi_error_i(axi_err),
		.redundancy_error_i(redundancy_error),
		.status_i(status_reg),
		.start_i(write_dst_addr),
		
		.clear_internal_mem_o(clear_internal_mem),
		.read_mem_o(read_mem),
		.write_mem_o(write_mem),
		.addr_o(master_addr),
		.data_word_count_o(controller_data_word_count),
		.word_sel_o(word_sel),
		.bit_sel_o(bit_sel),
		.run_prng_o(next_pattern),
		.irq_o(irq_o),
		.status_o(next_status_reg),
        .busy(next_busy_flag)
    );
    
    transposer t (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .data_i(m_axi_rdata_i),
        .word_sel_i(word_sel),
        .write_valid_i(write_internal_mem),
        .clear_mem_i(clear_internal_mem),
        .random_i(prng_out[23:0]),
        .D_i(D),
        .R_s_i(R_s),
        .direction_i(direction),
        .comp_redund_i(comp_redund),
        .bit_sel_i(bit_sel),
        .data_o(transposer_out),
        .redundancy_error_o(redundancy_error)
    );
    
    ca_prng prng (
        .clk(clk_i),
        .reset_n(rstn_i),
        .init_pattern_data(s_axi_wdata_i),
        .load_init_pattern(write_prng_seed),
        .next_pattern(next_pattern),

        .update_rule(8'd0),
        .load_update_rule(1'b0),

        .prng_data(prng_out)
    );
    
    fifo_dma # (
        .C_WIDTH(64),
        .C_DEPTH(5)
    ) f (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .data_i({master_addr, transposer_out}),
        .push_i(write_mem),
        .data_o({m_axi_awaddr_o, m_axi_wdata_o}),
        .pop_i(write_complete),
        .empty_o(fifo_empty),
        .full_o(fifo_full)
    );
    
    m_axi_controller m_axi_c (
        .aclk_i(clk_i),
        .aresetn_i(rstn_i),
        
        .awvalid_o(m_axi_awvalid_o),
        .awready_i(m_axi_awready_i),
        .awprot_o(m_axi_awprot_o),
        
        .wvalid_o(m_axi_wvalid_o),
        .wready_i(m_axi_wready_i),
        .wstrb_o(m_axi_wstrb_o),
        
        .bvalid_i(m_axi_bvalid_i),
        .bready_o(m_axi_bready_o),
        .bresp_i(m_axi_bresp_i),
        
        .arvalid_o(m_axi_arvalid_o),
        .arready_i(m_axi_arready_i),
        .arprot_o(m_axi_arprot_o),
        
        .rvalid_i(m_axi_rvalid_i),
        .rready_o(m_axi_rready_o),
        .rresp_i(m_axi_rresp_i),
        
        .fifo_empty_i(fifo_empty),
        .read_mem_i(read_mem),
        .axi_err_o(axi_err),
        .write_internal_mem_o(write_internal_mem),
        .write_complete_o(write_complete)
    );
    
    assign m_axi_araddr_o = master_addr;
    
    s_axi_controller # (
        .C_BASE_ADDR(C_BASE_ADDR)
    ) s_axi_c (
        .aclk_i(clk_i),
        .aresetn_i(rstn_i),
        
        .awvalid_i(s_axi_awvalid_i),
        .awready_o(s_axi_awready_o),
        .awaddr_i(s_axi_awaddr_i),
        .awprot_i(s_axi_awprot_i),
        
        .wvalid_i(s_axi_wvalid_i),
        .wready_o(s_axi_wready_o),
        // .wdata_i(s_axi_wdata_i),
        // .wstrb_i(s_axi_wstrb_i), ignore write strobes
        
        .bvalid_o(s_axi_bvalid_o),
        .bready_i(s_axi_bready_i),
        .bresp_o(s_axi_bresp_o),
        
        .arvalid_i(s_axi_arvalid_i),
        .arready_o(s_axi_arready_o),
        .araddr_i(s_axi_araddr_i),
        .arprot_i(s_axi_arprot_i),
        
        .rvalid_o(s_axi_rvalid_o),
        .rready_i(s_axi_rready_i),
        .rdata_o(s_axi_rdata_o),
        .rresp_o(s_axi_rresp_o),
        
        .status_reg_i(status_reg),
        .busy_flag_i(busy_flag), // new
        .write_src_addr_o(write_src_addr),
        .write_config_reg_o(write_config_reg),
        .write_config_reg_two_o(write_config_reg_two),
        .write_prng_seed_o(write_prng_seed),
        .write_dst_addr_o(write_dst_addr)
    );
    
endmodule
