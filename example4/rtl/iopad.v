// author : Pantea Kiaei

module iopad #(parameter PADTECH = "SYNTHESIS") (
    input inp,
    input oen,
    output outp, 
    inout pad
);
/*
if (PADTECH == "SYNTHESIS") begin
	PDD12DGZ iopadTech (.OEN(oen), .I(inp), .C(outp), .PAD(pad)); // tpz io library
//	PDDW0812CDG outpadTech (.OEN(oen), .IE(1'b1), .DS(1'b0), .PE(1'b1), .I(inp), .C(outp), .PAD(pad)); // tph (slim) io library
end*/ if (PADTECH == "SIMULATION") begin
	iopadSim iopadTech (.OEN(oen), .I(inp), .C(outp), .PAD(pad));
end if (PADTECH == "FPGA") begin // will be inferred by the FPGA EDA tool
	iopadSim iopadTech (.OEN(oen), .I(inp), .C(outp), .PAD(pad));
end

endmodule


/*
module iopadv #(parameter PADTECH = "SYNTHESIS", parameter WIDTH = 1) (
    input [WIDTH-1:0] inp,
    input [WIDTH-1:0] oen,
    output [WIDTH-1:0] outp,
    inout [WIDTH-1:0] pad
);

genvar cnt;
generate
    for (cnt=0 ; cnt<WIDTH ; cnt=cnt+1) begin
        iopad #(.PADTECH(PADTECH)) iopadTech (.inp(inp[cnt]), .oen(oen[cnt]), .outp(outp[cnt]), .pad(pad[cnt]));
    end
endgenerate

endmodule
*/

module iopadSim (
	input OEN,
	input I,
	output C,
	inout PAD
);

	//assign C = PAD;
	assign C = ~OEN ? PAD : 1'bZ;
	assign PAD = OEN ? I : 1'bZ;

endmodule
