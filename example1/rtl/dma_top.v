module dma_top  #(
  parameter DATA_WIDTH   = 32,
  parameter ADDRESS_BITS = 32
)(
    input clk_i,    // Clock
    input rstn_i,   // reset active low
    // master (ram-dma) --> memory_arbiter
    output reg [ADDRESS_BITS-1:0] tdma_ram_address_out,
    output reg [DATA_WIDTH/8-1:0] tdma_ram_wstrb_out,
    output reg tdma_ram_valid,
    output reg [DATA_WIDTH-1  :0] tdma_ram_data_out,
    input [DATA_WIDTH-1  :0] tdma_ram_data_in,
    output reg tdma_ram_write,
    output reg tdma_ram_read,
    input tdma_ram_ready,
    input ram_done,
    // slave (proc-dma) --> memory_interface
    output reg [DATA_WIDTH-1  :0] tdma_data_out,
    output reg tdma_valid,
    input tdma_read,
    input tdma_write,
    input [ADDRESS_BITS-1:0] tdma_address_in,
    input [DATA_WIDTH-1  :0] tdma_data_in,   
    output tdma_ready
);


//---------------------------- dma and ram interface:

// AXI4-Lite Master Interface
wire            m_axi_awvalid_o; // write
reg             m_axi_awready_i; // write
wire    [31:0]  m_axi_awaddr_o; // write
wire    [2:0]   m_axi_awprot_o; // write
        
wire            m_axi_wvalid_o;
reg             m_axi_wready_i;
wire    [31:0]  m_axi_wdata_o;
wire    [3:0]   m_axi_wstrb_o;
        
reg             m_axi_bvalid_i;
wire            m_axi_bready_o;
reg     [1:0]   m_axi_bresp_i;
        
wire            m_axi_arvalid_o;
reg             m_axi_arready_i;
wire    [31:0]  m_axi_araddr_o;
wire    [2:0]   m_axi_arprot_o;
        
reg             m_axi_rvalid_i;
wire            m_axi_rready_o;
reg     [31:0]  m_axi_rdata_i;
reg     [1:0]   m_axi_rresp_i;
        

localparam  STATE_M_IDLE  = 0,
            STATE_M_WADDR = 1,
            STATE_M_WDATA = 2,
            STATE_M_WMEM  = 3,
            STATE_M_BRESP = 4,
            STATE_M_RADDR = 5,
            STATE_M_RMEM  = 6,
            STATE_M_RDATA = 7;

reg [3:0] state_m;
reg [DATA_WIDTH-1 :0] ram_read_data;

wire irq_o;

