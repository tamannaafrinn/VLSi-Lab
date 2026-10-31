-- tb_register_1bit.vhd : table-driven check of register_1bit
-- Inputs change on the falling edge, Q is read 1 ns after the rising edge.

library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_register_1bit is
end entity tb_register_1bit;

architecture bench of tb_register_1bit is

  component register_1bit is
    port (
      CLK, RESET, LOAD, D : in  std_logic;
      Q                   : out std_logic
    );
  end component;

  signal CLK, RESET, LOAD, D, Q : std_logic := '0';

  type vector_t is record
    rst, ld, din, q_exp : std_logic;
  end record;
  type plan_t is array (natural range <>) of vector_t;

  --                 rst  ld   d    expected Q
  constant PLAN : plan_t := (
    ('1', '0', '1', '0'),   -- reset (D = 1 is ignored)
    ('0', '1', '1', '1'),   -- load 1
    ('0', '0', '0', '1'),   -- hold  (D = 0 is ignored)
    ('0', '1', '0', '0'),   -- load 0
    ('0', '0', '1', '0'),   -- hold  (D = 1 is ignored)
    ('0', '1', '1', '1'),   -- load 1 again
    ('1', '1', '1', '0')    -- reset beats load
  );

begin

  uut : register_1bit
    port map (CLK => CLK, RESET => RESET, LOAD => LOAD, D => D, Q => Q);

  clock : process
  begin
    CLK <= '0'; wait for 5 ns;
    CLK <= '1'; wait for 5 ns;
  end process clock;

  checker : process
    variable bad : natural := 0;
  begin
    for i in PLAN'range loop
      wait until falling_edge(CLK);
      RESET <= PLAN(i).rst;
      LOAD  <= PLAN(i).ld;
      D     <= PLAN(i).din;
      wait until rising_edge(CLK);
      wait for 1 ns;
      report "step " & integer'image(i + 1) &
             " | RESET=" & to_string(PLAN(i).rst) &
             " LOAD="    & to_string(PLAN(i).ld) &
             " D="       & to_string(PLAN(i).din) &
             " -> Q="    & to_string(Q);
      if Q /= PLAN(i).q_exp then
        report "MISMATCH at step " & integer'image(i + 1) &
               ", expected Q=" & to_string(PLAN(i).q_exp) severity error;
        bad := bad + 1;
      end if;
    end loop;

    if bad = 0 then
      report "tb_register_1bit: all 7 steps matched";
    else
      report "tb_register_1bit: " & integer'image(bad) & " step(s) failed" severity error;
    end if;
    finish;
  end process checker;

end architecture bench;
