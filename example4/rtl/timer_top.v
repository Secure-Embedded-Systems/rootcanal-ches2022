module timer_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_BITS = 32
)(
    input                       clk, 
    input                       rst_n,
    input [ADDRESS_BITS-1:0]    address_in,
    input                       r_en,
    output reg [DATA_WIDTH-1:0] counter_out,
    output reg                  valid,
    output                      ready 
);

reg [DATA_WIDTH-1:0] counter_clk;
reg restart_counter;

always @(posedge clk) begin
    if (!rst_n) begin
        counter_clk <= {DATA_WIDTH{1'b0}};
    end
    else begin
        if (restart_counter) begin
            counter_clk <= {DATA_WIDTH{1'b0}};
        end 
        else begin
            counter_clk <= counter_clk + 8'h01;
        end
    end
end


//-------- read and write logic:
always @(posedge clk) begin
    if (!rst_n) begin
        counter_out <= {DATA_WIDTH{1'b0}};
        restart_counter <= 1'b0;
        valid <= 1'b0;
    end
    else begin
        if (r_en && (address_in[5:2]==4'h1)) begin
            counter_out <= counter_clk;
            restart_counter <= 1'b1;
            valid <= 1'b1;
        end
        else begin
            restart_counter <= 1'b0;
            valid <= 1'b0;
        end
    end
end

assign ready = 1'b1;

endmodule
