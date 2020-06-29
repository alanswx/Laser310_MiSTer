module sprom
 #(parameter int unsigned width_a = 8,
 parameter int unsigned widthad_a= 8,
 parameter init_file= "dummy.mif",
 localparam int unsigned addrBits = $clog2(widthad_a)
 )
(
 input logic clock,
 input logic [widthad_a-1:0] address,
 output logic [width_a-1:0]q  
);
 logic [width_a-1:0] rom [(2**widthad_a-1):0];
 // initialise ROM contents
 initial begin
  $readmemh(init_file,rom);
 end
 always_ff @ (posedge clock)
 begin
  q <= rom[address];
 end
endmodule : sprom
