

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlPath is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           rx_done_tick : in STD_LOGIC;
           wr_uart : out STD_LOGIC;
           tx_full : in STD_LOGIC;
           tx_empty : in STD_LOGIC;
           ram_write : out STD_LOGIC;
           ram_clr : out STD_LOGIC;
           ram_data_out : in STD_LOGIC_VECTOR(7 downto 0);
           addr_cnt_clear : out STD_LOGIC;
           addr_cnt_en : out STD_LOGIC;
           addr_cnt_up_down : out STD_LOGIC;
           addr_cnt_zero : in STD_LOGIC; 
           opcode_reg_load : out STD_LOGIC;
           opcode_reg_clear : out STD_LOGIC;
           output_reg_load : out STD_LOGIC;
           output_reg_clear : out STD_LOGIC;
           output_reg_mux : out STD_LOGIC_VECTOR(1 downto 0);
           ascii_in : in STD_LOGIC_VECTOR (7 downto 0);
           custom_out : out STD_LOGIC_VECTOR(7 downto 0)); 
end ControlPath;

architecture Behavioral of ControlPath is

    type FSM is (Init, HandlePrompt, WaitRx, Print, HandleEnter, HandleBackspace, STOP);
    signal state_reg, state_next : FSM := Init;

    -- type StringType is array(0 to 5) of std_logic_vector(7 downto 0);
    -- shared variable word : StringType := (others => (others => '0'));
    signal i_cnt, i_cnt_next : integer := 0;

    constant SPACE : std_logic_vector(7 downto 0) := x"20";
    constant ENTER : std_logic_vector(7 downto 0) := x"0d";
    constant DELETE : std_logic_vector(7 downto 0) := x"7F";
    constant PROMPT : std_logic_vector(7 downto 0) := x"3e";
    constant LINEFEED : std_logic_vector(7 downto 0) := x"0A";
    constant BACKSPACE : std_logic_vector(7 downto 0) := x"08";

    constant ASCII_START : std_logic_vector(7 downto 0) := x"21";
    constant ASCII_STOP : std_logic_vector(7 downto 0) := x"7E";

    function ValidAscii( val : std_logic_vector(7 downto 0)) return boolean is
    begin
        if(val = ENTER) or 
        (val = SPACE) or 
        (val = DELETE) or
        (val >= ASCII_START and val <= ASCII_STOP)
        then
            return true;
        else
            return false;
        end if;
    end function;

begin
    process(clk, rst)
    begin
        if rst = '1' then
            state_reg <= Init;
            i_cnt <= 0;
        elsif rising_edge(clk) then
            state_reg <= state_next;
            i_cnt <= i_cnt_next;
        end if;
    end process;

    process(state_reg, rx_done_tick, tx_empty, tx_full, ascii_in)
    begin
        state_next <= state_reg;
        wr_uart <= '0';
        ram_write <= '0';
        ram_clr <= '0';
        addr_cnt_clear <= '0';
        addr_cnt_en <= '0';
        addr_cnt_up_down <= '0';
        opcode_reg_load <= '0';
        opcode_reg_clear <= '0';
        output_reg_load <= '0';
        output_reg_clear <= '0';
        output_reg_mux <= "00";
        i_cnt_next <= i_cnt;
        custom_out <= (others => '0');
        case state_reg is
            when Init =>
                output_reg_mux <= "10";
                wr_uart <= '1';
                custom_out <= LINEFEED;
                i_cnt_next <= 0;
                
                state_next <= HandlePrompt;
            when HandlePrompt =>
                if tx_full = '0' then
                    output_reg_mux <= "10";
                    wr_uart <= '1';
                    i_cnt_next <= i_cnt + 1;
                    if i_cnt = 0 then
                        custom_out <= ENTER; 
                    elsif i_cnt = 1 then
                        custom_out <= PROMPT; 
                        state_next <= WaitRx;
                    end if;
                end if;
            when WaitRx =>
                if rx_done_tick = '1' then
                    if ValidAscii(ascii_in) then
                        if ascii_in = ENTER then
                            wr_uart <= '1';
                            ram_write <= '1';
                            addr_cnt_en <= '1';
                            i_cnt_next <= 0;
                            output_reg_mux <= "10";
                            custom_out <= LINEFEED;
                            wr_uart <= '1';
                            state_next <= HandleEnter;
                        elsif ascii_in = DELETE then
                            if addr_cnt_zero = '0' then
                                wr_uart <= '1';
                                ram_write <= '1';
                                addr_cnt_en <= '1';
                                i_cnt_next <= 0;
                                output_reg_mux <= "10";
                                custom_out <= BACKSPACE;
                                ram_clr <= '1';
                                addr_cnt_up_down <= '1';
                                wr_uart <= '1';
                                state_next <= HandleBackspace;
                            end if;
                        else
                            wr_uart <= '1';
                            ram_write <= '1';
                            addr_cnt_en <= '1';
                        end if;
                    end if;
                end if;
            

            when HandleBackspace =>
                if tx_full = '0' then
                    output_reg_mux <= "10";
                    wr_uart <= '1';
                    i_cnt_next <= i_cnt + 1;
                    if i_cnt = 0 then
                        custom_out <= SPACE; 
                    elsif i_cnt = 1 then
                        custom_out <= BACKSPACE; 
                        state_next <= WaitRx;
                    end if;
                end if;
            when HandleEnter =>
                if tx_full = '0' then
                    output_reg_mux <= "10";
                    custom_out <= ENTER; 
                    wr_uart <= '1';
                    state_next <= Print;
                    addr_cnt_clear <= '1';
                end if;
            when Print =>
                if tx_full = '0' then
                    if ram_data_out = ENTER then
                        wr_uart <= '1';
                        output_reg_mux <= "10";
                        custom_out <= LINEFEED; 
                        addr_cnt_clear <= '1';
                        i_cnt_next <= 0;
                        state_next <= HandlePrompt;
                    else
                        wr_uart <= '1';
                        output_reg_mux <= "01";
                        addr_cnt_en <= '1';
                    end if;
                end if;
            when STOP =>
        end case;
    end process;
end Behavioral;
