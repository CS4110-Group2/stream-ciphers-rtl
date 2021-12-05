library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rc4_rom is
    Generic( ADDR_WIDTH : integer := 8;
             DATA_WIDTH : integer := 8;
             RC4_KEY    : string := "ZAAAAAAA");
    Port ( address  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
           data_out : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0));
end rc4_rom;


architecture Behavioral of rc4_rom is

    type mem is array (0 to 2**ADDR_WIDTH-1) of STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);

    function init_rom(key : string) return mem is 
        variable tmp : mem := (others => (others => '0'));
    begin 
        for i in key'range loop 
            tmp(i-1) := std_logic_vector(to_unsigned(character'pos(key(i)), DATA_WIDTH));
        end loop;
        return tmp;
    end init_rom;	 

    constant rom_block : mem := init_rom(RC4_KEY);

begin

    data_out <= rom_block(to_integer(unsigned(address) mod RC4_KEY'length));

end Behavioral;
