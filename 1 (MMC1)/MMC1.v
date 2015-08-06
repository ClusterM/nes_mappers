// MMC1B mapper

module MMC1 # (parameter USE_CHR_RAM = 0)
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
	output reg [18:10] ppu_addr_out,
	output ppu_rd_out,
	output ppu_wr_out,
	output ppu_flash_ce,
	output ppu_sram_ce,
	output reg ppu_ciram_a10,
	output ppu_ciram_ce,

	output irq
);
	reg [5:0] load;
	reg [4:0] control;
	reg [4:0] prg_bank;
	reg [4:0] chr0_bank;
	reg [4:0] chr1_bank;
	reg [3:0] clock, reset_clock;
	reg reseted;
	reg started;
	
	assign cpu_wr_out = cpu_rw_in;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = ~(cpu_addr_in[14] && cpu_addr_in[13] 
		&& m2 && romsel && !prg_bank[4]); // prg_bank[4] ignored for MMC1A (mapper 155)
	assign led = ~romsel;
	
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	
	assign ppu_sram_ce = USE_CHR_RAM ? ppu_addr_in[13] : 1'b1;
	assign ppu_flash_ce = USE_CHR_RAM ? 1'b1 : ppu_addr_in[13];

	assign ppu_ciram_ce = ~ppu_addr_in[13];	
	assign irq = 1'bz;
	
	initial begin
		started = 0;
	end

	always @ (posedge romsel)
	begin
		/*
		if (cpu_addr_in[14:1] == 14'b11111111111110 && cpu_rw_in == 1) // reset vector
		begin
			control <= 5'b01100;
			prg_bank <= 0;
		end
		*/
		if (!started)
		begin
			control <= 5'b01100;
			prg_bank <= 0;
			started <= 1;
		end
		if (cpu_rw_in == 0)
		begin
			if (cpu_data_in[7] == 1) // reset
			begin
				load <= 6'b100000;
				control[3:2] <= 2'b11;
				reset_clock <= clock;
				reseted <= 1;			
			end 
			// stupid workaround for Bill & Ted's Excellent Video Game Adventure which uses "INC $FFFF"
			else if (reseted == 0 || !(clock == reset_clock || clock == reset_clock+1))
			//else
			begin				
				reseted <= 0;
				load = {cpu_data_in[0], load[5:1]};
				if (load[0] == 1)
				begin
					case (cpu_addr_in[14:13])
						2'b00: control <= load[5:1];
						2'b01: chr0_bank <= load[5:1];
						2'b10: chr1_bank <= load[5:1];
						2'b11: prg_bank <= load[5:1];
					endcase
					load = 6'b100000;
				end
			end
		end
	end
	
	always @ (*) // mirroring control
	begin
		case (control[1:0])
			2'b00: ppu_ciram_a10 <= 0;
			2'b01: ppu_ciram_a10 <= 1;
			2'b10: ppu_ciram_a10 <= ppu_addr_in[10]; // verical mirroring
			2'b11: ppu_ciram_a10 <= ppu_addr_in[11]; // horizontal mirroring
		endcase
	end
	
	always @ (*) // CPU memory mapping
	begin
		// workaround for games that requires power-up state
		/*
		if (cpu_addr_in[14:1] == 14'b11111111111110 && cpu_rw_in == 1) // reset vector
		begin
			cpu_addr_out[18:12] <= {5'b11111, cpu_addr_in[13:12]}; // fixed to the last bank
		end else
		begin
		*/
			case (control[3:2])			
				2'b00: cpu_addr_out[18:12] <= {1'b0, prg_bank[3:1], cpu_addr_in[14:12]}; // 32KB bank mode
				2'b01: cpu_addr_out[18:12] <= {1'b0, prg_bank[3:1], cpu_addr_in[14:12]}; // 32KB bank mode
				2'b10: if (cpu_addr_in[14] == 0) // $8000-$BFFF
						cpu_addr_out[18:12] <= {5'b00000, cpu_addr_in[13:12]}; // fixed to the first bank
					else // $C000-$FFFF
						cpu_addr_out[18:12] <= {1'b0, prg_bank[3:0], cpu_addr_in[13:12]};  // 16KB bank selected
				2'b11: if (cpu_addr_in[14] == 0) // $8000-$BFFF
						cpu_addr_out[18:12] <= {1'b0, prg_bank[3:0], cpu_addr_in[13:12]};  // 16KB bank selected
					else // $C000-$FFFF
						cpu_addr_out[18:12] <= {5'b11111, cpu_addr_in[13:12]}; // fixed to the last bank
			endcase
		//end
	end
	
	always @ (*) // PPU memory mapping
	begin
		case (control[4])
			0: ppu_addr_out[18:10] <= {2'b00, chr0_bank[4:1], ppu_addr_in[12:10]}; // 8KB bank mode
			1: if (ppu_addr_in[12] == 0) // 4KB bank mode
					ppu_addr_out[18:10] <= {2'b00, chr0_bank, ppu_addr_in[11:10]}; // first bank
				else
					ppu_addr_out[18:10] <= {2'b00, chr1_bank, ppu_addr_in[11:10]}; // second bank
		endcase
	end

	always @ (posedge m2)
	begin
		clock = clock+1;
	end
endmodule
