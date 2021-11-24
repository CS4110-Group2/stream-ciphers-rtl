library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom is
    Port ( address : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0));
end rom;

architecture Behavioral of rom is

	type mem is array (0 to 7) of STD_LOGIC_VECTOR (7 downto 0);

	constant rom_block : mem := 
	(
		x"5A", -- address 00
		x"41", -- address 01
		x"41", -- address 02
		x"41", -- address 03
		x"41", -- address 04
		x"41", -- address 05
		x"41", -- address 06
		x"41"  -- address 07
	);

begin

	-- Only interested in the last three bits of the address.
	data_out <= rom_block(to_integer(unsigned(address(2 downto 0))));

end Behavioral;
