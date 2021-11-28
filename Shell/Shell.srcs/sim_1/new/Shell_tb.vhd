
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity Shell_tb is
--  Port ( );
end Shell_tb;

architecture Behavioral of Shell_tb is

	signal clk_period : time := 10 ns;
	signal clk : STD_LOGIC;
	signal rst : STD_LOGIC;
	signal RsRx : STD_LOGIC;
	signal RsTx : STD_LOGIC;
	signal seg : STD_LOGIC_VECTOR (7 downto 0);
	signal an : STD_LOGIC_VECTOR (3 downto 0);

	Component Shell is
		Port ( clk : in STD_LOGIC;
			   rst : in STD_LOGIC;
			   RsRx : in STD_LOGIC;
			   RsTx : out STD_LOGIC;
			   seg : out STD_LOGIC_VECTOR (7 downto 0);
			   an : out STD_LOGIC_VECTOR (3 downto 0));
	end Component;

	procedure writeUart
	( 
		constant c: in std_logic_vector(7 downto 0); 
		signal rx : out std_logic; 
		constant bitrate : in integer := 19200 
	) 
	is
		constant wait_time : time := integer(real(real(1)/real(bitrate))*1000000) *1 us;
		-- constant c : unsigned(7 downto 0) := to_unsigned(char, 8);
	begin
		rx <= '0';
		wait for wait_time;

		for i in 0 to c'length-1 loop
			rx <= c(i);
			wait for wait_time;
		end loop;
		rx <= '1';
		wait for wait_time*20;
	end procedure writeUart;



	constant BITRATE : integer := 19200;
    
    constant input : string := "Attack at dawn";


begin
	UUT : Shell
	port map
	(
		clk => clk,
		rst => rst,
		RsRx => RsRx,
		RsTx => RsTx
	);


	process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	process
	begin
		rst <= '1';
		RsRx <= '1';
		wait for clk_period*4;
		rst <= '0';
		wait for clk_period*4;
		-- wait for 375 ms;
		writeUart( x"7F", RsRx, BITRATE);
		writeUart( x"7F", RsRx, BITRATE);
		writeUart( x"7F", RsRx, BITRATE);

		writeUart( x"2d", RsRx, BITRATE);
		writeUart( x"68", RsRx, BITRATE);
		writeUart( x"0d", RsRx, BITRATE);


        for i in input'range loop 
            writeUart(std_logic_vector(to_unsigned(character'pos(input(i)), 8)), RsRx, BITRATE);
		end loop;
		writeUart( x"7F", RsRx, BITRATE);
		writeUart( x"7F", RsRx, BITRATE);
		writeUart( x"7F", RsRx, BITRATE);
		writeUart( x"62", RsRx, BITRATE);
		writeUart( x"0d", RsRx, BITRATE);
		wait;
	end process;



end Behavioral;
