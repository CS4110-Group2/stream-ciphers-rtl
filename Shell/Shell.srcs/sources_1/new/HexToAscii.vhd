

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HexToAscii is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           load : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           ascii : out STD_LOGIC_VECTOR (7 downto 0));
end HexToAscii;

architecture Behavioral of HexToAscii is

    signal hex_msb : std_logic_vector(7 downto 0);

begin
    hex_temp_reg : entity work.Reg(Behavioral)
    generic map
    (
        SIZE => 8
    )
    port map
    (
        clk => clk,
        rst => rst,
        load => load,
        clear => '0',
        data_in => data_in,
        data_out => hex_msb
    );

    ascii(7 downto 4) <= x"0" when hex_msb = x"30" else
    x"1" when hex_msb = x"31" else
    x"2" when hex_msb = x"32" else
    x"3" when hex_msb = x"33" else
    x"4" when hex_msb = x"34" else
    x"5" when hex_msb = x"35" else
    x"6" when hex_msb = x"36" else
    x"7" when hex_msb = x"37" else
    x"8" when hex_msb = x"38" else
    x"9" when hex_msb = x"39" else
    x"A" when hex_msb = x"41" or hex_msb = x"61" else
    x"B" when hex_msb = x"42" or hex_msb = x"62" else
    x"C" when hex_msb = x"43" or hex_msb = x"63" else
    x"D" when hex_msb = x"44" or hex_msb = x"64" else
    x"E" when hex_msb = x"45" or hex_msb = x"65" else
    x"F" when hex_msb = x"46" or hex_msb = x"66" else
    (others => 'U'); --invalid

    ascii(3 downto 0) <=    x"0" when data_in = x"30" else
    x"1" when data_in = x"31" else
    x"2" when data_in = x"32" else
    x"3" when data_in = x"33" else
    x"4" when data_in = x"34" else
    x"5" when data_in = x"35" else
    x"6" when data_in = x"36" else
    x"7" when data_in = x"37" else
    x"8" when data_in = x"38" else
    x"9" when data_in = x"39" else
    x"A" when data_in = x"41" or data_in = x"61" else
    x"B" when data_in = x"42" or data_in = x"62" else
    x"C" when data_in = x"43" or data_in = x"63" else
    x"D" when data_in = x"44" or data_in = x"64" else
    x"E" when data_in = x"45" or data_in = x"65" else
    x"F" when data_in = x"46" or data_in = x"66" else
    (others => 'U'); --invalid
end Behavioral;
