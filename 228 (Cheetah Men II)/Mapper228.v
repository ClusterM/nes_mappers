module Mapper228
	(
	output led,
		
	input	m2,
	input romsel,
	input cpu_rw_in,
	output reg [18:12] cpu_addr_out,
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
	reg [5:0] chr_bank;
	reg prg_mode;
	reg [4:0] prg_bank;
	reg [1:0] prg_chip;
	reg mirroring;

	assign led = ~romsel;

	/*
	assign cpu_addr_out[18:12] = {
			((romsel == 0 && cpu_addr_in[14:1] == 14'b11111111111110 && cpu_rw_in == 1) ? 4'b0000 : prg_bank[4:1])
		, cpu_addr_in[14]^prg_mode, cpu_addr_in[13:12]};
	*/
	assign cpu_wr_out = cpu_rw_in;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = ~(cpu_addr_in[14] && cpu_addr_in[13] && m2 && romsel);
	
	assign ppu_addr_out[18:10] = {chr_bank, ppu_addr_in[12:10]};
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	assign ppu_flash_ce = ppu_addr_in[13];
	assign ppu_sram_ce = 1;
	assign ppu_ciram_a10 = !mirroring ? ppu_addr_in[10] : ppu_addr_in[11];
	assign ppu_ciram_ce = ~ppu_addr_in[13];
	
	assign irq = 1'bz;
	
	initial 
	begin
		chr_bank <= 0;
		prg_mode <= 0;
		prg_bank <= 0;
		prg_chip <= 0;
		mirroring <= 0;
	end
	
	always @ (posedge romsel)
	begin
		if (cpu_rw_in == 0)
		begin
			chr_bank <= {cpu_addr_in[3:0], cpu_data_in[1:0]};
			prg_mode <= cpu_addr_in[5];
			prg_bank <= cpu_addr_in[10:6];
			prg_chip <= cpu_addr_in[12:11];
			mirroring <= cpu_addr_in[13];
		end
		
		/*
		if (cpu_addr_in[14:1] == 14'b11111111111110 && cpu_rw_in == 1) // reset vector
		begin
			chr_bank <= 0;
			prg_mode <= 0;
			prg_bank <= 0;
			prg_chip <= 0;
			mirroring <= 0;
		end
		*/
	end
	
	always @ (*)
	begin
	/*
		if (cpu_addr_in[14:1] == 14'b11111111111110 && cpu_rw_in == 1 && romsel == 0)
			cpu_addr_out[18:12] = cpu_addr_in[14:12];
		else begin
	*/
			if (cpu_addr_in[14] == 0 || prg_mode)
				cpu_addr_out[18:14] = prg_bank;
			else
				cpu_addr_out[18:14] = prg_bank+1;
			cpu_addr_out[13:12] = cpu_addr_in[13:12];
//		end
	end
endmodule
