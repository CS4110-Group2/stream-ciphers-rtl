
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity AsciiToHex is
    Port ( ascii   : in STD_LOGIC_VECTOR (7 downto 0);
           hex     : out STD_LOGIC_VECTOR (7 downto 0);
           lsb_msb : in  STD_LOGIC);
end AsciiToHex;

architecture Behavioral of AsciiToHex is


    type TableType is array(0 to (2**4)-1) of std_logic_vector(7 downto 0);
    constant table : TableType := 
    (
        x"30", 
        x"31", 
        x"32", 
        x"33", 
        x"34", 
        x"35", 
        x"36", 
        x"37", 
        x"38", 
        x"39", 
        x"41", 
        x"42", 
        x"43", 
        x"44", 
        x"45", 
        x"46"
);

begin
    hex <= table(to_integer(unsigned(ascii(3 downto 0)))) when lsb_msb = '0' else
           table(to_integer(unsigned(ascii(7 downto 4))));

end Behavioral;
