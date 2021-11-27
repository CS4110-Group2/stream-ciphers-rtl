
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hex_to_ascii is
    Port ( hex : in unsigned (7 downto 0);
           passthrough : in std_logic;
           MSBits : in std_logic;
           ascii : out unsigned (7 downto 0));
end hex_to_ascii;

architecture Behavioral of hex_to_ascii is
    signal converted: unsigned(7 downto 0);
    signal MSbs: unsigned(3 downto 0);
    signal LSbs: unsigned(3 downto 0);
begin

converted <= -- Don't do anything when we can't trust the input
             converted when passthrough = '1' else
             -- Numbers
             (hex - x"30") when ((hex >= x"30") and (hex <= x"39")) else
             -- Uppercase letters
             (hex - x"41") when ((hex >= x"41") and (hex <= x"5A")) else
             -- Lowercase letters
             (hex - x"61") when ((hex >= x"61") and (hex <= x"7A")) else
             -- Just to prevent crashing
             converted;

MSbs <= converted(3 downto 0) when MSBits = '1' else
        MSBs;

LSBs <= converted(3 downto 0) when MSBits = '0' else
        LSBs;

ascii <= hex when passthrough /= '0' else
         MSBs & LSBs;
    
end Behavioral;
