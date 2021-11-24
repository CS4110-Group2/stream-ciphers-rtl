library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rc4_tb is
--  Port ( );
end rc4_tb;

architecture Behavioral of rc4_tb is

component top_level is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           rx : in STD_LOGIC;
           tx : out STD_LOGIC);
end component;

signal clk_tb, rst_tb : STD_LOGIC;
signal rx_tb, tx_tb : STD_LOGIC;

constant clk_period : time := 10 ns;
constant bit_period : time := 52083ns; -- time for 1 bit.. 1bit/19200bps = 52.08 us
constant ascii_a: std_logic_vector(7 downto 0) := x"48"; -- receive a
--constant ascii_a: std_logic_vector(7 downto 0) := x"62"; -- receive b

begin

	UUT: top_level
	port map (clk => clk_tb, rst => rst_tb, rx => rx_tb, tx => tx_tb);

	process
	begin
		clk_tb <= '0';
		wait for (clk_period / 2);
		clk_tb <= '1';
		wait for (clk_period / 2);
	end process;

	process
	begin
		rx_tb <= '1';
		--wait for clk_period*1000;
		wait for 20us;
		rx_tb <= '0';
		wait for bit_period;
		for i in 0 to 7 loop
			rx_tb <= ascii_a(i);
			wait for bit_period;
		end loop;
		rx_tb <= '1';

		wait for 3000us;

		rx_tb <= '0';
		wait for bit_period;
		for i in 0 to 7 loop
			rx_tb <= ascii_a(i);
			wait for bit_period;
		end loop;
		rx_tb <= '1';
		wait;
	end process;

end Behavioral;
