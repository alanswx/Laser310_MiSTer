//============================================================================
// VZ Loader 
// 
// Author: alanswx (https://github.com/alanswx)
// June 2020
//
//============================================================================

module vz_loader
(
	input         I_CLK,
	input         I_RST,

	input        ioctl_wr,
	input [15:0] ioctl_addr,
	input  [7:0] ioctl_data,

	output reg [15:0] vz_addr,
	output reg [7:0] vz_data,
	output  reg vz_wr

);

reg inheader = 1;
reg inbody = 0;
reg infinish = 0;

reg [7:0] mode;

reg [15:0] cur_addr;
reg [15:0] start;
reg [15:0] end_addr;

reg [31:0] count;

// we need to reset when ioctl_download goes high again, for a second program
// load...

always@(posedge I_CLK) begin

	if(I_RST)begin
		inheader   <= 1;
		inbody     <= 0;
		infinish   <= 0;
		vz_wr      <= 0;
	end
	else if (ioctl_wr ) 
	begin
		if (inheader) 
		begin
			case (ioctl_addr[5:0])
				// 24 byte header
				00: ; // V
				01: ; // Z
				02: ; // 
				03: ; // 
				// 4-20 16 bytes - program name
				21: begin
					mode <= ioctl_data;
					if (ioctl_data == 'hF0) 
						count<= 'd8;
					else 
						count<='d2;
				    end
					// 21 - type - 
					// 	VZ_BASIC = 0xf0;
	                                //      VZ_MCODE = 0xf1;
					// 22, 23 start
					22: begin
						start[7:0] <= ioctl_data; 
                                               $display("start %x %x\n",start,ioctl_data);
					end
					23: begin

						start[15:8] <= ioctl_data;
                                               $display("start %x %x\n",start,ioctl_data);
                                               $display("mode %x %d\n",mode,mode);
                                               $display("start %x %d\n",start,start);
						inheader<=0;
						inbody<=1;
						infinish<=1;
				    		cur_addr <= { ioctl_data , start[7:0] };
					
					    end
			endcase
		end
		else if (inbody) 
		begin
			$display("in body curaddr %x\n",cur_addr);
			$display("in body ioctladdr %x\n",ioctl_addr);
			vz_addr  <= cur_addr;
			vz_data  <= ioctl_data;
			vz_wr    <= 1;
			cur_addr <= cur_addr +1'b1;
		end
	end
	else if (infinish) 
	    begin
		
            $display("in finish count %x %d\n",count,count);
		case (mode)
			// 	VZ_BASIC = 0xf0;
	                //      VZ_MCODE = 0xf1;
			'hf0:
				case (count)
					'd8:
					begin
						vz_addr<='h78a5;
						vz_data<=start[15:8];
					end
					'd7:
					begin
						vz_addr<='h78a4;
						vz_data<=start[7:0];
					end
					'd6 :
					begin
						vz_addr<='h78fa;
						vz_data<=cur_addr[15:8];
					end
					'd5 :
					begin
						vz_addr<='h78f9;
						vz_data<=cur_addr[7:0];
					end
					'd4 :
					begin
						vz_addr<='h78fc;
						vz_data<=cur_addr[15:8];
					end
					'd3 :
					begin
						vz_addr<='h78fb;
						vz_data<=cur_addr[7:0];
					end
					'd2 :
					begin
						vz_addr<='h78fe;
						vz_data<=cur_addr[15:8];
					end
					'd1 :
					begin
						vz_addr<='h78fd;
						vz_data<=cur_addr[7:0];
						infinish<=0;
					end
				endcase
			 'hf1:
		 		begin
					case (count)
						'd2:
						begin
							vz_addr<='h788f;
							vz_data<=start[15:8];
						end
						'd1:
						begin
							vz_addr<='h788e;
							vz_data<=start[7:0];
							infinish<=0;
						end
					endcase
		 		end
		 	endcase
			count<=count-1;
			if (!count) 
			begin
				vz_wr<=0;
				infinish   <= 0;
			end
		end else
		begin
			inheader   <= 1;
			inbody     <= 0;
			infinish   <= 0;
			vz_wr      <= 0;
            //$display("in the done spot %x %d\n",vz_wr,vz_wr);
		end
	
end

endmodule

