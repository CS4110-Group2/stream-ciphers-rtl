library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity autoclave_cipher is
    Port(data_in                : in  STD_LOGIC_VECTOR (7 downto 0);
         key                    : in  STD_LOGIC_VECTOR (7 downto 0);
         data_out               : out STD_LOGIC_VECTOR (7 downto 0);
         encrypt_decrypt_signal : in  STD_LOGIC);
end autoclave_cipher;

architecture Behavioral of autoclave_cipher is

    signal sdin     : unsigned (7 downto 0);
    signal skey     : unsigned (7 downto 0);
    signal cipher   : unsigned (7 downto 0);

begin
    sdin <= unsigned(data_in);
    skey <= unsigned(key);

    cipher <= -- case of space:
             x"20" when ( sdin=x"20" ) else
             -- Encrypting
             -- case of uppercase:
             ( ( ( sdin + skey ) MOD 26 ) + x"41") when ( ( ( sdin >= x"41" ) and ( sdin <= x"5A") ) and encrypt_decrypt_signal='1' ) else
             -- case of lowercase (add make it uppercase):
             ( ( ( sdin + skey - x"20" ) MOD 26 ) + x"61" ) when ( ( ( sdin >= x"61" ) and ( sdin <= x"7A") ) and encrypt_decrypt_signal='1' ) else

             -- Decrypting
             -- case of uppercase:
             ( ( ( 26 + sdin - skey ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"41" ) and ( sdin <= x"5A" ) ) ) else
             -- case of lowercase (add make it uppercase):
             ( ( ( 26 + sdin - skey - x"20" ) MOD 26 ) + x"61" ) when ( ( ( sdin >= x"61" ) and ( sdin <= x"7A" ) ) ) else
             sdin;

    data_out <= std_logic_vector(cipher);

end Behavioral;
