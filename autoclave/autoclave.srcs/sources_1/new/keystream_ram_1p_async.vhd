-- (adapted from) Listing 11.1
-- Single-port RAM with synchronous read
-- Modified from XST 8.1i rams_07
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keystream_one_port_ram is
    generic(
        ADDR_WIDTH: integer:=10; -- 1KB RAM
        DATA_WIDTH: integer:=8
    );
    port(
        clk, reset: in std_logic;
        en, load, clr: in std_logic;
        din: in std_logic_vector(DATA_WIDTH-1 downto 0);
        dout: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end keystream_one_port_ram;

architecture arch of keystream_one_port_ram is
    type ram_type is array (2**(ADDR_WIDTH - 5)-1 downto 0)
 of std_logic_vector (DATA_WIDTH-1 downto 0);
    signal ram: ram_type;
    signal data: std_logic_vector (DATA_WIDTH-1 downto 0);
    signal addr: unsigned(ADDR_WIDTH - 1 downto 0);
    signal update_addr: boolean;

begin
    process (clk,reset)
    begin
        if reset='1' then
            ram( 00 ) <= x"53"; -- S
            ram( 01 ) <= x"45"; -- E
            ram( 02 ) <= x"43"; -- C
            ram( 03 ) <= x"52"; -- R
            ram( 04 ) <= x"45"; -- E
            ram( 05 ) <= x"54"; -- T

            addr <= (others=>'0');
            update_addr <= false;
        elsif rising_edge(clk) then
            if(clr = '1') then
                addr <= (others=>'0');
                update_addr <= false;
            elsif(en = '1') then
                if(load = '1') then
                    -- Uppercase
                    if ( ( din >= x"41" ) and ( din <= x"5A") ) then
                        ram(to_integer(unsigned(addr) + 6)) <= din;
                        update_addr <= true;
                    -- If lowercase ( convert to uppercase )
                    elsif ( ( din >= x"61" ) and ( din <= x"7A") ) then
                        ram(to_integer(unsigned(addr) + 6)) <= std_logic_vector( unsigned(din) - x"20" );
                        update_addr <= true;
                    end if;
                elsif(load = '0' and update_addr = true) then
                    update_addr <= false;
                    addr <= addr + 1;
                end if;
            end if;
        end if;
    end process;

    dout <= ram(to_integer(unsigned(addr)));
end arch;