module NINA # (parameter MIRRORING_VERTICAL = 1)
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
	reg [3:0] bank;

	assign led = ~romsel;

	assign cpu_addr_out[18:12] = {bank[3], cpu_addr_in[14:12]};
	assign cpu_wr_out = 1;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = 1;
	
	assign ppu_addr_out[18:10] = {bank[2:0], ppu_addr_in[12:10]};
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = 1;
	assign ppu_flash_ce = ppu_addr_in[13];
	assign ppu_sram_ce = 1;
	assign ppu_ciram_a10 = MIRRORING_VERTICAL ? ppu_addr_in[10] : ppu_addr_in[11];
	assign ppu_ciram_ce = ~ppu_addr_in[13];
	
	assign irq = 1'bz;
	
	always @ (negedge m2)
	begin
		if ({cpu_addr_in[14:13], cpu_addr_in[8]} == 3'b101 && romsel == 1 && cpu_rw_in == 0)
		begin
			 bank <= cpu_data_in[3:0];
		end
	end
endmodule
