library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ram is
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           address : in STD_LOGIC_VECTOR (7 downto 0);
           clk : in STD_LOGIC;
           write : in STD_LOGIC;
           rst : in STD_LOGIC);
end ram;

architecture Behavioral of ram is

	type mem is array (0 to 255) of std_logic_vector (7 downto 0);

	function init_ram return mem is
		variable ram : mem;
	begin
		for i in 0 to 255 loop
			ram(i) := std_logic_vector(to_unsigned(i, ram(i)'length));
		end loop;
		return ram;
	end function;

	signal ram : mem := init_ram;

begin
	process (clk, rst, write)
	begin
		if (rst = '1') then
			ram <= init_ram;
		elsif (rising_edge(clk)) then
			if (write = '1') then
				ram(to_integer(unsigned(address))) <= data_in;
			end if;
			--data_out <= ram(to_integer(unsigned(address)));
		end if;
	end process;

	data_out <= ram(to_integer(unsigned(address)));

end Behavioral;
