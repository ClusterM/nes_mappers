// CodeMasters mapper
module CodeMasters # (parameter MIRRORING_VERTICAL = 1)
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
	reg [3:0] cpu_bank;
	reg [1:0] mirroring;
	reg started;

	assign led = ~romsel;

	assign cpu_addr_out[18:14] = cpu_addr_in[14] ? {5'b11111} : {1'b0, cpu_bank};
	assign cpu_addr_out[13:12] = cpu_addr_in[13:12];
	assign cpu_wr_out = 1;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = 1;
	
	//assign ppu_addr_out[18:10] = ppu_addr_in[13:10];
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	assign ppu_sram_ce = ppu_addr_in[13];
	assign ppu_flash_ce = 1;
	assign ppu_ciram_a10 = mirroring[1] ? mirroring[0] : (mirroring[0] ? ppu_addr_in[10] : ppu_addr_in[11]);
	assign ppu_ciram_ce = ~ppu_addr_in[13];
	
	assign irq = 1'bz;
	
	initial
	begin
		started <= 0;
	end
	
	always @ (posedge romsel)
	begin
		if (cpu_rw_in == 0 && cpu_addr_in[14] == 1)
			cpu_bank <= cpu_data_in[3:0];
			
		if (cpu_rw_in == 0 && cpu_addr_in[14:12] == 3'b001) // allow to select mirroring for Fire Hawk
		begin
			mirroring = {1'b1, cpu_data_in[4]};
		end		
			
		if (!started)
		begin
			mirroring = {1'b0, MIRRORING_VERTICAL}; // reset mirroring
			started <= 1;
		end
		
		/*
		if (cpu_addr_in[14:1] == 14'b11111111111110 && cpu_rw_in == 1) // reset vector
		begin
			mirroring = {1'b0, MIRRORING_VERTICAL}; // reset mirroring
		end
		*/
	end
endmodule
