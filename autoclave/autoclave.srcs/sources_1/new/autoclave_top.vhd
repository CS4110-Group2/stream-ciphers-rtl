library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity autoclave is
    generic(
        -- Default setting:
        RAM_ADDR_WIDTH : integer := 10;  -- # maximum size of the RAM: 2^10 (1024)
        RAM_DATA_WIDTH : integer := 8    -- # 8-bit data words
    );
    port(
        clk, reset: in std_logic;
        en, load, clr: in std_logic;
        ascii_in: in std_logic_vector(7 downto 0);
        ascii_out: out std_logic_vector(7 downto 0);
        switchEncrypt: in std_logic;
        ledEncrypt: out std_logic
    );
end autoclave;

architecture str_arch of autoclave is
    signal ascii_k: std_logic_vector(7 downto 0);
    signal key: std_logic_vector(7 downto 0);
    signal cphr_out: std_logic_vector(7 downto 0);

begin
    ledEncrypt <= switchEncrypt;
    ascii_out <= cphr_out;
    ascii_k <= ascii_in when switchEncrypt='1' else cphr_out;

    keystream_ram_unit: entity work.keystream_one_port_ram(arch)
        generic map(ADDR_WIDTH=>RAM_ADDR_WIDTH, DATA_WIDTH=>RAM_DATA_WIDTH )
        port map(
            clk=>clk, reset=>reset,
            en=>en, load=>load, clr=>clr,
            din=>ascii_k, dout=>key
        );

    cipher_unit: entity work.cipher(arch)
        port map(
            en=>en, load=>load,
            ascii_r=>ascii_in, key=>key, encrypt=>switchEncrypt,
            cphr_out=>cphr_out
        );

end str_arch;