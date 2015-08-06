// NES-EVENT cartridge
// (c) Cluster, 2015
// http://clusterrr.com

module NES_EVENT # (
/*
	DIP switches: 0 - closed, 1 - opened
	OOOO - 5.001
	OOOC - 5.316
	OOCO - 5.629
	OOCC - 5.942
	OCOO - 6.254
	OCOC - 6.567
	OCCO - 6.880
	OCCC - 7.193
	COOO - 7.505
	COOC - 7.818
	COCO - 8.131
	COCC - 8.444
	CCOO - 8.756
	CCOC - 9.070
	CCCO - 9.318
	CCCC - 9.695
*/
	parameter DIP_SWITCH_4 = 1
	parameter DIP_SWITCH_3 = 0, 
	parameter DIP_SWITCH_2 = 1, 
	parameter DIP_SWITCH_1 = 1, 
) 
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
		
	output reg irq
);
	reg [5:0] load;
	reg [4:0] control;
	reg [4:0] prg_bank;
	reg [4:0] chr0_bank;
	reg [29:0] timer;
	
	assign cpu_wr_out = cpu_rw_in;
	assign cpu_rd_out = ~cpu_rw_in;
	assign cpu_flash_ce = romsel;
	assign cpu_sram_ce = ~(cpu_addr_in[14] && cpu_addr_in[13] 
		&& m2 && romsel && !prg_bank[4]); // prg_bank[4] ignored for MMC1A (mapper 155)
	assign led = ~chr0_bank[4]; // led is on when timer is on
	
	assign ppu_rd_out = ppu_rd_in;
	assign ppu_wr_out = ppu_wr_in;
	
	assign ppu_sram_ce = ppu_addr_in[13];
	assign ppu_flash_ce = 1;

	assign ppu_ciram_ce = ~ppu_addr_in[13];	
	
	initial
	begin
		control <= 5'b01100; // MMC1, состояние после ресета
		chr0_bank <= 5'b10000; // первый чип и первый банк
		prg_bank <= 0;
		load = 6'b100000;
		timer = 0;
	end
	
	always @ (posedge romsel)
	begin		
		if (cpu_rw_in == 0)
		begin
			if (cpu_data_in[7] == 1) // ресет
			begin
				load = 6'b100000;
				control[3:2] <= 2'b11;
			end else begin				
				load = {cpu_data_in[0], load[5:1]};
				if (load[0] == 1)
				begin
					case (cpu_addr_in[14:13])
						2'b00: control <= load[5:1];
						2'b01: chr0_bank <= load[5:1];
						//2'b10: chr1_bank <= load[5:1];
						2'b11: prg_bank <= load[5:1];
					endcase
					load = 6'b100000;
				end
			end
		end
	end	
		
	always @ (posedge m2)
	begin
		if (chr0_bank[4] == 1) // сброс таймера
		begin
			timer = {1'b0, DIP_SWITCH_4[0], DIP_SWITCH_3[0], DIP_SWITCH_2[0], DIP_SWITCH_1[0], 25'b0000000000000000000000000};
			irq <= 1'bZ;
		end else // отсчёт!
		begin
			timer = timer + 1;
			if (timer == 30'b111111111111111111111111111111)
				irq <= 0; // время вышло!
		end
	end
	
	always @ (*) // управление зеркалированием
	begin
		case (control[1:0])
			2'b00: ppu_ciram_a10 <= 0;
			2'b01: ppu_ciram_a10 <= 1;
			2'b10: ppu_ciram_a10 <= ppu_addr_in[10]; // вертикальный мирроринг
			2'b11: ppu_ciram_a10 <= ppu_addr_in[11]; // горизонтальный мирроринг
		endcase
	end
	
	always @ (*) // Переключение CPU банков
	begin
		if (chr0_bank[3] == 0) // первый 128K чип
		begin
			cpu_addr_out[18:12] <= {2'b00, chr0_bank[2:1], cpu_addr_in[14:12]}; // 32KB режим
		end else begin // второй 128K чип
			case (control[3:2])			
				2'b00: cpu_addr_out[18:12] <= {2'b01, prg_bank[2:1], cpu_addr_in[14:12]}; // 32KB режим
				2'b01: cpu_addr_out[18:12] <= {2'b01, prg_bank[2:1], cpu_addr_in[14:12]}; // 32KB режим
				2'b10: if (cpu_addr_in[14] == 0) // $8000-$BFFF
						cpu_addr_out[18:12] <= {5'b01000, cpu_addr_in[13:12]}; // всегда первый банк
					else // $C000-$FFFF
						cpu_addr_out[18:12] <= {2'b01, prg_bank[2:0], cpu_addr_in[13:12]};  // 16KB режим
				2'b11: if (cpu_addr_in[14] == 0) // $8000-$BFFF
						cpu_addr_out[18:12] <= {2'b01, prg_bank[2:0], cpu_addr_in[13:12]};  // 16KB режим
					else // $C000-$FFFF
						cpu_addr_out[18:12] <= {5'b01111, cpu_addr_in[13:12]}; // Всегда последний банк во втором 128K чипе
			endcase
		end
	end

endmodule
