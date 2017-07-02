----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:08:12 06/30/2017 
-- Design Name: 
-- Module Name:    board_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library work;
use work.io_interface.all;
entity board_top is
    Port ( CLK100MHZ : in  STD_LOGIC;
           sw : in  STD_LOGIC_VECTOR (15 downto 0);
           CPU_RESETN : in  STD_LOGIC;
           BTNC : in  STD_LOGIC;
           BTND : in  STD_LOGIC;
           BTNL : in  STD_LOGIC;
           BTNR : in  STD_LOGIC;
           BTNU : in  STD_LOGIC;
			  led : out STD_LOGIC_VECTOR(15 downto 0);
			  CA,CB,CC,CD,CE,CF,CG,DP : out STD_LOGIC;
			  AN: out STD_LOGIC_VECTOR(7 downto 0)
			  );
end board_top;

architecture Behavioral of board_top is
component cpu_top
  port (
    clk, resetb: IN std_logic;
    sw: IN std_logic_vector(15 downto 0);
    btnU, btnD, btnL, btnR, btnC : in std_logic;
    ssd: OUT ssd_interface;
    led: OUT std_logic_vector(7 downto 0);
    boot_done: out std_logic;
	 addr : out std_logic_vector(31 downto 0)
    );
	 end component;
	 signal reset, clk : std_logic;
	 signal boot_done : std_logic;
	 signal ssd_cpu : ssd_interface;
	 signal segments : std_logic_vector(7 downto 0);
	 signal ssd_hex : std_logic_vector(3 downto 0);
	 signal seg_hex, seg_cpu : std_logic_vector(7 downto 0);
	 signal cpu_addr : std_logic_vector(31 downto 0);
	 signal counter, counter_btn : integer;
	 signal btn_pressed, btn_debounced : std_logic;
	 signal ssd_pointer : std_logic_vector(2 downto 0);
begin
	dp <= segments(7);
	cg <= segments(6);
	cf <= segments(5);
	ce <= segments(4);
	cd <= segments(3);
	cc <= segments(2);
	cb <= segments(1);
	ca <= segments(0);
	reset <= not cpu_resetn;
	clk <= clk100mhz;
	
	-- Components
	CPU0 : cpu_top port map (
	clk => clk, resetb => reset, 
	btnc => btnc, btnd => btnd, btnl => btnl, btnr => btnr, btnu => btnu,
	led => led(7 downto 0), 
	ssd => ssd_cpu, sw=>sw,
	boot_done => boot_done,
	addr=>cpu_addr
	);
	
	-- Convert one hex to ssd
	hex_to_ssd : process (ssd_hex)
	begin
		case to_integer(unsigned(ssd_hex)) is
			when 16#0# => seg_hex <= "11000000";
			when 16#1# => seg_hex <= "11111001";
			when 16#2# => seg_hex <= "10100100";
			when 16#3# => seg_hex <= "10110000";
			when 16#4# => seg_hex <= "10011001";
			when 16#5# => seg_hex <= "10010010";
			when 16#6# => seg_hex <= "10000010";
			when 16#7# => seg_hex <= "11111000";
			when 16#8# => seg_hex <= "10000000";
			when 16#9# => seg_hex <= "10010000";
			when 16#A# => seg_hex <= "10001000";
			when 16#B# => seg_hex <= "10000011";
			when 16#C# => seg_hex <= "11000110";
			when 16#D# => seg_hex <= "10100001";
			when 16#E# => seg_hex <= "10000110";
			when 16#F# => seg_hex <= "10001110";
			when others => seg_hex <= "11111111";
		end case;
	end process;
	
	-- SSD Scanner
	ssd_scanner : process (clk, reset)
		variable tmp_seg : std_logic_vector(7 downto 0);
	begin
		if (reset = '1') then
			counter <= 0;
			ssd_pointer <= "000";
			ssd_hex <= (others => '0');
		elsif (clk'event and clk = '1') then
			if (counter = 100000) then
				counter <= 0;
				ssd_pointer <= std_logic_vector(unsigned(ssd_pointer) + to_unsigned(1,ssd_pointer'length));
				tmp_seg := ssd_cpu(to_integer(unsigned(ssd_pointer)));
				for i in 0 to 7 loop
					if (tmp_seg(i) = '1') then
					seg_cpu(i) <= '0';
					else
					seg_cpu(i) <= '1';
					end if;
				end loop;
				an <= (others=>'1');
				an(to_integer(unsigned(ssd_pointer))) <= '0';
				case to_integer(unsigned(ssd_pointer)) is
					when 16#7# => ssd_hex <= cpu_addr(15 downto 12);
					when 16#6# => ssd_hex <= cpu_addr(11 downto 8);
					when 16#5# => ssd_hex <= cpu_addr(7 downto 4);
					when 16#4# => ssd_hex <= cpu_addr(3 downto 0);
					when 16#3# => ssd_hex <= sw(15 downto 12);
					when 16#2# => ssd_hex <= sw(11 downto 8);
					when 16#1# => ssd_hex <= sw(7 downto 4);
					when 16#0# => ssd_hex <= sw(3 downto 0);
					when others => NULL;
				end case;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;
	
	segment_mux : process (seg_hex, seg_cpu, boot_done)
	begin
		if (boot_done = '1') then
			segments <= seg_cpu;
			led(15 downto 14) <= (others => '1');
			led(13 downto 8) <= (others => '0');
		else 
			segments <= seg_hex;
			led(15 downto 9) <= (others => '0');
			led(8) <= '1';
			end if;
	end process;
	
	-- ButtonC Debouncer/SCEN
	btn_scen : process (clk, reset)
	begin
		if (reset = '1') then
			counter_btn <= 0;
			btn_pressed <= '0';
			btn_debounced <= '0';
		elsif (clk'event and clk = '1') then
			if (btn_debounced = '0') then
				if (btn_pressed = '0' and btnc = '1') then
					btn_pressed <= '1';
				elsif (btn_pressed = '1') then
					if (counter_btn = 50000000) then
						counter_btn <= 0;
						-- Held for enough time
						if (btnc = '1') then
							btn_debounced <= '1';
						else
							btn_pressed <= '0';
						end if;
					else
					counter_btn <= counter_btn + 1;
					end if;
				end if;
			else
				if (btn_pressed = '1' and btnc = '0') then
					btn_pressed <= '0';
				elsif (btn_pressed = '0') then
					if (counter_btn = 50000000) then
						counter_btn <= 0;
						-- Held for enough time
						if (btnc = '0') then
							btn_debounced <= '0';
						else
							btn_pressed <= '1';
						end if;
					else
					counter_btn <= counter_btn + 1;
					end if;			
				end if;
			end if;
		end if;
	end process;

end Behavioral;

