

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HexToAscii is
    Port ( hex_lsb : in STD_LOGIC_VECTOR (7 downto 0);
           hex_msb : in STD_LOGIC_VECTOR (7 downto 0);
           ascii : out STD_LOGIC_VECTOR (7 downto 0));
end HexToAscii;

architecture Behavioral of HexToAscii is
begin
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

    ascii(3 downto 0) <= x"0" when hex_lsb = x"30" else
                         x"1" when hex_lsb = x"31" else
                         x"2" when hex_lsb = x"32" else
                         x"3" when hex_lsb = x"33" else
                         x"4" when hex_lsb = x"34" else
                         x"5" when hex_lsb = x"35" else
                         x"6" when hex_lsb = x"36" else
                         x"7" when hex_lsb = x"37" else
                         x"8" when hex_lsb = x"38" else
                         x"9" when hex_lsb = x"39" else
                         x"A" when hex_lsb = x"41" or hex_lsb = x"61" else
                         x"B" when hex_lsb = x"42" or hex_lsb = x"62" else
                         x"C" when hex_lsb = x"43" or hex_lsb = x"63" else
                         x"D" when hex_lsb = x"44" or hex_lsb = x"64" else
                         x"E" when hex_lsb = x"45" or hex_lsb = x"65" else
                         x"F" when hex_lsb = x"46" or hex_lsb = x"66" else
                         (others => 'U'); --invalid
end Behavioral;
