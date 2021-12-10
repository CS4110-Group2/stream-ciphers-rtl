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
    type FSM is (Enter_KSA, KSA1, KSA2, KSA3, PRGA0, PRGA1, PRGA2, Init_Ram, Reset_Cipher, Wait_For_Start, KSA0);
    signal state_reg, state_next : FSM := Init_Ram;
    signal ready_reg, ready_next : STD_LOGIC := '0';
    signal done_reg, done_next   : STD_LOGIC := '0';
    
    constant COUNTER_I_OUT : STD_LOGIC_VECTOR (1 downto 0) := "00";
    constant REG_J_OUT     : STD_LOGIC_VECTOR (1 downto 0) := "01";
    constant REG_TMP_OUT   : STD_LOGIC_VECTOR (1 downto 0) := "10";

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
        ram_address_select <= COUNTER_I_OUT;
        ram_data_in_select <= '0';
        reg_j_select       <= '0';
        reg_tmp_select     <= '0';
        load_reg_out       <= '0';

        case state_reg is
            when Reset_Cipher =>
                counter_i_clear <= '1';
                clear_reg_j     <= '1';
                state_next      <= Init_Ram;
            when Init_Ram =>
                if (counter_i_max_tick = '1') then
                    state_next <= Enter_KSA;
                end if;
                ram_address_select <= COUNTER_I_OUT;
                ram_data_in_select <= '1';
                ram_write          <= '1';
                counter_i_inc      <= '1';
            when Enter_KSA =>
                ram_data_in_select <= '0';
                reg_j_select       <= '1';
                load_reg_j         <= '1';
                state_next         <= KSA0;
            when KSA0 =>
                ram_address_select <= REG_J_OUT;
                ram_data_in_select <= '0';
                reg_j_select       <= '1';
                reg_tmp_select     <= '0';
                load_reg_tmp       <= '1';
                state_next         <= KSA1;
            when KSA1 =>
                ram_address_select <= COUNTER_I_OUT;
                ram_data_in_select <= '0';
                reg_tmp_select     <= '0';
                reg_j_select       <= '1';
                load_reg_tmp       <= '1';
                ram_write          <= '1';
                state_next         <= KSA2;
            when KSA2 =>
                ram_address_select <= REG_J_OUT;
                ram_write          <= '1';
                if (counter_i_max_tick = '1') then
                    counter_i_load <= '1';
                    reg_j_select   <= '0';
                    clear_reg_j    <= '1';
                    ready_next     <= '1';
                    state_next     <= Wait_For_Start;
                else
                    counter_i_inc <= '1';
                    state_next    <= KSA3;
                end if;
            when KSA3 =>
                ram_address_select <= COUNTER_I_OUT;
                reg_j_select       <= '1';
                load_reg_j         <= '1';
                state_next         <= KSA0;
            when Wait_For_Start =>
                if (start = '1') then
                    ram_address_select <= COUNTER_I_OUT;
                    reg_j_select       <= '0';
                    reg_tmp_select     <= '0';
                    load_reg_j         <= '1';
                    load_reg_tmp       <= '1';
                    state_next         <= PRGA0;
                else
                    ready_next <= '1';
                end if;
            when PRGA0 =>
                ram_address_select <= REG_J_OUT;
                reg_tmp_select     <= '0';
                load_reg_tmp       <= '1';
                ram_write          <= '1';
                state_next         <= PRGA1;
            when PRGA1 =>
                ram_address_select <= COUNTER_I_OUT;
                ram_write          <= '1';
                reg_tmp_select     <= '1';
                load_reg_tmp       <= '1';
                state_next         <= PRGA2;
            when PRGA2 =>
                ram_address_select <= REG_TMP_OUT;
                counter_i_inc      <= '1';
                ready_next         <= '1';
                done_next          <= '1';
                load_reg_out       <= '1';
                state_next         <= Wait_For_Start;
        end case;
    end process;

end Behavioral;
