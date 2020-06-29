module spram #(parameter addr_width_g=8, parameter data_width_g=8) 
   (
	input logic clock,
	input logic clken,
	input logic wren,
	input logic [(data_width_g-1):0] data,
	input logic [(addr_width_g-1):0] address,
	output logic [(data_width_g-1):0] q
);

	logic [(data_width_g-1):0] mem [(2**addr_width_g-1):0];
	
	always_ff @(posedge clock)
	 begin
		if (wren) mem[address] <= data;
	//$display("data=%h addr=%h word=%h",data, addr, addr[31:2]);
	end

	assign q=  mem[address] ;

endmodule: spram
