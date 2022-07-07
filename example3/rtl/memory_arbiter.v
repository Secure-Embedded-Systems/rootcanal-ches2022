module memory_arbiter #(
  parameter DATA_WIDTH   = 32,
  parameter ADDRESS_BITS = 32
) (
    input clk, 
    input reset_n,
    //-------- connections to ram
    input  [DATA_WIDTH-1  :0] d_mem_data_out,
    input  [ADDRESS_BITS-1:0] d_mem_address_out,
    input  d_mem_valid,
    input  d_mem_ready,
    output d_mem_read,
    output d_mem_write,
    output [DATA_WIDTH/8-1:0] d_mem_byte_en,
    output [ADDRESS_BITS-1:0] d_mem_address_in,
    output [DATA_WIDTH-1  :0] d_mem_data_in,
    //-------- connections to memory interface
    output [DATA_WIDTH-1  :0] interface_d_mem_data_out,
    output [ADDRESS_BITS-1:0] interface_d_mem_address_out,
    output interface_d_mem_valid,
    output interface_d_mem_ready,
    input  interface_d_mem_read,
    input  interface_d_mem_write,
    input  [DATA_WIDTH/8-1:0] interface_d_mem_byte_en,
    input  [ADDRESS_BITS-1:0] interface_d_mem_address_in,
    input  [DATA_WIDTH-1  :0] interface_d_mem_data_in,
    //-------- connections to dma
    // master (ram-dma)
    input  [ADDRESS_BITS-1:0] tdma_ram_address_out,
    input  [DATA_WIDTH/8-1:0] tdma_ram_wstrb_out,
    input  tdma_ram_valid,
    input  [DATA_WIDTH-1  :0] tdma_ram_data_out,
    input  tdma_ram_write,
    input  tdma_ram_read,
    output [DATA_WIDTH-1  :0] tdma_ram_data_in,
    output tdma_ram_ready,
    output ram_done
    );

reg [2:0] state;
localparam  STATE_INIT      = 3'd0,
            STATE_TDMA_R    = 3'd1,
            STATE_TDMA_W    = 3'd2,
            STATE_INTRFC_R  = 3'd3,
            STATE_INTRFC_W  = 3'd4;
            
wire ram_access_free;
reg  [ADDRESS_BITS-1:0] interface_d_mem_address_in_reg;
reg  [DATA_WIDTH/8-1:0] interface_d_mem_byte_en_reg;
reg  [DATA_WIDTH-1  :0] interface_d_mem_data_in_reg;
reg  [ADDRESS_BITS-1:0] tdma_ram_address_out_reg;
reg  [DATA_WIDTH/8-1:0] tdma_ram_wstrb_out_reg;
reg  [DATA_WIDTH-1  :0] tdma_ram_data_out_reg;



