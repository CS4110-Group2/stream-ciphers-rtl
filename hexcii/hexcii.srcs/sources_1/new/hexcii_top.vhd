
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hexcii is
    Port ( byte_in : in unsigned (7 downto 0);
         --           en : in std_logic; If needed, add to passthrough flags further down
         MSBits : in std_logic; -- (7 downto 4) when '1', (3 downto 0) when '0'
         encode : in std_logic; -- else decode
         rc4 : in std_logic;
         byte_out : out unsigned (7 downto 0));
end hexcii;

architecture Behavioral of hexcii is
    signal passthrough_enc: std_logic;
    signal passthrough_dec: std_logic;

    signal enc_out: unsigned(7 downto 0);
    signal dec_out: unsigned(7 downto 0);
begin
    passthrough_enc <= '1' when ((rc4 = '1') and (encode = '0')) else '0';
    passthrough_dec <= '1' when ((rc4 = '1') and (encode = '1')) else '0';
    byte_out <= enc_out when encode = '1' else
                dec_out when encode = '0';
                
    ascii_to_hex_unit: entity work.ascii_to_hex(Behavioral)
        port map(
            ascii=>byte_in,
            passthrough=>passthrough_enc,
            MSBits=>MSBits,
            hex=>enc_out
        );
        
    hex_to_ascii_unit: entity work.hex_to_ascii(Behavioral)
        port map(
            hex=>byte_in,
            passthrough=>passthrough_dec,
            MSBits=>MSBits,
            ascii=>dec_out            
        );
end Behavioral;