always @(posedge clk_i) begin
    if(~rstn_i) begin
        state_m <= STATE_M_IDLE;
        tdma_ram_address_out <= {ADDRESS_BITS{1'b0}};
        tdma_ram_valid <= 1'b0;
        m_axi_awready_i <= 1'b0;
        m_axi_wready_i <= 1'b0;
        tdma_ram_data_out <= {DATA_WIDTH{1'b0}};
        tdma_ram_wstrb_out <= {DATA_WIDTH/8{1'b0}}; 
        m_axi_bvalid_i <= 1'b0;
        m_axi_bresp_i <= 2'b10; // slverr
        m_axi_arready_i <= 1'b0;
        tdma_ram_write <= 1'b0;
        tdma_ram_read <= 1'b0;
        ram_read_data <= {DATA_WIDTH{1'b0}};
        m_axi_rvalid_i <= 1'b0;
        m_axi_rdata_i <= {DATA_WIDTH{1'b0}};
        m_axi_rresp_i <= 2'b10; // slverr
    end else begin
        case (state_m)
            STATE_M_IDLE: begin // 0
                m_axi_bvalid_i <= 1'b0;
                m_axi_rvalid_i <= 1'b0;
                m_axi_rresp_i <= 2'b10; // slverr
                if (m_axi_awvalid_o) begin
                    state_m <= STATE_M_WADDR;
                    tdma_ram_address_out <= m_axi_awaddr_o;
                    m_axi_awready_i <= 1'b1;
                end else begin
                    if (m_axi_arvalid_o) begin
                        tdma_ram_address_out <= m_axi_araddr_o;
                        m_axi_arready_i <= 1'b1;
                        state_m <= STATE_M_RADDR;
                    end
                end
            end
            STATE_M_WADDR: begin // 1
                m_axi_awready_i <= 1'b0;
                if(m_axi_wvalid_o) begin
                    state_m <= STATE_M_WDATA;
                    m_axi_wready_i <= 1'b1;
                    tdma_ram_data_out <= m_axi_wdata_o;
                    tdma_ram_wstrb_out <= m_axi_wstrb_o;
                end
            end
            STATE_M_WDATA: begin // 2
                m_axi_wready_i <= 1'b0;
                if (tdma_ram_ready) begin // write to ram
                    tdma_ram_valid <= 1'b1;
                    tdma_ram_write <= 1'b1;
                    tdma_ram_read <= 1'b0;
                    state_m <= STATE_M_WMEM;
                end
            end
            STATE_M_WMEM: begin // 3
                tdma_ram_valid <= 1'b1;
                tdma_ram_write <= 1'b1;
                if (ram_done) begin
                    tdma_ram_valid <= 1'b0;
                    tdma_ram_write <= 1'b0;
                    state_m <= STATE_M_BRESP;
                end
            end
            STATE_M_BRESP: begin // 4
                m_axi_bvalid_i <= 1'b1;
                m_axi_bresp_i <= 2'b00; // ok
                if (m_axi_bready_o) begin
                    // m_axi_bvalid_i <= 1'b0; //pk debug
                    state_m <= STATE_M_IDLE;
                    // m_axi_bresp_i <= 2'b10; // slverr //pk debug
                end
            end
            STATE_M_RADDR: begin // 5
                m_axi_arready_i <= 1'b0;
                if (tdma_ram_ready) begin // read from ram
                    tdma_ram_valid <= 1'b1;
                    tdma_ram_read <= 1'b1;
                    tdma_ram_write <= 1'b0;
                    state_m <= STATE_M_RMEM;
                end
            end
            STATE_M_RMEM: begin // 6
                tdma_ram_valid <= 1'b1;
                tdma_ram_read <= 1'b1;
                // ram_read_data <= tdma_ram_data_in; // debug
                if (ram_done) begin
                    tdma_ram_valid <= 1'b0;
                    tdma_ram_read <= 1'b0;
                    ram_read_data <= tdma_ram_data_in; // debug
                    state_m <= STATE_M_RDATA;
                end
            end
            STATE_M_RDATA: begin // 7
                tdma_ram_valid <= 1'b0;
                tdma_ram_read <= 1'b0;
                if (m_axi_rready_o) begin
                    m_axi_rvalid_i <= 1'b1;
                    m_axi_rdata_i <= ram_read_data;
                    m_axi_rresp_i <= 2'b00; // ok
                    state_m <= STATE_M_IDLE;
                end
            end
            default : /* default */;
        endcase
    end
end

//---------------------------- processor and dma interface:
reg         s_axi_awvalid_i; // write
reg [31:0]  s_axi_awaddr_i; // write
reg [2:0]   s_axi_awprot_i; // pk: not used
reg         s_axi_wvalid_i; // write
reg [31:0]  s_axi_wdata_i; // write
reg [3:0]   s_axi_wstrb_i; // pk: not used 
reg         s_axi_bready_i; // write
reg         s_axi_arvalid_i; // read
reg [31:0]  s_axi_araddr_i; // read
reg         s_axi_rready_i; // read
reg [2:0]   s_axi_arprot_i; // pk: not used
wire        s_axi_awready_o; // write
wire        s_axi_wready_o; // write
wire        s_axi_bvalid_o; // write 
wire [1:0]  s_axi_bresp_o; // write
wire        s_axi_arready_o; // read
wire        s_axi_rvalid_o; // read
wire [31:0] s_axi_rdata_o; // read

wire [1:0]  s_axi_rresp_o; // read


reg [1:0]   bresp_recvd;

parameter   STATE_S_IDLE  = 0,
            STATE_S_WADDR = 1,
            STATE_S_WDATA = 2,
            STATE_S_BRESP = 3,
            STATE_S_RADDR = 4,
            STATE_S_RDATA = 5;

reg [2:0] state_s;

always@(posedge clk_i) begin
    if (!rstn_i) begin
        s_axi_awvalid_i <= 1'b0;
        s_axi_awaddr_i  <= 32'h0;
        s_axi_wvalid_i  <= 1'b0;
        s_axi_wdata_i   <= 32'h0;
        s_axi_bready_i  <= 1'b0;
        s_axi_arvalid_i <= 1'b0;
        s_axi_araddr_i  <= 32'h0;
        s_axi_rready_i  <= 1'b0;
        tdma_data_out <= 32'h0;
        // tdma_address_out <= 32'h0;
        tdma_valid <= 1'b0;
        state_s <= STATE_S_IDLE;
		bresp_recvd <= 2'b00;
    end else begin
        case (state_s)
            STATE_S_IDLE: begin
                tdma_valid <= 1'b0;
                s_axi_bready_i <= 1'b0;
                s_axi_rready_i <= 1'b0;
                if (tdma_write) begin
                    s_axi_awvalid_i <= 1'b1;
                    s_axi_awaddr_i <= tdma_address_in;
                    s_axi_wvalid_i <= 1'b1;
                    s_axi_wdata_i <= tdma_data_in;
                    state_s <= STATE_S_WADDR;
                end else if (tdma_read) begin
                    s_axi_arvalid_i <= 1'b1;
                    s_axi_araddr_i <= tdma_address_in;
                    state_s <= STATE_S_RADDR;
                end
            end
            STATE_S_WADDR: begin
                if (s_axi_awready_o) begin
                    s_axi_awvalid_i <= 1'b0;
                    if (s_axi_wready_o) begin
                        tdma_valid <= 1'b1;
                    	state_s <= STATE_S_BRESP; 
                    end else begin
                        state_s <= STATE_S_WDATA; 
                    end
                end
            end
            STATE_S_WDATA: begin
                if (s_axi_wready_o) begin
                    // tdma_address_out <= s_axi_awaddr_i;
                    s_axi_wvalid_i <= 1'b0;
                    tdma_valid <= 1'b1;
                    state_s <= STATE_S_BRESP; 
                end
            end
			STATE_S_BRESP: begin
				s_axi_bready_i <= 1'b1;
				if (s_axi_bvalid_o) begin
					bresp_recvd <= s_axi_bresp_o;
                    state_s <= STATE_S_IDLE; 
				end
			end
            STATE_S_RADDR: begin
                if (s_axi_arready_o) begin
                    s_axi_arvalid_i <= 1'b0;
                    state_s <= STATE_S_RDATA;
                end
            end
            STATE_S_RDATA: begin
                if (s_axi_rvalid_o) begin
                    tdma_data_out <= s_axi_rdata_o;
                    // tdma_address_out <= s_axi_araddr_i;
                    tdma_valid <= 1'b1;
                    s_axi_rready_i <= 1'b1;
                    state_s <= STATE_S_IDLE; 
                end
            end
        endcase
    end
end

assign tdma_ready = (state_s==STATE_S_IDLE) & (state_m==STATE_M_IDLE);


//---------------------------- dma instantiation:
tDMA #(
        .C_BASE_ADDR(32'h0300_0000) // pk
    ) tdma_inst (
        .clk_i (clk_i),
        .rstn_i (rstn_i),
        
        // AXI4-Lite Master Interface
        .m_axi_awvalid_o(m_axi_awvalid_o),
        .m_axi_awready_i(m_axi_awready_i),
        .m_axi_awaddr_o(m_axi_awaddr_o),
        .m_axi_awprot_o(m_axi_awprot_o),
        
        .m_axi_wvalid_o(m_axi_wvalid_o),
        .m_axi_wready_i(m_axi_wready_i),
        .m_axi_wdata_o(m_axi_wdata_o),
        .m_axi_wstrb_o(m_axi_wstrb_o),
        
        .m_axi_bvalid_i(m_axi_bvalid_i),
        .m_axi_bready_o(m_axi_bready_o),
        .m_axi_bresp_i(m_axi_bresp_i),
        
        .m_axi_arvalid_o(m_axi_arvalid_o),
        .m_axi_arready_i(m_axi_arready_i),
        .m_axi_araddr_o(m_axi_araddr_o),
        .m_axi_arprot_o(m_axi_arprot_o),
        
        .m_axi_rvalid_i(m_axi_rvalid_i),
        .m_axi_rready_o(m_axi_rready_o),
        .m_axi_rdata_i(m_axi_rdata_i),
        .m_axi_rresp_i(m_axi_rresp_i),
        
        // AXI4-Lite Slave Interface
        .s_axi_awvalid_i(s_axi_awvalid_i),
        .s_axi_awready_o(s_axi_awready_o),
        .s_axi_awaddr_i(s_axi_awaddr_i),
        .s_axi_awprot_i(s_axi_awprot_i),
        
        .s_axi_wvalid_i(s_axi_wvalid_i),
        .s_axi_wready_o(s_axi_wready_o),
        .s_axi_wdata_i(s_axi_wdata_i), // pk: to prng
        .s_axi_wstrb_i(s_axi_wstrb_i), 
       
        .s_axi_bvalid_o(s_axi_bvalid_o),
        .s_axi_bready_i(s_axi_bready_i),
        .s_axi_bresp_o(s_axi_bresp_o),
        
        .s_axi_arvalid_i(s_axi_arvalid_i),
        .s_axi_arready_o(s_axi_arready_o),
        .s_axi_araddr_i(s_axi_araddr_i),
        .s_axi_arprot_i(s_axi_arprot_i),
        
        .s_axi_rvalid_o(s_axi_rvalid_o),
        .s_axi_rready_i(s_axi_rready_i),
        .s_axi_rdata_o(s_axi_rdata_o),
        .s_axi_rresp_o(s_axi_rresp_o),
        
        .irq_o(irq_o)
    );
endmodule
