library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;

entity rc4_tb is
end rc4_tb;

architecture Behavioral of rc4_tb is

signal clk_tb, rst_tb, clear_tb : STD_LOGIC;
signal start_tb, ready_tb, done_tb : STD_LOGIC;
signal data_in_tb, data_out_tb : STD_LOGIC_VECTOR (7 downto 0);

constant clk_period : time := 10 ns;

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
	   wait until ready_tb = '1';
	   data_in_tb <= x"61"; --a
	   start_tb <= '1';
	   wait for clk_period;
	   start_tb <= '0';
	   wait until done_tb = '1' for 10*clk_period ;
	   
	   assert data_out_tb = x"15"
	       report "[Fail] Expected: 0x15"
	       severity failure;
	   
	   wait until ready_tb = '1' for 10*clk_period ;
	   data_in_tb <= x"62"; --b
	   start_tb <= '1';
	   wait for clk_period;
	   start_tb <= '0';
	   
	   wait until done_tb = '1' for 10*clk_period ;
	   
	   assert data_out_tb = x"8d"
	       report "[Fail] Expected 0x8D"
	       severity failure;
	       
	   clear_tb <= '1';
	   wait for clk_period;
	   clear_tb <= '0';
	   
	   wait until ready_tb = '1';
	   data_in_tb <= x"61"; --a
	   start_tb <= '1';
	   wait for clk_period;
	   start_tb <= '0';
	   wait until done_tb = '1' for 10*clk_period ;
	   
	   assert data_out_tb = x"15"
	       report "[Fail] Expected: 0x15"
	       severity failure;
	   
	   report "Test: OK";
	   finish;
	end process;

end Behavioral;
