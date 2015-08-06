 module Mapper34 # (parameter MIRRORING_VERTICAL = 0)
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
	reg [1:0] prg_bank;
	reg [3:0] chr_bank [0:1];
	reg use_chr_ram;

	assign led = ~romsel;

	assign cpu_addr_out[18:12] = {prg_bank, cpu_addr_in[14:12]};
	assign cpu_wr_out = cpu_rw_in;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = ~(cpu_addr_in[14] && cpu_addr_in[13] && m2 && romsel);
	
	assign ppu_addr_out[18:10] = {chr_bank[ppu_addr_in[12]], ppu_addr_in[11:10]};
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	assign ppu_flash_ce = use_chr_ram ? 1 : ppu_addr_in[13];
	assign ppu_sram_ce = use_chr_ram ? ppu_addr_in[13] : 1;
	assign ppu_ciram_a10 = MIRRORING_VERTICAL ? ppu_addr_in[10] : ppu_addr_in[11];
	assign ppu_ciram_ce = ~ppu_addr_in[13];
	
	assign irq = 1'bz;
	
	reg started;
	
	initial
	begin
		started <= 0;
	end
	
	always @ (negedge m2)
	begin
		if (cpu_rw_in == 0)
		begin
			if (romsel == 0) // BNROM
			begin
				prg_bank <= cpu_data_in[1:0];
				chr_bank[0] <= 0;
				chr_bank[1] <= 1;
				use_chr_ram <= 1;
			end else 
				begin // NINA-001
				case (cpu_addr_in[14:0])
					15'b111111111111101: prg_bank <= {1'b0, cpu_data_in[0]}; // $7FFD
					15'b111111111111110, // $7FFE
					15'b111111111111111: // $7FFF
						begin
							chr_bank[cpu_addr_in[0]] <= cpu_data_in[3:0]; 
							use_chr_ram <= 0;
						end
				endcase
			end
		end
		
		if (!started)
		begin
			prg_bank <= 0;
			chr_bank[0] <= 0;
			chr_bank[1] <= 1;
			use_chr_ram <= 1; // use CHR RAM until CHR bank not selected
			started <= 1;
		end
		
		/*
		if (cpu_addr_in[14:1] == 14'b11111111111110 && romsel == 0 && cpu_rw_in == 1) // reset vector
		begin
			prg_bank <= 0;
			chr_bank[0] <= 0;
			chr_bank[1] <= 1;
			use_chr_ram <= 1; // use CHR RAM until CHR bank not selected
		end	
		*/
	end
endmodule
