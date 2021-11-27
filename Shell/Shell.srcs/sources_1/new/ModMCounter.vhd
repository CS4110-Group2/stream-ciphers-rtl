

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ModMCounterEn is
    Generic( N : integer := 4;
             M : Integer := 16);
    Port ( en : in STD_LOGIC;
           rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           clr : in STD_LOGIC;
           q : out STD_LOGIC_VECTOR (N-1 downto 0);
           max_tick : out STD_LOGIC);
end ModMCounterEn;

architecture Behavioral of ModMCounterEn is

    signal state_reg, state_next : unsigned(N-1 downto 0) := (others => '0');

begin

    process(clk, rst, en)
    begin
        if rst = '1' then
            state_reg <= (others => '0');
        elsif(rising_edge(clk)) then
            if(en = '1') then
                state_reg <= state_next;
            end if;
        end if;
    end process;

    --Next state logic
    state_next <= (others => '0') when state_reg = M-1 or clr = '1' else
                  state_reg + 1;

    --Output logic
    q <= std_logic_vector(state_reg);
    max_tick <= '1' when state_reg = M-1 else
                '0';

end Behavioral;
