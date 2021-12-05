library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rc4_control_path is
    Port ( clk                : in  STD_LOGIC;
           rst                : in  STD_LOGIC;
           clear              : in  STD_LOGIC;
           start              : in  STD_LOGIC;
           ready              : out STD_LOGIC;
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
           ram_data_in_select : out STD_LOGIC;
           reg_j_select       : out STD_LOGIC;
           load_reg_out       : out STD_LOGIC);
end rc4_control_path;

architecture Behavioral of rc4_control_path is
    type FSM is (s0, s2, s3, s4, s6, s7, s8, Init_Ram, Reset_Cipher, Wait_For_Start, KSA);
    signal state_reg, state_next : FSM := Init_Ram;
    signal ready_reg, ready_next : STD_LOGIC := '0';
    signal done_reg, done_next   : STD_LOGIC := '0';


begin
    process (clk, rst)
    begin
        if (rst = '1') then
            state_reg <= Init_Ram;
            ready_reg <= '0';
            done_reg  <= '0';
        elsif (rising_edge(clk)) then
            if (clear = '1') then
                state_reg <= Reset_Cipher;
                ready_reg <= '0';
                done_reg  <= '0';
            else
                state_reg <= state_next;
                ready_reg <= ready_next;
                done_reg  <= done_next;
            end if;
        end if;
    end process;

    done  <= done_reg;
    ready <= ready_reg;

    process (state_reg, start, counter_i_max_tick, ready_reg, done_reg)
    begin
        state_next         <= state_reg;
        done_next          <= '0';
        ready_next         <= '0';
        load_reg_j         <= '0';
        load_reg_tmp       <= '0';
        ram_write          <= '0';
        counter_i_inc      <= '0';
        counter_i_clear    <= '0';
        counter_i_load     <= '0';
        clear_reg_j        <= '0';
        ram_address_select <= "00";
        ram_data_in_select <= '0';
        reg_j_select       <= '0';
        reg_tmp_select     <= '0';
        load_reg_out <= '0';

        case state_reg is
            when Reset_Cipher =>
                counter_i_clear <= '1';
                clear_reg_j     <= '1';
                state_next      <= Init_Ram;
            when Init_Ram =>
                if (counter_i_max_tick = '1') then
                    state_next <= s0;
                end if;
                ram_address_select <= "00";
                ram_data_in_select <= '1';
                ram_write          <= '1';
                counter_i_inc      <= '1';
            when s0 =>
                ram_data_in_select <= '0';
                reg_j_select       <= '1';
                load_reg_j         <= '1';
                state_next         <= KSA;
            when KSA =>
                ram_address_select <= "01";
                ram_data_in_select <= '0';
                reg_j_select       <= '1';
                reg_tmp_select     <= '0';
                load_reg_tmp       <= '1';
                state_next         <= s2;
            when s2 =>
                ram_address_select <= "00";
                ram_data_in_select <= '0';
                reg_tmp_select     <= '0';
                reg_j_select       <= '1';
                load_reg_tmp       <= '1';
                ram_write          <= '1';
                state_next         <= s3;
            when s3 =>
                ram_address_select <= "01";
                ram_write          <= '1';
                if (counter_i_max_tick = '1') then
                    counter_i_load <= '1';
                    reg_j_select   <= '0';
                    clear_reg_j    <= '1';
                    state_next     <= Wait_For_Start;
                else
                    counter_i_inc <= '1';
                    state_next    <= s4;
                end if;
            when s4 =>
                ram_address_select <= "00";
                reg_j_select       <= '1';
                load_reg_j         <= '1';
                state_next         <= KSA;
            when Wait_For_Start =>
                if (start = '1') then
                    ram_address_select <= "00";
                    reg_j_select       <= '0';
                    reg_tmp_select     <= '0';
                    load_reg_j         <= '1';
                    load_reg_tmp       <= '1';
                    state_next         <= s6;
                else
                    ready_next <= '1';
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
                counter_i_inc      <= '1';
                ready_next         <= '1';
                done_next          <= '1';
                load_reg_out <= '1';
                state_next         <= Wait_For_Start;
        end case;
    end process;

end Behavioral;
