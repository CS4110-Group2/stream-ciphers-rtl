library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity autoclave_cipher is
    Port ( start : in STD_LOGIC; 
         ascii_r : in STD_LOGIC_VECTOR (7 downto 0);
         key : in STD_LOGIC_VECTOR (7 downto 0);
         cphr_out : out STD_LOGIC_VECTOR (7 downto 0);
         encrypt : in STD_LOGIC );
end autoclave_cipher;

architecture arch of autoclave_cipher is
    signal sdin:  unsigned (7 downto 0);
    signal skey:  unsigned (7 downto 0);
    signal sdout: unsigned (7 downto 0);

begin
    sdin <= unsigned(ascii_r);
    skey <= unsigned(key);

    sdout <= sdout when start /= '1' else
             -- case of space:
             x"20" when ( sdin=x"20" ) else
             -- Encrypting
             -- case of uppercase:
             ( ( ( ( sdin - x"41" ) + ( skey - x"41" ) ) MOD 26 ) + x"41") when ( ( ( sdin >= x"41" ) and ( sdin <= x"5A") ) and encrypt='1' ) else
             -- case of lowercase (add make it uppercase):
             ( ( ( ( sdin - x"61" ) + ( skey - x"41" ) ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"61" ) and ( sdin <= x"7A") ) and encrypt='1' ) else

             -- Decrypting
             -- case of uppercase:
             ( ( ( 26 + ( sdin - x"41" ) - ( skey - x"41" ) ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"41" ) and ( sdin <= x"5A" ) ) ) else
             -- case of lowercase (add make it uppercase):
             ( ( ( 26 +( sdin - x"61" ) - ( skey - x"41" ) ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"61" ) and ( sdin <= x"7A" ) ) ) else
             sdin;

    cphr_out <= std_logic_vector(sdout);

end arch;
