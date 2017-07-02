----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/29/2017 01:11:23 PM
-- Design Name:
-- Module Name: cpu_top_tb - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
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
library std;
use std.textio.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.io_interface.all;

entity cpu_top_tb is
--  Port ( );
end cpu_top_tb;


architecture Behavioral of cpu_top_tb is
  subtype word_t is std_logic_vector(31 downto 0);
  type ram_t is array(0 to 1023) of word_t;
  signal ram_data_tb : ram_t;
  constant clk_period: time := 10ns;
  signal clk_tb: std_logic;
  signal resetb_tb: std_logic;
  signal sw_tb : std_logic_vector(15 downto 0);
  signal btnU_tb, btnD_tb, btnL_tb, btnR_tb, btnC_tb : std_logic;
  signal ssd_tb : ssd_interface;
  signal led_tb : std_logic_vector(7 downto 0);
  signal boot_done_tb : std_logic;
  signal addr_tb : std_logic_vector(31 downto 0);
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

-- https://electronics.stackexchange.com/questions/180446/how-to-load-std-logic-vector-array-from-text-file-at-start-of-simulation
-- Read a *.hex file
  impure function ocram_ReadMemFile(FileName : STRING) return ram_t is
    file FileHandle       : TEXT open READ_MODE is FileName;
    variable CurrentLine  : LINE;
    variable TempWord     : word_t;
    variable Result       : ram_t    := (others => (others => '0'));
    variable i : integer;

  begin
    for i in 0 to 1023 loop
      exit when endfile(FileHandle);

      readline(FileHandle, CurrentLine);
      hread(CurrentLine, TempWord);
      Result(i)    := TempWord;
    end loop;

    return Result;
  end function;

  procedure load_program(
    FileName : in string;
    signal resetb_tb : out std_logic;
    signal sw_tb : out std_logic_vector(15 downto 0);
    signal btnC_tb : out std_logic;
    signal ram_data_tb : out ram_t
    ) is
    variable program_32bit : ram_t := (others => (others => 'U'));
    variable tmp32 : word_t;
  begin
    program_32bit := ocram_ReadMemFile(FileName);
    ram_data_tb <= program_32bit;

    wait until rising_edge(clk_tb);
    resetb_tb <= '1';
    wait until rising_edge(clk_tb);
    wait until rising_edge(clk_tb);
    wait until rising_edge(clk_tb);
    resetb_tb <= '0';
    wait until rising_edge(clk_tb);
    for i in 0 to 1023 loop
      exit when boot_done_tb = '1';
      tmp32 := program_32bit(i);
      sw_tb <= tmp32(15 downto 0);
      btnC_tb <= '1';
      wait until rising_edge(clk_tb);
      btnC_tb <= '0';
      wait until rising_edge(clk_tb);
      wait until rising_edge(clk_tb);
      sw_tb <= tmp32(31 downto 16);
      btnC_tb <= '1';
      wait until rising_edge(clk_tb);
      btnC_tb <= '0';
      wait until rising_edge(clk_tb);
      wait until rising_edge(clk_tb);
      wait until rising_edge(clk_tb);
    end loop;
    wait until rising_edge(clk_tb);
    
  end procedure;

  procedure wait32 is
  begin
    for i in 0 to 31 loop
      wait until rising_edge(clk_tb);
    end loop;
  end procedure;
  


begin

  UUT: cpu_top port map (
    clk=>clk_tb, resetb=>resetb_tb, 
    sw=>sw_tb, 
    btnU=>btnU_tb, btnD=>btnD_tb, btnL=>btnL_tb, btnR=>btnR_tb, btnC=>btnC_tb,
    ssd=>ssd_tb, led=>led_tb, boot_done=>boot_done_tb,
	 addr=>addr_tb
    );

  clock_generate : process
  begin
    clk_tb <= '0', '1' after (clk_period / 2);
    wait for clk_period;
  end process clock_generate;

  stimulus : process
  begin
  -- Test 1: 1 + 1 = 2. 2 should be in RAM data[3]
  load_program("../Sources/test00.txt", resetb_tb, sw_tb, btnC_tb, ram_data_tb);
  wait for 300 ns;
  -- Test 2: -SubLEq- in SSD outputs
  load_program("../Sources/helloworld.txt", resetb_tb, sw_tb, btnC_tb, ram_data_tb);
  wait for 1000 ns;
  end process;
end Behavioral;