//--- connections to ram:
assign d_mem_read = (state==STATE_TDMA_R) | (state==STATE_INTRFC_R);
assign d_mem_write = (state==STATE_TDMA_W) | (state==STATE_INTRFC_W);
assign d_mem_byte_en =  (state==STATE_TDMA_W | state==STATE_TDMA_R) ? tdma_ram_wstrb_out_reg:
                        (state == STATE_INTRFC_W | state==STATE_INTRFC_R) ? interface_d_mem_byte_en_reg:
                        // (state == STATE_INTRFC_W | state==STATE_INTRFC_R) ? interface_d_mem_byte_en:
                        {DATA_WIDTH/8{1'b0}};
assign d_mem_address_in =   (state==STATE_TDMA_W | state==STATE_TDMA_R) ? tdma_ram_address_out_reg:
                            (state == STATE_INTRFC_W | state==STATE_INTRFC_R) ? interface_d_mem_address_in_reg:
                            // (state == STATE_INTRFC_W | state==STATE_INTRFC_R) ? interface_d_mem_address_in:
                            {ADDRESS_BITS{1'b0}};
assign d_mem_data_in =  (state==STATE_TDMA_W) ? tdma_ram_data_out_reg:
                        (state == STATE_INTRFC_W) ? interface_d_mem_data_in_reg:
                        // (state == STATE_INTRFC_W) ? interface_d_mem_data_in:
                        {DATA_WIDTH{1'b0}};

//--- connections to memory interface:
assign interface_d_mem_data_out = (state==STATE_INTRFC_R) ? d_mem_data_out : {DATA_WIDTH{1'b0}};
assign interface_d_mem_address_out = (state == STATE_INTRFC_W | state==STATE_INTRFC_R) ? d_mem_address_out : {ADDRESS_BITS{1'b0}};
assign interface_d_mem_valid = (state==STATE_INTRFC_R) ? d_mem_valid : 1'b0;
//assign interface_d_mem_ready = (state==STATE_INTRFC_W) ? d_mem_ready : 1'b0;
assign interface_d_mem_ready = (state==STATE_INIT | state==STATE_INTRFC_W | state==STATE_INTRFC_R) ? d_mem_ready : 1'b0;


//--- connections to dma:
assign tdma_ram_data_in = (state==STATE_TDMA_R) ? d_mem_data_out : {DATA_WIDTH{1'b0}};
assign ram_done = (state==STATE_TDMA_R && d_mem_valid) || (state==STATE_TDMA_W && d_mem_ready);
//assign tdma_ram_ready = (state==STATE_TDMA_W) ? d_mem_ready : 1'b0;
assign tdma_ram_ready = (state==STATE_INIT | state==STATE_TDMA_W | state==STATE_TDMA_R) ? d_mem_ready : 1'b0;

// ------ FSM:
always @(posedge clk) begin
    if(~reset_n) begin
        state <= STATE_INIT;
        interface_d_mem_address_in_reg <= {ADDRESS_BITS{1'b0}};
        interface_d_mem_byte_en_reg <= {DATA_WIDTH/8{1'b0}};
        interface_d_mem_data_in_reg <= {DATA_WIDTH{1'b0}};
        tdma_ram_address_out_reg <= {ADDRESS_BITS{1'b0}};
        tdma_ram_wstrb_out_reg <= {DATA_WIDTH/8{1'b0}};
        tdma_ram_data_out_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        case (state)
            STATE_INIT: begin
                if (tdma_ram_read) begin
                    tdma_ram_address_out_reg <= tdma_ram_address_out;
                    tdma_ram_wstrb_out_reg <= tdma_ram_wstrb_out;
                    tdma_ram_data_out_reg <= tdma_ram_data_out;
                    state <= STATE_TDMA_R;
                end else if (tdma_ram_write) begin
                    tdma_ram_address_out_reg <= tdma_ram_address_out;
                    tdma_ram_wstrb_out_reg <= tdma_ram_wstrb_out;
                    tdma_ram_data_out_reg <= tdma_ram_data_out;
                    state <= STATE_TDMA_W;
                end else if (interface_d_mem_read) begin
                    interface_d_mem_address_in_reg <= interface_d_mem_address_in;
                    interface_d_mem_byte_en_reg <= interface_d_mem_byte_en;
                    state <= STATE_INTRFC_R;
                end else if (interface_d_mem_write) begin
                    interface_d_mem_address_in_reg <= interface_d_mem_address_in;
                    interface_d_mem_byte_en_reg <= interface_d_mem_byte_en;
                    interface_d_mem_data_in_reg <= interface_d_mem_data_in;
                    state <= STATE_INTRFC_W;
                end
            end
            STATE_TDMA_R: begin // TODO: make connections to read from ram
                if (d_mem_valid) begin
                    state <= STATE_INIT;
                end
            end
            STATE_TDMA_W: begin // TODO: make connections to write to the ram
                if (d_mem_ready) begin
                    state <= STATE_INIT;
                end
            end
            STATE_INTRFC_R: begin // TODO: make connections to read from ram
                if (d_mem_valid) begin
                    state <= STATE_INIT;
                end
            end
            STATE_INTRFC_W: begin // TODO: make connections to write to the ram
                if (d_mem_ready) begin
                    state <= STATE_INIT;
                end
            end
            default : /* default */;
        endcase
    end
end

endmodule
