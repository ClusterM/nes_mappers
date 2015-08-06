module AxROM
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
	reg [7:0] bank;
	
	assign led = ~romsel;

	assign cpu_addr_out[18:12] = {bank[2:0], cpu_addr_in[14:12]};
	assign cpu_wr_out = 1;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = 1;
	
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	assign ppu_flash_ce = 1;
	assign ppu_sram_ce = ppu_addr_in[13];
	assign ppu_ciram_a10 = bank[4];
	assign ppu_ciram_ce = ~ppu_addr_in[13];
	
	assign irq = 1'bz;
	
	always @ (posedge romsel)
	begin
		if (cpu_rw_in == 0)
			bank = cpu_data_in;
	end
endmodule
