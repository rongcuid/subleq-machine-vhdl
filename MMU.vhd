----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/29/2017 07:23:06 PM
-- Design Name:
-- Module Name: MMU - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MMU is
  port (
    clk : in std_logic;
    resetb : in std_logic;
    we : in std_logic;
    en : in std_logic;
    addr : in std_logic_vector(31 downto 0);
    di : in std_logic_vector(31 downto 0);
    do : out std_logic_vector(31 downto 0);
    -- To Peripherals
    switch : in std_logic_vector(15 downto 0);
    btnU, btnD, btnL, btnR, btnC : in std_logic;
    ssd0,ssd1,ssd2,ssd3,ssd4,ssd5,ssd6,ssd7 : out std_logic_vector(7 downto 0)
    );
end MMU;

architecture Behavioral of MMU is
  type device is (DEV_RAM, DEV_SFR);
  signal selected_device : device;
  signal ram_we, ram_en, sfr_we, sfr_en : std_logic;
  signal ram_addr : std_logic_vector(9 downto 0);
  signal sfr_addr : std_logic_vector(31 downto 0);
  signal sfr_hit : std_logic;
  signal ram_do, sfr_do : std_logic_vector(31 downto 0);
  component MainRAM port(
    clk : in std_logic;
    we : in std_logic;
    en : in std_logic;
    addr : in std_logic_vector(9 downto 0);
    di : in std_logic_vector(31 downto 0);
    do : out std_logic_vector(31 downto 0)
    );
  end component;
  component SFR port (
    clk, resetb : in std_logic;
    we : in std_logic;
    en : in std_logic;
    addr : in std_logic_vector(31 downto 0);
    di : in std_logic_vector(31 downto 0);
    do : out std_logic_vector(31 downto 0);
    hit : out std_logic;
    switch : in std_logic_vector(15 downto 0);
    btnU, btnD, btnL, btnR, btnC : in std_logic;
    ssd0,ssd1,ssd2,ssd3,ssd4,ssd5,ssd6,ssd7 : out std_logic_vector(7 downto 0)
    );
  end component;
begin

  memory_map : process (addr)
  begin
    case addr(15 downto 12) is
      -- 0xXXXX0xxx Main Memory
      when "0000" => selected_device <= DEV_RAM;
      -- 0xXXXX1xxx SFR
      when "0001" => selected_device <= DEV_SFR;
      when others => NULL;
    end case;
  end process;

  -- Main RAM is here
  RAM0: MainRAM port map (
    clk=>clk, we=>ram_we, en=>ram_en, addr=>ram_addr, di=>di, do=>ram_do
    );
  SFR0: SFR port map (
    clk=>clk, resetb=>resetb, we=>sfr_we, en=>sfr_en, addr=>sfr_addr, di=>di,
    do=>sfr_do, hit=>sfr_hit,
    switch=>switch, 
    btnU=>btnU, btnD=>btnD, btnL=>btnL, btnR=>btnR, btnC=>btnC,
    ssd0=>ssd0, ssd1=>ssd1,ssd2=>ssd2,ssd3=>ssd3,ssd4=>ssd4,ssd5=>ssd5,ssd6=>ssd6,ssd7=>ssd7
    );

  -- Devices mirror themselves
  ram_we <= we;
  ram_en <= en;
  ram_addr <= addr(11 downto 2);
  sfr_we <= we;
  sfr_en <= en;
  sfr_addr <= addr;
  -- Routes correct data into corresponding devices, each with one clock latency
  data_mux : process (ram_do, sfr_do, sfr_hit)
  begin
  if (sfr_hit = '0') then
      do <= ram_do;
  else
      do <= sfr_do;
  end if;
end process;
end Behavioral;
