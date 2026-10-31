-- alu_8bit.vhd : 8-bit ALU that shares one ripple-carry adder between four operations
-- CSE 450 VLSI Lab, Experiment 04 | Most. Sadia Afrin Tamanna (22201137)
--
--   OP    operation   RESULT
--   000   ADD         A + B
--   001   SUB         A - B       (A + not B + 1)
--   010   AND         A and B
--   011   OR          A or B
--   100   XOR         A xor B
--   101   NOT         not A
--   110   INC         A + 1       (A + 00, carry-in 1)
--   111   DEC         A - 1       (A + FF, carry-in 0)
--
-- Flags: ZERO  = result is 00
--        CARRY = adder carry-out, arithmetic only (for SUB, 1 means "no borrow")
--        NEG   = top bit of the result
--        OVF   = signed overflow, arithmetic only

library ieee;
use ieee.std_logic_1164.all;

entity alu_8bit is
  port (
    A, B   : in  std_logic_vector(7 downto 0);
    OP     : in  std_logic_vector(2 downto 0);
    RESULT : out std_logic_vector(7 downto 0);
    ZERO   : out std_logic;
    CARRY  : out std_logic;
    NEG    : out std_logic;
    OVF    : out std_logic
  );
end entity alu_8bit;

architecture rtl of alu_8bit is

  -- the ripple-carry adder from the earlier labs
  component adder_8bit is
    port (
      A    : in  std_logic_vector(7 downto 0);
      B    : in  std_logic_vector(7 downto 0);
      CIN  : in  std_logic;
      SUM  : out std_logic_vector(7 downto 0);
      COUT : out std_logic
    );
  end component;

  signal b_eff    : std_logic_vector(7 downto 0);  -- second operand the adder sees
  signal cin_eff  : std_logic;                     -- carry-in the adder sees
  signal sum      : std_logic_vector(7 downto 0);
  signal cout_add : std_logic;
  signal arith    : std_logic;                     -- 1 for ADD, SUB, INC, DEC
  signal res      : std_logic_vector(7 downto 0);

begin

  -- step 1: decide what the adder is given
  with OP select
    b_eff <= B     when "000",     -- ADD : A + B
             not B when "001",     -- SUB : A + not B (+ 1)
             x"00" when "110",     -- INC : A + 0 (+ 1)
             x"FF" when "111",     -- DEC : A + FF
             x"00" when others;    -- logic ops: adder output is not used

  with OP select
    cin_eff <= '1' when "001" | "110",
               '0' when others;

  -- step 2: one adder serves all four arithmetic operations
  ADDER : adder_8bit
    port map (A => A, B => b_eff, CIN => cin_eff, SUM => sum, COUT => cout_add);

  -- step 3: choose which answer leaves the ALU
  with OP select
    res <= sum     when "000" | "001" | "110" | "111",
           A and B when "010",
           A or B  when "011",
           A xor B when "100",
           not A   when "101",
           x"00"   when others;

  arith <= '1' when OP = "000" or OP = "001" or OP = "110" or OP = "111" else '0';

  -- step 4: outputs and flags
  RESULT <= res;
  ZERO   <= '1' when res = x"00" else '0';
  NEG    <= res(7);
  CARRY  <= cout_add and arith;
  OVF    <= arith and not (A(7) xor b_eff(7)) and (A(7) xor res(7));

end architecture rtl;
