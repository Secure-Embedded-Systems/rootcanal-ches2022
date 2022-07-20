// author : Pantea Kiaei

module gpio_top (
	input clk, 
	input resetn, 
	input valid,
	output reg ready,
	input wen,
	input [23:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata,
	input [7:0] gpio_i,
	output reg [7:0] gpio_o,
	output reg [7:0] gpio_oen
//	input [15:0] gpio_i,
//	output reg [15:0] gpio_o,
//	output reg [15:0] gpio_oen
);

	always @(posedge clk) begin
		if (!resetn) begin
//			gpio_o <= 16'h00;
//			gpio_oen <= 16'h00;
			gpio_o <= 8'h00;
			gpio_oen <= 8'h00;
			rdata <= 32'h00;
			ready <= 1'b0;
		end else begin
			ready <= 1'b0;
			if (valid) begin
				ready <= 1'b1;
				if (addr[23] == 1'b1) begin // gpio config registers
					rdata <= {31'b0, gpio_oen[addr[4:2]]};
//					rdata <= {31'b0, gpio_oen[addr[5:2]]};
					if (wen) begin
//						gpio_oen[addr[5:2]] <= wdata[0];
						gpio_oen[addr[4:2]] <= wdata[0];
					end
				end else if (addr[23] == 1'b0) begin // gpio data registers
					rdata <= {31'b0, gpio_i[addr[4:2]]};
//					rdata <= {31'b0, gpio_i[addr[5:2]]};
					if (wen) begin
//						gpio_o[addr[5:2]] <= wdata[0];
						gpio_o[addr[4:2]] <= wdata[0];
					end
				end
			end else begin
				rdata <= 32'h00000000; //new
			end
		end
	end


endmodule 
