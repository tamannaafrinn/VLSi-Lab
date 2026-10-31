-- tb_alu_8bit.vhd : self-checking testbench for alu_8bit
-- Each check holds the inputs for 10 ns, then compares RESULT and the four flags
-- with values the testbench works out on its own.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu_8bit is
end entity tb_alu_8bit;

architecture bench of tb_alu_8bit is

  component alu_8bit is
    port (
      A, B   : in  std_logic_vector(7 downto 0);
      OP     : in  std_logic_vector(2 downto 0);
      RESULT : out std_logic_vector(7 downto 0);
      ZERO   : out std_logic;
      CARRY  : out std_logic;
      NEG    : out std_logic;
      OVF    : out std_logic
    );
  end component;

  signal a_tb, b_tb, res_tb     : std_logic_vector(7 downto 0) := (others => '0');
  signal op_tb                  : std_logic_vector(2 downto 0) := (others => '0');
  signal z_tb, c_tb, n_tb, v_tb : std_logic;

  type pair_t is record
    opa, opb : integer;
  end record;
  type pair_list_t is array (natural range <>) of pair_t;

  -- corner cases, tried on every opcode
  constant CORNERS : pair_list_t := (
    (0,   0),      -- all zeros
    (255, 255),    -- all ones
    (127, 1),      -- +127 + 1 : signed overflow on ADD
    (128, 1),      -- -128 - 1 : signed overflow on SUB and DEC
    (255, 1),      -- carry / wrap-around
    (5,   10),     -- borrow on SUB
    (85,  170)     -- 0x55 and 0xAA
  );

begin

  uut : alu_8bit
    port map (A => a_tb, B => b_tb, OP => op_tb, RESULT => res_tb,
              ZERO => z_tb, CARRY => c_tb, NEG => n_tb, OVF => v_tb);

  checker : process
    variable total, bad   : natural := 0;
    variable exp_res      : integer;
    variable exp_c, exp_v : std_logic;
    variable sv           : integer;

    -- a byte read as a signed number
    function signed_val (x : integer) return integer is
    begin
      if x >= 128 then
        return x - 256;
      end if;
      return x;
    end function;

    procedure check (op : integer; a, b : integer) is
    begin
      a_tb  <= std_logic_vector(to_unsigned(a, 8));
      b_tb  <= std_logic_vector(to_unsigned(b, 8));
      op_tb <= std_logic_vector(to_unsigned(op, 3));
      wait for 10 ns;

      exp_c := '0';
      exp_v := '0';
      case op is
        when 0 =>                                   -- ADD
          exp_res := (a + b) mod 256;
          if a + b > 255 then exp_c := '1'; end if;
          sv := signed_val(a) + signed_val(b);
          if sv > 127 or sv < -128 then exp_v := '1'; end if;
        when 1 =>                                   -- SUB (carry 1 = no borrow)
          exp_res := (a - b + 256) mod 256;
          if a >= b then exp_c := '1'; end if;
          sv := signed_val(a) - signed_val(b);
          if sv > 127 or sv < -128 then exp_v := '1'; end if;
        when 2 => exp_res := to_integer(to_unsigned(a, 8) and to_unsigned(b, 8));
        when 3 => exp_res := to_integer(to_unsigned(a, 8) or  to_unsigned(b, 8));
        when 4 => exp_res := to_integer(to_unsigned(a, 8) xor to_unsigned(b, 8));
        when 5 => exp_res := 255 - a;               -- NOT A
        when 6 =>                                   -- INC
          exp_res := (a + 1) mod 256;
          if a = 255 then exp_c := '1'; end if;
          if signed_val(a) + 1 > 127 then exp_v := '1'; end if;
        when others =>                              -- DEC
          exp_res := (a - 1 + 256) mod 256;
          if a >= 1 then exp_c := '1'; end if;
          if signed_val(a) - 1 < -128 then exp_v := '1'; end if;
      end case;

      total := total + 1;
      if to_integer(unsigned(res_tb)) /= exp_res or c_tb /= exp_c or v_tb /= exp_v
         or (z_tb = '1') /= (exp_res = 0) or (n_tb = '1') /= (exp_res >= 128) then
        bad := bad + 1;
        report "FAIL: op=" & integer'image(op) & " A=" & integer'image(a) &
               " B=" & integer'image(b) &
               " got=" & integer'image(to_integer(unsigned(res_tb))) &
               " expected=" & integer'image(exp_res) severity error;
      end if;
    end procedure;
  begin

    -- part 1: corner cases on every opcode (7 x 8 = 56 checks)
    for op in 0 to 7 loop
      for k in CORNERS'range loop
        check(op, CORNERS(k).opa, CORNERS(k).opb);
      end loop;
    end loop;

    -- part 2: sweep A and B over 0, 15, 30 ... 255 on every opcode
    for op in 0 to 7 loop
      for ia in 0 to 17 loop
        for ib in 0 to 17 loop
          check(op, 15 * ia, 15 * ib);
        end loop;
      end loop;
    end loop;

    if bad = 0 then
      report "tb_alu_8bit: all " & integer'image(total) & " checks matched";
    else
      report "tb_alu_8bit: " & integer'image(bad) & " of " & integer'image(total) &
             " checks failed" severity failure;
    end if;
    wait;
  end process checker;

end architecture bench;
