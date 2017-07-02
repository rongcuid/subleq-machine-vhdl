----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/29/2017 07:46:28 PM
-- Design Name:
-- Module Name: SFR - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SFR is
  port (
  -- To MMU
    clk : in std_logic;
    resetb : in std_logic;
    we : in std_logic;
    en : in std_logic;
    addr : in std_logic_vector(31 downto 0);
    di : in std_logic_vector(31 downto 0);
    do : out std_logic_vector(31 downto 0);
    hit : out std_logic;
    -- To Peripherals
    switch : in std_logic_vector(15 downto 0);
    btnU, btnD, btnL, btnR, btnC : in std_logic;
    ssd0,ssd1,ssd2,ssd3,ssd4,ssd5,ssd6,ssd7 : out std_logic_vector(7 downto 0)
    );
end SFR;

architecture Behavioral of SFR is
begin
  clocked_process : process(clk, resetb)
  variable tmp32 : std_logic_vector(31 downto 0);
  begin
    if resetb = '1' then
      ssd0 <= (others => '0');
      ssd1 <= (others => '0');
      ssd2 <= (others => '0');
      ssd3 <= (others => '0');
      ssd4 <= (others => '0');
      ssd5 <= (others => '0');
      ssd6 <= (others => '0');
      ssd7 <= (others => '0');
      hit <= '0';
    elsif (clk'event and clk = '1') then
	   tmp32 := (others => '0');
      if (en = '1') then
        hit <= '1';
        case to_integer(unsigned(addr)) is
          -- Output ports return 0
          when 16#0000_0100# => do <= (others => '0');
          when 16#0000_0104# => do <= (others => '0');
          when 16#0000_0108# => do <= (others => '0');
          when 16#0000_0109# => do <= (others => '0');
          when 16#0000_010A# => do <= (others => '0');
          when 16#0000_010B# => do <= (others => '0');
          when 16#0000_010C# => do <= (others => '0');
          when 16#0000_010D# => do <= (others => '0');
          when 16#0000_010E# => do <= (others => '0');
          when 16#0000_010F# => do <= (others => '0');
          -- Input ports
          when 16#0000_0200# => 
            tmp32(15 downto 0) := switch;
            do <= tmp32;
          when 16#0000_0204# => do <= (0 => btnU, others => '0');
          when 16#0000_0208# => do <= (0 => btnD, others => '0');
          when 16#0000_020C# => do <= (0 => btnL, others => '0');
          when 16#0000_0210# => do <= (0 => btnR, others => '0');
          when 16#0000_0214# => do <= (0 => btnC, others => '0');
          when 16#0000_0218# =>
            do <= (0 => btnU, 1 => btnD, 2 => btnL, 3 => btnR, 4 => btnC, others => '0');
          when others => hit <= '0';
        end case;
      end if;
      if (we = '1') then
        case to_integer(unsigned(addr)) is
          when 16#0000_0100# => 
            ssd3 <= di(31 downto 24);
            ssd2 <= di(23 downto 16);
            ssd1 <= di(15 downto 8);
            ssd0 <= di(7 downto 0);
          when 16#0000_0104# => 
            ssd7 <= di(31 downto 24);
            ssd6 <= di(23 downto 16);
            ssd5 <= di(15 downto 8);
            ssd4 <= di(7 downto 0);
          when 16#0000_0108# => ssd0 <= di(7 downto 0);
          when 16#0000_0109# => ssd1 <= di(7 downto 0);
          when 16#0000_010A# => ssd2 <= di(7 downto 0);
          when 16#0000_010B# => ssd3 <= di(7 downto 0);
          when 16#0000_010C# => ssd4 <= di(7 downto 0);
          when 16#0000_010D# => ssd5 <= di(7 downto 0);
          when 16#0000_010E# => ssd6 <= di(7 downto 0);
          when 16#0000_010F# => ssd7 <= di(7 downto 0);
          when others => NULL;
      end case;
      end if;
    end if;
  end process;
end Behavioral;
