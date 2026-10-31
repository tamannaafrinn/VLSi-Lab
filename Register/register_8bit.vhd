-- register_8bit.vhd : eight flip-flops sharing one reset and one load enable
-- CSE 450 VLSI Lab, Experiment 03 | Most. Sadia Afrin Tamanna (22201137)

library ieee;
use ieee.std_logic_1164.all;

entity register_8bit is
  port (
    CLK, RESET, LOAD : in  std_logic;
    D                : in  std_logic_vector(7 downto 0);
    Q                : out std_logic_vector(7 downto 0)
  );
end entity register_8bit;

architecture rtl of register_8bit is
  signal stored : std_logic_vector(7 downto 0) := x"00";
begin

  capture : process (CLK)
  begin
    if rising_edge(CLK) then
      if RESET = '1' then          -- rule 1: reset always wins
        stored <= x"00";
      elsif LOAD = '1' then        -- rule 2: take a new value
        stored <= D;
      end if;                      -- rule 3: otherwise keep the old one
    end if;
  end process capture;

  Q <= stored;

end architecture rtl;
