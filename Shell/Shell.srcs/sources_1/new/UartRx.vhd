

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UartRx is
    Generic( D_BIT : integer := 8;
             SB_TICK : integer := 16);
    Port ( rx           : in  STD_LOGIC;
           clk          : in  STD_LOGIC;
           rst          : in  STD_LOGIC;
           s_tick       : in  STD_LOGIC;
           dout         : out STD_LOGIC_VECTOR (D_BIT - 1 downto 0);
           rx_done_tick : out STD_LOGIC);
end UartRx;

architecture Behavioral of UartRx is

    type State_Type is (Idle, Start, Data, Stop);
    signal state_reg, state_next : State_Type := Idle;

    signal s_reg, s_next : unsigned(SB_TICK-1 downto 0) := (others => '0');
    signal n_reg, n_next : unsigned(D_BIT-1 downto 0) := (others => '0');
    signal b_reg, b_next : std_logic_vector(D_BIT - 1 downto 0);

begin

    process(clk, rst)
    begin
        if rst = '1' then
            state_reg <= Idle;
            s_reg     <= (others => '0');
            n_reg     <= (others => '0');
            b_reg     <= (others => '0');
        elsif rising_edge(clk) then
            if s_tick = '1' then
                state_reg <= state_next;
                s_reg     <= s_next;
                n_reg     <= n_next;
                b_reg     <= b_next;
            end if;
        end if;
    end process;

    process(rx, s_tick, state_reg, s_reg, n_reg, b_reg)
    begin
        state_next   <= state_reg;
        s_next       <= s_reg;
        n_next       <= n_reg;
        b_next       <= b_reg;
        rx_done_tick <= '0';
        case state_reg is
            when Idle =>
                if rx = '0' then
                    s_next     <= (others => '0');
                    state_next <= Start;
                end if;

            when Start =>
                if s_tick = '1' then
                    if s_reg = 7 then
                        s_next     <= (others => '0');
                        n_next     <= (others => '0');
                        state_next <= Data;
                    else
                        s_next <= s_reg + 1; 
                    end if;
                end if;

            when Data =>
                if s_tick = '1' then
                    if s_reg = 15 then
                        s_next <= (others => '0');
                        b_next <= rx & b_reg(7 downto 1);
                        if n_reg = (D_BIT - 1) then
                            state_next <= Stop;
                        else
                            n_next <= n_reg + 1;
                        end if;
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

            when Stop =>
                if s_tick = '1' then
                    if s_reg = SB_TICK - 1 then
                        rx_done_tick <= '1';
                        state_next   <= Idle;
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
        end case;
    end process;

    dout <= b_reg;

end Behavioral;
