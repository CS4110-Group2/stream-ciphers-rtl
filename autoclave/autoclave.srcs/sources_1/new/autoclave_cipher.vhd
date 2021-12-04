library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity autoclave_cipher is
    Port(start                  : in  STD_LOGIC; 
         data_in                : in  STD_LOGIC_VECTOR (7 downto 0);
         key                    : in  STD_LOGIC_VECTOR (7 downto 0);
         data_out               : out STD_LOGIC_VECTOR (7 downto 0);
         encrypt_decrypt_signal : in  STD_LOGIC);
end autoclave_cipher;

architecture Behavioral of autoclave_cipher is
    --signal sdin:  unsigned (7 downto 0);
    --signal skey:  unsigned (7 downto 0);
    signal cipher: unsigned (7 downto 0);

begin
    process(start, data_in, key, encrypt_decrypt_signal)
    begin
    if (start = '1') then
        if data_in = x"20" then
            cipher <= x"20";
        elsif (data_in <= x"5a" and data_in >= x"41") then
            if encrypt_decrypt_signal = '1' then
                cipher <= ((unsigned(data_in) + unsigned(key)) mod 26) + x"41";
            else
                -- Add +26 in case the result would underflow.
                cipher <= ((26 + unsigned(data_in) - unsigned(key)) mod 26) + x"41";
            end if;
        elsif (data_in <= x"7a" and data_in >= x"61") then
            if encrypt_decrypt_signal = '1' then
                -- Add -32 to transform lower letter to upper. (a --> A)
                cipher <= ((unsigned(data_in) + unsigned(key) - 32) mod 26) + x"61";
            else
                cipher <= ((26 + unsigned(data_in) - unsigned(key) - 32) mod 26) + x"61";
            end if;
        end if;
    end if;
    end process;
    data_out <= std_logic_vector(cipher);


    --sdin <= unsigned(ascii_r);
    --skey <= unsigned(key);

    --sdout <= sdout when start /= '1' else
    --         -- case of space:
    --         x"20" when ( sdin=x"20" ) else
    --         -- Encrypting
    --         -- case of uppercase:
    --         ( ( ( ( sdin - x"41" ) + ( skey - x"41" ) ) MOD 26 ) + x"41") when ( ( ( sdin >= x"41" ) and ( sdin <= x"5A") ) and encrypt='1' ) else
    --         -- case of lowercase (add make it uppercase):
    --         ( ( ( ( sdin - x"61" ) + ( skey - x"41" ) ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"61" ) and ( sdin <= x"7A") ) and encrypt='1' ) else

    --         -- Decrypting
    --         -- case of uppercase:
    --         ( ( ( 26 + ( sdin - x"41" ) - ( skey - x"41" ) ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"41" ) and ( sdin <= x"5A" ) ) ) else
    --         -- case of lowercase (add make it uppercase):
    --         ( ( ( 26 +( sdin - x"61" ) - ( skey - x"41" ) ) MOD 26 ) + x"41" ) when ( ( ( sdin >= x"61" ) and ( sdin <= x"7A" ) ) ) else
    --         sdin;

    --cphr_out <= std_logic_vector(sdout);

end Behavioral;
