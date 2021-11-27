library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_path is
    Port ( clk                : in  STD_LOGIC;
           rst                : in  STD_LOGIC;
           start              : in  STD_LOGIC;
           ready              : out  STD_LOGIC;
           done               : out STD_LOGIC;
           counter_i_max_tick : in  STD_LOGIC;
           counter_i_inc      : out STD_LOGIC;
           counter_i_clear    : out STD_LOGIC;
           counter_i_load     : out STD_LOGIC;
           clear_reg_j        : out STD_LOGIC;
           load_reg_j         : out STD_LOGIC;
           load_reg_tmp       : out STD_LOGIC;
           ram_write          : out STD_LOGIC;
           ram_address_select : out STD_LOGIC_VECTOR (1 downto 0);
           reg_tmp_select     : out STD_LOGIC;
           reg_j_select       : out STD_LOGIC);
end control_path;

architecture Behavioral of control_path is
	type FSM is (s0, s1, s2, s3, s4, s5, s6, s7, s8);
	signal state_reg, state_next : FSM;
	signal done_reg : STD_LOGIC;

begin

	process (clk, rst)
	begin
		if (rst = '1') then
			state_reg <= s0;
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
		elsif (falling_edge(clk)) then
			done <= done_reg;
		end if;
	end process;

	process (state_reg, start, counter_i_max_tick)
	begin
		state_next       <= state_reg;
		load_reg_j       <= '0';
		load_reg_tmp     <= '0';
		ram_write        <= '0';
		counter_i_inc    <= '0';
		counter_i_clear  <= '0';
	    counter_i_load   <= '0';
		done_reg         <= '0';
		ready            <= '0';
		clear_reg_j      <= '0';

		case state_reg is
			when s0 =>
				counter_i_clear <= '1';
				reg_j_select    <= '1';
				load_reg_j      <= '1';
				state_next      <= s1;
			when s1 =>
				if (counter_i_max_tick = '1') then
					counter_i_load <= '1';
					reg_j_select   <= '0';
					clear_reg_j    <= '1';
					state_next     <= s5;
				else
					ram_address_select <= "01";
					reg_tmp_select     <= '0';
					load_reg_tmp       <= '1';
					state_next         <= s2;
				end if;
			when s2 =>
				ram_address_select <= "00";
				reg_tmp_select     <= '0';
				load_reg_tmp       <= '1';
				ram_write          <= '1';
				state_next         <= s3;
			when s3 =>
				ram_address_select <= "01";
				ram_write          <= '1';
				counter_i_inc      <= '1';
				state_next         <= s4;
			when s4 =>
				ram_address_select <= "00";
				load_reg_j         <= '1';
				state_next         <= s1;
			when s5 =>
				if (start = '1') then
					ram_address_select <= "00";
					reg_j_select       <= '0';
					reg_tmp_select     <= '0';
					load_reg_j         <= '1';
					load_reg_tmp       <= '1';
					state_next         <= s6;
				else
					ready <= '1';
				end if;
			when s6 =>
				ram_address_select <= "01";
				reg_tmp_select     <= '0';
				load_reg_tmp       <= '1';
				ram_write          <= '1';
				state_next         <= s7;
			when s7 =>
				ram_address_select <= "00";
				ram_write          <= '1';
				reg_tmp_select     <= '1';
				load_reg_tmp       <= '1';
				state_next         <= s8;
			when s8 =>
				ram_address_select <= "10";
				done_reg           <= '1';
				counter_i_inc      <= '1';
				ready              <= '1';
				state_next         <= s5;
		end case;
	end process;

end Behavioral;
