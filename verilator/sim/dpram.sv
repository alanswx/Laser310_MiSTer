module dpram#(
    parameter data_width_g = 8,
    parameter addr_width_g = 10
) (
    // Port A
    input   wire                clk_a_i,
    input   wire                we_i,
    input   wire                en_a_i,
    input   wire    [addr_width_g-1:0]  addr_a_i,
    input   wire    [data_width_g-1:0]  data_a_i,
    output  reg     [data_width_g-1:0]  data_a_o,
     
    // Port B
    input   wire                clk_b_i,
    input   wire                wren_b,
    input   wire    [addr_width_g-1:0]  addr_b_i,
    input   wire    [data_width_g-1:0]  data_b,
    output  reg     [data_width_g-1:0]  data_b_o,

    input wire byteena_a,
    input wire byteena_b
);
 
// Shared memory
reg [data_width_g-1:0] mem [(2**addr_width_g)-1:0];
 
// Port A
always @(posedge clk_a_i) begin
    data_a_o      <= mem[addr_a_i];
    if(we_i) begin
        data_a_o      <= data_a_i;
        mem[addr_a_i] <= data_a_i;
    end
end
 
// Port B
always @(posedge clk_b_i) begin
    data_b_o      <= mem[addr_b_i];
    if(wren_b) begin
        data_b_o      <= data_b;
        mem[addr_b_i] <= data_b;
    end
end
 
endmodule
