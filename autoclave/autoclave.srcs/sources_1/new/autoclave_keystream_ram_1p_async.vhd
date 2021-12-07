-- (adapted from) Listing 11.1
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity autoclave_keystream_one_port_ram is
    generic(
        ADDR_WIDTH : INTEGER := 6;
        DATA_WIDTH : INTEGER := 8
    );
    port(
        clk      : in  STD_LOGIC;
        addr     : in STD_LOGIC_VECTOR(ADDR_WIDTH -1 downto 0);
        load     : in  STD_LOGIC;
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
    );
end autoclave_keystream_one_port_ram;

architecture Behavioral of autoclave_keystream_one_port_ram is
    type ram_type is array (2**(ADDR_WIDTH)-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);

    function init_ram(key : string) return ram_type is 
        variable tmp : ram_type := (others => (others => '0'));
    begin 
        for i in key'range loop 
            tmp(i-1) := std_logic_vector(to_unsigned(character'pos(key(i)), DATA_WIDTH));
        end loop;
        return tmp;
    end init_ram;	 

    constant KEYWORD : string := "SECRET";
    signal ram            : ram_type := init_ram("SECRET");
    signal data           : std_logic_vector (DATA_WIDTH-1 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if load = '1' then
                -- Uppercase
                if ( data_in < x"61" ) then
                    ram(to_integer(unsigned(addr) + KEYWORD'length)) <= data_in;
                -- If lowercase ( convert to uppercase )
                else
                    ram(to_integer(unsigned(addr) + KEYWORD'length)) <= std_logic_vector( unsigned(data_in) - x"20" );
                end if;
            end if;
        end if;
    end process;

    data_out <= ram(to_integer(unsigned(addr)));

end Behavioral;
