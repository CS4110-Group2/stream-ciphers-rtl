library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use std.env.finish;
use IEEE.std_logic_textio.all;

entity rc4_tb is
end rc4_tb;

architecture Behavioral of rc4_tb is

signal clk_tb, rst_tb, clear_tb : STD_LOGIC;
signal start_tb, ready_tb, done_tb : STD_LOGIC;
signal data_in_tb, data_out_tb : STD_LOGIC_VECTOR (7 downto 0);

constant clk_period : time := 10 ns;
constant bitrate    : integer := 19200;


type ascii_array is array (0 to 13) of std_logic_vector (7 downto 0);
constant plaintext  : ascii_array := (x"41", x"54", x"54", x"41", x"43", x"4b", x"20", x"41", x"54", x"20", x"44", x"41", x"57", x"4e");
constant rc4_cipher : ascii_array := (x"35", x"bb", x"56", x"f5", x"19", x"c9", x"17", x"67", x"7b", x"09", x"e6", x"bc", x"6f", x"4c");

signal tmp : std_logic_vector (7 downto 0) := (others => '0');

procedure write_byte
(
    constant byte : in std_logic_vector (7 downto 0);
    signal data_in_tb : out std_logic_vector (7 downto 0);
    signal start_tb : out std_logic
)
is
begin
    wait until ready_tb = '1';
    data_in_tb <= byte;
    start_tb <= '1';
    wait for clk_period;
    start_tb <= '0';
    wait until done_tb = '1' for 10*clk_period;

end procedure write_byte;

begin

	UUT: entity work.rc4_top_level(Behavioral)
	port map (clk => clk_tb, rst => rst_tb, start => start_tb, data_in => data_in_tb,
	   data_out => data_out_tb, ready => ready_tb, done => done_tb, clear => clear_tb);

	process
	begin
		clk_tb <= '0';
		wait for (clk_period / 2);
		clk_tb <= '1';
		wait for (clk_period / 2);
	end process;

	process
	begin
	   clear_tb <= '0';
	     
	   for i in 0 to plaintext'length - 1 loop
	       write_byte(plaintext(i), data_in_tb, start_tb);
	       assert data_out_tb = rc4_cipher(i)
	           severity failure;
	   end loop;
	   
	   clear_tb <= '1';
	   wait for clk_period;
	   clear_tb <= '0';
	   
	   for i in 0 to plaintext'length - 1 loop
	       write_byte(plaintext(i), data_in_tb, start_tb);
	       assert data_out_tb = rc4_cipher(i)
	           severity failure;
	   end loop;
	   
	   report "Test: OK";
	   finish;
	end process;

end Behavioral;
