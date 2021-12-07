library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity autoclave_top_level is
    generic(
        RAM_ADDR_WIDTH : INTEGER := 6;  
        RAM_DATA_WIDTH : INTEGER := 8 
    );
    port(
        clk                    : in  STD_LOGIC;
        rst                    : in  STD_LOGIC;
        clear                  : in  STD_LOGIC;
        start                  : in  STD_LOGIC;
        data_in                : in  STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
        data_out               : out STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
        encrypt_decrypt_signal : in  STD_LOGIC
    );
end autoclave_top_level;

architecture Behavioral of autoclave_top_level is
    signal ascii_k : STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
    signal key     : STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);
    signal cipher  : STD_LOGIC_VECTOR (RAM_DATA_WIDTH-1 downto 0);

    signal update_key, load_ram, inc_address, clear_address : STD_LOGIC;
    signal ram_address : STD_LOGIC_VECTOR (RAM_ADDR_WIDTH-1 downto 0);
    signal ram_counter_enable : STD_LOGIC;

begin
    ascii_k <= data_in when encrypt_decrypt_signal = '1' else cipher;


    update_key <= '1' when ( ( ( data_in >= x"41" ) and ( data_in <= x"5A") ) or ( ( data_in >= x"61" ) and ( data_in <= x"7A") ) ) and start = '1' else
                  '0';

    ram_counter_enable <= update_key or clear; 
                
    keystream_ram_unit: entity work.autoclave_keystream_one_port_ram(Behavioral)
    generic map(ADDR_WIDTH => RAM_ADDR_WIDTH, DATA_WIDTH => RAM_DATA_WIDTH )
    port map(
        clk      => clk,
        addr     => ram_address,
        load     => update_key,
        data_in  => ascii_k,
        data_out => key
    );

    cipher_unit: entity work.autoclave_cipher(Behavioral)
    port map(
        data_in                => data_in,
        key                    => key,
        encrypt_decrypt_signal => encrypt_decrypt_signal,
        data_out               => cipher
    );

    addr_counter : entity work.ModMCounterEn(Behavioral)
    generic map
    ( 
        N => RAM_ADDR_WIDTH, 
        M => (2**RAM_ADDR_WIDTH-1)
    )
    port map
    (
        en       => ram_counter_enable,
        rst      => rst,
        clk      => clk,
        clr      => clear,
        data_in  => (others => '0'),
        load_en  => '0',
        q        => ram_address,
        max_tick => open
    );
    
    data_out <= cipher;

end Behavioral;
