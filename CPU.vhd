----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/29/2017 08:09:44 PM
-- Design Name:
-- Module Name: CPU - Behavioral
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

entity CPU is
  port(
  clk, resetb: in std_logic;
  -- To MMU
  mmu_we, mmu_en : out std_logic;
  mmu_addr : out std_logic_vector(31 downto 0);
  mmu_di : out std_logic_vector(31 downto 0);
  mmu_do : in std_logic_vector(31 downto 0)
  );
end CPU;

architecture Behavioral of CPU is
  type cpu_state is (IF1, IF2_ID, MEMB1, MEMB2_MEMA1, MEMA2, BR_WB);
  signal state : cpu_state;
  signal pc : std_logic_vector(31 downto 0);
  signal b : std_logic_vector(15 downto 0);
  signal a, c : std_logic_vector(7 downto 0);

  signal data_b, data_c : std_logic_vector(31 downto 0);
begin
  mmu_en <= '1';
  clocked_process : process (clk, resetb)
  variable c_tmp : std_logic_vector (31 downto 0);
  begin
    if (resetb = '1') then
      pc <= (others => '0');
      state <= IF1;
    elsif (clk'event and clk = '1') then
      case state is
        when IF1 => state <= IF2_ID;
                    pc <= std_logic_vector(unsigned(pc) + 4);
        when IF2_ID =>
          state <= MEMB1;
          -- Decode
          b <= mmu_do(31 downto 16);
          a <= mmu_do(15 downto 8);
          c <= mmu_do(7 downto 0);
          -- Start getting B
        when MEMB1 => state <= MEMB2_MEMA1;
        -- Save B and load A
        when MEMB2_MEMA1 =>
          state <= MEMA2;
          data_b <= mmu_do;
        -- Save A and calculate jump PC
        when MEMA2 =>
          state <= BR_WB;
          data_b <= std_logic_vector(signed(data_b) - signed(mmu_do));
          c_tmp := std_logic_vector(shift_left(resize(signed(c),c_tmp'length),2) + signed(pc));
          data_c <= c_tmp;
        when BR_WB =>
          state <= IF1;
          if (signed(data_b) <= 0) then
            pc <= data_c;
          end if;
      end case;
    end if;
  end process;

  ofl : process (state, pc, a, b, data_b)
  constant z16 : std_logic_vector(15 downto 0) := (others => '0');
  variable tmp32 : std_logic_vector(31 downto 0);
  begin
    tmp32 := (others => '0');
    mmu_we <= '0';
	 mmu_addr <= (others=>'-');
	 mmu_di <= (others=>'-');
    case state is
      when IF1 => mmu_addr <= pc;
      when IF2_ID => NULL; -- Do nothing
      when MEMB1 => mmu_addr <= z16 & b;
      when MEMB2_MEMA1 =>
      -- A is 8 bits, B is 16 bits. Addition is 17 bits
        tmp32 := std_logic_vector(resize(signed(a),tmp32'length));
        -- Left shift 2
        tmp32 := std_logic_vector(shift_left(signed(tmp32),2));
        -- Add to b
        tmp32 := std_logic_vector(signed(tmp32) + resize(signed(b),tmp32'length));
        mmu_addr <= tmp32;
      when MEMA2 => NULL; 
      when BR_WB =>
		  mmu_addr(31 downto 16) <= (others => '0');
        mmu_addr(15 downto 0) <= b;
        mmu_di <= data_b;
        mmu_we <= '1';
  end case;
  end process;

end Behavioral;
