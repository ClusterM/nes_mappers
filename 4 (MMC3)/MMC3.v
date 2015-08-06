// MMC3 mapper
module MMC3 # (parameter USE_CHR_RAM = 1)
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
	output ppu_ciram_a10,
	output ppu_ciram_ce,
		
	output reg irq
);
	reg [2:0] bank_select;
	reg prg_mode;
	reg chr_mode;
	reg [7:0] r [0:7];
	reg mirroring;
	reg [7:6] ram_protect;
	reg [7:0] irq_latch;
	reg [7:0] irq_counter;
	reg [2:0] a12_low_time;
	reg irq_reload;
	reg irq_reload_clear;
	reg irq_enabled;
	reg irq_value;
	reg irq_ready;
	reg started;
	
	assign cpu_wr_out = cpu_rw_in || ram_protect[6];
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = !(cpu_addr_in[14] && cpu_addr_in[13] && m2 && romsel && ram_protect[7]);
	assign led = ~romsel;
	
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	
	// Enable CHR RAM or CHR ROM
	assign ppu_sram_ce = USE_CHR_RAM ? ppu_addr_in[13] : 1'b1;
	assign ppu_flash_ce = USE_CHR_RAM ? 1'b1 : ppu_addr_in[13];

	assign ppu_ciram_ce = !ppu_addr_in[13];
	
	// Mirroring control
	assign ppu_ciram_a10 = mirroring ? ppu_addr_in[11] : ppu_addr_in[10];
	
	initial
	begin
		irq_enabled = 0;
		irq_ready = 0;
	end
		
	always @ (posedge romsel)
	begin
		if (cpu_rw_in == 0)
		begin
			case ({cpu_addr_in[14:13], cpu_addr_in[0]})
				3'b000: begin  // $8000-$9FFE, even
					bank_select <= cpu_data_in[2:0];
					prg_mode <= cpu_data_in[6];
					chr_mode <= cpu_data_in[7];
				end
				3'b001: r[bank_select] <= cpu_data_in; // $8001-$9FFF, odd
				3'b010: mirroring <= cpu_data_in[0]; // $A000-$BFFE, even
				3'b011: ram_protect <= cpu_data_in[7:6]; // $A001-$BFFF, odd
				3'b100: irq_latch <= cpu_data_in; // $C000-$DFFE, even
				3'b101: irq_reload <= 1; // $C001-$DFFF, odd
				3'b110: irq_enabled <= 0; // $E000-$FFFE, even
				3'b111: irq_enabled <= 1; // $E001-$FFFF, odd
			endcase
		end
		if (irq_reload_clear)
			irq_reload <= 0;
	end
	
	// PRG banking
	always @ (*)
	begin
		case ({cpu_addr_in[14:13], prg_mode})
			3'b000: cpu_addr_out[18:13] <= r[6][5:0];
			3'b001: cpu_addr_out[18:13] <= 6'b111110;
			3'b010,
			3'b011: cpu_addr_out[18:13] <= r[7][5:0];
			3'b100: cpu_addr_out[18:13] <= 6'b111110;
			3'b101: cpu_addr_out[18:13] <= r[6][5:0];
			default: cpu_addr_out[18:13] <= 6'b111111;
		endcase
		cpu_addr_out[12] <= cpu_addr_in[12];
	end
	
	// CHR banking
	always @ (*)
	begin
		if (ppu_addr_in[12] == chr_mode)		
			ppu_addr_out[17:10] <= {r[ppu_addr_in[11]][7:1], ppu_addr_in[10]};
		else
			ppu_addr_out[17:10] <= r[2+ppu_addr_in[11:10]];
		ppu_addr_out[18] <= 0;
	end
	
	// Renable IRQ only when PPU A12 is low
	always @ (*)
	begin
		if (!irq_enabled)
		begin
			irq_ready = 0;
			irq <= 1'bZ;
		end else if (irq_enabled && !irq_value)
			irq_ready = 1;
		else if (irq_ready && irq_value)
			irq <= 1'b0;
	end
	
	// IRQ counter
	always @ (posedge ppu_addr_in[12])
	begin
		if (a12_low_time == 3)
		begin
			//irq_counter_last = irq_counter;
			if ((irq_reload && !irq_reload_clear) || (irq_counter == 0))
			begin
				irq_counter = irq_latch;
				if (irq_reload) irq_reload_clear <= 1;
			end else
				irq_counter = irq_counter-1;
			if (irq_counter == 0 && irq_enabled)
				irq_value = 1;
			else
				irq_value = 0;
		end
		if (!irq_reload) irq_reload_clear <= 0;		
	end
	
	// A12 must be low for 3 rises of M2
	always @ (posedge m2, posedge ppu_addr_in[12])
	begin
		if (ppu_addr_in[12])
			a12_low_time <= 0;
		else if (a12_low_time < 3)
			a12_low_time <= a12_low_time + 1;
	end
	
endmodule
