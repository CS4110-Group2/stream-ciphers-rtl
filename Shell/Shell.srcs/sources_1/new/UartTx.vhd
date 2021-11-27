

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UartTx is
    Generic( D_BIT : integer := 8;
             SB_TICK : integer := 16);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           din : in STD_LOGIC_VECTOR (7 downto 0);
           tx_start : in STD_LOGIC;
           s_tick : in STD_LOGIC;
           tx_done_tick : out STD_LOGIC;
           tx : out STD_LOGIC);
end UartTx;

architecture Behavioral of UartTx is

    type State_Type is (Idle, Start, Data, Stop);
    signal state_reg, state_next : State_type;
    signal s_reg, s_next : unsigned(D_BIT - 1 downto 0);
    signal n_reg, n_next : unsigned(D_BIT - 1 downto 0);
    signal b_reg, b_next : std_logic_vector(D_BIT - 1 downto 0);
    signal tx_reg, tx_next : std_logic;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            state_reg <= Idle;
            s_reg <= (others => '0');
            n_reg <= (others => '0');
            b_reg <= (others => '0');
            tx_reg <= '1';
        elsif rising_edge(clk) then
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
        end if;
    end process;

    process(s_tick, tx_start, din, s_reg, n_reg, b_reg, tx_reg, state_reg)
    begin
        state_next <= state_reg;
        s_next <= s_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        tx_next <= tx_reg;
        tx_done_tick <= '0';
        case state_reg is
            when Idle =>
                tx_next <= '1';
                if tx_start = '1' then
                    state_next <= Start;
                    s_next <= (others => '0');
                    b_next <= din;
                end if;

            when Start =>
                tx_next <= '0';
                if s_tick = '1' then
                    if s_reg = (SB_TICK - 1) then
                        state_next <= Data;
                        s_next <= (others => '0');
                        n_next <= (others => '0');
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

            when Data =>
                tx_next <= b_reg(0); 
                if s_tick = '1' then
                    if s_reg = (SB_TICK - 1) then
                        s_next <= (others => '0');
                        b_next <= '0' & b_reg(D_BIT - 1 downto 1);
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
                tx_next <= '1';
                if s_tick = '1' then
                    if s_reg = (SB_TICK - 1) then

                        tx_done_tick <= '1';
                        state_next <= Idle;
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;
        end case;
    end process;

    tx <= tx_reg;

end Behavioral;
