-- tb_register_8bit.vhd : table-driven check of register_8bit
-- Inputs change on the falling edge, Q is read 1 ns after the rising edge.

library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_register_8bit is
end entity tb_register_8bit;

architecture bench of tb_register_8bit is

  component register_8bit is
    port (
      CLK, RESET, LOAD : in  std_logic;
      D                : in  std_logic_vector(7 downto 0);
      Q                : out std_logic_vector(7 downto 0)
    );
  end component;

  signal CLK, RESET, LOAD : std_logic := '0';
  signal D : std_logic_vector(7 downto 0) := (others => '0');
  signal Q : std_logic_vector(7 downto 0);

  type vector_t is record
    rst, ld : std_logic;
    din     : std_logic_vector(7 downto 0);
    q_exp   : std_logic_vector(7 downto 0);
  end record;
  type plan_t is array (natural range <>) of vector_t;

  --                 rst  ld   d       expected Q
  constant PLAN : plan_t := (
    ('1', '0', x"FF", x"00"),   -- reset (D = FF is ignored)
    ('0', '1', x"A5", x"A5"),   -- load A5
    ('0', '0', x"5A", x"A5"),   -- hold  (D = 5A is ignored)
    ('0', '1', x"5A", x"5A"),   -- load 5A
    ('0', '1', x"C3", x"C3"),   -- load C3
    ('0', '0', x"0F", x"C3"),   -- hold  (D = 0F is ignored)
    ('1', '1', x"FF", x"00")    -- reset beats load
  );

begin

  uut : register_8bit
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
             " D=0x"     & to_hstring(PLAN(i).din) &
             " -> Q=0x"  & to_hstring(Q);
      if Q /= PLAN(i).q_exp then
        report "MISMATCH at step " & integer'image(i + 1) &
               ", expected Q=0x" & to_hstring(PLAN(i).q_exp) severity error;
        bad := bad + 1;
      end if;
    end loop;

    if bad = 0 then
      report "tb_register_8bit: all 7 steps matched";
    else
      report "tb_register_8bit: " & integer'image(bad) & " step(s) failed" severity error;
    end if;
    finish;
  end process checker;

end architecture bench;
