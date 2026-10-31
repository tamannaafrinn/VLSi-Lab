-- register_1bit.vhd : one flip-flop with synchronous reset and load enable
-- CSE 450 VLSI Lab, Experiment 03 | Most. Sadia Afrin Tamanna (22201137)

library ieee;
use ieee.std_logic_1164.all;

entity register_1bit is
  port (
    CLK, RESET, LOAD, D : in  std_logic;
    Q                   : out std_logic
  );
end entity register_1bit;

architecture rtl of register_1bit is
  signal stored : std_logic := '0';
begin

  capture : process (CLK)
  begin
    if rising_edge(CLK) then
      if RESET = '1' then          -- rule 1: reset always wins
        stored <= '0';
      elsif LOAD = '1' then        -- rule 2: take a new value
        stored <= D;
      end if;                      -- rule 3: otherwise keep the old one
    end if;
  end process capture;

  Q <= stored;

end architecture rtl;
