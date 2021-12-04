-- (adapted from) Listing 11.1
-- Single-port RAM with synchronous read
-- Modified from XST 8.1i rams_07
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity autoclave_keystream_one_port_ram is
    generic(
        ADDR_WIDTH : INTEGER := 10; -- 1KB RAM
        DATA_WIDTH : INTEGER := 8
    );
    port(
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        clear    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
    );
end autoclave_keystream_one_port_ram;

architecture Behavioral of autoclave_keystream_one_port_ram is
    type ram_type is array (2**(ADDR_WIDTH - 5)-1 downto 0) 
    of std_logic_vector (DATA_WIDTH-1 downto 0);

    signal ram            : ram_type;
    signal data           : std_logic_vector (DATA_WIDTH-1 downto 0);
    signal address        : unsigned(ADDR_WIDTH - 1 downto 0);
    signal update_address : boolean;

begin
    process (clk, rst)
    begin
        if rst = '1' then
            ram( 00 ) <= x"53"; -- S
            ram( 01 ) <= x"45"; -- E
            ram( 02 ) <= x"43"; -- C
            ram( 03 ) <= x"52"; -- R
            ram( 04 ) <= x"45"; -- E
            ram( 05 ) <= x"54"; -- T

            address        <= (others=>'0');
            update_address <= false;
        elsif rising_edge(clk) then
            if clear = '1' then
                address        <= (others=>'0');
                update_address <= false;
            elsif start = '1' then
                -- Uppercase
                if ( ( data_in >= x"41" ) and ( data_in <= x"5A") ) then
                    ram(to_integer(unsigned(address) + 6)) <= data_in;
                    update_address                         <= true;
                -- If lowercase ( convert to uppercase )
                elsif ( ( data_in >= x"61" ) and ( data_in <= x"7A") ) then
                    ram(to_integer(unsigned(address) + 6)) <= std_logic_vector( unsigned(data_in) - x"20" );
                    update_address                         <= true;
                end if;
            elsif (start = '0' and update_address = true) then
                update_address <= false;
                address        <= address + 1;
            end if;
        end if;
    end process;

    data_out <= ram(to_integer(unsigned(address)));

end Behavioral;
