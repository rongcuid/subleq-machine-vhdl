----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/29/2017 08:45:39 PM
-- Design Name:
-- Module Name: cpu_top - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
package io_interface is
  type ssd_interface is array(0 to 7) of std_logic_vector(7 downto 0);
end package;

package body io_interface is
end package body;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.io_interface.all;

entity cpu_top is
  port (
    clk, resetb: IN std_logic;
    sw: IN std_logic_vector(15 downto 0);
    btnU, btnD, btnL, btnR, btnC : in std_logic;
    ssd: OUT ssd_interface;
    led: OUT std_logic_vector(7 downto 0);
    boot_done: out std_logic;
	 addr : out std_logic_vector(31 downto 0)
    );
end cpu_top;

architecture Behavioral of cpu_top is
  signal mmu_we, mmu_en : std_logic;
  signal mmu_addr, mmu_di, mmu_do : std_logic_vector(31 downto 0);
-- CPU to MMU signals
  signal cpu_mmu_we, cpu_mmu_en : std_logic;
  signal cpu_mmu_addr, cpu_mmu_di, cpu_mmu_do : std_logic_vector(31 downto 0);
  signal resetb_cpu : std_logic;
-- Bootloader to MMU signals
  signal bl_we, bl_en : std_logic;
  signal bl_mmu_addr, bl_mmu_di : std_logic_vector(31 downto 0);
  signal bl_commit : std_logic;
  signal released : std_logic;
  signal bl_addr : std_logic_vector(31 downto 0);
  type boot_state is (IDLE, IDLE2, LOADL, DONE);
  signal state : boot_state;
  signal lowword : std_logic_vector(15 downto 0);
  component CPU
    port(
      clk, resetb: in std_logic;
      mmu_we, mmu_en : out std_logic;
      mmu_addr : out std_logic_vector(31 downto 0);
      mmu_di : out std_logic_vector(31 downto 0);
      mmu_do : in std_logic_vector(31 downto 0)
      );
  end component;
  component MMU
    port (
      clk : in std_logic;
      resetb : in std_logic;
      we : in std_logic;
      en : in std_logic;
      addr : in std_logic_vector(31 downto 0);
      di : in std_logic_vector(31 downto 0);
      do : out std_logic_vector(31 downto 0);
      switch : in std_logic_vector(15 downto 0);
      btnU, btnD, btnL, btnR, btnC : in std_logic;
      ssd0,ssd1,ssd2,ssd3,ssd4,ssd5,ssd6,ssd7 : out std_logic_vector(7 downto 0)
      );
  end component;
begin
addr <= bl_addr;
	-- TODO actually use the leds
	led <= (others => '0');
  CPU0 : CPU port map (
    clk=>clk, resetb=>resetb_cpu,
    mmu_we=>cpu_mmu_we,
    mmu_en=>cpu_mmu_en,
    mmu_addr=>cpu_mmu_addr,
    mmu_di=>cpu_mmu_di,
    mmu_do=>cpu_mmu_do
    );

  MMU0 : MMU port map (
    clk=>clk, resetb=>resetb,
    we=>mmu_we,
    en=>mmu_en,
    addr=>mmu_addr,
    di=>mmu_di,
    do=>mmu_do,
    switch => sw,
    btnU=>btnU, btnD=>btnD, btnL=>btnL, btnR=>btnR, btnC=>btnC,
    ssd0=>ssd(0), ssd1=>ssd(1),ssd2=>ssd(2),ssd3=>ssd(3),ssd4=>ssd(4),ssd5=>ssd(5),ssd6=>ssd(6),ssd7=>ssd(7)
    );

  -- Generate a single pulse when button is pressed
  btnC_scen_process : process (clk, resetb)
  begin
    if (resetb = '1') then
      bl_commit <= '0';
      released <= '1';
    elsif (clk'event and clk = '1') then
      if (btnC = '1' and bl_commit = '0' and released = '1') then
        bl_commit <= '1';
        released <= '0';
      elsif (bl_commit = '1') then
        bl_commit <= '0';
      end if;
      if (btnC = '0') then
        released <= '1';
      end if;
    end if;
  end process;

  -- Load program into memory
  bootloader : process (clk, resetb)
    constant EOF : std_logic_vector(31 downto 0) := (others => '1');
  begin
    if (resetb = '1') then
	 	 bl_addr <= (others => '0');
		state <= IDLE;
      bl_mmu_addr <= (others => '0');
      boot_done <= '0';
      resetb_cpu <= '1';
      bl_we <= '0';
      bl_en <= '1';
    elsif (clk'event and clk = '1') then
      case state is
        when IDLE =>
          if (bl_commit = '1') then
            state <= LOADL;
            bl_we <= '0';
            -- Load 2 bytes at a time
            lowword <= sw;
          end if;
        when IDLE2 =>
          if (bl_commit = '1') then
            state <= LOADL;
            bl_we <= '0';
            -- Load 2 bytes at a time
            lowword <= sw;
            bl_mmu_addr <= std_logic_vector(unsigned(bl_mmu_addr) + 4);
          end if;
        when LOADL =>
          if (bl_commit = '1') then
            -- If not EOF
            if (sw & lowword /= EOF) then
              state <= IDLE2;
              bl_we <= '1';
              bl_mmu_di <= sw & lowword;
				  bl_addr <= std_logic_vector(unsigned(bl_addr) + to_unsigned(4,bl_addr'length));
            else
              -- EOF detected
              state <= DONE;
              boot_done <= '1';
              resetb_cpu <= '0';
            end if;
          end if;
        when DONE => bl_we <= '0';
      end case;
    end if;
  end process;
  

  cpu_mmu_do <= mmu_do;
  mmu_mux : process (state, cpu_mmu_we, cpu_mmu_en, cpu_mmu_addr, cpu_mmu_di, bl_we, bl_en, bl_mmu_addr, bl_mmu_di)
  begin
    if (state = DONE) then
      mmu_we <= cpu_mmu_we;
      mmu_en <= cpu_mmu_en;
      mmu_addr <= cpu_mmu_addr;
      mmu_di <= cpu_mmu_di;
    else
      mmu_we <= bl_we;
      mmu_en <= bl_en;
      mmu_addr <= bl_mmu_addr;
      mmu_di <= bl_mmu_di;

    end if;
  end process;
  
end Behavioral;
