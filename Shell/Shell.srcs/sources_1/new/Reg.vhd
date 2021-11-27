

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Reg is
    Generic( SIZE : integer := 8);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           load : in STD_LOGIC;
           clear : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (SIZE-1 downto 0);
           data_out : out STD_LOGIC_VECTOR (SIZE-1 downto 0));
end Reg;

architecture Behavioral of Reg is

    signal q_reg, q_next : STD_LOGIC_VECTOR(SIZE-1 downto 0);

begin

    process(clk, rst)
    begin
        if rst = '1' then
            q_reg <= (others => '0');
        elsif rising_edge(clk) then
            q_reg <= q_next;
        end if;
    end process;

    process(q_reg, load, data_in, clear)
    begin
        q_next <= q_reg;
        if clear = '1' then
            q_next <= (others => '0');
        elsif(load = '1') then
            q_next <= data_in;
        else
        end if;
    end process;

    data_out <= q_reg;

end Behavioral;
