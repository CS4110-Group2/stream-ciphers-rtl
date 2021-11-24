library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           inc : in STD_LOGIC;
		   load : in STD_LOGIC;
           clear : in STD_LOGIC;
		   max_tick : out STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           q : out STD_LOGIC_VECTOR (7 downto 0));
end counter;

architecture Behavioral of counter is
	signal r_reg, r_next : unsigned (7 downto 0) := (others => '0');

begin

	process (clk, rst)
	begin
		if (rst = '1') then
			r_reg <= (others => '0');
		elsif (rising_edge(clk)) then
			r_reg <= r_next;
		end if;
	end process;

	r_next <= (others => '0') when clear = '1' else
			  r_reg + 1 when inc = '1' else
			  unsigned(data_in) when load = '1' else
			  r_reg;

	q <= std_logic_vector(r_reg);

	max_tick <= '1' when r_reg = "11111111" else
				'0';

end Behavioral;
