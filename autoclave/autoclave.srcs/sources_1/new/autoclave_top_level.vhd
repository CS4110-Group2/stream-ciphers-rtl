library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity autoclave_top_level is
    generic(
        -- Default setting:
        RAM_ADDR_WIDTH : INTEGER := 10;  -- # maximum size of the RAM: 2^10 (1024)
        RAM_DATA_WIDTH : INTEGER := 8    -- # 8-bit data words
    );
    port(
        clk                    : in  STD_LOGIC;
        rst                    : in  STD_LOGIC;
        clear                  : in  STD_LOGIC;
        start                  : in  STD_LOGIC;
        data_in                : in  STD_LOGIC_VECTOR (7 downto 0);
        data_out               : out STD_LOGIC_VECTOR (7 downto 0);
        encrypt_decrypt_signal : in  STD_LOGIC
    );
end autoclave_top_level;

architecture Behavioral of autoclave_top_level is
    signal ascii_k : std_logic_vector (7 downto 0);
    signal key     : std_logic_vector (7 downto 0);
    signal cipher  : std_logic_vector (7 downto 0);

begin
    ascii_k <= data_in when encrypt_decrypt_signal = '1' else cipher;

    keystream_ram_unit: entity work.autoclave_keystream_one_port_ram(Behavioral)
    generic map(ADDR_WIDTH => RAM_ADDR_WIDTH, DATA_WIDTH => RAM_DATA_WIDTH )
    port map(
        clk      => clk,
        rst      => rst,
        start    => start,
        clear    => clear,
        data_in  => ascii_k,
        data_out => key
    );

    cipher_unit: entity work.autoclave_cipher(Behavioral)
    port map(
        start                  => start,
        data_in                => data_in,
        key                    => key,
        encrypt_decrypt_signal => encrypt_decrypt_signal,
        data_out               => cipher
    );
    
    data_out <= cipher;

end Behavioral;
