module VRC2b
	(
	output led,
		
	input	m2,
	input romsel,
	input cpu_rw_in,
	output [18:12] cpu_addr_out,
	input [14:0] cpu_addr_in,
	input [7:0] cpu_data_in,
	output cpu_wr_out,
	output cpu_rd_out,
	output cpu_flash_ce,
	output cpu_sram_ce,
		
	input ppu_rd_in,
	input ppu_wr_in,
	input [13:10] ppu_addr_in,
	output [18:10] ppu_addr_out,
	output ppu_rd_out,
	output ppu_wr_out,
	output ppu_flash_ce,
	output ppu_sram_ce,
	output ppu_ciram_a10,
	output ppu_ciram_ce,
		
	output irq
);
	reg [7:0] prg_bank [0:1];
	reg [1:0] mirroring;
	reg [3:0] chr_bank [0:15];
	
	wire a_hi, a_low;
	assign a_hi = cpu_addr_in[1] | cpu_addr_in[3] | cpu_addr_in[5] | cpu_addr_in[7];
	assign a_low = cpu_addr_in[0] | cpu_addr_in[2] | cpu_addr_in[4] | cpu_addr_in[6];

	assign led = ~romsel;

	assign cpu_addr_out[18:12] = cpu_addr_in[14] ? {5'b11111, cpu_addr_in[13:12]} : {1'b0, prg_bank[cpu_addr_in[13]][4:0], cpu_addr_in[12]} ;
	assign cpu_wr_out = cpu_rw_in;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = ~(cpu_addr_in[14] && cpu_addr_in[13] && m2 && romsel);
	
	assign ppu_addr_out[18:10] = {chr_bank[{ppu_addr_in[12:10], 1'b1}], chr_bank[{ppu_addr_in[12:10], 1'b0}]} ;
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	assign ppu_flash_ce = ppu_addr_in[13];
	assign ppu_sram_ce = 1;
	assign ppu_ciram_a10 = mirroring[1] ? mirroring[0] : (mirroring[0] ? ppu_addr_in[11] : ppu_addr_in[10]);
	assign ppu_ciram_ce = ~ppu_addr_in[13];
	
	assign irq = 1'bz;
	
	always @ (posedge romsel)
	begin
		if (cpu_rw_in == 0)
		begin
			case (cpu_addr_in[14:12])
				3'b000: prg_bank[0] <= cpu_data_in; // $8000
				3'b010: prg_bank[1] <= cpu_data_in; // $A000
				3'b001: mirroring <= {a_hi, a_low}; // $9000
				default: chr_bank[{cpu_addr_in[14:12]-2'b11, a_hi, a_low}] <= cpu_data_in[3:0];
			endcase
		end
	end
endmodule
