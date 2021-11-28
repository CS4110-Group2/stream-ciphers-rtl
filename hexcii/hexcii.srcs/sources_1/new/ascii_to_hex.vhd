
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ascii_to_hex is
    Port ( ascii : in unsigned (7 downto 0);
           passthrough : in std_logic;
           MSBits : in std_logic;
           hex : out unsigned (7 downto 0));
end ascii_to_hex;

architecture Behavioral of ascii_to_hex is
    signal bits: unsigned (3 downto 0);
           
begin

bits <= ascii(7 downto 4) when MSBits = '1' else
        ascii(3 downto 0) when MSBits = '0' else
        bits;
        
hex <= ascii when passthrough /= '0' else
       -- convert to it's hex number value (0 - 9)
       (bits + x"30") when (bits < 10) else
       -- convert to it's hex letter value (A - F)
       (bits + x"41");

end Behavioral;
